param(
    [Parameter(Mandatory=$true)][string]$Archive,
    [ValidateSet('windows','linux')][string]$Platform = 'windows'
)
# Failure-path regression: no native code runs in this test.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$logRoot = Join-Path $root 'builds/validation'
$missingEngine = Join-Path $root 'builds/m18-intentionally-missing-engine.exe'
if (Test-Path -LiteralPath $missingEngine) { throw 'Test requires its engine path to be absent' }
$names = @('PV_EOSG_PROBE_EXTENSION', 'APPDATA', 'LOCALAPPDATA', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME')
$beforeEnv = @{}
foreach ($name in $names) { $beforeEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
$beforeDirs = @(Get-ChildItem -LiteralPath $logRoot -Directory -Filter 'm18-native-*' | ForEach-Object {$_.FullName})
$failed = $false
try { & "$PSScriptRoot/test_eosg_native.ps1" -Godot $missingEngine -Platform $Platform -Archive $Archive -Repetitions 1 }
catch {
    if ($_.FullyQualifiedErrorId -notlike '*Microsoft.PowerShell.Commands.StartProcessCommand*') { throw }
    $failed = $true
}
if (-not $failed) { throw 'Launcher falsely accepted missing engine' }
$newDirs = @(Get-ChildItem -LiteralPath $logRoot -Directory -Filter 'm18-native-*' | Where-Object {$_.FullName -notin $beforeDirs})
if ($newDirs.Count -ne 1 -or -not (Test-Path -LiteralPath (Join-Path $newDirs[0].FullName 'archive.json'))) {
    throw 'Failure did not reach the expected inspected candidate run'
}
if (@(Get-ChildItem -LiteralPath $newDirs[0].FullName -Directory).Count -ne 0) {
    throw 'Launcher left native candidate or user cache after failed launch'
}
foreach ($name in $names) {
    if ([Environment]::GetEnvironmentVariable($name, 'Process') -cne $beforeEnv[$name]) {
        throw "Launcher failed to restore environment variable $name"
    }
}
$rejected = $false
try { & "$PSScriptRoot/inspect_eosg_candidate.ps1" -Platform $Platform -Archive (Join-Path $root '.gitignore') | Out-Null }
catch { if ($_.Exception.Message -like 'M18_CHECKSUM_FAIL:*') { $rejected = $true } else { throw } }
if (-not $rejected) { throw 'Inspector accepted incorrect archive bytes' }
Write-Output 'M18_LAUNCHER_FAILURE_CLEANUP_OK environment_restored=true native_files_remaining=0'
Write-Output 'M18_CHECKSUM_NEGATIVE_OK'
