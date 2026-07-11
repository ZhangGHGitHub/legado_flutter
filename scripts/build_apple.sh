#!/usr/bin/env bash
# Phase 3.4 — 构建 macOS / iOS（需在 macOS 上运行）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "=== flutter pub get ==="
flutter pub get

TARGET="${1:-all}"

build_macos() {
  echo "=== flutter build macos --release ==="
  flutter build macos --release
  echo "输出: build/macos/Build/Products/Release/"
}

build_ios() {
  echo "=== flutter build ios --release --no-codesign ==="
  flutter build ios --release --no-codesign
  echo "输出: build/ios/iphoneos/Runner.app"
}

case "$TARGET" in
  macos) build_macos ;;
  ios) build_ios ;;
  all)
    build_macos
    build_ios
    ;;
  *)
    echo "用法: $0 [macos|ios|all]"
    exit 1
    ;;
esac

echo "=== 完成 ==="
