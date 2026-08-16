$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$composeFile = Join-Path $repoRoot "tools/local-webdav/docker-compose.yml"
$pidFile = Join-Path $repoRoot ".local-webdav/node-server.pid"

docker compose -f $composeFile down
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker compose stop skipped or failed; checking Node fallback."
}

if (Test-Path $pidFile) {
    $pid = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($pid) {
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $pid -Force
            Write-Host "Stopped Node WebDAV process $pid."
        }
    }
    Remove-Item $pidFile -ErrorAction SilentlyContinue
}
