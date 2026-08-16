function New-GitPromptSettings {
    <#
    .SYNOPSIS
        Creates a default PsGitPrompt settings object.
    .DESCRIPTION
        Analog of the bash original's GIT_PROMPT_* environment variables, exposed as a single
        settings object (posh-git-style convention) rather than env vars. The module assigns
        one instance to $global:GitPromptSettings on import; edit its properties directly
        (e.g. $GitPromptSettings.ShowSha = $false) to change behavior - settings are read
        fresh on every prompt draw, so no re-import is needed.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    [PSCustomObject]@{
        PSTypeName      = 'PsGitPrompt.Settings'
        ShowOrigin      = $true
        ShowSha         = $true
        ShowStashes     = $true
        ShowTracking    = $true
        UseAsciiMarkers = $false
        InlineMode      = $true
    }
}
