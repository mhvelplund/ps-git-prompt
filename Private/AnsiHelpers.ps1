# ANSI SGR color codes, ported 1:1 from bash-git-prompt-hook.sh / bash-smart-prompt.sh.
# Codes are terminal-standard and OS-agnostic; only the escaping mechanism changes for PowerShell.
$script:AnsiCodes = @{
    Reset                 = '0'

    Marker                = '0;34'   # standalone `| |` delimiters
    OriginText            = '0;35'
    BranchDefault         = '36;1'
    BranchLocal           = '0;34'   # no upstream configured
    BranchEmptyRepoSuffix = '0;31'
    BranchMaster          = '32;1'
    BranchDevelop         = '31;1'
    BranchRelease         = '33;1'
    TrackingSuffix        = '0;34'
    DetachedHead          = '45;33;1'
    GitState              = '44;33;1'
    TagAnnotated          = '33;1'
    TagNonAnnotated       = '0;33'
    Sha                   = '36'
    ShaSeparator          = '0;34'
    AheadBehind           = '0;33'
    Stash                 = '0;34'
    Modified              = '0;31'

    # Smart-prompt only
    UserElevated          = '0;31'
    PromptElevated        = '1;33'
    UserSsh               = '0;33'
    PromptSsh             = '1;32'
    UserLocal             = '0;32'
    PromptLocal           = '1;33'
    LineMarkerOk          = '0;34'
    LineMarkerFail        = '0;31'
    ExitCode              = '0;31'
    Timer                 = '0;36'
    JobCount              = '0;34'
    Cwd                   = '0;33'
    ClearGlyph            = '0;1;36'
}

$script:AnsiStripRegex = [regex]'\x1b\[[0-9;]*m'

function New-AnsiText {
    <#
        Wraps text in the named SGR code and a trailing reset.
        Empty text stays empty (no stray escape sequences for absent segments).
    #>
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string] $Code,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Text
    )
    if ([string]::IsNullOrEmpty($Text)) { return '' }
    "`e[${Code}m${Text}`e[0m"
}

function Get-AnsiVisibleLength {
    [OutputType([int])]
    param([Parameter(Mandatory)] [AllowEmptyString()] [string] $Text)
    ($script:AnsiStripRegex.Replace($Text, '')).Length
}

# UTF-8 (default) vs ASCII fallback marker tables, keyed by $Settings.UseAsciiMarkers.
$script:Markers = @{
    Utf8 = @{
        Origin                 = '→'
        ModifiedPrefix         = '≠'
        StashPrefix            = 'ᐅ'
        AheadMarker            = '↑'
        BehindMarker           = '↓'
        AheadBehindSep         = ' '
        AheadBehindPre         = ''
        AheadBehindPost        = ''
        TrackingSep            = ' ← '
        TagAnnotatedPrefix     = '✔'
        TagNonAnnotatedPrefix  = '✘'
        TagNonAnnotatedSuffix  = ''
        ClearGlyph             = '⏎'
    }
    Ascii = @{
        Origin                 = ''
        ModifiedPrefix         = 'M:'
        StashPrefix            = 'stashes:'
        AheadMarker            = 'ahead '
        BehindMarker           = 'behind '
        AheadBehindSep         = ', '
        AheadBehindPre         = '['
        AheadBehindPost        = ']'
        TrackingSep            = ' <- '
        TagAnnotatedPrefix     = ''
        TagNonAnnotatedPrefix  = ''
        TagNonAnnotatedSuffix  = ':non-annotated'
        ClearGlyph             = '⏎'   # not marker-toggle-controlled, kept identical in both modes
    }
}

function Get-GitPromptMarkers {
    [OutputType([hashtable])]
    param([Parameter(Mandatory)] $Settings)
    if ($Settings.UseAsciiMarkers) { return $script:Markers.Ascii }
    return $script:Markers.Utf8
}
