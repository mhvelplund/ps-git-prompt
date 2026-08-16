function Get-GitPromptStatus {
    <#
    .SYNOPSIS
        Computes the colored git-status text for a directory, without printing anything.
    .DESCRIPTION
        Analog of the bash original's git_bash_prompt() function/module boundary: a pure
        function of the repo state plus the settings toggles, independently usable outside the
        smart prompt (e.g. from a custom prompt function).
    .PARAMETER RightLength
        Column budget for inline/right-side rendering (analog of GIT_PROMPT_RIGHT_LENGTH).
        0 (default) means "separate-line mode" - OwnLineText is populated with the full,
        undegraded line. When positive, the 7-tier width ladder is applied: if it fits,
        InlineText holds the result (Fits = $true); if nothing fits even after full
        degradation, OwnLineText holds the reduced fallback line (shortened origin, no
        tracking suffix) for the caller to render on its own line instead.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string] $Path = (Get-Location).ProviderPath,
        [int] $RightLength = 0,
        $Settings = $global:GitPromptSettings
    )

    $info = Get-GitStatusInfo -Path $Path -Settings $Settings
    $result = [PSCustomObject]@{
        IsGitRepo   = $info.IsGitRepo
        Fits        = $false
        Tier        = 0
        InlineText  = ''
        OwnLineText = ''
    }
    if (-not $info.IsGitRepo) { return $result }

    $segments = Format-GitStatusSegments -Info $info -Settings $Settings

    if ($RightLength -gt 0) {
        $ladder = Resolve-GitPromptWidthLadder -Segments $segments -Budget $RightLength -Settings $Settings
        $result.Fits = $ladder.Fits
        $result.Tier = $ladder.Tier
        if ($ladder.Fits) {
            $result.InlineText = $ladder.Text
        } else {
            $result.OwnLineText = Format-GitPromptOwnLine -Segments $segments -ShortOrigin -ExcludeTracking
        }
    } else {
        $result.OwnLineText = Format-GitPromptOwnLine -Segments $segments
    }

    $result
}
