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

Invoke-GodotCheck -Name "version" -Arguments @("--version") -Marker "4.7.2.stable."
Invoke-GodotCheck -Name "import" -Arguments @("--headless", "--path", ".", "--import")
Get-ChildItem core,save_system,tests,dev_tools -Recurse -Filter "*.gd" | ForEach-Object {
    $relative = $_.FullName.Substring($projectRoot.Length + 1).Replace("\", "/")
    Invoke-GodotCheck -Name ("parse-" + $_.BaseName) -Arguments @("--headless", "--path", ".", "--check-only", "--script", $relative)
}
Invoke-GodotCheck -Name "tests" -Arguments @("--headless", "--path", ".", "--script", "tests/bootstrap_test.gd") -Marker "PROJECTVELOCITY_TESTS_OK"
Invoke-GodotCheck -Name "m1-tests" -Arguments @("--headless", "--path", ".", "--script", "tests/save_foundation_test.gd") -Marker "PROJECTVELOCITY_M1_TESTS_OK"
Invoke-GodotCheck -Name "boot" -Arguments @("--headless", "--path", ".", "--quit-after", "600", "--", "--smoke-test") -Marker "PROJECTVELOCITY_BOOT_OK"
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
Write-Output "M0 + M1 validation passed."
