param(
    [string]$Godot = 'godot',
    [ValidateSet('training', 'industrial')][string]$Map = 'industrial',
    [ValidateRange(1024, 65535)][int]$Port = 24715
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$runRoot = Join-Path $projectRoot ('builds/validation/manual-network-' + [guid]::NewGuid().ToString('N'))
$processes = @()
try {
    foreach ($role in @('host', 'client')) {
        $roleRoot = Join-Path $runRoot $role
        New-Item -ItemType Directory -Force -Path $roleRoot | Out-Null
        $arguments = @('--path', ('"' + $projectRoot + '"'),
            '--log-file', ('"' + (Join-Path $roleRoot 'godot.log') + '"'),
            '--', '--local-network', "--role=$role", "--port=$Port", "--map=$Map")
        # Windows PowerShell 5.1 has no Start-Process -Environment parameter.
        # Children inherit these process-local values; restore the caller immediately.
        $previousAppData = $env:APPDATA
        $previousLocalAppData = $env:LOCALAPPDATA
        try {
            $env:APPDATA = $roleRoot
            $env:LOCALAPPDATA = $roleRoot
            $process = Start-Process -FilePath $Godot -ArgumentList $arguments -PassThru -WindowStyle Normal `
                -WorkingDirectory $projectRoot `
                -RedirectStandardOutput (Join-Path $roleRoot 'stdout.log') `
                -RedirectStandardError (Join-Path $roleRoot 'stderr.log')
        } finally {
            $env:APPDATA = $previousAppData
            $env:LOCALAPPDATA = $previousLocalAppData
        }
        $processes += $process
        $deadline = [DateTime]::UtcNow.AddSeconds(20)
        do {
            if ($process.HasExited) { throw "$role exited during startup; inspect $roleRoot" }
            $stdout = Get-Content -LiteralPath (Join-Path $roleRoot 'stdout.log') -Raw -ErrorAction SilentlyContinue
            if ($stdout -and $stdout.Contains("M15_READY role=$role")) { break }
            if ([DateTime]::UtcNow -ge $deadline) { throw "$role startup timed out; inspect $roleRoot" }
            Start-Sleep -Milliseconds 100
        } while ($true)
    }
    Write-Output "Host PID $($processes[0].Id), client PID $($processes[1].Id). Keep both game windows open."
    Write-Output "Wait for GO, then focus a game window: A/D move, Space jump, Shift dash."
    Write-Output "Ready is automatic on first launch; F6 toggles it. Logs: $runRoot"
} catch {
    foreach ($process in $processes) {
        if (-not $process.HasExited) { $process.Kill() }
    }
    throw
}
