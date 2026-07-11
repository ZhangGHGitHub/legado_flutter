# Windows 发布打包脚本
# 用法: .\scripts\package_windows.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

Write-Host "=== Legado Flutter Windows 打包 ===" -ForegroundColor Cyan

# 1. 编译 Rust 引擎
& "$PSScriptRoot\build_rust.ps1"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 2. Flutter Release 构建
Write-Host "`n=== Flutter build windows --release ===" -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$ReleaseDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
$DllSrc = Join-Path $ProjectRoot "rust\target\release\legado_engine.dll"

if (Test-Path $DllSrc) {
    Copy-Item $DllSrc $ReleaseDir -Force
    Write-Host "已复制 legado_engine.dll → $ReleaseDir" -ForegroundColor Green
} else {
    Write-Host "警告: 未找到 $DllSrc，请确认 Rust 编译成功" -ForegroundColor Yellow
}

Write-Host "`n=== 打包完成 ===" -ForegroundColor Green
Write-Host "输出目录: $ReleaseDir" -ForegroundColor Green
Write-Host "可执行文件: legado_flutter.exe" -ForegroundColor Green
Write-Host "`n分发时请包含整个 Release 目录（含 data\ 子目录）" -ForegroundColor Yellow
