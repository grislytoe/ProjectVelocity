param([string]$Godot = "godot", [switch]$ExportWindows)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$logRoot = Join-Path $projectRoot "builds/validation"
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
[System.IO.File]::WriteAllText((Join-Path $projectRoot "builds/.gdignore"), "")

function Invoke-GodotCheck {
    param([string]$Name, [string[]]$Arguments, [string]$Marker = "")
    $stdout = Join-Path $logRoot "$Name.stdout.log"
    $stderr = Join-Path $logRoot "$Name.stderr.log"
    $process = Start-Process -FilePath $Godot -ArgumentList $Arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $processHandle = $process.Handle
    if (-not $process.WaitForExit(120000)) {
        $process.Kill($true)
        throw "$Name timed out"
    }
    $process.WaitForExit()
    $output = (Get-Content $stdout -Raw -Encoding UTF8) + (Get-Content $stderr -Raw -Encoding UTF8)
    Write-Output $output
    if ($process.ExitCode -ne 0 -or $output -match '(?m)(SCRIPT ERROR:|ERROR:|Parse Error|WARNING:)') {
        throw "$Name failed (exit $($process.ExitCode)); inspect builds/validation"
    }
    if ($Marker -and -not $output.Contains($Marker)) { throw "$Name missing success marker" }
}

Invoke-GodotCheck -Name "version" -Arguments @("--version") -Marker "4.7.2.stable."
Invoke-GodotCheck -Name "import" -Arguments @("--headless", "--path", ".", "--import")
& (Join-Path $PSScriptRoot "check_trial_hash.ps1") -Godot $Godot
Get-ChildItem core,gameplay,networking,visuals,save_system,map_data,ui,tests,dev_tools -Recurse -Filter "*.gd" | ForEach-Object {
    $relative = $_.FullName.Substring($projectRoot.Length + 1).Replace("\", "/")
    Invoke-GodotCheck -Name ("parse-" + $_.BaseName) -Arguments @("--headless", "--path", ".", "--check-only", "--script", $relative)
}
Invoke-GodotCheck -Name "tests" -Arguments @("--headless", "--path", ".", "--script", "tests/bootstrap_test.gd") -Marker "PROJECTVELOCITY_TESTS_OK"
Invoke-GodotCheck -Name "m1-tests" -Arguments @("--headless", "--path", ".", "--script", "tests/save_foundation_test.gd") -Marker "PROJECTVELOCITY_M1_TESTS_OK"
Invoke-GodotCheck -Name "m2-tests" -Arguments @("--headless", "--path", ".", "--script", "tests/input_layer_test.gd") -Marker "PROJECTVELOCITY_M2_TESTS_OK"
Invoke-GodotCheck -Name "m3-motor" -Arguments @("--headless", "--path", ".", "--script", "tests/player_motor_test.gd") -Marker "PROJECTVELOCITY_M3_MOTOR_OK"
Invoke-GodotCheck -Name "m3-restart" -Arguments @("--headless", "--path", ".", "--script", "tests/player_restart_test.gd") -Marker "PROJECTVELOCITY_M3_RESTART_OK"
$replayHashes = @()
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m3-physics-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/player_physics_test.gd") -Marker "PROJECTVELOCITY_M3_PHYSICS_OK"
    $log = Get-Content (Join-Path $logRoot "m3-physics-$fps.stdout.log") -Raw
    if ($log -notmatch 'M3_REPLAY_HASH=([0-9a-f]{64})') { throw "Missing physics replay hash" }
    $replayHashes += $Matches[1]
}
if (@($replayHashes | Select-Object -Unique).Count -ne 1) { throw "M3 physics differs between render rates" }
Invoke-GodotCheck -Name "m4-tests" -Arguments @("--headless", "--path", ".", "--script", "tests/character_presentation_test.gd") -Marker "PROJECTVELOCITY_M4_OK"
Invoke-GodotCheck -Name "m4-no-visuals" -Arguments @("--headless", "--path", ".", "--fixed-fps", "60", "--script", "tests/player_physics_test.gd", "--", "--without-presentation") -Marker "PROJECTVELOCITY_M3_PHYSICS_OK"
$noVisuals = Get-Content (Join-Path $logRoot "m4-no-visuals.stdout.log") -Raw
if ($noVisuals -notmatch 'M3_REPLAY_HASH=([0-9a-f]{64})' -or $Matches[1] -ne $replayHashes[0]) { throw "Presentation affects physics replay" }
Invoke-GodotCheck -Name "boot" -Arguments @("--headless", "--path", ".", "--quit-after", "600", "--", "--smoke-test") -Marker "PROJECTVELOCITY_BOOT_OK"
Invoke-GodotCheck -Name "m5-tests" -Arguments @("--headless", "--path", ".", "--script", "tests/camera_test.gd") -Marker "PROJECTVELOCITY_M5_OK"
$cameraHashes = @()
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m5-physics-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/player_physics_test.gd", "--", "--with-camera") -Marker "PROJECTVELOCITY_M3_PHYSICS_OK"
    $log = Get-Content (Join-Path $logRoot "m5-physics-$fps.stdout.log") -Raw
    if ($log -notmatch 'M3_REPLAY_HASH=([0-9a-f]{64})' -or $Matches[1] -ne $replayHashes[0]) { throw "Camera affects gameplay" }
    if ($log -notmatch 'M5_CAMERA_HASH=([0-9a-f]{64})') { throw "Missing camera hash" }
    $cameraHashes += $Matches[1]
}
if (@($cameraHashes | Select-Object -Unique).Count -ne 1) { throw "Camera differs between render rates" }
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m6-playground-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/test_playground_test.gd") -Marker "PROJECTVELOCITY_M6_OK"
}
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m7-lifecycle-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/checkpoint_respawn_test.gd") -Marker "PROJECTVELOCITY_M7_OK"
}
$platformHashes = @()
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m8-platforms-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/platform_modules_test.gd") -Marker "PROJECTVELOCITY_M8_OK"
    $log = Get-Content (Join-Path $logRoot "m8-platforms-$fps.stdout.log") -Raw
    if ($log -notmatch 'M8_REPLAY_HASH=([0-9a-f]{64})') { throw "Missing platform replay hash" }
    $platformHashes += $Matches[1]
}
if (@($platformHashes | Select-Object -Unique).Count -ne 1) { throw "Platforms differ between render rates" }
$hazardHashes = @()
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m9-hazards-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/hazard_modules_test.gd") -Marker "PROJECTVELOCITY_M9_OK"
    $log = Get-Content (Join-Path $logRoot "m9-hazards-$fps.stdout.log") -Raw
    if ($log -notmatch 'M9_REPLAY_HASH=([0-9a-f]{64})') { throw "Missing hazard replay hash" }
    $hazardHashes += $Matches[1]
}
if (@($hazardHashes | Select-Object -Unique).Count -ne 1) { throw "Hazards differ between render rates" }
$trialHashes = @()
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m10-trial-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/time_trial_test.gd") -Marker "PROJECTVELOCITY_M10_OK"
    $log = Get-Content (Join-Path $logRoot "m10-trial-$fps.stdout.log") -Raw
    if ($log -notmatch 'M10_REPLAY_HASH=([0-9a-f]{64})') { throw "Missing trial replay hash" }
    $trialHashes += $Matches[1]
}
if (@($trialHashes | Select-Object -Unique).Count -ne 1) { throw "Time Trial differs between render rates" }
Invoke-GodotCheck -Name "m11-ui" -Arguments @("--headless", "--path", ".", "--script", "tests/ui_foundation_test.gd") -Marker "PROJECTVELOCITY_M11_OK"
Invoke-GodotCheck -Name "m12-settings" -Arguments @("--headless", "--path", ".", "--script", "tests/settings_test.gd") -Marker "PROJECTVELOCITY_M12_OK"
Invoke-GodotCheck -Name "m12-ui" -Arguments @("--headless", "--path", ".", "--script", "tests/settings_runtime_test.gd") -Marker "PROJECTVELOCITY_M12_RUNTIME_OK"
Invoke-GodotCheck -Name "m13-maps" -Arguments @("--headless", "--path", ".", "--script", "tests/map_framework_test.gd") -Marker "PROJECTVELOCITY_M13_OK"
New-Item -ItemType Directory -Force builds/m14 | Out-Null
Invoke-GodotCheck -Name "m14-maps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "60", "--script", "tests/industrial_map_test.gd") -Marker "PROJECTVELOCITY_M14_MAP_OK"
$industrialHashes = @()
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m14-route-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/industrial_route_test.gd") -Marker "PROJECTVELOCITY_M14_ROUTE_OK"
    $routeLog = Get-Content (Join-Path $logRoot "m14-route-$fps.stdout.log") -Raw
    if ($routeLog -notmatch 'M14_REPLAY_HASH=([0-9a-f]{64})') { throw "Missing Industrial input replay hash" }
    $industrialHashes += $Matches[1]
}
if (@($industrialHashes | Select-Object -Unique).Count -ne 1) { throw "Industrial replay differs between render rates" }
foreach ($route in @('shortcut', 'recovery')) {
    Invoke-GodotCheck -Name "m14-$route" -Arguments @("--headless", "--path", ".", "--fixed-fps", "60", "--script", "tests/industrial_route_test.gd", "--", "--$route") -Marker "PROJECTVELOCITY_M14_ROUTE_OK"
}
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m15-core-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/network_core_test.gd") -Marker "PROJECTVELOCITY_M15_CORE_OK"
    & (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Fps $fps -Port (24715 + $fps)
}
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Profile wan -Snapshots 30 -Reconnect -Port 24915
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Profile stress -Map industrial -Port 24916
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Lifecycle -Port 24917
foreach ($fps in @(30, 60, 144)) {
    Invoke-GodotCheck -Name "m16-race-$fps" -Arguments @("--headless", "--path", ".", "--fixed-fps", "$fps", "--script", "tests/network_race_test.gd") -Marker "PROJECTVELOCITY_M16_RACE_OK"
}
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Race -Malicious -Map industrial -Port 24921
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Race -Malicious -Map industrial -Profile stress -Port 24922
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Race -Map industrial -Profile wan -Snapshots 30 -Reconnect -Port 24923
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Race -Retry -Map industrial -Port 24926
& (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Race -Reconnect -DisconnectTick 1900 -Map industrial -Port 24927

git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "Staged whitespace validation failed" }
git diff --check
if ($LASTEXITCODE -ne 0) { throw "Git whitespace validation failed" }

if ($ExportWindows) {
    New-Item -ItemType Directory -Force -Path "builds/windows" | Out-Null
    Invoke-GodotCheck -Name "export" -Arguments @("--headless", "--path", ".", "--export-debug", '"Windows Staging"', "builds/windows/ProjectVelocity.exe")
    $Godot = Join-Path $projectRoot "builds/windows/ProjectVelocity.exe"
    Invoke-GodotCheck -Name "export-boot" -Arguments @("--headless", "--quit-after", "600", "--", "--smoke-test") -Marker "PROJECTVELOCITY_BOOT_OK"
    Invoke-GodotCheck -Name "m15-export-boot" -Arguments @("--headless", "--quit-after", "30", "--", "--local-network", "--role=host", "--port=24920") -Marker "M15_READY role=host protocol=3"
    & (Join-Path $PSScriptRoot "test_local_network.ps1") -Godot $Godot -Race -Malicious -Map industrial -Port 24924
    $editorLog = Get-Content (Join-Path $logRoot "boot.stdout.log") -Raw
    $exportLog = Get-Content (Join-Path $logRoot "export-boot.stdout.log") -Raw
    if ($editorLog -notmatch 'PV_MAP_BOOT_HASH=([0-9a-f]{64})') { throw "Missing editor map identity" }
    $mapHash = $Matches[1]
    if ($exportLog -notmatch 'PV_MAP_BOOT_HASH=([0-9a-f]{64})' -or $Matches[1] -ne $mapHash) {
        throw "Export map identity differs from editor"
    }
    if ($editorLog -notmatch 'PV_INDUSTRIAL_BOOT_HASH=([0-9a-f]{64})') { throw "Missing Industrial editor identity" }
    $industrialHash = $Matches[1]
    if ($exportLog -notmatch 'PV_INDUSTRIAL_BOOT_HASH=([0-9a-f]{64})' -or $Matches[1] -ne $industrialHash) {
        throw "Export Industrial identity differs from editor"
    }
}
Write-Output "M0-M16 validation passed, including separate-process localhost network sessions."
