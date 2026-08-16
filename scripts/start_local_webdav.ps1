$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$composeFile = Join-Path $repoRoot "tools/local-webdav/docker-compose.yml"
$serverFile = Join-Path $repoRoot "tools/local-webdav/server.mjs"
$dataDir = Join-Path $repoRoot ".local-webdav/data"
$pidFile = Join-Path $repoRoot ".local-webdav/node-server.pid"
$logFile = Join-Path $repoRoot ".local-webdav/node-server.log"
$errFile = Join-Path $repoRoot ".local-webdav/node-server.err.log"

New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

$port = if ($env:LOCAL_WEBDAV_PORT) { $env:LOCAL_WEBDAV_PORT } else { "19080" }
$user = if ($env:LOCAL_WEBDAV_USER) { $env:LOCAL_WEBDAV_USER } else { "legado" }
$password = if ($env:LOCAL_WEBDAV_PASSWORD) { $env:LOCAL_WEBDAV_PASSWORD } else { "legado-test" }

function Write-WebDavDetails {
    param([string] $Backend)

    Write-Host "Local WebDAV is running via $Backend."
    Write-Host "Windows/Desktop URL: http://127.0.0.1:$port/"
    Write-Host "Android emulator URL: http://10.0.2.2:$port/"
    Write-Host "Username: $user"
    Write-Host "Password: $password"
    Write-Host "Data directory: $dataDir"
}

$dockerUsable = $false
docker info *> $null
if ($LASTEXITCODE -eq 0) {
    $dockerUsable = $true
}

if ($dockerUsable) {
    docker compose -f $composeFile up -d
    if ($LASTEXITCODE -eq 0) {
        Write-WebDavDetails "Docker"
        exit 0
    }
    Write-Host "Docker WebDAV failed to start; falling back to Node."
}

if (Test-Path $pidFile) {
    $existingPid = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($existingPid) {
        $existingProcess = Get-Process -Id $existingPid -ErrorAction SilentlyContinue
        if ($existingProcess) {
            Write-WebDavDetails "Node"
            exit 0
        }
    }
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Neither Docker Desktop nor Node.js is available to run the local WebDAV server."
}

if (-not $env:LOCAL_WEBDAV_ROOT) {
    $env:LOCAL_WEBDAV_ROOT = $dataDir
}

$process = Start-Process `
    -FilePath "node" `
    -ArgumentList @($serverFile) `
    -WorkingDirectory $repoRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $logFile `
    -RedirectStandardError $errFile `
    -PassThru

Set-Content -Path $pidFile -Value $process.Id
Start-Sleep -Milliseconds 800

if ($process.HasExited) {
    Remove-Item $pidFile -ErrorAction SilentlyContinue
    if (Test-Path $errFile) {
        Get-Content $errFile
    }
    throw "Node WebDAV failed to start."
}

Write-WebDavDetails "Node"
