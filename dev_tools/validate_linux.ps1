param([string]$Godot = 'godot')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$logRoot = Join-Path $projectRoot 'builds/validation-linux'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'builds/.gdignore'), '')

function Invoke-GodotCheck {
    param([string]$Name, [string[]]$Arguments, [string]$Marker = '')
    $stdout = Join-Path $logRoot "$Name.stdout.log"
    $stderr = Join-Path $logRoot "$Name.stderr.log"
    $process = Start-Process -FilePath $Godot -ArgumentList $Arguments -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(360000)) {
        $process.Kill($true)
        throw "$Name timed out after 360 seconds"
    }
    $process.WaitForExit()
    $output = (Get-Content $stdout -Raw -Encoding UTF8) + (Get-Content $stderr -Raw -Encoding UTF8)
    Write-Output $output
    if ($process.ExitCode -ne 0 -or $output -match '(?m)(SCRIPT ERROR:|ERROR:|Parse Error|WARNING:)') {
        throw "$Name failed (exit $($process.ExitCode))"
    }
    if ($Marker -and -not $output.Contains($Marker)) { throw "$Name missing success marker" }
}

Invoke-GodotCheck 'version' @('--version') '4.7.2.stable.official.ed1daf0bf'
Invoke-GodotCheck 'import' @('--headless', '--path', '.', '--import')
& (Join-Path $PSScriptRoot 'check_trial_hash.ps1') -Godot $Godot

Get-ChildItem core,gameplay,networking,visuals,save_system,map_data,ui,tests,dev_tools -Recurse -Filter '*.gd' | ForEach-Object {
    $relative = $_.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
    Invoke-GodotCheck ("parse-" + $_.BaseName) @('--headless', '--path', '.', '--check-only', '--script', $relative)
}

$singleCases = @(
    @('m0', 'tests/bootstrap_test.gd', 'PROJECTVELOCITY_TESTS_OK'),
    @('m1', 'tests/save_foundation_test.gd', 'PROJECTVELOCITY_M1_TESTS_OK'),
    @('m2', 'tests/input_layer_test.gd', 'PROJECTVELOCITY_M2_TESTS_OK'),
    @('m3-motor', 'tests/player_motor_test.gd', 'PROJECTVELOCITY_M3_MOTOR_OK'),
    @('m3-restart', 'tests/player_restart_test.gd', 'PROJECTVELOCITY_M3_RESTART_OK'),
    @('m4', 'tests/character_presentation_test.gd', 'PROJECTVELOCITY_M4_OK'),
    @('m5', 'tests/camera_test.gd', 'PROJECTVELOCITY_M5_OK'),
    @('m11', 'tests/ui_foundation_test.gd', 'PROJECTVELOCITY_M11_OK'),
    @('m12', 'tests/settings_test.gd', 'PROJECTVELOCITY_M12_OK'),
    @('m12-runtime', 'tests/settings_runtime_test.gd', 'PROJECTVELOCITY_M12_RUNTIME_OK'),
    @('m13', 'tests/map_framework_test.gd', 'PROJECTVELOCITY_M13_OK'),
    @('m14-map', 'tests/industrial_map_test.gd', 'PROJECTVELOCITY_M14_MAP_OK'),
    @('m19', 'tests/eos_adapter_test.gd', 'PROJECTVELOCITY_M19_POLICY_OK live=false native=false'),
    @('m20-contract', 'tests/lobby_contract_test.gd', 'PROJECTVELOCITY_M20_CONTRACT_OK live=false native=false'),
    @('m20-ui', 'tests/lobby_ui_test.gd', 'PROJECTVELOCITY_M20_UI_OK live=false native=false'),
    @('m21-ui', 'tests/online_match_ui_test.gd', 'PROJECTVELOCITY_M21_UI_OK'),
    @('m23', 'tests/art_pass_test.gd', 'PROJECTVELOCITY_M23_ART_OK'),
    @('m24', 'tests/performance_benchmark_test.gd', 'PROJECTVELOCITY_M24_PERFORMANCE_OK')
)
foreach ($case in $singleCases) {
    Invoke-GodotCheck $case[0] @('--headless', '--path', '.', '--script', $case[1]) $case[2]
}

$rateCases = @(
    @('m3-physics', 'tests/player_physics_test.gd', 'PROJECTVELOCITY_M3_PHYSICS_OK'),
    @('m6', 'tests/test_playground_test.gd', 'PROJECTVELOCITY_M6_OK'),
    @('m7', 'tests/checkpoint_respawn_test.gd', 'PROJECTVELOCITY_M7_OK'),
    @('m8', 'tests/platform_modules_test.gd', 'PROJECTVELOCITY_M8_OK'),
    @('m9', 'tests/hazard_modules_test.gd', 'PROJECTVELOCITY_M9_OK'),
    @('m10', 'tests/time_trial_test.gd', 'PROJECTVELOCITY_M10_OK'),
    @('m14-route', 'tests/industrial_route_test.gd', 'PROJECTVELOCITY_M14_ROUTE_OK'),
    @('m15', 'tests/network_core_test.gd', 'PROJECTVELOCITY_M15_CORE_OK'),
    @('m16', 'tests/network_race_test.gd', 'PROJECTVELOCITY_M16_RACE_OK'),
    @('m17', 'tests/network_stress_test.gd', 'PROJECTVELOCITY_M17_STRESS_OK'),
    @('m21', 'tests/online_series_test.gd', 'PROJECTVELOCITY_M21_SERIES_OK'),
    @('m22', 'tests/disconnect_reconnect_test.gd', 'PROJECTVELOCITY_M22_RECONNECT_OK')
)
foreach ($case in $rateCases) {
    foreach ($fps in @(30, 60, 144)) {
        Invoke-GodotCheck "$($case[0])-$fps" @('--headless', '--path', '.', '--fixed-fps', "$fps", '--script', $case[1]) $case[2]
    }
}

Invoke-GodotCheck 'boot' @('--headless', '--path', '.', '--quit-after', '900', '--', '--smoke-test') 'PROJECTVELOCITY_BOOT_OK'
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace validation failed.' }
git diff --check
if ($LASTEXITCODE -ne 0) { throw 'Git whitespace validation failed.' }
Write-Output 'M25_LINUX_AUTOMATED_VALIDATION_OK'
