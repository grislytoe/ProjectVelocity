param(
    [string]$Godot = 'godot',
    [ValidateSet('solo_traversal','hazard_station','ui_first_open','load_leak')][string]$Scenario = 'hazard_station',
    [ValidateSet('quality','low','balanced','performance')][string]$Preset = 'balanced',
    [ValidateSet('1920x1080','1280x800')][string]$Resolution = '1280x800',
    [switch]$Unpaced,
    [ValidateRange(1,3600)][int]$Warmup = 120,
    [ValidateRange(30,20000)][int]$Samples = 600,
    [ValidateRange(10,600)][int]$TimeoutSeconds = 180,
    [string]$HardwareClass = 'actual-not-certified',
    [switch]$CertifiedHardware,
    [switch]$CompositionOnly,
    [switch]$AllowSoftwareRenderer
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$runId = [guid]::NewGuid().ToString('N')
$runRoot = Join-Path $projectRoot "builds/validation/m24-$Scenario-$Preset-$runId"
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
$resultPath = Join-Path $runRoot 'result.json'
$stdout = Join-Path $runRoot 'stdout.log'
$stderr = Join-Path $runRoot 'stderr.log'
$sha = (git rev-parse HEAD).Trim()
$activePower = (powercfg /getactivescheme | Out-String).Trim()
$powerState = if ($activePower -match '\(([^)]+)\)') { $Matches[1] } else { 'reported-in-local-log' }
$arguments = @('--path', ('"' + $projectRoot + '"'), '--resolution', $Resolution, '--audio-driver', 'Dummy', '--log-file',
    ('"' + (Join-Path $runRoot 'godot.log') + '"'))
if (-not $Unpaced) { $arguments += @('--max-fps', '60') }
$arguments += @('dev_tools/performance_benchmark.tscn', '--', "--scenario=$Scenario", "--preset=$Preset",
    "--resolution=$Resolution", "--paced=$(( -not $Unpaced).ToString().ToLowerInvariant())",
    "--vsync=$(( -not $Unpaced).ToString().ToLowerInvariant())", "--warmup=$Warmup", "--samples=$Samples",
    ('"--output=' + $resultPath.Replace('\','/') + '"'), "--git-sha=$sha", ('"--hardware-class=' + $HardwareClass + '"'),
    "--certified-hardware=$($CertifiedHardware.ToString().ToLowerInvariant())",
    "--composition-only=$($CompositionOnly.ToString().ToLowerInvariant())", ('"--power-state=' + $powerState + '"'))
$process = $null
$memorySamples = @()
try {
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while (-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
        $process.Refresh()
        $memorySamples += [pscustomobject]@{ working_set = [int64]$process.WorkingSet64; private_bytes = [int64]$process.PrivateMemorySize64 }
        Start-Sleep -Milliseconds 250
    }
    if (-not $process.HasExited) { throw "M24 benchmark timeout after $TimeoutSeconds seconds" }
    $process.WaitForExit()
    $output = (Get-Content -LiteralPath $stdout -Raw) + (Get-Content -LiteralPath $stderr -Raw)
    $diagnostics = @($output -split "`r?`n" | Where-Object { $_ -match '^(SCRIPT ERROR:|Parse Error|ERROR:|WARNING:)' })
    if ($AllowSoftwareRenderer) {
        $diagnostics = @($diagnostics | Where-Object {
            $_ -ne 'WARNING: Your video card drivers seem not to support the required OpenGL 3.3 version, switching to ANGLE.'
        })
    }
    if ($process.ExitCode -ne 0 -or $diagnostics.Count -gt 0 `
        -or -not $output.Contains('PROJECTVELOCITY_M24_BENCHMARK_OK')) {
        Write-Output $output
        throw "M24 benchmark failed; inspect $runRoot"
    }
    if (-not (Test-Path -LiteralPath $resultPath)) { throw 'M24 result JSON missing' }
    $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
    if ($memorySamples.Count -eq 0) { throw 'External process memory sampler produced no samples' }
    $result.memory.process_working_set_bytes = [int64](($memorySamples | Measure-Object working_set -Maximum).Maximum)
    $result.memory.process_private_bytes = [int64](($memorySamples | Measure-Object private_bytes -Maximum).Maximum)
    $result.environment | Add-Member -NotePropertyName driver -NotePropertyValue `
        (Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty DriverVersion)
    $result.environment | Add-Member -NotePropertyName ram_bytes -NotePropertyValue `
        ([int64](Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory)
    $result.environment.power_state = $powerState
    $result | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $resultPath -Encoding UTF8
    $memorySamples | Export-Csv -LiteralPath (Join-Path $runRoot 'process-memory.csv') -NoTypeInformation
    Write-Output "PROJECTVELOCITY_M24_LAUNCH_OK $runRoot"
    Write-Output ($result | ConvertTo-Json -Depth 4)
} finally {
    if ($null -ne $process) {
        if (-not $process.HasExited) {
            & taskkill.exe /PID $process.Id /T /F | Out-Null
            $process.WaitForExit(5000) | Out-Null
        }
        $process.Dispose()
    }
}
