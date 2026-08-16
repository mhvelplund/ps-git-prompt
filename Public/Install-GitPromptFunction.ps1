# Defined at module scope (not nested inside Install-GitPromptFunction below) so this
# scriptblock's session-state binding stays the module's own - a `function global:prompt { }`
# statement defined *inside* another function loses that binding and can no longer resolve the
# module's private helpers (Get-GitStatusInfo, Get-ConsoleWidth, etc.) once installed globally.
$script:GitPromptScriptBlock = {
    # These two lines MUST be the very first statements in this scriptblock, in this order:
    # reading $? first (before it gets reset to $true by the assignment itself), then
    # $LASTEXITCODE (before any native command run later in this scriptblock - e.g. git.exe -
    # overwrites it). This mirrors bash's `last_status=$?` being first in PROMPT_COMMAND.
    $lastSucceeded = $?
    $lastExitCode = $global:LASTEXITCODE

    $settings = $global:GitPromptSettings
    $c = $script:AnsiCodes

    $clearPrefix = Get-ClearLinePrefix

    $timerText = Get-CommandTimerString
    $rawCwd = (Get-Location).ProviderPath
    $cwd = Get-PromptDisplayCwd -Path $rawCwd
    $jobCount = @(Get-Job -ErrorAction SilentlyContinue).Count

    $line1Left = Get-PromptLineOneLeft -ExitCode $lastExitCode -Succeeded $lastSucceeded `
        -Timer $timerText -JobCount $jobCount -Cwd $cwd

    if ($settings.InlineMode) {
        $budget = (Get-ConsoleWidth) - (Get-AnsiVisibleLength $line1Left) - 2
        $status = Get-GitPromptStatus -Path $rawCwd -RightLength $budget -Settings $settings
    } else {
        $status = Get-GitPromptStatus -Path $rawCwd -RightLength 0 -Settings $settings
    }

    $lineMarkerColor = if ($lastSucceeded) { $c.LineMarkerOk } else { $c.LineMarkerFail }
    $top = New-AnsiText -Code $lineMarkerColor -Text '┌ '
    $mid = New-AnsiText -Code $lineMarkerColor -Text '│ '
    $bottom = New-AnsiText -Code $lineMarkerColor -Text '└ '

    if (Test-IsElevated) {
        $userColor = $c.UserElevated; $promptColor = $c.PromptElevated; $promptSymbol = '#'
    } elseif (Test-IsSshSession) {
        $userColor = $c.UserSsh; $promptColor = $c.PromptSsh; $promptSymbol = '$'
    } else {
        $userColor = $c.UserLocal; $promptColor = $c.PromptLocal; $promptSymbol = '$'
    }
    $userHostText = (New-AnsiText -Code $userColor -Text $env:USERNAME) +
                    (New-AnsiText -Code $c.TrackingSuffix -Text '@') +
                    (New-AnsiText -Code $userColor -Text $env:COMPUTERNAME) +
                    (New-AnsiText -Code $promptColor -Text $promptSymbol) + ' '
    $bottomLine = "$bottom$userHostText"

    if ($status.IsGitRepo -and $status.Fits) {
        $result = "$top$line1Left$($status.InlineText)`n$bottomLine"
    } elseif ($status.IsGitRepo) {
        $result = "$top$($status.OwnLineText)`n$mid$line1Left`n$bottomLine"
    } else {
        $result = "$top$line1Left`n$bottomLine"
    }

    $Host.UI.RawUI.WindowTitle = "$env:USERNAME@$env:COMPUTERNAME`: $rawCwd"

    "$clearPrefix$result"
}

function Install-GitPromptFunction {
    <#
    .SYNOPSIS
        Installs the git-aware "smart prompt" as the session's `prompt` function.
    .DESCRIPTION
        Analog of bash-smart-prompt.sh: builds a two-line (git info inline, when it fits) or
        three-line (git info promoted to its own line) prompt, with exit code, a per-command
        timer, job count, cwd, and user@host, colored per elevation/SSH-session/last-exit-code.
    #>
    [CmdletBinding()]
    param($Settings = $global:GitPromptSettings)
    Set-Item -Path function:global:prompt -Value $script:GitPromptScriptBlock
}
