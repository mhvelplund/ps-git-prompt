@{
    RootModule           = 'PsGitPrompt.psm1'
    ModuleVersion        = '1.0.0'
    GUID                 = '7ef32266-a437-41df-8e8a-a5bb686904dd'
    Author               = 'Mads Hvelplund'
    Copyright            = '(c) 2026 Mads Hvelplund. PowerShell port of bash-git-prompt-hook by BlueWizardHat.'
    Description          = 'A git-aware, width-adaptive PowerShell prompt - a PowerShell 7 port of bash-git-prompt-hook.'
    PowerShellVersion    = '7.0'
    CompatiblePSEditions = @('Core')
    FunctionsToExport    = @('Get-GitPromptStatus', 'Install-GitPromptFunction', 'New-GitPromptSettings', 'Write-GitPromptStandalone')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags = @('git', 'prompt', 'PSEdition_Core')
        }
    }
}
