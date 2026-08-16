function Format-GitStatusSegments {
    <#
        Builds the colored, ready-to-concatenate text pieces for one git status snapshot.
        Each piece already carries its own leading separator whitespace (mirrors how the
        bash original concatenates), and is '' when the underlying value is absent/zero —
        callers just concatenate non-empty pieces in order, no join-separator logic needed.

        Deliberate deviation from the bash original: there, $GIT_PROMPT_SHOW_ORIGIN only
        gates origin display in inline/right-side mode - separate-line mode always showed
        origin regardless of the setting. Here ShowOrigin consistently gates origin in every
        mode, which is simpler and less surprising.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] $Info,
        [Parameter(Mandatory)] $Settings
    )
    $m = Get-GitPromptMarkers -Settings $Settings
    $c = $script:AnsiCodes

    # --- Branch / tag / detached-HEAD / state ---
    $branchState = ''
    if ($Info.IsDetached) {
        if ($Info.IsAnnotatedTag) {
            $inner = "$($m.TagAnnotatedPrefix)$($Info.TagName)"
            $branchState = New-AnsiText -Code $c.DetachedHead -Text " $inner "
        } elseif ($Info.IsNonAnnotatedTag) {
            $inner = "$($m.TagNonAnnotatedPrefix)$($Info.TagName)$($m.TagNonAnnotatedSuffix)"
            $branchState = New-AnsiText -Code $c.DetachedHead -Text " $inner "
        } elseif ($Info.BranchName -eq 'NO BRANCH') {
            $branchState = New-AnsiText -Code $c.DetachedHead -Text ' NO BRANCH '
        } else {
            $branchState = New-AnsiText -Code $c.DetachedHead -Text " $($Info.Sha) "
        }
    } else {
        $color = $c.BranchDefault
        if ($Info.BranchName -in @('master', 'main')) { $color = $c.BranchMaster }
        elseif ($Info.BranchName -eq 'develop') { $color = $c.BranchDevelop }
        elseif ($Info.BranchName -match '(?i)^release-') { $color = $c.BranchRelease }
        elseif (-not $Info.HasUpstream) { $color = $c.BranchLocal }
        $branchState = New-AnsiText -Code $color -Text " $($Info.BranchName)"
        if ($Info.IsEmptyRepo) {
            $branchState += (New-AnsiText -Code $c.ShaSeparator -Text '|') +
                             (New-AnsiText -Code $c.BranchEmptyRepoSuffix -Text 'empty-repository')
        }
    }
    if ($Info.State) {
        $branchState += New-AnsiText -Code $c.GitState -Text " $($Info.State) "
    }

    $sha = ''
    if ($Settings.ShowSha -and $Info.Sha -and -not $Info.IsDetached) {
        $sha = (New-AnsiText -Code $c.ShaSeparator -Text '|') + (New-AnsiText -Code $c.Sha -Text $Info.Sha)
    }

    $modified = ''
    if ($Info.DirtyCount -gt 0) {
        $modified = New-AnsiText -Code $c.Modified -Text " $($m.ModifiedPrefix)$($Info.DirtyCount)"
    }

    $aheadBehind = ''
    if ($Info.Ahead -gt 0 -or $Info.Behind -gt 0) {
        $parts = [System.Collections.Generic.List[string]]::new()
        if ($Info.Ahead -gt 0) { $parts.Add("$($m.AheadMarker)$($Info.Ahead)") }
        if ($Info.Behind -gt 0) { $parts.Add("$($m.BehindMarker)$($Info.Behind)") }
        $inner = "$($m.AheadBehindPre)$($parts -join $m.AheadBehindSep)$($m.AheadBehindPost)"
        $aheadBehind = New-AnsiText -Code $c.AheadBehind -Text " $inner"
    }

    $stash = ''
    if ($Settings.ShowStashes -and $Info.StashCount -gt 0) {
        $stash = New-AnsiText -Code $c.Stash -Text " $($m.StashPrefix)$($Info.StashCount)"
    }

    $tracking = ''
    if ($Settings.ShowTracking -and $Info.HasUpstream -and $Info.Upstream -ne "origin/$($Info.BranchName)") {
        $tracking = New-AnsiText -Code $c.TrackingSuffix -Text "$($m.TrackingSep)$($Info.Upstream)"
    }

    $originText = ''
    $originShortText = ''
    if ($Settings.ShowOrigin) {
        $originValue = if ($Info.Origin) { $Info.Origin } else { '[no origin]' }
        $originText = New-AnsiText -Code $c.OriginText -Text $originValue
        $short = $originValue
        $idx = $short.LastIndexOf(':'); if ($idx -ge 0) { $short = $short.Substring($idx + 1) }
        $idx = $short.LastIndexOf('/'); if ($idx -ge 0) { $short = $short.Substring($idx + 1) }
        $originShortText = New-AnsiText -Code $c.OriginText -Text $short
    }

    [PSCustomObject]@{
        BranchState     = $branchState
        Sha             = $sha
        Modified        = $modified
        AheadBehind     = $aheadBehind
        Stash           = $stash
        Tracking        = $tracking
        OriginText      = $originText
        OriginShortText = $originShortText
        OriginMarker    = $m.Origin
    }
}

function Format-GitPromptOwnLine {
    <#
        The "dedicated line" rendering shared by standalone mode, three-line smart-prompt
        mode, and the width-ladder's tier-7 exhausted fallback (which additionally shortens
        the origin and drops the tracking suffix).
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] $Segments,
        [switch] $ShortOrigin,
        [switch] $ExcludeTracking
    )
    $origin = if ($ShortOrigin) { $Segments.OriginShortText } else { $Segments.OriginText }
    $tracking = if ($ExcludeTracking) { '' } else { $Segments.Tracking }
    $origin + $Segments.BranchState + $Segments.Sha + $Segments.Modified + $Segments.AheadBehind + $Segments.Stash + $tracking
}
