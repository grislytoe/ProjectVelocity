param(
    [string]$Godot = 'godot',
    [string]$ConditionFile = '',
    [ValidateSet('clean', 'wan', 'stress', 'rtt80', 'rtt150', 'rtt200', 'rtt250', 'combined')][string]$Profile = 'clean',
    [ValidateSet(20, 30)][int]$Snapshots = 20,
    [ValidateSet(30, 60, 144)][int]$Fps = 60,
    [ValidateRange(1024, 65535)][int]$Port = 24715,
    [int]$HostSeed = 15,
    [int]$ClientSeed = 29,
    [ValidateSet('1280x800', '1920x1080')][string]$Resolution = '1280x800',
    [switch]$ProfileChange,
    [switch]$HostDrop,
    [int]$DropDuration = 45,
    [switch]$Rendered,
    [switch]$Exported,
    [switch]$Reconnect,
    [int]$DisconnectTick = 700,
    [switch]$Lifecycle,
    [switch]$Race,
    [switch]$Malicious,
    [switch]$Retry,
    [switch]$Series,
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
        $arguments = @('--resolution', $Resolution, '--max-fps', "$Fps", '--log-file', ('"' + (Join-Path $roleRoot 'godot.log') + '"'))
        # Official export templates load their adjacent pack and disable --path overrides.
        if (-not $Exported) { $arguments += @('--path', ('"' + $projectRoot + '"')) }
        if (-not $Rendered) { $arguments += '--headless' }
        $arguments += @('--', '--local-network', "--role=$role", "--port=$Port", '--auto=true',
            '--timeout-ticks=600',
            "--ticks=$(if ($Series) { if ($role -eq 'host') { 3600 } else { 3480 } } elseif ($Race) { if ($role -eq 'host') { 2400 } else { 2280 } } elseif ($role -eq 'host') { 1200 } else { 1080 })", "--emulation=$Profile",
            "--snapshots=$Snapshots", "--capture-size=$Resolution", "--seed=$(if ($role -eq 'host') { $HostSeed } else { $ClientSeed })",
            "--map=$Map",
            "--disconnect-tick=$DisconnectTick",
            "--drop-at=$(if (($Reconnect -and $role -eq 'client') -or ($HostDrop -and $role -eq 'host')) { $DisconnectTick } else { -1 })",
            "--drop-duration=$DropDuration", "--profile-change=$($ProfileChange.ToString().ToLowerInvariant())",
            ('"--report=' + (Join-Path $roleRoot 'stress.json') + '"'),
            "--lifecycle=$($Lifecycle.ToString().ToLowerInvariant())",
            "--race=$($Race.ToString().ToLowerInvariant())", "--malicious=$($Malicious.ToString().ToLowerInvariant())",
            "--retry=$($Retry.ToString().ToLowerInvariant())",
            "--series=$($Series.ToString().ToLowerInvariant())", "--rounds=$(if ($Series -or $Retry) { 2 } else { 1 })",
            ('"--evidence=' + (Join-Path $roleRoot 'screen') + '"'))
        if ($ConditionFile) { $arguments += ('"--condition-file=' + (Resolve-Path -LiteralPath $ConditionFile).Path + '"') }
        $previousAppData = $env:APPDATA
        $previousLocalAppData = $env:LOCALAPPDATA
        try {
            $env:APPDATA = $roleRoot
            $env:LOCALAPPDATA = $roleRoot
            $process = Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden `
                -RedirectStandardOutput (Join-Path $roleRoot 'stdout.log') `
                -RedirectStandardError (Join-Path $roleRoot 'stderr.log')
        } finally {
            $env:APPDATA = $previousAppData
            $env:LOCALAPPDATA = $previousLocalAppData
        }
        $null = $process.Handle
        $processes += $process
        # Both run real time; no --fixed-fps, which accelerates headless clocks independently.
    }
    # Race fixtures need 40 seconds of physics plus startup/scheduling headroom on CI.
    $processTimeoutMs = if ($Series) { 120000 } elseif ($Race) { 90000 } else { 45000 }
    $deadline = [DateTime]::UtcNow.AddMilliseconds($processTimeoutMs)
    foreach ($process in $processes) {
        if (-not $process.WaitForExit([Math]::Max(1, [int]($deadline - [DateTime]::UtcNow).TotalMilliseconds))) { throw "M15 process $($process.Id) timeout; $runRoot" }
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
    if ($HostDrop) {
        if (-not $reports[1].status.Contains('Host disconnected')) { throw 'Host drop did not end guest session' }
    }
    if (-not $HostDrop -and [Math]::Abs($reports[0].clock - $reports[1].clock) -gt 30) { throw 'Match clock drift exceeds 500ms under emulation' }
    if (-not $HostDrop -and -not $reports[0].round_complete -and ($reports[0].clock - $reports[1].clock) -ne ($reports[0].host_tick - $reports[1].host_tick)) {
        throw 'Clock is inconsistent with authoritative host ticks'
    }
    if ($Reconnect) {
        $reconnectedAfterFinal = ($reports[0].phase -eq 9 -and $reports[1].phase -eq 9 -and
            $reports[0].round_complete -and $reports[1].round_complete)
        if (-not $reconnectedAfterFinal -and ($reports[0].events.RESUME -lt 1 -or $reports[1].events.RESUME -lt 1)) {
            throw 'Reconnect did not resume the match'
        }
    }
    if ($Lifecycle) {
        foreach ($report in $reports) {
            foreach ($event in @('DEATH', 'RESPAWN', 'CHECKPOINT', 'FINISH', 'HAZARD')) {
                if ($report.events.$event -lt 1) { throw "Missing replicated lifecycle event $event" }
            }
        }
    }
    if ($Race) {
        foreach ($report in $reports) {
            $requiredEvents = if ($Series) { @('CHECKPOINT', 'FINISH', 'WINNER', 'START', 'ROUND_TRANSITION') } else {
                @('SKIPPED_CHECKPOINT', 'DEATH', 'RESPAWN', 'CHECKPOINT', 'FINISH', 'WINNER',
                    'SAW_HIT', 'LASER_HIT', 'TURRET_FIRE', 'PROJECTILE_HIT', 'POOL_RETURN', 'JUMP_PAD', 'PLATFORM_BREAK', 'PLATFORM_RESTORE')
            }
            foreach ($event in $requiredEvents) {
                if ($report.events.$event -lt 1) { throw "M16 missing replicated event $event; $runRoot" }
            }
            if ($report.pool_nodes -ne 10) { throw 'M16 pool invariant' }
            if ($Series) {
                # Complete-series assertions follow below.
            } elseif ($Retry) {
                if (-not $report.retry_started -or $report.winner -ne 0) { throw 'M16 ready/retry did not start round2' }
            } elseif (-not $report.round_complete -or $report.winner -ne 2) { throw 'M16 both Finish/winner did not complete round' }
        }
        if ($reports[0].pool_peak -gt 10) { throw 'M16 pool cap exceeded' }
        if ($Retry -and -not $Series -and ($reports[0].input_ack -eq 65535 -or $reports[0].input_ack -lt 30 -or $reports[1].history -gt 30)) {
            throw 'M16 round2 input sequence was not consumed/reconciled'
        }
        if ($reports[0].pool_active -ne 0) { throw 'M16 pool not retired after results' }
        if (($reports[0].progress | ConvertTo-Json -Compress) -ne ($reports[1].progress | ConvertTo-Json -Compress)) {
            throw 'M16 durable progress failed to converge'
        }
        $pairedEvents = if ($Series) { @('CHECKPOINT', 'FINISH', 'WINNER', 'START') } else {
            @('CHECKPOINT', 'FINISH', 'DEATH', 'SAW_HIT', 'LASER_HIT', 'PROJECTILE_HIT', 'WINNER')
        }
        foreach ($event in $pairedEvents) {
            if ($reports[0].events.$event -ne $reports[1].events.$event) { throw "M16 event count mismatch/double presentation: $event" }
        }
        if ($Malicious -and ($reports[1].claims_sent -lt 100 -or $reports[0].authority_rejections -lt 100)) {
            throw 'M16 forged packet rejection was not exercised'
        }
    }
    if ($Series) {
        foreach ($report in $reports) {
            if ($report.round_index -ne 2 -or $report.rounds_total -ne 2 -or $report.round_results.Count -ne 2) {
                throw "M21 complete two-round series was not observed; $runRoot"
            }
            if ($report.phase -ne 9 -or $report.score[0] -ne 1 -or $report.score[1] -ne 1 -or $report.final_winner -ne 0) {
                throw "M21 final Draw/score mismatch; $runRoot"
            }
            if ($report.best_times[0] -lt 0 -or $report.best_times[1] -lt 0) { throw 'M21 best times missing' }
        }
        for ($round = 0; $round -lt 2; $round++) {
            if ($reports[0].round_results[$round][4] -ne $reports[1].round_results[$round][4] -or
                $reports[0].round_results[$round][5][0] -ne $reports[1].round_results[$round][5][0] -or
                $reports[0].round_results[$round][5][1] -ne $reports[1].round_results[$round][5][1] -or
                $reports[0].round_results[$round][2] -ne $reports[1].round_results[$round][2]) {
                throw 'M21 authoritative round history did not converge'
            }
        }
    }
    if (-not $HostDrop -and -not $Series -and $reports[0].phase -ne 9 -and -not $reports[0].status.Contains('paused')) {
        throw 'Missing orderly guest disconnect observation'
    }
    if ($ProfileChange) {
        foreach ($role in @('host','client')) {
            $stress = Get-Content -LiteralPath (Join-Path $runRoot "$role/stress.json") -Raw | ConvertFrom-Json
            if ($stress.profile_changes -ne 2) { throw 'Scheduled profile changes did not both apply' }
        }
    }
    & (Join-Path $PSScriptRoot 'evaluate_network_stress.ps1') -RunRoot $runRoot -Race:$Race -HostDrop:$HostDrop
    $reports | ConvertTo-Json -Depth 6
    Write-Output "PROJECTVELOCITY_M15_LOCALHOST_OK $runRoot"
} finally {
    foreach ($process in $processes) {
        # CI's console launcher owns an engine child; timeout cleanup must include that child.
        if (-not $process.HasExited) { & taskkill.exe /PID $process.Id /T /F | Out-Null; $process.WaitForExit(5000) | Out-Null }
        $process.Dispose()
    }
    # Retain evidence; remove only engine caches belonging to this unique run.
    $ownedRoot = [IO.Path]::GetFullPath($runRoot).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    foreach ($role in @('host','client')) {
        $cachePath = [IO.Path]::GetFullPath((Join-Path $runRoot "$role/Godot"))
        if (-not $cachePath.StartsWith($ownedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Cleanup escaped owned run directory' }
        if (Test-Path -LiteralPath $cachePath) { Remove-Item -LiteralPath $cachePath -Recurse -Force }
    }
}
