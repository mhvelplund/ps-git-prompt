<#
.SYNOPSIS
    Sets up the same helpful git aliases and color config as the bash original's
    install-git-aliases.sh.
.DESCRIPTION
    Standalone and optional - not run by Install.ps1, same as the bash original isn't wired
    into install-prompt.sh. Run it yourself when you want it: .\Scripts\Install-GitAliases.ps1
    Straight 1:1 port; every value below is OS-agnostic 'git config --global' data.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Write-Host 'Setting up some helpful Git aliases'

$aliases = [ordered]@{
    lg   = "log --graph --decorate --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
    lga  = "log --graph --decorate --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative --all"
    st   = 'status'
    ci   = 'commit'
    br   = 'branch'
    co   = 'checkout'
    df   = 'diff'
    dc   = 'diff --cached'
    lol  = 'log --graph --decorate --pretty=oneline --abbrev-commit'
    lola = 'log --graph --decorate --pretty=oneline --abbrev-commit --all'
    ls   = 'ls-files'
    ign  = 'ls-files -o -i --exclude-standard'
}
foreach ($name in $aliases.Keys) {
    git config --global "alias.$name" $aliases[$name]
}

git config --global color.ui auto
git config --global branch.current 'yellow reverse'
git config --global branch.local yellow
git config --global branch.remote green
git config --global diff.meta 'yellow bold'
git config --global diff.frag 'magenta bold'
git config --global diff.old 'red bold'
git config --global diff.new 'green bold'
git config --global status.added yellow
git config --global status.changed green
git config --global status.untracked cyan

Write-Host 'Done.'
