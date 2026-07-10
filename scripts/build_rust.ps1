# 编译 Rust 书源引擎（Windows）
# 用法: .\scripts\build_rust.ps1
# 说明: 自动把 %USERPROFILE%\.cargo\bin 加入 PATH，无需全局配置 cargo

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

$CargoBin = Join-Path $env:USERPROFILE ".cargo\bin"
$CargoExe = Join-Path $CargoBin "cargo.exe"

if (-not (Test-Path $CargoExe)) {
    Write-Host "未找到 cargo: $CargoExe" -ForegroundColor Red
    Write-Host "请先安装 Rust: https://rustup.rs/" -ForegroundColor Yellow
    Write-Host "或运行完整环境脚本: .\scripts\setup_rust_engine.ps1" -ForegroundColor Yellow
    exit 1
}

$env:Path = "$CargoBin;" + $env:Path

Write-Host "=== 编译 legado_engine (release) ===" -ForegroundColor Cyan
Write-Host "cargo: $CargoExe" -ForegroundColor DarkGray

Push-Location (Join-Path $ProjectRoot "rust\legado_engine")
try {
    & $CargoExe build --release
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    $dllRelease = Join-Path $ProjectRoot "rust\target\release\legado_engine.dll"
    $dllCrate = Join-Path $ProjectRoot "rust\legado_engine\target\release\legado_engine.dll"

    if (Test-Path $dllRelease) {
        Write-Host "`n输出: $dllRelease" -ForegroundColor Green
    } elseif (Test-Path $dllCrate) {
        Write-Host "`n输出: $dllCrate" -ForegroundColor Green
    } else {
        Write-Host "`n编译完成，请检查 rust/target/release/ 下的 legado_engine.dll" -ForegroundColor Yellow
    }

    Write-Host "`n下一步: flutter run -d windows" -ForegroundColor Yellow
} finally {
    Pop-Location
}
