# R0 重基线与迁移追踪

状态：R0 基线已建立；2026-07-29 扩展架构检查后重新登记 R1-R6 残留。本文是当前 Rust + Flutter 重构的 R0 工作记录，
不替代 `REFACTOR_PLAN.md` 的阶段顺序，也不把历史 UI 复刻清单当作执行主线。

## 1. 事实来源与工作树

- 原版核对基线：根目录 `legado-main/`，只读，不参与 Flutter、Rust、Gradle 或 CI 构建。
- 活跃计划：`REFACTOR_PLAN.md`；行为验收：`LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md`；
  架构历史：`REFACTOR_ARCHITECTURE_BASELINE.md`；流程与变更记录：
  `DEVELOPMENT_PROCESS.md`、根目录 `CHANGELOG.md`。
- 历史资料：`archive/UI_REPLICATION_PLAN.md` 和 `docs/superpowers/` 下的 Phase/Wave 文件仅用于追溯，
  不得作为当前 R0-R6 执行顺序或 UI 像素验收依据。
- 本次开始时工作树已有大量已跟踪修改、文件迁移删除和未跟踪交付资产。R0 只新增本文、
  边界检查和最小文档口径调整；不重置、暂存、提交、移动或删除已有改动。

## 2. 阶段重新判定

| 阶段 | 当前判定 | 需要的后续证据 |
|---|---|---|
| R0 | 基线已建立，扩展检查已执行 | 按扩展规则持续减少并记录违规 |
| R1 | Room v99 门禁通过，组装边界继续 | 移除模型/服务默认具体适配器，统一根组合层 |
| R2 | 重新打开 | Rust 网络调用链、TLS、订阅和书单契约 |
| R3 | 重新打开 | Rust 正文/替换/压缩包唯一事实来源及双跑门禁 |
| R4 | 历史门禁有记录 | 仅在目录行为回归时重新开启 2A/2B |
| R5 | 本地开发门禁通过，未架构/发布完成 | 同步策略、本地 Web 服务归属和外部 WebDAV 验收 |
| R6 | 目录迁移完成，未退出 | 应用用例依赖、受控 UI 验收、平台与发布门禁 |

## 3. Flutter 残留业务清单

### 必须迁往 Rust

| 范围 | 当前 Dart 位置 | 目标阶段 | 迁移要求 |
|---|---|---|---|
| 原版 Kotlin Room 数据迁移 | `legado-main/app/src/main/java/io/legado/app/data/AppDatabase.kt`、`DatabaseMigrations.kt` 为只读基线；Rust 入口在 `rust/legado_engine/src/db/room_import.rs` | R1 | 先探针和字段映射，再做事务导入、备份/回滚、幂等和真实 fixture；不得修改 `legado-main/` |
| 正文净化、去重、重分段 | `lib/help/content_processor.dart`、`content_help.dart` | R3 | 先以原版/Dart/Rust fixture 双跑，保持字符位置和分页输入 |
| 替换规则执行 | `lib/services/replace_service.dart` | R3 | Rust 作为唯一正则与替换事实来源 |
| 规则订阅网络与解析 | `lib/services/rule_sub_import_service.dart` | R2 | Rust HTTP 处理 TLS、SSRF、重定向、JSON 与更新决策 |
| 书源 URL 拉取 | `lib/services/book_source_service.dart` | R2 | 删除 Dart `HttpClient` 与 TLS 绕过 |
| 书单网络与格式解析 | `lib/services/bookshelf_list_io.dart` | R2 | Flutter 仅保留文件选择和结果展示 |
| 远端 ZIP 书籍解包 | `lib/services/remote_archive_import_service.dart` | R3 | Rust 处理 ZIP、安全路径和格式识别 |
| 同步冲突与备份恢复策略 | `lib/services/sync_conflict_policy.dart`、`backup_service.dart` | R4 | 保持 ETag/412、ZIP 格式和失败不破坏本地数据 |
| 本地 Web 服务监听与路由 | `rust/legado_engine/src/web_server.rs` | R5 | 迁至 Flutter/Dart IO；Rust 只保留业务 port |

### 允许的 Flutter UI/平台职责

- `TextPainter` 断行、分页、动画、Widget、导航、页面状态和用户输入。
- 文件选择、权限、平台路径、字体/背景资源落盘、剪贴板和 UI 资源缓存。
- Dart IO 本地 Web 服务的监听、路由、认证、响应和状态；其业务查询必须经过 application port。

### 暂停项

- Web/WASM/PWA 平台构建与验收。
- 真实 Android 系统 TTS 引擎验收；HTTP TTS 的通用网络通道仍属于 R2。
- 发布前正式或主流 WebDAV 服务验收，需外部服务或凭证。

## 4. 已知边界违规与允许例外

- `lib/features/bookshelf/remote_book_page.dart`、`lib/features/sources/source_debug_page.dart`、
  `lib/features/book/toc_sheet.dart` 仍直接接触基础设施或 DAO，列为 R1/R6 清理项。
- `BookProvider`、`ReplaceProvider`、`SourceProvider` 仍默认构造 DAO、FRB port 或 Dart 业务服务，
  列为 R1/R2/R3 调用者迁移项。
- `AppBootstrap` 的引擎/数据库初始化是受控启动桥；`lib/infrastructure/**` 的 FRB 调用是允许适配层，
  但不得扩散到 Feature、Widget 或 Provider。
- 生产代码中两个 TLS 绕过点（规则订阅、书源 URL 拉取）是 R2 阻断项；后续迁移不得保留。

## 5. 工件分类

| 分类 | 路径 | R0 处置 |
|---|---|---|
| 保留只读基线 | `legado-main/`、`reference/` | 保留并忽略；不得构建、修改或提交 |
| 原位归档候选 | `docs/superpowers/` | 保留现有未提交内容，待可追溯拆分后物理归档 |
| 保留交付资产 | `rust/vendor/`、`integration_test/`、`tools/local-webdav/`、`scripts/*webdav*.ps1` | 不清理；后续按阶段精确纳入提交 |
| 本地证据/探针 | `original_legado.db*`、`tools/*.db`、`tools/*.png`、`tools/*.txt` | 忽略，不删除；删除需要独立确认 |

## 6. 静态边界检查

运行：

```powershell
.\scripts\check_architecture_boundaries.ps1
```

检查范围是 `lib/features/`、`lib/widgets/` 和 `lib/providers/`。它禁止直接使用 FRB/Bridge、
DAO/DatabaseHelper、基础设施适配器、生成 Rust API、Dio 和业务 HTTP 客户端。Dart 的本地文件
I/O 不被该脚本一概禁止，必须结合本节“允许 Flutter UI/平台职责”人工分类。

当前违规是 R1-R6 的迁移 backlog，不因 R0 脚本首次报告非零而被伪装为通过；每个后续迁移单元
必须减少或明确登记违规数，最终 R6 退出时归零。

2026-07-27 的 R1-6 `SourceDebugPage` 复验已将计数从 `21` 降至 `19`：Feature 不再直接导入或构造
`FrbBookSourceDebugPort`。随后 R1-7 `TocSheet` 复验移除了 DAO 和文件缓存 adapter 的四项 Feature 违规，
计数降至 `15`；R1-8 `ReplaceProvider` 复验再移除两项 DAO 违规，计数降至 `13`；R1-9
`BookProvider` 复验移除四项 DAO/cache adapter 违规，计数降至 `9`；R1-10 `SourceProvider` 复验
移除两项 DAO 违规，计数降至 `7`；R1-11 移除 SourceProvider 的 FRB adapter 组合，计数降至 `5`。
其余 `5` 项为 R2/R3/R4 backlog；R1 的旧 schema、章节身份和阅读位置门禁已按当前工程 Rust schema 复验。
用户已确认要支持原版数据库迁移，因此 R1 新增 R1-12 Kotlin Room v99 数据迁移门禁；现已完成探针、23 个
实体表原始快照、核心映射、事务导入、备份/回滚、幂等和 Android 设备 smoke。非核心表采用 archive-only
保留原始列和值，暂不宣称已建立对应产品业务 port。

## 7. 本轮验证记录（2026-07-27）

- 开始前执行 `git status --short`：工作树已存在大批跟踪修改、页面迁移删除和未跟踪交付资产；
  本轮没有重置、暂存、提交、移动或删除这些文件。
- `scripts/check_architecture_boundaries.ps1`：脚本可执行，按设计以退出码 `1` 报告 `21` 项当前
  违规。重点包括 Feature 对 DAO/infrastructure/FRB adapter 的直接引用，以及 Provider 对 DAO、
  FRB adapter 和 `HttpClient` 的直接引用；这些是迁移 backlog，不是本轮通过结论。
- `flutter analyze --no-pub`：通过，输出 `No issues found!`。
- `git diff --check`：通过；仅输出当前工作树已有文件的 LF/CRLF 转换警告。

本轮未运行 Flutter/Rust 全量测试，因为只改变文档、`.gitignore` 和独立检查脚本；下一次涉及
Dart 或 Rust 生产代码的迁移单元必须按阶段门禁运行定向测试，并在阶段结束时运行全量回归。

## 8. 历史计划入口归档（2026-07-27）

- 未修改的 `UI_REPLICATION_PLAN.md` 已移动到 `docs/archive/`；文档索引、主计划和开发流程的
  活跃入口均已改为归档路径。
- `docs/superpowers/` 和 `.superpowers/sdd` 中仍含未提交的历史资料，保持原路径并明确标为
  原位归档候选。物理归档必须等待既有改动拆分为可追溯提交后执行，避免将用户改动混入 R0。
- 本步没有改动 Kotlin 原版基线、Flutter/Rust 生产代码、数据库或备份格式。

## 9. 版本控制分组

当前工作树的建议提交顺序、排除项和精确暂存规则见
[`R0_WORKTREE_GROUPS.md`](./R0_WORKTREE_GROUPS.md)。本文件只建立分组依据；在获得明确授权前，
不得执行暂存、提交或推送。

## 10. R1-12 数据库迁移门禁追溯（2026-07-29）

R1-12 已满足当前计划的数据库迁移退出条件。原版 `legado-main/` 仍只读，
本轮没有修改、暂存、提交或推送既有工作树内容。

- `rust/legado_engine/src/db/room_import.rs` 提供 Room v99 只读探针、23 个实体表稳定快照和 Rust v17
  映射；保留 `legacy_room_imports` 原始 JSON 快照、列和值与未映射字段，避免把不支持字段静默丢弃。
- 导入路径包含导入前备份、单事务写入、失败回滚、源快照指纹幂等、主键/绑定冲突统计和迁移报告；
  书签仅在书名和作者唯一匹配时绑定，`readRecord` 聚合时间不做猜测。
- 章节 ID 保持与 Flutter `Chapter.idFor` 一致的 UTF-16 FNV-1a 语义；`durChapterPos` 保持 UTF-16
  章内位置语义；书源规则 JSON 解析为嵌套对象并保留原始字符串。
- FRB 绑定、Dart application port/service 和备份配置页入口已接入；页面不直接构造 FRB adapter。非核心表以
  archive-only 方式保存，`book_sources_part` 是 Room schema 定义的只读 view，不作为独立实体迁移。

验证结果：

- `cargo fmt -p legado_engine`：通过。
- `cargo test -p legado_engine db::room_import::tests -- --nocapture`：`10/10` 通过。
- `cargo test -p legado_engine`：`127` 个 Rust 测试通过；既有网络 ignored 测试保持原规则。
- `flutter analyze --no-pub`：通过，`No issues found!`。
- Dart/备份页定向测试：`6/6` 通过；`flutter test --no-pub --concurrency=1`：`521` 通过，3 个既有在线测试跳过。
- 真实 `original_legado.db` 只读探测：`user_version=99`，Room identity hash 为
  `90980f1d0da029cf3254f354b227a2fe`；23 个实体表存在但当前均为 0 行。
- Android `emulator-5556` 两阶段 Driver smoke 通过：真实文件导入及导入后写入；强制停止/新进程后读取、
  重复导入幂等、本地备份、清空和恢复。

范围说明：

- 真实 `original_legado.db` 当前为空库，因此真实文件没有提供非空业务行；非空等价 fixture 已覆盖核心
  字段、阅读位置、规则 JSON、章节身份、详细记录、书签歧义和非核心原始行。
- 非核心表没有 Rust v17 产品业务 port，但 23 个实体表已纳入原始快照、指纹、备份和恢复路径，不会静默丢失。

因此，R1-12 标记为“数据库迁移门禁通过”。非核心表产品业务 port 和真实非空原版数据的补充采集属于后续
独立工作；本轮没有推进新的 R2-R6 实现，也没有修改正文、目录、分页、章节身份或断行规则。
