function Get-ClearLinePrefix {
    <#
        If the previous command's output didn't end with a trailing newline (cursor isn't at
        column 0), shows a bold-cyan clear-line glyph and starts a fresh line before the real
        prompt draws - same visible behavior as the bash original's PS1_CLEARLINE, achieved
        more directly here: PowerShell can emit an explicit newline rather than relying on
        bash's pad-the-line-until-it-wraps trick.
    #>
    [OutputType([string])]
    param()
    try {
        if ([Console]::CursorLeft -eq 0) { return '' }
    } catch {
        return ''
    }
    $m = Get-GitPromptMarkers -Settings $global:GitPromptSettings
    $glyph = New-AnsiText -Code $script:AnsiCodes.ClearGlyph -Text $m.ClearGlyph
    "$glyph`n"
}
