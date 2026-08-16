<#
.SYNOPSIS
    Installs PsGitPrompt into your PowerShell profile.
.DESCRIPTION
    Analog of the bash original's install-prompt.sh. Does NOT copy any files - the module is
    referenced in place from this repo's own location (like bash's GIT_PROMPT_DIR), so a later
    `git pull` in this repo picks up updates automatically. Idempotent: running this again after
    a successful install just reports that it's already installed.

    Appends a marker-delimited block to $PROFILE.CurrentUserAllHosts that sets
    $env:PSGITPROMPT_DIR and dot-sources Scripts\ProfileSnippet.ps1 - the one file you're meant
    to hand-edit afterwards to change settings (see Scripts\ProfileSnippet.ps1). Then opens that
    file for editing.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$snippetPath = Join-Path $PSScriptRoot 'ProfileSnippet.ps1'
$profilePath = $PROFILE.CurrentUserAllHosts

$markerBegin = '# BEGIN - PSGITPROMPT-MARKER'
$markerEnd = '# END - PSGITPROMPT-MARKER'

if (-not (Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$existingContent = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
if ($existingContent -and $existingContent.Contains($markerBegin)) {
    Write-Host "PsGitPrompt is already installed in '$profilePath'."
} else {
    Write-Host "Installing PsGitPrompt in '$profilePath'"
    $block = @"

$markerBegin
`$env:PSGITPROMPT_DIR = "$repoRoot"
. "$snippetPath"
$markerEnd
"@
    Add-Content -Path $profilePath -Value $block
}

$env:PSGITPROMPT_DIR = $repoRoot

# Open the user-editable snippet for customization.
$editor = $null
$editorArgs = @()
if ($env:EDITOR) {
    $editor = $env:EDITOR
} elseif (Get-Command code -ErrorAction SilentlyContinue) {
    $editor = 'code'
    $editorArgs = @('-w')
} else {
    $editor = 'notepad.exe'
}

Write-Host "Opening '$snippetPath' with '$editor' so you can review/customize your settings."
& $editor @editorArgs $snippetPath
$editorExit = $LASTEXITCODE

Write-Host "Installation done. Restart your shell, or run '. `$PROFILE' to pick it up now."
exit $editorExit
