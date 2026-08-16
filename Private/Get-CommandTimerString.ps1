$script:LastTimerHistoryId = -1
$script:LastTimerText = ''

function Format-TimerDelta {
    <#
        Tiered, most-significant-unit-first formatting, ported 1:1 from bash-command-timer-hook.sh:
          hours   -> "H:MMh"
          minutes -> "M:SSm"
          seconds -> "S.Ts" (tenths, dropped if zero) or "Ss"
          else    -> "~MSms" (literal tilde prefix)
    #>
    [OutputType([string])]
    param([Parameter(Mandatory)] [int] $DeltaMs)
    $ms = $DeltaMs % 1000
    $s = [int]($DeltaMs / 1000) % 60
    $m = [int]($DeltaMs / 60000) % 60
    $h = [int]($DeltaMs / 3600000)
    if ($h -gt 0) { return ('{0}:{1:D2}h' -f $h, $m) }
    if ($m -gt 0) { return ('{0}:{1:D2}m' -f $m, $s) }
    if ($s -gt 0) {
        $tenths = [int]($ms / 100)
        if ($tenths -gt 0) { return ('{0}.{1}s' -f $s, $tenths) }
        return "${s}s"
    }
    return "~${ms}ms"
}

function Get-CommandTimerString {
    <#
        Uses PowerShell's native per-command history timestamps instead of replicating bash's
        manual DEBUG-trap Stopwatch emulation - simpler, and avoids the bash original's edge
        case where a blank Enter (no command executed, so its DEBUG trap never fires) leaves
        timer_start unset and produces a garbage elapsed time. Here, a blank Enter just leaves
        the previously displayed value unchanged (no new History entry to time).
    #>
    [OutputType([string])]
    param()
    $h = Get-History -Count 1
    if (-not $h) { return $script:LastTimerText }
    if ($h.Id -eq $script:LastTimerHistoryId) { return $script:LastTimerText }
    $script:LastTimerHistoryId = $h.Id
    if ($h.EndExecutionTime -and $h.StartExecutionTime) {
        $deltaMs = [int]($h.EndExecutionTime - $h.StartExecutionTime).TotalMilliseconds
        $script:LastTimerText = Format-TimerDelta -DeltaMs $deltaMs
    }
    $script:LastTimerText
}
