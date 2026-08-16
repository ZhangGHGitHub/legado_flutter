---
description: Project folder structure and file placement conventions. Applies to all file creation and organization.
alwaysApply: true
---

# Structure: Legado Flutter

## 原则

1. **新增代码先选目录**：所有新增文件必须按本文件定义的目录结构放入对应位置。
2. **不确定先问**：如果 AI 不确定某个文件应放在哪个目录，应暂停并提问，等待用户确认。
3. **新旧并存不强制搬迁**：历史遗留目录（如 `lib/bookshelf/`）保持不动，**仅当用户明确要求时**再按新结构搬迁。
4. **命名后缀**：文件命名遵循 `snake_case`，且按用途添加后缀，便于识别。

---

## 完整目录树

```
legado_flutter/
├── lib/
│   ├── main.dart                 # 应用入口
│   │
│   ├── pages/                    # 页面层 — 每个子目录对应一个全屏/Tab 页
│   │   ├── home/                 # 书架页 (路由: /home)
│   │   ├── explore/              # 探索/搜索页 (路由: /explore)
│   │   ├── rss/                  # RSS 订阅页 (路由: /rss)
│   │   ├── reader/               # 阅读页 (路由: /reader)
│   │   └── settings/             # 设置页 (路由: /settings)
│   │
│   ├── services/                 # 业务服务层 — 单例/静态类，处理业务逻辑
│   │   ├── book_source_service.dart
│   │   ├── bookshelf_service.dart
│   │   ├── reading_progress_service.dart
│   │   └── webdav_service.dart
│   │
│   ├── providers/                # 状态管理层 — ChangeNotifier 实现
│   │   ├── bookshelf_provider.dart
│   │   ├── reader_provider.dart
│   │   ├── settings_provider.dart
│   │   └── theme_provider.dart
│   │
│   ├── models/                   # 数据模型层 — 纯 Dart 数据类
│   │   ├── book.dart
│   │   ├── chapter.dart
│   │   ├── source.dart
│   │   └── read_config.dart
│   │
│   ├── widgets/                  # 可复用 UI 组件 — 跨 2+ 页面复用
│   │   ├── empty_state.dart
│   │   ├── loading_indicator.dart
│   │   ├── error_view.dart
│   │   ├── cover_image.dart
│   │   └── custom_app_bar.dart
│   │
│   ├── bridge/                   # FFI 封装层 — 业务侧调用入口（不手改生成物）
│   │   ├── legado_engine_bridge.dart
│   │   └── legado_db_bridge.dart
│   │
│   ├── src/rust/                 # flutter_rust_bridge 生成代码（勿手改）
│   │   ├── api.dart              # 对外 API 门面
│   │   ├── api/                  # 分模块 API（如 toc.dart）
│   │   ├── frb_generated.dart    # FRB 编解码 / wire
│   │   └── frb_generated.io.dart
│   │
│   ├── config/                   # 配置与开关
│   │   ├── app_config.dart       # 应用级配置（底栏显隐、书架风格等）
│   │   └── engine_config.dart    # 引擎启动兼容占位（Rust-only，无切换）
│   │
│   ├── database/                 # 数据库层
│   │   ├── database_helper.dart  # SQLite 初始化与连接
│   │   └── dao/
│   │       ├── book_dao.dart
│   │       └── source_dao.dart
│   │
│   └── theme/                    # 主题系统
│       ├── theme.dart
│       ├── color_schemes.dart
│       ├── legado_tokens.dart
│       └── reader_style.dart
│
├── rust/                         # Rust 核心引擎
│   └── legado_engine/
│       ├── Cargo.toml
│       ├── src/
│       │   ├── lib.rs            # 对外 FFI 接口（标记 #[frb]）
│       │   ├── http/             # HTTP / Cookie / login_header_store 等
│       │   ├── rule/             # 规则与 JS（loginCheckJs 等）
│       │   ├── api/              # FRB 暴露的业务 API
│       │   └── db/               # SQLite
│       └── tests/
│
├── docs/
│   ├── DEVELOPMENT_PROCESS.md
│   └── RELEASE.md
│
├── scripts/
│   ├── build_engine.sh
│   └── generate_bridge.sh
│
└── packages/
    └── flutter_tts/
```

示例文件名为目标约定；与仓库现有文件名不完全一致时，**新代码按此命名，旧文件不强制改名**。

> **FRB 路径说明：** `flutter_rust_bridge` 默认生成到 `lib/src/rust/`（见仓库根 `flutter_rust_bridge.yaml`）。业务代码经 `lib/bridge/*_bridge.dart` 调用，**不要**把生成文件搬到 `bridge/`，也不要手改 `frb_generated*.dart`。

---

## 目录放置规则（AI 决策指南）

| 场景 | 放置位置 | 示例 |
| :--- | :--- | :--- |
| 新增一个全屏页面 | `lib/pages/[page_name]/` | `lib/pages/profile/` |
| 页面内专用的 UI 组件 | 放在该页面子目录下，如 `lib/pages/reader/widgets/` | `reader_control_bar.dart` |
| 跨 2+ 页面复用的 UI 组件 | `lib/widgets/` | `empty_state.dart` |
| 业务逻辑（非 UI） | `lib/services/` | `bookshelf_service.dart` |
| 状态管理（ChangeNotifier） | `lib/providers/` | `reader_provider.dart` |
| 纯数据类（无逻辑） | `lib/models/` | `book.dart` |
| FFI 业务封装 | `lib/bridge/` | `legado_engine_bridge.dart` |
| FRB 自动生成代码 | `lib/src/rust/`（codegen，勿手改） | `api.dart` / `frb_generated.dart` |
| 应用配置/开关 | `lib/config/` | `app_config.dart` |
| 数据库操作 | `lib/database/dao/` | `book_dao.dart` |
| 主题/颜色/Token | `lib/theme/` | `legado_tokens.dart` |
| Rust 核心逻辑（非 FFI 接口） | `rust/legado_engine/src/` | `http/login_header_store.rs` |
| Rust FFI 暴露接口 | `rust/legado_engine/src/api/` | `#[frb]` 标记的函数 |

---

## 文件命名后缀约定

| 目录 | 后缀 | 示例 |
| :--- | :--- | :--- |
| `lib/services/` | `_service.dart` | `bookshelf_service.dart` |
| `lib/providers/` | `_provider.dart` | `reader_provider.dart` |
| `lib/models/` | 无后缀 或 `_model.dart` | `book.dart` |
| `lib/database/dao/` | `_dao.dart` | `book_dao.dart` |
| `lib/config/` | `_config.dart` | `app_config.dart` |
| `lib/bridge/` | 无后缀 | `legado_engine_bridge.dart` |
| `lib/src/rust/` | 生成物，勿手改命名 | `api.dart` / `frb_generated.dart` |
| `lib/pages/` 内页面 | `_page.dart` | `home_page.dart` |

---

## 迁移说明

### 当前状态

- 历史目录（如 `lib/bookshelf/`、`lib/ui/`）可能存在，但**本次规则不强制一次性搬迁**。
- `lib/pages/home/` 通过 re-export 对齐目标路径；实现仍在 `lib/pages/bookshelf/`。
- 新增代码必须按上述新结构放置。

### 搬迁触发条件

- 仅当用户明确提出“按 structure.md 重构目录”时，才执行搬迁。
- 搬迁时优先处理高频修改的目录（如 `pages/`、`services/`），低影响目录（如 `theme/`）可延后。

### AI 操作指引

1. 收到编码任务时，先判断新增文件属于上述哪个目录。
2. 如果找不到完全匹配的目录，在对话中提问，等待用户指定。
3. 如果用户要求修改历史目录中的文件，直接修改即可，无需将整个目录搬迁到新结构。
