param(
    [string]$Godot = 'godot',
    [ValidateSet('clean', 'wan', 'stress')][string]$Profile = 'clean',
    [ValidateSet(20, 30)][int]$Snapshots = 20,
    [ValidateSet(30, 60, 144)][int]$Fps = 60,
    [int]$Port = 24715,
    [switch]$Rendered,
    [switch]$Reconnect,
    [switch]$Lifecycle,
    [switch]$Race,
    [switch]$Malicious,
    [switch]$Retry,
    [ValidateSet('training', 'industrial')][string]$Map = 'training'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$runId = [guid]::NewGuid().ToString('N')
$runRoot = Join-Path $projectRoot "builds/validation/m15-$Profile-$Snapshots-$Fps-$runId"
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
$processes = @()
try {
    foreach ($role in @('host', 'client')) {
        $roleRoot = Join-Path $runRoot $role
        New-Item -ItemType Directory -Force -Path $roleRoot | Out-Null
        $arguments = @('--path', ('"' + $projectRoot + '"'),
            '--max-fps', "$Fps", '--log-file', ('"' + (Join-Path $roleRoot 'godot.log') + '"'))
        if (-not $Rendered) { $arguments += '--headless' }
        $arguments += @('--', '--local-network', "--role=$role", "--port=$Port", '--auto=true',
            '--timeout-ticks=600',
            "--ticks=$(if ($Race) { if ($role -eq 'host') { 2400 } else { 2280 } } elseif ($role -eq 'host') { 1200 } else { 1080 })", "--emulation=$Profile",
            "--snapshots=$Snapshots", "--seed=$(if ($role -eq 'host') { 15 } else { 29 })",
            "--map=$Map", "--reconnect=$($Reconnect.ToString().ToLowerInvariant())",
            "--lifecycle=$($Lifecycle.ToString().ToLowerInvariant())",
            "--race=$($Race.ToString().ToLowerInvariant())", "--malicious=$($Malicious.ToString().ToLowerInvariant())",
            "--retry=$($Retry.ToString().ToLowerInvariant())",
            ('"--evidence=' + (Join-Path $roleRoot 'screen') + '"'))
        $process = Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden `
            -RedirectStandardOutput (Join-Path $roleRoot 'stdout.log') `
            -RedirectStandardError (Join-Path $roleRoot 'stderr.log') `
            -Environment @{ APPDATA = $roleRoot; LOCALAPPDATA = $roleRoot }
        $null = $process.Handle
        $processes += $process
        # Both run real time; no --fixed-fps, which accelerates headless clocks independently.
    }
    foreach ($process in $processes) {
        if (-not $process.WaitForExit(45000)) { throw "M15 process $($process.Id) timeout; $runRoot" }
        $process.WaitForExit()
    }
    $reports = @()
    foreach ($role in @('host', 'client')) {
        $stdout = Get-Content (Join-Path $runRoot "$role/stdout.log") -Raw
        $stderr = Get-Content (Join-Path $runRoot "$role/stderr.log") -Raw
        if ($stderr -match '(SCRIPT ERROR|ERROR:|WARNING:)' -or -not $stdout.Contains('PROJECTVELOCITY_M15_PROCESS_OK')) {
            Write-Output $stdout
            Write-Output $stderr
            throw "M15 $role failed; $runRoot"
        }
        $line = ($stdout -split "`n" | Where-Object { $_.StartsWith('M15_RESULT=') })
        $reports += $line.Substring(11) | ConvertFrom-Json
    }
    if ($reports[0].session -ne $reports[1].session) { throw 'Host/guest session mismatch' }
    if ([Math]::Abs($reports[0].clock - $reports[1].clock) -gt 30) { throw 'Match clock drift exceeds 500ms under emulation' }
    if (-not $reports[0].round_complete -and ($reports[0].clock - $reports[1].clock) -ne ($reports[0].host_tick - $reports[1].host_tick)) {
        throw 'Clock is inconsistent with authoritative host ticks'
    }
    if ($Reconnect -and $reports[0].events.RESUME -lt 1) { throw 'Reconnect did not resume the match' }
    if ($Lifecycle) {
        foreach ($report in $reports) {
            foreach ($event in @('DEATH', 'RESPAWN', 'CHECKPOINT', 'FINISH', 'HAZARD')) {
                if ($report.events.$event -lt 1) { throw "Missing replicated lifecycle event $event" }
            }
        }
    }
    if ($Race) {
        foreach ($report in $reports) {
            foreach ($event in @('SKIPPED_CHECKPOINT', 'DEATH', 'RESPAWN', 'CHECKPOINT', 'FINISH',
                'WINNER', 'SAW_HIT', 'LASER_HIT', 'TURRET_FIRE', 'PROJECTILE_HIT', 'POOL_RETURN', 'JUMP_PAD', 'PLATFORM_BREAK', 'PLATFORM_RESTORE')) {
                if ($report.events.$event -lt 1) { throw "M16 missing replicated event $event; $runRoot" }
            }
            if ($report.pool_nodes -ne 10) { throw 'M16 pool invariant' }
            if ($Retry) {
                if (-not $report.retry_started -or $report.winner -ne 0) { throw 'M16 ready/retry did not start round2' }
            } elseif (-not $report.round_complete -or $report.winner -ne 2) { throw 'M16 both Finish/winner did not complete round' }
        }
        if ($reports[0].pool_peak -gt 10) { throw 'M16 pool cap exceeded' }
        if ($Retry -and ($reports[0].input_ack -eq 65535 -or $reports[0].input_ack -lt 30 -or $reports[1].history -gt 30)) {
            throw 'M16 round2 input sequence was not consumed/reconciled'
        }
        if ($reports[0].pool_active -ne 0) { throw 'M16 pool not retired after results' }
        if (($reports[0].progress | ConvertTo-Json -Compress) -ne ($reports[1].progress | ConvertTo-Json -Compress)) {
            throw 'M16 durable progress failed to converge'
        }
        foreach ($event in @('CHECKPOINT', 'FINISH', 'DEATH', 'SAW_HIT', 'LASER_HIT', 'PROJECTILE_HIT', 'WINNER')) {
            if ($reports[0].events.$event -ne $reports[1].events.$event) { throw "M16 event count mismatch/double presentation: $event" }
        }
        if ($Malicious -and ($reports[1].claims_sent -lt 100 -or $reports[0].authority_rejections -lt 100)) {
            throw 'M16 forged packet rejection was not exercised'
        }
    }
    if (-not $reports[0].status.Contains('paused')) { throw 'Missing orderly guest disconnect observation' }
    $reports | ConvertTo-Json -Depth 6
    Write-Output "PROJECTVELOCITY_M15_LOCALHOST_OK $runRoot"
} finally {
    foreach ($process in $processes) {
        # CI's console launcher owns an engine child; timeout cleanup must include that child.
        if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        $process.Dispose()
    }
}
