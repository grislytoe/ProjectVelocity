param([switch]$RequireLive)
$ErrorActionPreference = 'Stop'
# Values remain in process memory. Never echo exceptions containing supplied paths.
$names = @('PV_EOS_PRODUCT_ID', 'PV_EOS_SANDBOX_ID', 'PV_EOS_DEPLOYMENT_ID',
    'PV_EOS_CLIENT_ID', 'PV_EOS_CLIENT_SECRET', 'PV_EOS_DEV_AUTH_ENDPOINT',
    'PV_EOS_DEV_AUTH_NAME_A', 'PV_EOS_DEV_AUTH_NAME_B', 'PV_EOS_SDK_ARCHIVE')
foreach ($name in $names) {
    $present = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))
    Write-Output "$name present=$($present.ToString().ToLowerInvariant())"
}
$archiveExists = $false
$archiveReadable = $false
$noticeCandidates = $false
$sdkHeaderCandidates = $false
$archive = [Environment]::GetEnvironmentVariable('PV_EOS_SDK_ARCHIVE')
$zip = $null
try {
    if (-not [string]::IsNullOrWhiteSpace($archive)) {
        $archiveExists = Test-Path -LiteralPath $archive -PathType Leaf
        if ($archiveExists) {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zip = [System.IO.Compression.ZipFile]::OpenRead($archive)
            $archiveReadable = $true
            # Entry-name hints only: no extraction, contents, paths or false clearance.
            $noticeCandidates = @($zip.Entries | Where-Object { $_.FullName -match '(?i)notice|license|agreement' }).Count -gt 0
            $sdkHeaderCandidates = @($zip.Entries | Where-Object { $_.FullName -match '(^|/)eos_version\.h$' }).Count -eq 1
        }
    }
} catch {
    $archiveReadable = $false
} finally {
    if ($null -ne $zip) { $zip.Dispose() }
    $archive = $null
}
Write-Output "sdk_archive_exists=$archiveExists readable_zip=$archiveReadable notice_candidates=$noticeCandidates version_header_candidate=$sdkHeaderCandidates"
Write-Output 'exact_sdk_and_notices_reviewed=false redistribution_cleared=false native_adapter_approved=false'
$templates = if ($env:APPDATA) { Join-Path $env:APPDATA 'Godot/export_templates/4.7.2.stable' } else {
    Join-Path ([Environment]::GetFolderPath('UserProfile')) '.local/share/godot/export_templates/4.7.2.stable'
}
$windows = (Test-Path (Join-Path $templates 'windows_debug_x86_64.exe')) -and (Test-Path (Join-Path $templates 'windows_release_x86_64.exe'))
$linux = (Test-Path (Join-Path $templates 'linux_debug.x86_64')) -and (Test-Path (Join-Path $templates 'linux_release.x86_64'))
Write-Output "windows_templates=$windows linux_templates=$linux"
Write-Output 'M19_VERDICT=BLOCKED live_attempted=false; presence never proves valid configuration or online/export acceptance'
if ($RequireLive) { exit 2 }
