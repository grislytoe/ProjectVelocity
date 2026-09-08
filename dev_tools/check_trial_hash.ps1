param([switch]$Update)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$files = Get-ChildItem (Join-Path $root 'gameplay') -Recurse -File |
    Where-Object { $_.Extension -in '.gd', '.tscn', '.tres' } |
    Sort-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') }
$content = [System.Text.StringBuilder]::new()
foreach ($file in $files) {
    $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
    [void]$content.Append($relative + "`n")
    [void]$content.Append([IO.File]::ReadAllText($file.FullName).Replace("`r`n", "`n"))
}
$sha = [Security.Cryptography.SHA256]::Create()
$digest = [BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($content.ToString()))).Replace('-', '').ToLowerInvariant()
$sha.Dispose()
$path = Join-Path $root 'map_data/trial_map_definition.gd'
$source = [IO.File]::ReadAllText($path)
if ($Update) {
    $source = [regex]::Replace($source, 'CONTENT_HASH: String = "[^"]+"', ('CONTENT_HASH: String = "' + $digest + '"'))
    [IO.File]::WriteAllText($path, $source)
} elseif (-not $source.Contains('CONTENT_HASH: String = "' + $digest + '"')) {
    throw 'Solo gameplay content changed: update the manifest with dev_tools/check_trial_hash.ps1 -Update'
}
Write-Output "M10_CONTENT_HASH=$digest"
