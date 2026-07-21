---
description: Tech stack, coding conventions, and engineering standards. Applies to all code files.
alwaysApply: true
---

# Tech: Legado Flutter

## Language & Framework

- **Dart (SDK ^3.11) + Flutter**：UI 层使用 Flutter 构建，遵循 Material Design 3 设计规范。
- **Rust**：书源解析核心位于 `rust/legado_engine`，通过 `flutter_rust_bridge` 进行 FFI 调用。
- **状态管理**：Provider（保持现状，不引入其他状态管理方案）。
- **本地存储**：SQLite（通过 `sqlite3`）+ SharedPreferences。
- **网络请求**：dio（保持现状，不引入其他网络库）。
- **HTML 解析辅助**：html 库（用于轻量解析，复杂解析交给 Rust）。

### 依赖管理规则

- **新增依赖前必须暂停并提问**：当现有依赖无法满足需求时，先在对话中说明理由并等待确认，不得擅自引入。
- **优先复用现有依赖**：在考虑新增依赖前，先评估是否能用 dio、html 或 Flutter 原生能力实现。

---

## 书源引擎设计（Rust 核心）

### 核心挑战：JavaScript 规则处理

原版 Legado 的书源规则包含 **JavaScript 表达式**（如章节列表过滤、正文内容净化等）。Rust 引擎需要能够解析和执行这些 JS 逻辑。

### 技术方案（待定选型）

在 Rust 中处理 JS 规则，有以下可行路径：

- **方案 A - 嵌入 JS 引擎**：引入 `rquickjs` 或 `deno_core` 等 Rust 库，在引擎内直接执行 JS 代码段。优点是兼容性高，缺点是增加二进制体积和内存占用。
- **方案 B - 规则预编译 + AST 解释**：将 JS 规则解析为 AST，用 Rust 原生实现一套轻量解释器。优点是性能高、无额外运行时，缺点是实现复杂度高。
- **方案 C - 混合模式**：核心解析逻辑用 Rust 实现，将 JS 表达式提取后通过 FFI 回调 Dart 侧的 JS 解释器（如 `flutter_js`）执行。

**AI 行为约束**：在未确定最终方案前，新增解析逻辑时需先提问“这段逻辑是否涉及 JS 规则？”，并根据用户确认选择对应实现方式。

---

## Data & Engine

### 数据存储原则

- **本地优先**：所有阅读数据（书架、进度、书源）优先存储在本地 SQLite + SharedPreferences 中。
- **云端仅作为备份**：WebDAV 仅用于用户主动触发的备份/恢复，不作为主要数据源。

### 引擎使用规则

- **唯一引擎：Rust**：所有书源解析逻辑（搜索、目录、正文）均在 `rust/legado_engine` 中实现，经 `flutter_rust_bridge` 暴露给 Flutter。
- **不再提供 Dart 引擎切换**：`lib/config/engine_config.dart` 仅为兼容启动流程的空加载占位，不含用户可切换的双轨选项。
- **勿恢复 Dart 规则引擎**：不得重新引入设置页「Dart/Rust 切换」或独立 Dart 解析回退路径作为产品功能。

### UI 布局参考

- UI 布局和交互逻辑对标 **Jingshiro/legado**（原版 Android「阅读」），确保老用户零学习成本迁移。

---

## 性能与 FFI 设计原则

### FFI 调用策略

- **批量处理，减少高频通信**：避免在 Dart 和 Rust 之间频繁传递小块数据（如逐章节调用）。应设计“粗粒度”接口，例如一次调用返回整本书的目录结构。
- **异步优先**：所有涉及 Rust 引擎的调用（如搜索、解析）都必须是异步的，避免阻塞 UI 主线程。
- **性能目标**：章节解析和翻页操作不应导致 UI 掉帧（60fps），解析耗时超过 100ms 的操作需显示加载状态。

### 代码生成优化

`flutter_rust_bridge` 的代码生成在大型项目中可能变慢。建议：

- **分层架构**：将与 Flutter 交互的 FFI 接口层（`lib/bridge/`）与核心业务逻辑层（`rust/legado_engine/src/`）分离。
- **减少生成量**：仅对需要暴露给 Dart 的 Rust 函数添加 `#[frb]` 宏，内部逻辑不暴露，以减少生成代码量。

---

## Code Organization

```
lib/
├── pages/          # 完整页面（对应一个全屏或标签页），每个页面一个子目录
│   ├── home/       # 首页（书架）
│   ├── search/     # 搜索页
│   ├── reader/     # 阅读页
│   └── settings/   # 设置页
├── services/       # 业务服务类（如书架服务、书源管理服务、阅读进度服务）
├── providers/      # 状态管理类（与 Provider 配合使用的 ChangeNotifier 类）
├── models/         # 数据模型类（如 Book, Chapter, Source 等纯数据类）
├── widgets/        # 可复用的 UI 组件（不跨页面复用的组件应就近放在页面目录下）
├── bridge/         # Flutter 与 Rust 的 FFI 桥接代码（仅接口层）
├── config/         # 引擎开关、运行时配置
├── theme/          # 主题颜色、字体、样式定义
└── main.dart       # 应用入口

rust/legado_engine/
├── src/
│   ├── lib.rs      # 对外暴露的 FFI 接口（标记 #[frb]）
│   ├── parser/     # 核心解析逻辑（不对外暴露）
│   ├── source/     # 书源管理逻辑
│   └── utils/      # 辅助工具
└── Cargo.toml
```

### 命名规范

- **文件与目录**：Dart 文件使用 `snake_case`（如 `book_source_service.dart`）。
- **类名**：Widget 类使用 `PascalCase`（如 `ReadingPage`、`BookListTile`）。

---

## 编码规范与格式化 (Code Style & Formatting)

### Dart / Flutter 规范

**1. 格式化工具**
- **必须使用** `dart format` 进行代码格式化。
- 在提交前运行：`dart format lib/`
- **编辑器设置**：建议在 VS Code / Cursor 中开启“保存时自动格式化”（`editor.formatOnSave`）。

**2. 代码检查 (Linting)**
- 使用 `flutter_lints`（推荐）或项目自定义 `analysis_options.yaml`。
- 提交前运行：`flutter analyze`，确保无警告（或仅有预期的忽略）。
- **关键规则**：
  - 避免使用 `print()` 调试（生产版本应移除）。
  - 避免使用 `dynamic` 类型，除非绝对必要。
  - 未使用的变量、导入和参数必须移除或加 `_` 前缀。

**3. 导入规范**
- **导入排序**：
  1. Dart SDK 库（`dart:`）
  2. Flutter 库（`package:flutter`）
  3. 第三方依赖（`package:provider`）
  4. 项目内部库（`package:legado_flutter/`）
- 每组之间用空行分隔。
- **路径引用**：内部模块引用优先使用 `package:legado_flutter/...`（绝对导入），而非相对路径 `../`（除非在 `lib/` 内部有特殊原因）。

**4. 行长度**
- 遵循 Dart 默认规范：**最大行长度 80 字符**。
- （如有团队习惯放宽至 120，请在 `analysis_options.yaml` 中显式配置并记录于此。）

---

### Rust 规范

**1. 格式化工具**
- **必须使用** `rustfmt`（默认配置）。
- 在提交前运行：`cargo fmt`。

**2. 代码检查**
- 运行 `cargo clippy`，修复所有可警告项（或显式 `#[allow]`）。
- **关键约束**：
  - 避免 `unwrap()` 直接解包（优先使用 `?` 或 `expect()` 并附带错误信息）。
  - 函数返回类型尽量使用 `Result<T, E>`，避免隐式崩溃。

---

### 编辑器配置（推荐）

在项目根目录下创建 `.vscode/settings.json`（或 `.cursor/settings.json`），确保团队一致：

```json
{
  "editor.formatOnSave": true,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "Dart-Code.dart-code"
  },
  "[rust]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "rust-lang.rust-analyzer"
  }
}
```

---

## Quality

### 测试

- **Flutter 测试**：运行 `flutter test` 执行 Dart 层单元测试和 Widget 测试。
- **Rust 测试**：运行 `cargo test` 执行引擎层单元测试。
- **集成测试**：关键流程（搜索 → 加书架 → 阅读）需覆盖端到端测试。
- **测试规范**：详细流程见 `docs/DEVELOPMENT_PROCESS.md`（若文件存在，AI 在涉及测试流程时应自动读取；若暂无内容，请遵循本文件所述核心要点）。

### 发布

- 发布流程详见 `docs/RELEASE.md`（若文件存在，AI 在涉及发布流程时应自动读取；若暂无内容，请遵循本文件所述核心要点）。

### Git 提交规范

- 提交信息应具有描述性，说明“做了什么”和“为什么”，例如：`fix(reader): 修复章节解析时内存泄漏问题`。
- **禁止提交**：密钥文件（`.env`、`*.pem`）、本地配置文件等。

---

## Secrets & Security

### 密钥存储

- **本地存储**：WebDAV 凭据等敏感信息仅存储在 SharedPreferences 中，不写入任何代码文件。
- **无服务端场景**：本应用不涉及服务端部署，无服务端密钥暴露风险。

### 环境变量（备选方案）

- 如需在开发中使用测试凭据，可通过 `.env` 文件管理，但 **`.env` 必须加入 `.gitignore`**，不得提交到仓库。

---

## AI 行为约束（优先级从高到低）

1. **新增依赖**：必须暂停并提问，等待用户确认。
2. **代码放置**：根据目录结构，将新代码放入对应目录。如果不确定，先提问。
3. **引擎选择**：默认使用 Rust 实现新的解析逻辑，不主动修改 Dart 引擎代码（除非用户明确要求）。
4. **JS 规则处理**：涉及 JS 逻辑时，先确认当前采用的技术方案，再编码。
5. **安全**：不在任何代码中硬编码密钥、URL 或敏感信息。
6. **性能**：FFI 调用采用批量异步方式，避免高频通信。
