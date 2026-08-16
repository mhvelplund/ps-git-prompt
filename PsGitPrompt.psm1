$moduleRoot = $PSScriptRoot

foreach ($file in Get-ChildItem -Path (Join-Path $moduleRoot 'Private') -Filter '*.ps1') {
    . $file.FullName
}
foreach ($file in Get-ChildItem -Path (Join-Path $moduleRoot 'Public') -Filter '*.ps1') {
    . $file.FullName
}

if (-not $global:GitPromptSettings) {
    $global:GitPromptSettings = New-GitPromptSettings
}

Export-ModuleMember -Function 'Get-GitPromptStatus', 'Install-GitPromptFunction', 'New-GitPromptSettings', 'Write-GitPromptStandalone'
