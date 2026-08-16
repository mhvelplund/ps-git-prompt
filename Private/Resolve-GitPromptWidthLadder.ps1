function Resolve-GitPromptWidthLadder {
    <#
        Reproduces the bash original's fixed 7-tier degradation ladder for inline/right-side
        mode, verified line-by-line against bash-git-prompt-hook.sh (lines 296-364). Each tier
        is tried in order against the SAME segment set (re-assembled, not string-spliced), and
        the first one whose visible (ANSI-stripped) length fits the budget wins:
          1. everything, full origin
          2. drop SHA
          3. drop SHA, shorten origin to its last path segment
          4. drop SHA, drop origin entirely
          5. drop SHA, drop origin, drop stash
          6. drop SHA, drop origin, drop stash, drop tracking suffix (branch/state/modified/aheadbehind only)
          7. give up - caller should fall back to Format-GitPromptOwnLine -ShortOrigin -ExcludeTracking

        Branch/state, modified count, and ahead/behind are never dropped - if tier 6 doesn't
        fit, tier 7 signals the caller to abandon inline mode entirely.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] $Segments,
        [Parameter(Mandatory)] [int] $Budget,
        [Parameter(Mandatory)] $Settings
    )
    $c = $script:AnsiCodes
    $hasOrigin = [bool]($Settings.ShowOrigin -and $Segments.OriginText)
    $arrowGlyph = New-AnsiText -Code $c.OriginText -Text $Segments.OriginMarker
    $frontArrow = "  $arrowGlyph "
    $preOrigin = "  $arrowGlyph  "

    $tiers = @(
        @{ IncludeSha = $true;  IncludeStash = $true;  IncludeTracking = $true;  IncludeOrigin = $true;  ShortOrigin = $false }
        @{ IncludeSha = $false; IncludeStash = $true;  IncludeTracking = $true;  IncludeOrigin = $true;  ShortOrigin = $false }
        @{ IncludeSha = $false; IncludeStash = $true;  IncludeTracking = $true;  IncludeOrigin = $true;  ShortOrigin = $true }
        @{ IncludeSha = $false; IncludeStash = $true;  IncludeTracking = $true;  IncludeOrigin = $false; ShortOrigin = $false }
        @{ IncludeSha = $false; IncludeStash = $false; IncludeTracking = $true;  IncludeOrigin = $false; ShortOrigin = $false }
        @{ IncludeSha = $false; IncludeStash = $false; IncludeTracking = $false; IncludeOrigin = $false; ShortOrigin = $false }
    )

    for ($i = 0; $i -lt $tiers.Count; $i++) {
        $t = $tiers[$i]
        $text = $frontArrow + $Segments.BranchState
        if ($t.IncludeSha) { $text += $Segments.Sha }
        $text += $Segments.Modified + $Segments.AheadBehind
        if ($t.IncludeStash) { $text += $Segments.Stash }
        if ($t.IncludeTracking) { $text += $Segments.Tracking }
        if ($t.IncludeOrigin -and $hasOrigin) {
            $originText = if ($t.ShortOrigin) { $Segments.OriginShortText } else { $Segments.OriginText }
            $text += $preOrigin + $originText
        }
        if ((Get-AnsiVisibleLength $text) -le $Budget) {
            return [PSCustomObject]@{ Fits = $true; Tier = $i + 1; Text = $text }
        }
    }

    [PSCustomObject]@{ Fits = $false; Tier = 7; Text = $null }
}
