param(
    [Parameter(Mandatory=$true)][ValidateSet('windows','linux')][string]$Platform,
    [Parameter(Mandatory=$true)][string]$Archive
)
# Read-only archive inspection. Never executes, extracts or installs third-party code.
$ErrorActionPreference = 'Stop'
$pins = @{
    windows = 'f8fb24b8c92cd89ce810a4052afaaa267c9d22d165407c6f908456d185baa750'
    linux = 'd4a6bb5d5d0684afd03b76bce8c97776f7430166262d3430dacf197428feb35d'
}
if ((Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash -ne $pins[$Platform]) {
    throw 'M18_CHECKSUM_FAIL: expected exact official EOSG 2.3.0 platform archive'
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Archive).Path)
try {
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $total = 0L
    foreach ($entry in $zip.Entries) {
        $name = $entry.FullName
        if ($name -match '\\|:|(^|/)\.\.(/|$)|(^|/)\.(/|$)|^/' -or
            $name -notmatch '^epic-online-services-godot(/|$)' -or
            -not $seen.Add($name) -or
            (($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) {
            throw 'M18_ARCHIVE_PATH_FAIL: traversal, duplicate, symlink or unexpected root'
        }
        $total += $entry.Length
        if ($total -gt 1GB -or $zip.Entries.Count -gt 10000) { throw 'M18_ARCHIVE_LIMIT_FAIL' }
    }
    $binaries = @($zip.Entries | Where-Object {$_.FullName -match '\.(dll|so)$'} | ForEach-Object {
        $stream = $_.Open()
        try {
            $hash = [Security.Cryptography.SHA256]::Create()
            try { $digest = [BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
            finally { $hash.Dispose() }
        } finally { $stream.Dispose() }
        [ordered]@{path=$_.FullName; bytes=$_.Length; sha256=$digest}
    })
    [ordered]@{
        marker='M18_ARCHIVE_INSPECTED'; candidate='2.3.0'; platform=$Platform
        commit='e84320567a3a17d305478f5796707e69d2bdac4f'
        sha256=$pins[$Platform]
        sha512=(Get-FileHash -LiteralPath $Archive -Algorithm SHA512).Hash.ToLowerInvariant()
        entries=$zip.Entries.Count; expanded_bytes=$total; binaries=$binaries
        notices=@($zip.Entries | Where-Object {$_.FullName -match '(?i)license|notice|agreement'} | ForEach-Object {$_.FullName})
    } | ConvertTo-Json -Depth 5
} finally { $zip.Dispose() }
