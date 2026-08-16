function Test-IsSshSession {
    <#
        Windows OpenSSH Server sets the same SSH_CLIENT/SSH_CONNECTION/SSH_TTY
        env vars as Linux sshd, so this mirrors the bash original's check.
    #>
    [OutputType([bool])]
    param()
    [bool]($env:SSH_CLIENT -or $env:SSH_CONNECTION -or $env:SSH_TTY)
}
