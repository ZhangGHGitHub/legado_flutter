# Legado Flutter

Legado 阅读器的 Flutter 复刻版，书源引擎使用 Rust 实现。

## 架构

```
Flutter UI → Provider → BookSourceService (Dart 编排)
                              ↓ FFI
                    legado_engine (Rust 核心)
                      ├── HTTP + Cookie + 限速
                      ├── CSS/JSONPath 规则
                      └── search API
```

## 快速开始

```bash
flutter pub get
flutter run -d windows   # 或 android / ios
```

默认使用 Rust 书源引擎与 rusqlite 数据库；未编译时书源功能不可用。

## 编译 Rust 书源引擎

**前置条件**: 安装 [Rust](https://rustup.rs/)（安装后需**重新打开终端**，或直接用下方脚本）

### 方式一：项目脚本（推荐，自动修复 PATH）

```powershell
# 仅编译 Rust DLL（日常开发）
.\scripts\build_rust.ps1

# 首次搭建 / 重装 FRB 代码生成（较慢）
.\scripts\setup_rust_engine.ps1
```

### 方式二：手动命令

若终端提示「无法识别 cargo」，先用完整路径：

```powershell
$env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path
cd rust\legado_engine
cargo build --release
```

或一行：

```powershell
& "$env:USERPROFILE\.cargo\bin\cargo.exe" build --release --manifest-path rust\legado_engine\Cargo.toml
```

### 方式三：无需手动 cargo

直接 `flutter run -d windows` 也会通过 **Cargokit** 自动编译 Rust（首次较慢）。

永久加入 PATH（可选）：系统环境变量中添加 `%USERPROFILE%\.cargo\bin`。

## 引擎切换

设置 → **Rust 书源引擎** 开关，可在 Rust / Dart 双轨间切换（用于 A/B 对比）。

## 目录结构

```
rust/legado_engine/     # Rust 书源引擎 crate
lib/bridge/             # Dart FFI 桥接层
lib/config/             # EngineConfig 引擎开关
lib/services/           # BookSourceService（双轨搜索）
```

## Phase 进度

- [x] Phase 0: Rust crate + FRB 配置
- [x] Phase 1: HTTP + Cookie + 限速 + 基础搜索（Rust）
- [x] Phase 1: Dart 双轨改造 + 设置页开关
- [x] Phase 2A: AnalyzeRule 通用规则管道（Dart）
- [x] Phase 2B: FRB 绑定 + LegadoEngineBridge 对接（搜索）
- [ ] Phase 2C: Rust 目录/正文 + 移除站点 hack
- [ ] Phase 3: 移除 Dart 规则引擎
