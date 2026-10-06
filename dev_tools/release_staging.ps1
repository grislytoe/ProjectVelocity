param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('windows', 'linux')]
    [string]$Target,
    [Parameter(Mandatory = $true)]
    [string]$Godot,
    [Parameter(Mandatory = $true)]
    [string]$SourceSha,
    [string]$OutputRoot = 'builds/staging',
    [switch]$RenderedSmoke
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot

$version = '0.25.0-rc.1'
$buildNumber = 31
$protocol = 5
$wire = 4
$saveSchema = 5
$engineVersion = '4.7.2.stable.official.ed1daf0bf'
$templateSha512 = 'ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079'
$windowsEngineSha512 = '83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993'
$linuxEngineSha512 = '9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65'
$manifestUrl = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/SHA512-SUMS.txt'

$SourceSha = $SourceSha.ToLowerInvariant()
if ($SourceSha -notmatch '^[0-9a-f]{40}$') { throw 'SourceSha must be an exact 40-character Git SHA.' }

function Assert-UnderRoot {
    param([string]$Path, [string]$Root)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing path outside staging root: $fullPath"
    }
    return $fullPath
}

function Invoke-CheckedProcess {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$StdoutPath,
        [string]$StderrPath,
        [int]$TimeoutSeconds = 180,
        [hashtable]$Environment = @{},
        [int[]]$ExpectedExitCodes = @(0)
    )
    $start = [System.Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FilePath
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { [void]$start.ArgumentList.Add($argument) }
    foreach ($name in $Environment.Keys) { $start.Environment[$name] = [string]$Environment[$name] }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $start
    if (-not $process.Start()) { throw "Unable to start $FilePath" }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        throw "$FilePath timed out after $TimeoutSeconds seconds"
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    [System.IO.File]::WriteAllText($StdoutPath, $stdout, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText($StderrPath, $stderr, [System.Text.UTF8Encoding]::new($false))
    if ($process.ExitCode -notin $ExpectedExitCodes) {
        throw "$FilePath exited $($process.ExitCode); inspect $StdoutPath and $StderrPath"
    }
    return [ordered]@{ exit_code = $process.ExitCode; stdout = $stdout; stderr = $stderr }
}

function Assert-CleanGodotOutput {
    param([System.Collections.IDictionary]$Result, [string]$Context)
    $combined = $Result.stdout + "`n" + $Result.stderr
    if ($combined -match '(?m)(SCRIPT ERROR:|Parse Error|ERROR:|WARNING:)') {
        throw "$Context emitted an engine error or warning"
    }
}

function Get-Sha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-DeniedPath {
    param([string]$Path)
    $normalized = $Path.Replace('\', '/').TrimStart('./')
    return $normalized -match '(^|/)(tests|dev_tools|docs|\.tools|builds|\.git|\.github)(/|$)' -or
        $normalized -match '(^|/)(export_credentials\.cfg|save(\.backup)?\.json|\.env($|\.)|[^/]+\.(log|pfx|p12|key|corrupt-[^/]+))$' -or
        $normalized -match '(^|/)(addons/epic-online-services-godot|EOSSDK|libEOSSDK|eosg)'
}

function Assert-ArchiveContents {
    param([string]$Archive, [string]$Kind, [string]$ListingPath)
    if ($Kind -eq 'zip') {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Archive)
        try { $entries = @($zip.Entries | ForEach-Object { $_.FullName }) }
        finally { $zip.Dispose() }
    } else {
        $entries = @(& tar -tzf $Archive)
        if ($LASTEXITCODE -ne 0) { throw "Unable to list $Archive" }
    }
    [System.IO.File]::WriteAllLines($ListingPath, $entries, [System.Text.UTF8Encoding]::new($false))
    $denied = @($entries | Where-Object { Test-DeniedPath $_ })
    if ($denied.Count -gt 0) { throw "Denied package paths: $($denied -join ', ')" }
    if ($entries.Count -lt 2) { throw "Archive contains too few files: $Archive" }
}

function Invoke-ExtractedSmoke {
    param([string]$Executable, [string]$LogPrefix, [switch]$Render, [string]$Resolution = '')
    $isWindowsTarget = $Target -eq 'windows'
    $isolated = Join-Path $targetRoot ("isolated-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $isolated | Out-Null
    $environment = @{}
    if ($isWindowsTarget) {
        $environment.APPDATA = Join-Path $isolated 'appdata'
        $environment.LOCALAPPDATA = Join-Path $isolated 'localappdata'
    } else {
        $environment.XDG_CONFIG_HOME = Join-Path $isolated 'config'
        $environment.XDG_CACHE_HOME = Join-Path $isolated 'cache'
        $environment.XDG_DATA_HOME = Join-Path $isolated 'data'
    }
    foreach ($path in $environment.Values) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    $arguments = @('--quit-after', '900')
    if (-not $Render) { $arguments = @('--headless') + $arguments }
    if ($Render) { $arguments = @('--audio-driver', 'Dummy') + $arguments }
    if ($Render -and $isWindowsTarget) {
        $arguments = @('--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3_angle') + $arguments
    }
    if ($Resolution) { $arguments += @('--resolution', $Resolution) }
    $arguments += @('--', '--smoke-test')
    try {
        $result = Invoke-CheckedProcess -FilePath $Executable -Arguments $arguments `
            -StdoutPath "$LogPrefix.stdout.log" -StderrPath "$LogPrefix.stderr.log" `
            -TimeoutSeconds 180 -Environment $environment
        Assert-CleanGodotOutput $result "staging smoke $Resolution"
        $combined = $result.stdout + "`n" + $result.stderr
        $expectedIdentity = "PV_BUILD_IDENTITY version=$version build=$buildNumber channel=STAGING protocol=$protocol wire=$wire save=$saveSchema source_sha=$SourceSha"
        if (-not $combined.Contains($expectedIdentity) -or -not $combined.Contains('PROJECTVELOCITY_BOOT_OK')) {
            throw "Staging smoke identity/marker mismatch: $LogPrefix"
        }
    } finally {
        $isolatedFull = Assert-UnderRoot $isolated $targetRoot
        if (Test-Path -LiteralPath $isolatedFull) { Remove-Item -LiteralPath $isolatedFull -Recurse -Force }
    }
}

$outputFull = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $OutputRoot))
New-Item -ItemType Directory -Force -Path $outputFull | Out-Null
$targetRoot = Assert-UnderRoot (Join-Path $outputFull $Target) $outputFull
if (Test-Path -LiteralPath $targetRoot) { Remove-Item -LiteralPath $targetRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null
$logs = Join-Path $targetRoot 'validation'
New-Item -ItemType Directory -Force -Path $logs | Out-Null

$provenancePath = Join-Path $projectRoot 'core/build/source_provenance.tres'
$provenanceText = [System.IO.File]::ReadAllText($provenancePath)
if ($provenanceText -notmatch 'source_sha = "(UNEMBEDDED|[0-9a-f]{40})"') { throw 'Missing source-SHA provenance placeholder.' }
$provenanceText = [regex]::Replace($provenanceText, 'source_sha = "(UNEMBEDDED|[0-9a-f]{40})"', "source_sha = `"$SourceSha`"")
[System.IO.File]::WriteAllText($provenancePath, $provenanceText, [System.Text.UTF8Encoding]::new($false))

$preset = if ($Target -eq 'windows') { 'Windows x86_64 Staging' } else { 'Linux x86_64 Staging' }
$platformName = if ($Target -eq 'windows') { 'windows-x86_64' } else { 'linux-x86_64' }
$packageName = "ProjectVelocity-$version-build$buildNumber-$platformName"
$packageDir = Join-Path $targetRoot $packageName
New-Item -ItemType Directory -Force -Path $packageDir | Out-Null
$executableName = if ($Target -eq 'windows') { 'ProjectVelocity.exe' } else { 'ProjectVelocity.x86_64' }
$executable = Join-Path $packageDir $executableName

$versionResult = Invoke-CheckedProcess -FilePath $Godot -Arguments @('--version') `
    -StdoutPath (Join-Path $logs 'godot-version.stdout.log') -StderrPath (Join-Path $logs 'godot-version.stderr.log')
if (-not $versionResult.stdout.Contains('4.7.2.stable.official.ed1daf0bf')) { throw 'Unexpected Godot build.' }

$auditZip = Join-Path $targetRoot 'resource-audit.zip'
$auditResult = Invoke-CheckedProcess -FilePath $Godot -Arguments @('--headless', '--path', $projectRoot, '--export-pack', $preset, $auditZip) `
    -StdoutPath (Join-Path $logs 'resource-export.stdout.log') -StderrPath (Join-Path $logs 'resource-export.stderr.log') -TimeoutSeconds 300
Assert-CleanGodotOutput $auditResult 'resource audit export'
Assert-ArchiveContents -Archive $auditZip -Kind 'zip' -ListingPath (Join-Path $logs 'resource-contents.txt')
Remove-Item -LiteralPath $auditZip -Force

$exportResult = Invoke-CheckedProcess -FilePath $Godot -Arguments @('--headless', '--path', $projectRoot, '--export-release', $preset, $executable) `
    -StdoutPath (Join-Path $logs 'export.stdout.log') -StderrPath (Join-Path $logs 'export.stderr.log') -TimeoutSeconds 300
Assert-CleanGodotOutput $exportResult 'release export'

$pck = Join-Path $packageDir 'ProjectVelocity.pck'
if (-not (Test-Path -LiteralPath $executable) -or -not (Test-Path -LiteralPath $pck)) { throw 'Release export is incomplete.' }
if ($Target -eq 'linux') {
    & chmod 755 $executable
    if ($LASTEXITCODE -ne 0) { throw 'Unable to set Linux executable permission.' }
    $launcher = Join-Path $packageDir 'run-projectvelocity.sh'
    $launcherText = @'
#!/usr/bin/env sh
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "$SCRIPT_DIR/ProjectVelocity.x86_64" "$@"
'@
    [System.IO.File]::WriteAllText($launcher, $launcherText, [System.Text.UTF8Encoding]::new($false))
    & chmod 755 $launcher
    if ($LASTEXITCODE -ne 0) { throw 'Unable to set launcher permission.' }
}

$readme = @"
ProjectVelocity $version / build $buildNumber / STAGING
This is an unsigned review candidate, not an approved or public release.
Source: $SourceSha
Windows: run ProjectVelocity.exe. Linux/SteamOS: run ./run-projectvelocity.sh.
Production Online is intentionally unavailable because the EOS gate is blocked.
Local developer ENet tooling is not available in this release export.
Verify the archive against SHA256SUMS and staging-manifest.json before running.
"@
[System.IO.File]::WriteAllText((Join-Path $packageDir 'STAGING-README.txt'), $readme, [System.Text.UTF8Encoding]::new($false))

if ($Target -eq 'linux') {
    $ldd = Invoke-CheckedProcess -FilePath 'ldd' -Arguments @($executable) `
        -StdoutPath (Join-Path $logs 'ldd.stdout.log') -StderrPath (Join-Path $logs 'ldd.stderr.log')
    if (($ldd.stdout + $ldd.stderr) -match 'not found') { throw 'Linux export has a missing shared library.' }
}

$archives = @()
if ($Target -eq 'windows') {
    $archive = Join-Path $targetRoot "$packageName.zip"
    Compress-Archive -LiteralPath $packageDir -DestinationPath $archive -CompressionLevel Optimal
    $archives += [ordered]@{ role = 'windows-portable'; path = $archive; kind = 'zip' }
} else {
    $archive = Join-Path $targetRoot "$packageName.tar.gz"
    & tar -czf $archive -C $targetRoot $packageName
    if ($LASTEXITCODE -ne 0) { throw 'Unable to create Linux archive.' }
    $archives += [ordered]@{ role = 'linux-portable'; path = $archive; kind = 'tar.gz' }
    $steamName = "ProjectVelocity-$version-build$buildNumber-steamos-x86_64.tar.gz"
    $steamArchive = Join-Path $targetRoot $steamName
    & tar -czf $steamArchive -C $targetRoot $packageName
    if ($LASTEXITCODE -ne 0) { throw 'Unable to create SteamOS-compatible archive.' }
    $archives += [ordered]@{ role = 'steamos-compatible-package'; path = $steamArchive; kind = 'tar.gz' }
}

$archiveRecords = @()
$index = 0
foreach ($item in $archives) {
    $listing = Join-Path $logs ("archive-$index-contents.txt")
    Assert-ArchiveContents -Archive $item.path -Kind ($(if ($item.kind -eq 'zip') { 'zip' } else { 'tar.gz' })) -ListingPath $listing
    $archiveRecords += [ordered]@{
        role = $item.role
        filename = Split-Path $item.path -Leaf
        bytes = (Get-Item -LiteralPath $item.path).Length
        sha256 = Get-Sha256 $item.path
    }
    $index += 1
}

$verifyRoot = Assert-UnderRoot (Join-Path $targetRoot ("verify-" + [guid]::NewGuid().ToString('N'))) $targetRoot
New-Item -ItemType Directory -Force -Path $verifyRoot | Out-Null
try {
    $primary = $archives[0]
    if ($primary.kind -eq 'zip') { Expand-Archive -LiteralPath $primary.path -DestinationPath $verifyRoot }
    else {
        & tar -xzf $primary.path -C $verifyRoot
        if ($LASTEXITCODE -ne 0) { throw 'Unable to extract archive for verification.' }
    }
    $extractedDir = Join-Path $verifyRoot $packageName
    $extractedExe = Join-Path $extractedDir $executableName
    $extractedPck = Join-Path $extractedDir 'ProjectVelocity.pck'
    if ((Get-Sha256 $extractedExe) -ne (Get-Sha256 $executable) -or (Get-Sha256 $extractedPck) -ne (Get-Sha256 $pck)) {
        throw 'Extracted executable/PCK hashes do not match the packaged files.'
    }
    Invoke-ExtractedSmoke -Executable $extractedExe -LogPrefix (Join-Path $logs 'extracted-headless-smoke')
    if ($RenderedSmoke -and $Target -eq 'windows') {
        foreach ($resolution in @('1280x720', '1280x800', '1920x1080')) {
            Invoke-ExtractedSmoke -Executable $extractedExe -LogPrefix (Join-Path $logs "extracted-render-$resolution") -Render -Resolution $resolution
        }
    }
    $denyIsolated = Assert-UnderRoot (Join-Path $targetRoot ("deny-" + [guid]::NewGuid().ToString('N'))) $targetRoot
    New-Item -ItemType Directory -Force -Path $denyIsolated | Out-Null
    $denyEnvironment = @{}
    if ($Target -eq 'windows') {
        $denyEnvironment.APPDATA = Join-Path $denyIsolated 'appdata'
        $denyEnvironment.LOCALAPPDATA = Join-Path $denyIsolated 'localappdata'
    } else {
        $denyEnvironment.XDG_CONFIG_HOME = Join-Path $denyIsolated 'config'
        $denyEnvironment.XDG_CACHE_HOME = Join-Path $denyIsolated 'cache'
        $denyEnvironment.XDG_DATA_HOME = Join-Path $denyIsolated 'data'
    }
    foreach ($path in $denyEnvironment.Values) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
    try {
        $denied = Invoke-CheckedProcess -FilePath $extractedExe -Arguments @('--headless', '--quit-after', '60', '--', '--local-network', '--role=host', '--port=24990') `
            -StdoutPath (Join-Path $logs 'production-dev-tool-denial.stdout.log') -StderrPath (Join-Path $logs 'production-dev-tool-denial.stderr.log') `
            -TimeoutSeconds 60 -Environment $denyEnvironment -ExpectedExitCodes @(1)
        if (($denied.stdout + $denied.stderr).Contains('M15_READY')) { throw 'Release export exposed development ENet tooling.' }
    } finally {
        if (Test-Path -LiteralPath $denyIsolated) { Remove-Item -LiteralPath $denyIsolated -Recurse -Force }
    }
} finally {
    if (Test-Path -LiteralPath $verifyRoot) { Remove-Item -LiteralPath $verifyRoot -Recurse -Force }
}

$fileRecords = @()
foreach ($file in Get-ChildItem -LiteralPath $packageDir -File | Sort-Object Name) {
    $fileRecords += [ordered]@{ filename = $file.Name; bytes = $file.Length; sha256 = Get-Sha256 $file.FullName }
}
$training = Get-Content -LiteralPath 'map_data/training_circuit.tres' -Raw
$foundry = Get-Content -LiteralPath 'map_data/industrial_foundry.tres' -Raw
if ($training -notmatch 'map_version = (\d+)' -or $training -notmatch 'declared_checksum = "([0-9a-f]{64})"') { throw 'Unable to read Training identity.' }
$trainingVersion = [int]([regex]::Match($training, 'map_version = (\d+)').Groups[1].Value)
$trainingChecksum = [regex]::Match($training, 'declared_checksum = "([0-9a-f]{64})"').Groups[1].Value
$foundryVersion = [int]([regex]::Match($foundry, 'map_version = (\d+)').Groups[1].Value)
$foundryChecksum = [regex]::Match($foundry, 'declared_checksum = "([0-9a-f]{64})"').Groups[1].Value

$manifest = [ordered]@{
    schema_version = 1
    candidate = [ordered]@{ version = $version; build = $buildNumber; channel = 'STAGING'; source_sha = $SourceSha }
    target = [ordered]@{ platform = $Target; architecture = 'x86_64'; steam_client_required = $false }
    identity = [ordered]@{ protocol = $protocol; wire = $wire; save = $saveSchema; physics_hz = 60; snapshot_hz = '20-30' }
    maps = @(
        [ordered]@{ id = 'solo_training'; version = $trainingVersion; checksum = $trainingChecksum },
        [ordered]@{ id = 'industrial_foundry'; version = $foundryVersion; checksum = $foundryChecksum }
    )
    archives = $archiveRecords
    contained_files = $fileRecords
    godot = [ordered]@{
        version = $engineVersion
        official_sha512_manifest = $manifestUrl
        engine_asset_sha512 = $(if ($Target -eq 'windows') { $windowsEngineSha512 } else { $linuxEngineSha512 })
        export_templates_sha512 = $templateSha512
    }
    validation = @('resource-contents.txt', 'export.stdout.log', 'extracted-headless-smoke.stdout.log', 'production-dev-tool-denial.stdout.log')
    reproducibility = 'Hashes identify this produced candidate; byte-for-byte reproducibility is not claimed because archive/build timestamps may vary.'
    blockers = @('unsigned binaries', 'M19 live EOS/Internet unavailable', 'physical Steam Deck/SteamOS runtime pending', 'approved low-end hardware certification pending', 'developer manual approval pending')
}
$manifestPath = Join-Path $targetRoot 'staging-manifest.json'
[System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 8) + "`n", [System.Text.UTF8Encoding]::new($false))

$sumLines = @()
foreach ($record in $archiveRecords) { $sumLines += "$($record.sha256)  $($record.filename)" }
foreach ($record in $fileRecords) { $sumLines += "$($record.sha256)  $packageName/$($record.filename)" }
$sumLines += "$(Get-Sha256 $manifestPath)  staging-manifest.json"
[System.IO.File]::WriteAllLines((Join-Path $targetRoot 'SHA256SUMS'), $sumLines, [System.Text.UTF8Encoding]::new($false))

if ([System.IO.File]::ReadAllText($manifestPath) -match '(?i)(C:\\Users\\|/home/[^/]+/|bearer|client_secret\s*[:=]\s*[^\s\"]+)') {
    throw 'Manifest contains a local absolute path or credential-like value.'
}

Write-Output "M25_STAGING_PACKAGE_OK target=$Target source_sha=$SourceSha"
foreach ($record in $archiveRecords) {
    Write-Output "M25_ARTIFACT name=$($record.filename) bytes=$($record.bytes) sha256=$($record.sha256)"
}
