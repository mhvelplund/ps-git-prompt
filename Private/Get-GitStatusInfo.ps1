function Get-GitStatusInfo {
    <#
        Gathers git repo state in as few git.exe invocations as possible (Windows process
        creation is much pricier than Linux fork/exec). The primary call is
        `git status --porcelain=v2 --branch`, which in one shot replaces the bash original's
        separate rev-parse/symbolic-ref/for-each-ref/rev-list/rev-parse --short/status calls.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] $Settings
    )

    $result = [PSCustomObject]@{
        IsGitRepo         = $false
        IsEmptyRepo       = $false
        BranchName        = ''
        IsDetached        = $false
        Sha               = ''
        Upstream          = ''
        HasUpstream       = $false
        Ahead             = 0
        Behind            = 0
        DirtyCount        = 0
        State             = ''
        IsAnnotatedTag    = $false
        IsNonAnnotatedTag = $false
        TagName           = ''
        Origin            = ''
        StashCount        = 0
    }

    $statusLines = git -C $Path status --porcelain=v2 --branch --untracked-files=normal 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $result
    }
    $result.IsGitRepo = $true

    foreach ($line in @($statusLines)) {
        switch -Regex ($line) {
            '^# branch\.oid (.+)$' {
                $oid = $Matches[1]
                if ($oid -eq '(initial)') { $result.IsEmptyRepo = $true }
                else { $result.Sha = $oid.Substring(0, [Math]::Min(8, $oid.Length)) }
                break
            }
            '^# branch\.head (.+)$' {
                $head = $Matches[1]
                if ($head -eq '(detached)') { $result.IsDetached = $true }
                else { $result.BranchName = $head }
                break
            }
            '^# branch\.upstream (.+)$' {
                $result.Upstream = $Matches[1]
                $result.HasUpstream = $true
                break
            }
            '^# branch\.ab \+(\d+) -(\d+)$' {
                $result.Ahead = [int]$Matches[1]
                $result.Behind = [int]$Matches[2]
                break
            }
            default {
                if (-not $line.StartsWith('#')) { $result.DirtyCount++ }
            }
        }
    }

    if ($result.IsDetached -and $result.IsEmptyRepo) {
        $result.BranchName = 'NO BRANCH'
    }

    $gitDirRaw = git -C $Path rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0 -and $gitDirRaw) {
        $gitDir = if ([System.IO.Path]::IsPathRooted($gitDirRaw)) { $gitDirRaw } else { Join-Path $Path $gitDirRaw }
        if ((Test-Path (Join-Path $gitDir 'rebase-merge') -PathType Container) -or
            (Test-Path (Join-Path $gitDir 'rebase-apply') -PathType Container)) {
            $result.State = 'REBASING'
        } elseif (Test-Path (Join-Path $gitDir 'MERGE_HEAD')) {
            $result.State = 'MERGING'
        } elseif (Test-Path (Join-Path $gitDir 'CHERRY_PICK_HEAD')) {
            $result.State = 'CHERRY-PICKING'
        } elseif (Test-Path (Join-Path $gitDir 'BISECT_LOG')) {
            $result.State = 'BISECTING'
        }
    }

    if ($Settings.ShowOrigin) {
        $originRaw = git -C $Path config --get remote.origin.url 2>$null
        if ($LASTEXITCODE -eq 0 -and $originRaw) {
            $result.Origin = $originRaw -replace '%[0-9A-Fa-f]{2}', [char]0x00A4
        } else {
            $result.Origin = '[no origin]'
        }
    }

    if ($Settings.ShowStashes) {
        $stashLines = @(git -C $Path stash list 2>$null)
        $result.StashCount = $stashLines.Count
    }

    if ($result.IsDetached -and -not $result.IsEmptyRepo) {
        $tagName = git -C $Path describe --exact-match HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $tagName) {
            $result.IsAnnotatedTag = $true
            $result.TagName = $tagName
        } else {
            $tagName = git -C $Path describe --exact-match --tags HEAD 2>$null
            if ($LASTEXITCODE -eq 0 -and $tagName) {
                $result.IsNonAnnotatedTag = $true
                $result.TagName = $tagName
            }
        }
    }

    $result
}
