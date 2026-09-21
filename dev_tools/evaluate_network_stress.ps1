param([Parameter(Mandatory=$true)][string]$RunRoot, [switch]$Race, [switch]$HostDrop)
$ErrorActionPreference = 'Stop'
$rows = @('host','client') | ForEach-Object { Get-Content -LiteralPath (Join-Path $RunRoot "$_/stress.json") -Raw | ConvertFrom-Json }
$checks = @()
foreach ($row in $rows) {
    if ($row.schema -ne 1 -or $row.protocol -ne 4 -or $row.wire -ne 3) { throw 'Stress report schema/identity mismatch' }
    if (-not $row.functional.ok) { throw 'Stress functional failure' }
    if ($row.emulator.queue_high_water -gt 256 -or $row.prediction.history_high_water -gt 240 -or $row.interpolation.high_water -gt 32) { throw 'Stress bounds exceeded' }
    if ($row.emulator.profile.simulated_rtt_ms -gt 200 -and $row.telemetry.warning_entries -eq 0) { throw 'Missing measured connection warning in high latency scenario' }
    if ($null -eq $row.cleanup -or $row.cleanup.queue -ne 0 -or $row.cleanup.history -ne 0 -or $row.cleanup.interpolation -ne 0 -or $row.cleanup.pool_active -ne 0 -or $row.cleanup.events -ne 0) { throw 'Stress teardown invariant failed' }
    $rtt = $row.telemetry.metrics.measured_rtt_ms.p50
    $band = if ($rtt -le 80) { 'near_ideal' } elseif ($rtt -le 150) { 'comfortable' } elseif ($rtt -le 200) { 'playable' } else { 'warning' }
    $checks += [ordered]@{ role=$row.role; measured_rtt_p50_ms=$rtt; estimated_one_way_p50_ms=$rtt/2;
        simulated_rtt_ms=$row.emulator.profile.simulated_rtt_ms; measured_band=$band;
        functional_pass=$true; comfort_certification='not specified numerically by master';
        ordinary_error_p95_px=$row.prediction.ordinary_error_px.p95; queue_peak=$row.emulator.queue_high_water }
}
$clockSkew = [Math]::Abs($rows[0].functional.clock - $rows[1].functional.clock)
if (-not $HostDrop -and $clockSkew -gt 30) { throw 'Clock convergence failed' }
if ($Race -and -not $HostDrop) {
    if ($rows[0].functional.winner -ne $rows[1].functional.winner -or $rows[0].functional.pool_active -ne 0 -or $rows[1].functional.pool_active -ne 0) { throw 'Race convergence/cleanup failed' }
}
[ordered]@{ schema=1; functional_pass=$true; clock_skew_ticks=$clockSkew; endpoints=$checks } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $RunRoot 'evaluation.json') -Encoding UTF8
