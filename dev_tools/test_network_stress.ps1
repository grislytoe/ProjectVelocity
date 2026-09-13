param([string]$Godot = 'godot', [switch]$Extended, [switch]$Rendered)
$ErrorActionPreference = 'Stop'
$runCases = @(
    @{ Profile='rtt150'; Race=$true; Malicious=$true; Map='industrial' },
    @{ Profile='combined'; Race=$true; Map='industrial'; Reconnect=$true; Snapshots=30 },
    @{ Profile='combined'; Race=$true; Map='industrial'; Retry=$true; Snapshots=30 }
)
if ($Extended) {
    $runCases = @()
    foreach ($profile in @('clean','rtt80','rtt150','rtt200','rtt250')) {
        $runCases += @{ Profile=$profile; Race=$true; Malicious=$true; Map='industrial'; Rendered=[bool]$Rendered }
    }
    $runCases += @(
        @{ Profile='combined'; Race=$true; Map='industrial'; Reconnect=$true; Snapshots=30 },
        @{ Profile='rtt200'; Race=$true; Map='industrial'; Reconnect=$true; DisconnectTick=1900 },
        @{ Profile='rtt250'; Race=$true; Malicious=$true; Map='industrial'; Fps=30; Rendered=[bool]$Rendered; Resolution='1920x1080' },
        @{ Profile='rtt150'; Race=$true; Malicious=$true; Map='industrial'; Fps=144; Rendered=[bool]$Rendered; Resolution='1920x1080' },
        @{ Profile='combined'; Race=$true; Map='industrial'; Reconnect=$true; Snapshots=30 },
        @{ Profile='clean'; ProfileChange=$true; Map='industrial' },
        @{ Profile='rtt250'; HostDrop=$true; DisconnectTick=900; Map='industrial' },
        @{ Profile='combined'; Race=$true; Map='industrial'; Retry=$true; Snapshots=30 }
    )
}
$index = 0
foreach ($case in $runCases) {
    $index++
    Write-Output "M17 heartbeat: case $index/$($runCases.Count) $($case.Profile)"
    & (Join-Path $PSScriptRoot 'test_local_network.ps1') -Godot $Godot -Port (25100 + $index) @case
}
Write-Output 'PROJECTVELOCITY_M17_MATRIX_OK'
