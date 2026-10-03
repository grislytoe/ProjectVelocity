param([switch]$RequireClean)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot

$tracked = @(git ls-files)
if ($LASTEXITCODE -ne 0) { throw 'git ls-files failed.' }
$denied = @($tracked | Where-Object {
    $_ -match '(^|/)(builds|\.tools|\.godot)(/|$)' -or
    $_ -match '(^|/)(save(\.backup)?\.json|export_credentials\.cfg|\.env($|\.)|[^/]+\.(pfx|p12|key|log))$' -or
    $_ -match '(^|/)(addons/epic-online-services-godot|EOSSDK|libEOSSDK)'
})
if ($denied.Count -gt 0) { throw "Denied tracked files: $($denied -join ', ')" }

$secretPatterns = @(
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'gh[pousr]_[A-Za-z0-9]{30,}',
    'AKIA[0-9A-Z]{16}',
    '(?i)pv_eos_client_secret\s*[:=]\s*["''][^"'']+["'']'
)
$matches = @()
foreach ($path in $tracked) {
    $item = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
    if ($null -eq $item -or $item.Length -gt 1048576) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($item.FullName)
    if ($bytes -contains 0) { continue }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    foreach ($pattern in $secretPatterns) {
        if ($text -match $pattern) { $matches += "$path [$pattern]" }
    }
}
if ($matches.Count -gt 0) { throw "Credential-like tracked content: $($matches -join '; ')" }

if (Test-Path -LiteralPath 'addons') { throw 'Unexpected runtime addons directory; EOS/vendor binaries must not be bundled.' }
if (-not (Test-Path -LiteralPath 'DEPENDENCIES.md')) { throw 'Dependency inventory is missing.' }
if ((Get-Content -LiteralPath 'DEPENDENCIES.md' -Raw) -notmatch 'Godot engine and official export templates') {
    throw 'Godot dependency/license entry is missing.'
}
if ((Get-Content -LiteralPath 'project.godot' -Raw) -notmatch 'common/physics_ticks_per_second=60') {
    throw 'Committed source must explicitly retain 60 Hz physics.'
}
if ((Get-Content -LiteralPath 'core/build/build_info.gd' -Raw) -notmatch '0\.25\.0-rc\.1') {
    throw 'M25 RC identity is missing.'
}

if ($RequireClean) {
    $status = @(git status --porcelain)
    if ($status.Count -gt 0) { throw "Repository is not clean: $($status -join '; ')" }
}

Write-Output 'M25_RELEASE_SOURCE_AUDIT_OK no_credentials=true no_vendor_runtime=true telemetry_upload=false-by-architecture'
