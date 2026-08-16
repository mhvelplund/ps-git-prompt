<#
.SYNOPSIS
    Removes the PsGitPrompt marker block from your PowerShell profile.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$profilePath = $PROFILE.CurrentUserAllHosts
$markerBegin = '# BEGIN - PSGITPROMPT-MARKER'
$markerEnd = '# END - PSGITPROMPT-MARKER'

if (-not (Test-Path $profilePath)) {
    Write-Host "No profile found at '$profilePath' - nothing to do."
    return
}

$lines = Get-Content -Path $profilePath
$startIndex = -1
$endIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq $markerBegin) { $startIndex = $i }
    if ($lines[$i].Trim() -eq $markerEnd) { $endIndex = $i; break }
}

if ($startIndex -lt 0 -or $endIndex -lt 0) {
    Write-Host "PsGitPrompt marker block not found in '$profilePath' - nothing to do."
    return
}

# Also drop a single leading blank line before the marker, if Install.ps1 put one there.
if ($startIndex -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$startIndex - 1])) {
    $startIndex--
}

$newLines = @()
if ($startIndex -gt 0) { $newLines += $lines[0..($startIndex - 1)] }
if ($endIndex + 1 -lt $lines.Count) { $newLines += $lines[($endIndex + 1)..($lines.Count - 1)] }

Set-Content -Path $profilePath -Value $newLines
Remove-Item Env:\PSGITPROMPT_DIR -ErrorAction SilentlyContinue

Write-Host "Removed the PsGitPrompt block from '$profilePath'."
Write-Host "This only affects new shells - restart any open shells to fully unload it."
