# PsGitPrompt profile snippet - feel free to edit.
# This file is dot-sourced from your $PROFILE by Install.ps1 (via the PSGITPROMPT-MARKER
# block); editing it takes effect the next time you open a shell (or run:  . $PROFILE).
#
# Uncomment and change any of these to override the defaults. Settings are read fresh on
# every prompt draw, so you can also just change them interactively at any time:
#   $GitPromptSettings.ShowSha = $false

Import-Module (Join-Path $env:PSGITPROMPT_DIR 'PsGitPrompt.psd1') -Force

# $GitPromptSettings.ShowOrigin      = $true    # show the remote origin URL
# $GitPromptSettings.ShowSha         = $true    # show the abbreviated commit hash
# $GitPromptSettings.ShowStashes     = $true    # show the stash count
# $GitPromptSettings.ShowTracking    = $true    # show "<- upstream" when it differs from origin/<branch>
# $GitPromptSettings.UseAsciiMarkers = $false   # swap glyphs (-> M: [ahead N]) for plain ASCII
# $GitPromptSettings.InlineMode      = $true    # two-line (git info inline) vs three-line layout

Install-GitPromptFunction
