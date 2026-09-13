param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [Parameter(Mandatory=$true)][ValidateSet('windows','linux')][string]$Platform,
    [Parameter(Mandatory=$true)][string]$Archive,
    [ValidateRange(1,20)][int]$Repetitions = 20,
    [switch]$Rendered,
    [switch]$InvalidPlatform
)
# Native-only internal evaluation, not an SDK redistribution/install into ordinary startup.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$audit = & "$PSScriptRoot/inspect_eosg_candidate.ps1" -Platform $Platform -Archive $Archive
$reportRoot = Join-Path $root ('builds/validation/m18-native-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $reportRoot | Out-Null
$audit | Set-Content (Join-Path $reportRoot 'archive.json')
$candidate = Join-Path $reportRoot 'candidate'
New-Item -ItemType Directory -Path $candidate | Out-Null
[IO.File]::WriteAllText((Join-Path $candidate '.gdignore'), '')
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Archive).Path)
try {
    $prefix = 'epic-online-services-godot/addons/epic-online-services-godot/'
    foreach ($entry in $zip.Entries) {
        if (-not $entry.FullName.StartsWith($prefix) -or
            $entry.FullName -notmatch '\.(dll|so)$|/eosg\.gdextension$|/LICENSE\.md$') { continue }
        $destination = [IO.Path]::GetFullPath((Join-Path $candidate $entry.FullName.Substring($prefix.Length)))
        if (-not $destination.StartsWith($candidate + [IO.Path]::DirectorySeparatorChar)) { throw 'M18_PATH_ESCAPE' }
        New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $false)
    }
} finally { $zip.Dispose() }
$ownedEnv = @('PV_EOSG_PROBE_EXTENSION', 'APPDATA', 'LOCALAPPDATA', 'XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME')
$previous = @{}
foreach ($name in $ownedEnv) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    [Environment]::SetEnvironmentVariable('PV_EOSG_PROBE_EXTENSION', (Join-Path $candidate 'eosg.gdextension'), 'Process')
    for ($i = 0; $i -lt $Repetitions; $i++) {
        $userRoot = Join-Path $reportRoot "user-$i"
        New-Item -ItemType Directory -Path $userRoot | Out-Null
        foreach ($name in $ownedEnv | Where-Object {$_ -ne 'PV_EOSG_PROBE_EXTENSION'}) {
            [Environment]::SetEnvironmentVariable($name, $userRoot, 'Process')
        }
        $args = @('--path', ('"' + $root + '"'), '--script', 'dev_tools/eosg_native_probe.gd', '--', '--eosg-native-probe')
        if ($InvalidPlatform) { $args += '--invalid-platform' }
        if (-not $Rendered) { $args = @('--headless') + $args }
        $launch = @{
            FilePath=$Godot; ArgumentList=$args; PassThru=$true
            RedirectStandardOutput=(Join-Path $reportRoot "$i.stdout.log")
            RedirectStandardError=(Join-Path $reportRoot "$i.stderr.log")
        }
        if ($env:OS -eq 'Windows_NT') { $launch.WindowStyle = 'Hidden' }
        $process = Start-Process @launch
        try {
            $null = $process.Handle
            if (-not $process.WaitForExit(30000)) { throw 'M18_NATIVE_TIMEOUT' }
            $process.WaitForExit()
            $output = (Get-Content $launch.RedirectStandardOutput -Raw) + (Get-Content $launch.RedirectStandardError -Raw)
            if ($process.ExitCode -ne 0 -or $output -notmatch 'M18_NATIVE_ONLY_OK' -or
                $output -match 'ERROR:|WARNING:|M18_FAIL|Failed to') {
                throw "M18_NATIVE_FAIL process=$i exit=$($process.ExitCode); inspect local sanitized logs"
            }
            if ($InvalidPlatform -and $output -notmatch 'M18_INVALID_PLATFORM rejected=true') {
                throw 'M18_INVALID_PLATFORM_REJECTION_MISSING'
            }
            Write-Output "M18_PROCESS_OK index=$i exit=0"
        } finally {
            if (-not $process.HasExited) { $process.Kill() ; $process.WaitForExit() }
            $process.Dispose()
        }
    }
    Write-Output "M18_NATIVE_MATRIX_OK processes=$Repetitions platform=$Platform rendered=$Rendered online=BLOCKED"
} finally {
    foreach ($name in $ownedEnv) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
    # Candidate contains proprietary native code. Keep evidence only; never upload this folder wholesale.
    $resolved = [IO.Path]::GetFullPath($candidate)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($reportRoot) + [IO.Path]::DirectorySeparatorChar)) { throw 'M18_CLEANUP_ESCAPE' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
