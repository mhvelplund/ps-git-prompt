function Write-GitPromptStandalone {
    <#
    .SYNOPSIS
        Prints the git status as a single "| ... |" line - the standalone-mode analog of
        sourcing bash-git-prompt-hook.sh directly (without the smart-prompt wrapper).
    .DESCRIPTION
        Prints nothing when the given path isn't inside a git working tree, matching the
        bash original's behavior of leaving the line empty outside a repo.
    #>
    [CmdletBinding()]
    param(
        [string] $Path = (Get-Location).ProviderPath,
        $Settings = $global:GitPromptSettings
    )
    $status = Get-GitPromptStatus -Path $Path -RightLength 0 -Settings $Settings
    if (-not $status.IsGitRepo) { return }

    $marker = New-AnsiText -Code $script:AnsiCodes.Marker -Text '|'
    Write-Host "$marker $($status.OwnLineText) $marker"
}
