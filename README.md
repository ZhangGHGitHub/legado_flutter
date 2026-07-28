# Legado Flutter

将 [Jingshiro/legado](https://github.com/Jingshiro/legado) 重构为 Rust + Flutter 的跨平台版本；Jingshiro/legado 是行为、数据和 UI 兼容性的参照基线。

根目录 `legado-main/` 是只读的原版核对目录，仅用于行为、数据结构、UI 和错误语义对照；它不是主源码目录，不参与 Flutter/Rust/Gradle/CI 构建，也不得直接修改。

**文档入口：** [docs/README.md](docs/README.md) · **开发流程：** [docs/DEVELOPMENT_PROCESS.md](docs/DEVELOPMENT_PROCESS.md)

## 架构

```
Flutter pages/providers
        ↓ application/domain ports
infrastructure adapters → FRB generated bindings
        ↓
legado_engine (Rust core)
  ├── HTTP + Cookie + rate limiting
  ├── CSS/JSONPath/Legado rules
  ├── SQLite database and backup
  └── WebDAV client and Web API
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

## 书源引擎

书源解析统一由 **Rust**（`rust/legado_engine`）完成，经 FFI 暴露给 Flutter。`EngineConfig` 仅为启动兼容占位，**无** Dart/Rust 用户切换。

## 目录结构

```
rust/legado_engine/     # Rust 书源引擎 crate
lib/application/        # 用例编排和任务生命周期
lib/domain/              # 领域模型、Repository 和 Port 接口
lib/infrastructure/      # FRB、数据库、缓存、WebDAV 适配器
lib/pages/               # 过渡期页面目录，R6 再按功能域迁移
lib/services/            # 过渡期服务；新边界优先使用 domain/application
lib/bridge/              # 兼容桥接层
lib/src/rust/            # FRB 生成代码，仅由适配层和兼容桥使用
```

## Phase 进度

重构阶段进度以 [docs/REFACTOR_PLAN.md](docs/REFACTOR_PLAN.md) 的 R0-R6 为准：

- [x] R0: 架构盘点与行为基线
- [ ] R1: 领域模型与数据访问边界；Kotlin Room v99 数据迁移门禁已重新打开，当前完成只读探针
- [ ] R2: 书源引擎与 FRB 适配边界；已有历史迁移记录，需在 R1-12 完成后复验
- [ ] R3: 阅读会话、正文处理与缓存链路；已有历史迁移记录，需在 R1-12 完成后复验
- [ ] R4: 目录顺序、章节身份和性能边界；已有历史 2A/2B 证据，需在 R1-12 完成后复验
- [ ] R5: 同步、备份和远端存储开发门禁；本地 WebDAV/Android 回归已有记录，发布前仍需正式或主流 WebDAV 服务真实验收
- [ ] R6: Feature UI 与平台适配收敛

当前执行焦点是 R1-12：原版 Kotlin Room v99 数据库迁移。Web/WASM/PWA 和真实 Android 系统 TTS 验收按项目文档暂停。
