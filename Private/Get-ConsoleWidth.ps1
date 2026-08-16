function Get-ConsoleWidth {
    <#
        [Console]::WindowWidth throws in hosts without a real console handle (e.g. some
        non-interactive/redirected invocations). Falls back to $Host.UI.RawUI.WindowSize,
        then a sane default, rather than letting the prompt function throw.
    #>
    [OutputType([int])]
    param()
    try {
        return [Console]::WindowWidth
    } catch {
        try {
            return $Host.UI.RawUI.WindowSize.Width
        } catch {
            return 120
        }
    }
}
