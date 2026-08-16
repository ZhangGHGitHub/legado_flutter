# Legado Flutter + Rust 三端通用重构设计

> 本文由项目设计稿固化，作为后续架构迁移、代码评审和阶段验收的约束来源。
> 与当前仓库既有重构计划冲突时，必须在 `REFACTOR_PLAN.md` 中登记差异和迁移批次，不能静默偏离。

## 一、目标架构

最终架构分为 Flutter UI、Rust Bridge 和 Rust Core 三层。

```text
Flutter App
  Pages / Widgets / State (Riverpod)
            |
  flutter_rust_bridge
            |
Rust Core
  书源引擎 / 解析规则 / 文本解析
  网络 / 数据库 / 工具库
```

核心原则：

- UI 层不包含业务逻辑，只负责渲染、交互和状态管理，并调用 Rust API。
- Rust 承载所有与界面无关的业务逻辑。
- 平台桥接层只保留必须使用原生 API 的能力，优先使用成熟 Flutter 插件。
- 数据流固定为：Flutter UI -> Rust API -> 纯数据 -> UI 状态。

## 二、原 Android 模块归属

| 原模块 | 类别 | 目标归属 |
|---|---|---|
| `model/` 数据模型 | 纯逻辑 | Rust |
| `help/` 解析器、JS 引擎、替换净化 | 纯逻辑 | Rust |
| `network/` 网络、Cookie、重试 | 可移植逻辑 | Rust |
| `database/` 实体、DAO、数据库操作 | 数据层 | Rust |
| `ui/` Activity、Adapter、View | UI | Flutter |
| `service/` 后台下载服务 | 平台相关 + 业务逻辑 | 原生桥接 + Rust |
| `widget/` 阅读器控件 | UI | Flutter |
| 本地文件读写 | 平台依赖 | Flutter 插件 + Rust 解析 |
| 分享、Intent | 平台依赖 | Platform Channel |

必须形成以下可追溯资产：

- 模块到目标归属的映射表。
- 归入 Rust 的公开 API 清单。
- Android Context/系统服务强依赖清单及替代方案。
- 现有 Flutter 功能与迁移分类的对应关系，避免重复迁移。

## 三、Rust 核心工程

目标结构：

```text
rust_core/
  Cargo.toml
  core/
    Cargo.toml
    src/
      lib.rs
      models.rs
      book_source.rs
      rule_engine.rs
      text_parser.rs
      network.rs
      db.rs
      error.rs
  ffi_bridge/
    Cargo.toml
    src/
      api/
        bookshelf.rs
        reader.rs
        discover.rs
        settings.rs
      lib.rs
```

Rust 核心依赖包括 `flutter_rust_bridge`、`serde`、`reqwest`、`rusqlite`、`thiserror`、QuickJS、CSS 选择器解析、EPUB 和编码探测。

### 3.1 难点约束

| 能力 | Rust 方案 | 必须满足 |
|---|---|---|
| JS 书源执行 | QuickJS 沙箱 | 禁止危险 API，执行超时 5 秒 |
| CSS/规则解析 | `scraper` 等 | 兼容原规则语法 |
| 正文替换/净化 | Rust 处理 | 保持原规则格式和行为 |
| TXT/EPUB | Rust 解析 | 使用编码探测，覆盖 GBK/GB18030 |
| 网络/Cookie | `reqwest` + Cookie | 移动端 UA、重试和超时一致 |
| 数据库 | `rusqlite` | Schema 一致，迁移可回滚 |

每项能力必须先完成最小原型和测试，再进入正式迁移。

### 3.2 FFI 错误和异步边界

- FFI 公开函数统一返回 `Result<T, AppError>`，禁止用字符串替代结构化错误。
- 禁止 panic；错误必须实现 `Display` 并能被 Dart 侧分类处理。
- 长耗时操作使用 `async fn` 或 `spawn_blocking`，不得阻塞 UI 线程。
- 数据库路径由 Flutter 通过统一的 `init(app_dir: String)` 传给 Rust。

## 四、Flutter UI

### 4.1 页面和状态

- 页面和组件只负责渲染、交互和状态订阅。
- 业务编排放在 application 层，Rust 调用放在 infrastructure 适配层。
- 统一使用 Riverpod，每个功能模块对应一个 Notifier。
- 主题和组件通过 `Theme.of(context)` 统一管理。
- 阅读器翻页等复杂组件必要时使用 `CustomPainter`，但不能把正文业务规则放回 UI。

### 4.2 数据模型

- Flutter 模型使用 `freezed` 生成。
- Flutter 模型必须与 Rust `serde` 模型镜像。
- JSON 序列化、不可变对象和字段变更必须由生成代码或明确契约维护。

### 4.3 UI 优先级

1. 书架
2. 阅读器核心
3. 发现页
4. 设置和书源管理
5. 规则编辑器

## 五、阶段路线

| 阶段 | 目标 | 成功标准 |
|---|---|---|
| Phase 0 | 审计现有 Flutter、Rust 和原版模块 | 形成架构差距分析、迁移映射和 API 清单 |
| Phase 1 | Rust 核心连通 | ping、书架列表、Rust 数据源接入书架 |
| Phase 2 | 书源引擎 | 搜索/发现切到 Rust，结果与原版一致 |
| Phase 3 | 阅读器 | Rust 提供正文流，Rust 执行正文净化，阅读体验无回退 |
| Phase 4 | 管理功能 | 导入导出、备份恢复、规则编辑器可用 |
| Phase 5 | 清理优化 | 移除旧逻辑，完成目标平台构建和兼容验收 |

每个 Phase 必须按“分析原模块 -> Rust 实现与测试 -> 生成 Dart 绑定 -> Flutter 对接 -> 人工验收”执行。

## 六、并行开发和契约先行

允许 Rust 和 Flutter UI 并行开发，但必须以契约为同步点。

### 6.1 角色边界

- Flutter 线负责页面、组件、状态、路由、主题和平台展示，不包含业务计算。
- Rust 线负责模型、网络、数据库、书源引擎和文本解析，并提供测试和绑定。

### 6.2 CoreApi 契约

必须建立 `api_contract.md`，统一维护函数、输入、输出、模型和错误。

```yaml
functions:
  - name: getBookshelf
    description: 获取书架所有书籍
    input: 无
    output: Result<Vec<Book>, AppError>
    models:
      Book: { id: String, name: String, author: String, cover_url: Option<String> }

  - name: searchBooks
    description: 在线搜索
    input: { source_url: String, keyword: String }
    output: Result<Vec<SearchResultItem>, AppError>

errors:
  AppError: [Network, Parse, Database, JsExecution]
```

Flutter 必须提供：

```dart
abstract class CoreApi {
  Future<List<Book>> getBookshelf();
  Future<List<SearchResultItem>> searchBooks(String sourceUrl, String keyword);
}

class MockCoreApi implements CoreApi {}
class RealCoreApi implements CoreApi {}
```

应用启动时按环境注入 `MockCoreApi` 或 `RealCoreApi`。UI 可以脱离 Rust 使用真实格式的 Mock 数据开发。

### 6.3 并行同步点

| 阶段 | Rust | Flutter | 同步点 |
|---|---|---|---|
| 契约定义 | 函数和模型 | 页面字段和交互 | `api_contract.md` |
| 骨架搭建 | ping 和基础封装 | Mock 页面 | 无阻塞并行 |
| 模块冲刺 | 书架/搜索 API | Mock 交互 | API 完成后联调 |
| 复杂模块 | 正文流 | Mock 分段和翻页 | 正文性能和字段契约 |
| 集成清理 | 性能和平台构建 | 移除 Mock | 全量联调 |

### 6.4 协作规则

- 契约文档随代码版本控制，修改必须同步更新 Rust 和 Flutter 测试。
- Mock 数据使用原版真实 JSON 样本，避免只覆盖理想字段。
- Rust 与 Flutter 可以独立分支开发，集成分支集中联调。
- CI 至少运行 Rust 测试、Flutter Widget 测试和集成冒烟测试。

## 七、强制风险约束

- JS 沙箱必须限制危险 API，并且有 5 秒执行超时。
- 数据库路径必须由 Flutter 显式传入 Rust。
- Rust 长耗时函数必须异步或放入阻塞线程。
- 所有 FFI 错误必须使用统一 `AppError`。
- 编码处理必须覆盖 GBK/GB18030，并提供对比 fixture。
- Rust 修改需要重启应用；UI 开发阶段可以使用 Mock。
- 契约变更必须同步更新文档、Mock、绑定和通知另一条开发线。

## 八、工具链

| 用途 | 工具 |
|---|---|
| Rust Android | cargo-ndk + Android NDK |
| Rust iOS | cargo lipo 或 Xcode 集成 |
| 代码生成 | flutter_rust_bridge_codegen generate |
| 自动化 | Makefile / just |
| 状态管理 | riverpod + riverpod_generator |
| 数据模型 | freezed |
| 日志 | Rust `log` + `android_logger`，Flutter `logger` |
| 测试 | `cargo test`、`flutter test` |

## 九、第一步行动

1. 审计 legado 和现有 Flutter，输出已迁移、未迁移、Dart 残留逻辑、状态管理和存储差距。
2. 创建书架和搜索的 `api_contract.md` 草案。
3. 建立 Rust 核心、FFI bridge 和模型契约。
4. 创建 `CoreApi`、`MockCoreApi`、`RealCoreApi` 和环境注入。
5. 从书架开始切换 Rust 数据源，保证 UI 代码不因真实/Mock 切换而修改。

## 十、当前仓库执行说明

本设计稿是目标架构；当前仓库的 `docs/REFACTOR_PLAN.md` 是阶段执行记录。两者关系如下：

- 本文定义最终设计、硬约束和验收方向。
- `REFACTOR_PLAN.md` 定义当前阶段、依赖顺序、暂停项和实际测试证据。
- `DEVELOPMENT_PROCESS.md` 定义每个变更的测试、记录和 Git 追溯要求。
- 未完成的目标不得通过修改断言、跳过测试或修改 `legado-main/` 标记为完成。
