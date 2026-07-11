# 多平台发布指南（Phase 3.4）

> Legado Flutter — Rust 引擎 + Flutter UI

## 前置条件

1. 安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)（3.11+）
2. 安装 [Rust](https://rustup.rs/)（stable）
3. Windows 编译引擎：`.\scripts\build_rust.ps1`
4. 验证：`flutter test`

## 平台发布方式

| 平台 | 发布方式 | 构建命令 |
|------|---------|---------|
| **Android** | Google Play | `flutter build appbundle --release` |
| **iOS** | TestFlight → App Store | `flutter build ipa --release` |
| **Windows** | Microsoft Store / 独立 EXE | `.\scripts\package_windows.ps1` |
| **macOS** | Mac App Store | `flutter build macos --release` |
| **Linux** | AppImage / Snap / Flatpak | `flutter build linux --release` |
| **Web** | Vercel / Cloudflare Pages (PWA) | `flutter build web --release` |

## Windows 独立包

```powershell
.\scripts\package_windows.ps1
```

输出目录：`build\windows\x64\runner\Release\`

需一并分发：
- `legado_engine.dll`（Cargokit 或 `build_rust.ps1` 产物）
- `data\` 资源目录

## Android / iOS 注意事项

- Rust 引擎通过 **Cargokit**（`rust_builder/`）在构建时自动编译
- 首次构建较慢（~5–15 分钟），后续增量较快
- iOS 需 Xcode + Apple 开发者账号

## Web 限制

- Web 平台 **不支持** Rust FFI 引擎（`LegadoEngineBridge` 会标记不可用）
- Web 版仅适合 UI 演示，阅读功能需等待 WASM 引擎（未来）

## 性能基准（Phase 3.3）

```powershell
cd rust\legado_engine
cargo bench --bench rule_bench
```

基准项：
- `html_search_parse` — HTML 搜索规则解析
- `html_toc_parse_200` — 200 章目录解析

## 功能对齐验证（Phase 3.1）

### 离线（Rust 单元测试）

```powershell
cd rust\legado_engine
cargo test --test phase3_alignment
```

### 在线（Flutter 集成测试，需网络）

```powershell
flutter test test/integration/phase3_alignment_test.dart
flutter test test/integration/engine_pipeline_test.dart
```

## 版本检查

应用内「我的 → 关于」显示 Rust 引擎版本。发布前确认 `engine_version()` 与 CHANGELOG 一致。
