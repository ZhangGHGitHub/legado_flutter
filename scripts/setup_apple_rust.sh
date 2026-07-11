#!/usr/bin/env bash
# Phase 3.4 — 安装 iOS/macOS Rust 交叉编译 target
set -euo pipefail

echo "=== 安装 Rust Apple targets ==="
rustup target add \
  aarch64-apple-darwin \
  x86_64-apple-darwin \
  aarch64-apple-ios \
  aarch64-apple-ios-sim \
  x86_64-apple-ios

echo ""
echo "=== 检查 Xcode ==="
if ! xcode-select -p >/dev/null 2>&1; then
  echo "请先安装 Xcode 并运行: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi
xcodebuild -version

echo ""
echo "=== 检查 CocoaPods ==="
if ! command -v pod >/dev/null 2>&1; then
  echo "未找到 pod，请安装: sudo gem install cocoapods"
  exit 1
fi
pod --version

echo ""
echo "完成。下一步:"
echo "  flutter pub get"
echo "  flutter build macos --release"
echo "  flutter build ios --release --no-codesign"
