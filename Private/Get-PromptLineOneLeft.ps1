function Get-PromptLineOneLeft {
    <#
        Builds the "[exitcode] timer [jobcount] cwd" segment shared by both the two-line
        inline layout (line 1) and the three-line layout (line 2). Also used, via its visible
        (ANSI-stripped) length, to compute the console-width budget for the inline git segment.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [int] $ExitCode,
        [Parameter(Mandatory)] [bool] $Succeeded,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Timer,
        [Parameter(Mandatory)] [int] $JobCount,
        [Parameter(Mandatory)] [string] $Cwd
    )
    $c = $script:AnsiCodes
    $text = ''
    if (-not $Succeeded) {
        $codeToShow = if ($ExitCode) { $ExitCode } else { 1 }
        $text += New-AnsiText -Code $c.ExitCode -Text "$codeToShow "
    }
    $text += New-AnsiText -Code $c.Timer -Text $Timer
    if ($JobCount -gt 0) {
        $text += New-AnsiText -Code $c.JobCount -Text " $JobCount"
    }
    $text += ' ' + (New-AnsiText -Code $c.Cwd -Text $Cwd)
    $text
}

function Get-PromptDisplayCwd {
    <#
        Analog of bash's \w prompt escape: shortens the home directory prefix to '~'.
    #>
    [OutputType([string])]
    param([Parameter(Mandatory)] [string] $Path)
    $home = $env:USERPROFILE
    if ($home -and $Path.StartsWith($home, [StringComparison]::OrdinalIgnoreCase)) {
        $rest = $Path.Substring($home.Length)
        return "~$rest"
    }
    $Path
}
