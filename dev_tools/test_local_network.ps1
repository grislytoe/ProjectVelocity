param(
    [string]$Godot = 'godot',
    [ValidateSet('clean', 'wan', 'stress')][string]$Profile = 'clean',
    [ValidateSet(20, 30)][int]$Snapshots = 20,
    [ValidateSet(30, 60, 144)][int]$Fps = 60,
    [int]$Port = 24715,
    [switch]$Rendered,
    [switch]$Reconnect,
    [switch]$Lifecycle,
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
        $arguments = @('--path', ('"' + $projectRoot + '"'), 'res://networking/local_network.tscn',
            '--max-fps', "$Fps", '--log-file', ('"' + (Join-Path $roleRoot 'godot.log') + '"'))
        if (-not $Rendered) { $arguments += '--headless' }
        $arguments += @('--', "--role=$role", "--port=$Port", '--auto=true',
            "--ticks=$(if ($role -eq 'host') { 1200 } else { 1080 })", "--emulation=$Profile",
            "--snapshots=$Snapshots", "--seed=$(if ($role -eq 'host') { 15 } else { 29 })",
            "--map=$Map", "--reconnect=$($Reconnect.ToString().ToLowerInvariant())",
            "--lifecycle=$($Lifecycle.ToString().ToLowerInvariant())",
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
    if (($reports[0].clock - $reports[1].clock) -ne ($reports[0].host_tick - $reports[1].host_tick)) {
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
    if (-not $reports[0].status.Contains('paused')) { throw 'Missing orderly guest disconnect observation' }
    $reports | ConvertTo-Json -Depth 6
    Write-Output "PROJECTVELOCITY_M15_LOCALHOST_OK $runRoot"
} finally {
    foreach ($process in $processes) {
        if (-not $process.HasExited) { $process.Kill(); $process.WaitForExit() }
        $process.Dispose()
    }
}
