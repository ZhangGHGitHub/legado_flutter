# Rust 书源引擎构建脚本
# 用法: .\scripts\setup_rust_engine.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

# 配置国内镜像（可选）
$env:RUSTUP_DIST_SERVER = "https://mirrors.ustc.edu.cn/rust-static"
$env:RUSTUP_UPDATE_ROOT = "https://mirrors.ustc.edu.cn/rust-static/rustup"
$env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path

Write-Host "=== Step 1: 检查 Rust 工具链 ===" -ForegroundColor Cyan
rustup default stable
rustc --version
cargo --version

Write-Host "`n=== Step 2: 安装 flutter_rust_bridge_codegen ===" -ForegroundColor Cyan
cargo install flutter_rust_bridge_codegen --version 2.11.1 --locked

Write-Host "`n=== Step 3: 集成 FRB 到 Flutter 项目 ===" -ForegroundColor Cyan
flutter_rust_bridge_codegen integrate --rust-crate-dir rust/legado_engine

Write-Host "`n=== Step 4: 生成 Dart/Rust 绑定代码 ===" -ForegroundColor Cyan
flutter_rust_bridge_codegen generate

Write-Host "`n=== Step 5: Flutter 依赖 ===" -ForegroundColor Cyan
flutter pub get

Write-Host "`n=== Step 6: 编译验证 ===" -ForegroundColor Cyan
Push-Location rust
cargo build --release
Pop-Location
flutter analyze lib

Write-Host "`n✅ Rust 书源引擎构建完成！" -ForegroundColor Green
Write-Host "运行 flutter run -d windows 测试搜索功能" -ForegroundColor Yellow
