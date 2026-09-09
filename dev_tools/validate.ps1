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
        $process.Kill()
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

& (Join-Path $PSScriptRoot "check_trial_hash.ps1")
Invoke-GodotCheck -Name "version" -Arguments @("--version") -Marker "4.7.2.stable."
Invoke-GodotCheck -Name "import" -Arguments @("--headless", "--path", ".", "--import")
Get-ChildItem core,gameplay,visuals,save_system,map_data,ui,tests,dev_tools -Recurse -Filter "*.gd" | ForEach-Object {
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
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw "Staged whitespace validation failed" }
git diff --check
if ($LASTEXITCODE -ne 0) { throw "Git whitespace validation failed" }

if ($ExportWindows) {
    New-Item -ItemType Directory -Force -Path "builds/windows" | Out-Null
    Invoke-GodotCheck -Name "export" -Arguments @("--headless", "--path", ".", "--export-debug", '"Windows Staging"', "builds/windows/ProjectVelocity.exe")
    $Godot = Join-Path $projectRoot "builds/windows/ProjectVelocity.exe"
    Invoke-GodotCheck -Name "export-boot" -Arguments @("--headless", "--quit-after", "600", "--", "--smoke-test") -Marker "PROJECTVELOCITY_BOOT_OK"
}
Write-Output "M0 + M1 + M2 + M3 + M4 + M5 + M6 + M7 + M8 + M9 + M10 + M11 + M12 validation passed. Camera and gameplay replays are render-rate independent; presentation/camera do not change movement."
