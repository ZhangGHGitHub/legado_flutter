# Legado Flutter — 项目重构主计划

> **开发流程：** [DEVELOPMENT_PROCESS.md](./DEVELOPMENT_PROCESS.md) · **文档索引：** [README.md](./README.md)  
> **主目标：** 在不改变 [Jingshiro/legado](https://github.com/Jingshiro/legado) 可观察行为的前提下，将其 Android/Kotlin 工程重构为 Rust + Flutter 跨平台工程，并收敛模块边界、数据流、缓存链路和 UI 组织方式。
> **行为验收：** [LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md](./LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md) 是本计划的验收子计划，不是独立的功能开发主线。
> **重构来源与基线：** [Jingshiro/legado](https://github.com/Jingshiro/legado)；UI 1:1 对齐和行为兼容是重构验收子目标，不是独立产品定位。
> **本地原版基线：** 根目录 `legado-main/` 是只读的原版行为、数据结构、UI 和错误语义核对目录，不是本项目的主源码目录，也不参与 Flutter/Rust 构建。
> 目标平台：Android / iOS / Windows / macOS / Linux / Web (WASM)  
> 最后更新：2026-08-01
> 引擎版本：**v0.5.6** | Rust DB Schema：**v17** | 原版 Room：**v99** | FRB：**2.11.1**
>
> 当前暂停项（2026-07-26）：Web 平台/WASM/PWA 构建、Web 平台适配和相关验收；TTS 真实 Android 引擎验收。除这两类门禁外，Android/Windows 重构继续按固定顺序推进。

> **统一设计约束：** [LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md](./LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md) 已于 2026-08-01 固化为目标架构和后续迁移的硬约束。当前 Provider、手写模型、字符串错误和宿主级 QuickJS 超时缺口均视为待迁移项；在对应门禁通过前，不得宣称严格设计一致。

### 0.0.1 设计稿收敛顺序

后续实现按以下顺序推进，每一项必须先补契约和测试，再迁移生产调用者；不得通过放宽断言或跳过测试关闭缺口：

1. Phase 0：补齐原 Android 模块归属映射、Rust API 清单、Android 平台依赖清单和现状差距报告。
2. Phase 1：建立 `api_contract.md`、`CoreApi`、`MockCoreApi`、`RealCoreApi`，先覆盖书架和搜索。
3. Phase 2：统一 Rust FFI `AppError`、Dart 错误映射和 `init(app_dir)` 初始化契约。
4. Phase 3：建立 Rust/Flutter 镜像模型，逐模块引入 `freezed`，保留兼容映射直到调用者完成迁移。
5. Phase 4：按模块将 Provider/ChangeNotifier 迁移为 Riverpod Notifier，逐批保留行为回归。
6. Phase 5：为 QuickJS 增加 5 秒执行中断、危险 API 门禁和超时 fixture。
7. Phase 6：补充 `chardetng` 或等价编码探测、GBK/GB18030 对比 fixture 和统一 Rust 本地书籍解析链。
8. Phase 7：补齐 Rust/Flutter/Android/Windows CI；其他平台按暂停条件单独验收，不伪造通过。

数据库 Room v99 -> Rust v17、正文/目录/分页/章节身份和 UTF-16 阅读位置门禁保持现有优先级，不因上述架构收敛改变行为。

2026-08-01 设计收敛批次：已建立 `CoreApi/MockCoreApi/RealCoreApi` 首批契约，`search/explore/get_book_info/get_toc/get_content/validate_source` 及下一章正文入口已迁移到 Rust `AppError`；`SearchResultItem` 已完成 freezed 镜像样板；新增 Riverpod CoreApi Notifier 样板和 Rust/Flutter/架构检查 CI。验证为 Rust `186`、Flutter `879` 通过，`3` 项既有条件跳过；业务页面仍未整体切换 Riverpod，剩余 FFI 错误边界继续按批次迁移。

2026-08-01 当前追溯补充：工作树继续完成 `BookReadConfig`、`BookGroup`、`Chapter` Freezed/兼容映射、`BookshelfNotifier` 状态样板、`debug_search/debug_toc` 和 23 个数据库入口的 Rust `AppError` 迁移；书架 Notifier 定向 `8` 项、Chapter 定向 `6` 项、组合根定向 `4` 项通过。FRB 生成链已恢复并验证：Rust 全量 `192` 项通过，Flutter 串行全量 `894` 项通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。运行时验证补建了过期的 `rust/target/debug/legado_engine.dll`，确认生成绑定与动态库协议一致。生成器的 SDK/analyzer 版本提示为非阻塞警告。本条只做追溯记录，不改变既定 Phase 顺序、R1-R6 退出条件或 Room v99 -> Rust v17、正文/目录/分页/章节身份/UTF-16 阅读位置门禁。

2026-08-01 网络错误边界批次：将 `fetch_public_text`、应用 HTTP 文本请求和二进制请求的公开 FFI 错误统一为 `AppError`，保留输入校验、文本解码、SSRF、响应大小、请求方法/头体和非 2xx 响应行为；新增网络错误分类回归并重新生成 FRB。Rust 网络定向 `9` 项、Rust 全量 `199` 项、Windows FRB HTTP 集成 `2` 项、Flutter 串行全量 `894` 项通过，`3` 项既有条件跳过；`flutter analyze --no-pub` 已通过。架构扫描和 `git diff --check` 待本批最后执行。其余网络配置/Cookie、裸 HTTP、RSS、JS、笔记和书签入口仍未迁移，不宣称统一错误边界已完成。

2026-08-01 网络错误边界扩展批次：将裸 `http_fetch`、网络配置、Cookie 和 HTTP trace 入口统一为 Rust `AppError`，保持限流、请求参数、Cookie 域规则、trace 行为和错误原文；新增网络/SSRF/字符解码/书源 URL 分类断言。Rust API 定向 `57` 项、Rust 全量 `202` 项、Windows FRB HTTP 集成 `2/2`、Flutter 串行全量 `894` 项通过，`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。QuickJS 超时、统一初始化、编码事实源和书架生产 Riverpod 切换仍按审查方案排队。

2026-08-01 QuickJS/数据库初始化追溯补充：`rust/legado_engine/src/rule/js_engine.rs` 统一脚本入口使用 QuickJS Runtime，增加 5 秒纯 QuickJS 执行 interrupt 和 `script/jsLib` 单项 256 KiB 输入上限；定向测试 `29/29` 通过。该 interrupt 只覆盖纯 QuickJS 执行；`java.ajax`、`getStrResponse` 和 WebView 宿主阻塞不在本批保证范围内，不据此宣称完整宿主端到端超时门禁已完成。`rust/legado_engine/src/db/mod.rs` 与 `src/api/db.rs` 增加 `init(app_dir)`：固定使用 `app_dir/legado.db`，空路径/文件路径拒绝，同目录幂等、异目录拒绝，schema 初始化在单事务中执行且失败不发布；初始化锁覆盖首次并发调用；数据库定向测试 `19/19` 通过。FRB 绑定已重新生成，`LegadoDbBridge` 已从旧文件路径入口切换为应用数据目录入口；release DLL 重建后备份服务定向测试 `10/10` 通过。`cargo test -p legado_engine` 为 `208` 项通过，Flutter 串行全量为 `894` 项通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界扫描、`cargo fmt -p legado_engine` 和 `git diff --check` 均通过。本条仅记录当前代码与证据，不新增或扩展 R1-12、R2、R6 阶段退出声明。
2026-08-01 公开 FFI 错误边界追溯补充：`get_book_info`、`query_dict_rule`、笔记和书签入口统一返回 Rust `AppError`；详情/字典保持解析、网络、JS、校验和不支持错误分类，笔记/书签保持数据库 CRUD、Markdown、排序、UTF-16 位置和错误原文。目录/校验内部通过 `AppError::into_legacy` 兼容既有 `String` 链。FRB 已重新生成，Rust 全量 `218` 项、Flutter 全量 `894` 项通过，`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。RSS、EPUB、浏览器宿主及其它公开 `Result<T, String>` 入口仍未迁移，本条不扩展 R1-12、R2、R6 阶段退出声明。

2026-08-01 公开 FFI 错误边界扩展批次：本地 EPUB/远程 ZIP 解析入口统一为 `AppError::Parse`，RSS 文章/正文入口统一为 `AppError::Network` 或 `AppError::Parse`；保留 EPUB/ZIP 的解析、大小限制、路径安全、文件筛选和成功结果，保留 RSS 的排序、分页、文章字段、正文解析和错误原文。FRB 已重新生成；新增 Rust RSS 分类边界测试、Dart `AppError` 原文和 ZIP 适配器回归。Rust 定向 RSS `4/4`、Rust 全量 `224` 项，Flutter 定向 `10/10`、Flutter 全量 `897` 项，均通过；另有 `3` 项既有 Flutter 条件跳过，`flutter analyze --no-pub`、release DLL 构建、架构边界扫描和 `git diff --check` 通过。本批同时修复 FRB 适配层的 `AppError` 原文提取，非 Rust 异常仍按原路径传播。浏览器宿主、QuickJS 宿主阻塞、其它公开 `Result<T, String>`、Dart 全链路统一展示和阶段退出条件仍未完成，本条不扩展 R1-12、R2、R3 或 R6 阶段退出声明。

2026-08-01 `eval_js` FFI 错误边界批次：将同步 `eval_js` 入口改为 `Result<String, AppError>`，脚本异常统一为 `AppError::JsExecution`，保留成功结果、错误原文、纯 QuickJS 5 秒 interrupt 和 `script/jsLib` 256 KiB 输入门禁；FRB 已重新生成。新增 Rust `eval_js` 成功/错误契约测试和 Dart 生成 API 结构化错误测试；Rust 定向 `2/2`、Rust 全量 `226`、Flutter 定向 `2/2`、Flutter 全量 `899` 通过，另有 `3` 项既有 Flutter 条件跳过，release DLL、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。本批不覆盖 `java.ajax`、`getStrResponse`、WebView 宿主阻塞、浏览器宿主或其它公开 `Result<T, String>`，不扩展 R1-12、R2、R3 或 R6 阶段退出声明。

2026-08-01 登录头预热 FFI 错误边界批次：将同步 `seed_login_header` 入口改为 `Result<(), AppError>`，保留 source URL/header trim、空值忽略、登录头缓存写入和无 dirty 更新行为；FRB 对应 codec 已同步，新增 Rust `3/3` 与 Dart `2/2` 契约测试。Rust 全量 `226`、Flutter 全量 `901` 通过，另有 `3` 项既有 Flutter 条件跳过，release DLL、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。生成器曾因 Windows 文件映射锁在 rustfmt 阶段警告，最终只保留 source-owned 的三处最小绑定差异；浏览器宿主、其它公开 `Result<T, String>` 和阶段退出条件仍未完成，本条不扩展 R1-12、R2、R3 或 R6 阶段退出声明。

2026-08-01 正文处理 FFI 错误边界批次：将同步 `process_content_for_reading` 入口改为 `Result<String, AppError>`，底层正文处理错误统一映射为 `AppError::Parse`，保留成功输出、替换规则、段落缩进、标题合并和重新分段行为；FRB 对应 codec 已同步，新增 Rust `2/2` 与 Dart `2/2` 契约测试。Rust 全量 `228`、Flutter 全量 `903` 通过，另有 `3` 项既有 Flutter 条件跳过，release DLL、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。本批不覆盖浏览器宿主、重复公开 FRB 子模块入口、WebDAV、平台验收、其它公开 `Result<T, String>` 或阶段退出条件，不扩展 R1-12、R2、R3 或 R6 阶段退出声明。

2026-08-01 重复公开 FRB 入口收敛批次：将 `search/explore/toc/debug/validate` 子模块入口标记为 `frb(ignore)` 并降为 `pub(crate)`，根 `api/mod.rs` wrapper 继续作为唯一公开 FRB API；重新生成绑定后移除子模块重复 Dart/Rust wire 导出并删除陈旧子模块 Dart wrapper，保留根入口参数、返回值、`AppError` 分类和内部调用路径。验证：`cargo fmt -p legado_engine`、Rust 全量 `228`、release 构建、`flutter analyze --no-pub`、Flutter 全量 `903` 通过且 `3` 项既有条件跳过，架构边界扫描和 `git diff --check` 通过。本批不改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、浏览器宿主、WebDAV、平台验收或阶段退出条件。

2026-08-01 浏览器宿主错误边界与 WebView 生命周期批次：将 `serve_source_browser_host`、`probe_source_browser_host` 公开失败结果统一为 `AppError`，保留成功 DTO、Dart 回调链和错误原文；取消为 `Cancelled`，不支持平台为 `Unsupported`，宿主停止/锁失败/线程失败为 `Unknown`。Rust 宿主增加 abort/clear 后清理当前 sender 的生命周期守卫，WebView dispose 后不再触发新的 Cookie 写入或回调；完成验证成功路径仍等待 Cookie 队列、抓取 DOM 并返回 finalUrl/body。Rust `browser_host` 定向 `7/7`、Dart 浏览器宿主/WebView 定向 `8/8`、Rust 全量 `234`、Flutter 串行全量 `908` 通过，另有 `3` 项既有 Flutter 条件跳过，release DLL、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。本批不改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、WebDAV、平台验收或阶段退出条件。

---

## 0.0 R0 重基线附录（2026-07-27）

本附录以当前工作树为依据，重新打开 R0 的“可追溯基础”门禁。此前约三百项未提交变更已拆分为
可追溯提交，但 Dart 仍保留平台无关业务逻辑，扩展后的架构检查也暴露出原扫描范围外的依赖；因此
历史 R0-R6 记录仍不能直接视为最终架构验收。

- `legado-main/` 是唯一的本地只读 Kotlin 行为基线；`reference/` 如存在，仅作为历史离线副本，
  两者均不得参与构建或被修改。
- 当前活跃执行顺序仍为 R0-R6。本轮 R0 的唯一事实记录是
  [`R0_REBASELINE.md`](./R0_REBASELINE.md)，其中列出 Flutter 残留业务、允许的平台例外、工件
  分类和静态边界检查结果。
- [`archive/UI_REPLICATION_PLAN.md`](./archive/UI_REPLICATION_PLAN.md) 与 `docs/superpowers/` 下的 Phase E/F、Wave 资料是历史功能库存和
  审计资料，不得作为当前重构的执行顺序或 R6 退出依据。UI 对照只用于受控状态下的兼容验收，
  不能取代目录、正文断行、分页、章节身份和阅读位置契约。
- R0 基线已经建立；2026-07-29 扩展静态检查后，R1 的默认适配器组装、R2 的网络/TLS、R3 的
  正文/替换/压缩包已完成复核和迁移，R5 的本地 Web 服务归属已迁至 Dart IO。正式/主流
  WebDAV 与目标平台/UI 发布验收仍未完成，R6 应用用例依赖继续按队列处理。
- 2026-07-27 用户确认“要数据库迁移”后，R1 增加 `R1-12 Kotlin Room v99 数据迁移门禁`；
  该门禁完成前不得把 R1 标记为最终退出，也不得以历史 R2-R6 记录替代当前阶段退出条件。

---

## 0. 重构总纲（2026-07-25 修订）

### 0.1 重构目标

当前工程是将 Jingshiro/legado 从 Android/Kotlin 迁移到 Rust + Flutter 的重构工程，已经具备较多功能，但代码组织仍按历史开发顺序堆叠，存在 `model`/`models`、`engine`/`services`、`help`/`utils`、页面与业务服务相互调用、Rust FRB 生成层与业务层边界不清等问题。后续工作的主任务不是继续堆功能，而是把迁移后的实现收敛为可维护、可测试、可替换的模块结构。

重构完成后应满足：

- UI 只依赖应用用例和状态，不直接拼装 Rust API、数据库 SQL、缓存文件路径或网络请求。
- 业务规则、阅读会话、目录、缓存、同步和备份各自有明确的领域边界；跨边界只能通过接口或用例通信。
- Rust 负责规则解析、网络和数据库等核心能力；Flutter 负责界面、交互和平台展示；FRB 生成代码只能由适配层使用。
- 数据库、章节文件、WebDAV 和缓存实现可以替换而不牵动页面；目录顺序、章节身份、阅读位置、正文内容和断行分页保持兼容。
- 每次重构只迁移一个边界或一条链路，旧入口与新入口可在过渡期并存，并由测试证明行为没有漂移。

### 0.1.1 原版核对目录边界

- `legado-main/` 只用于对照原版实现、行为、数据结构、UI 和错误语义。
- 不得直接修改、构建或发布 `legado-main/` 中的源码；重构代码必须位于当前 Flutter/Rust 工程目录。
- 不得将 `legado-main/` 加入 Flutter、Rust、Gradle 或 CI 的源码/依赖路径。
- 原版发现的差异必须通过当前工程的契约测试、集成测试或文档记录处理，不能通过修改原版基线消除差异。

### 0.2 目标模块边界

```text
lib/features/             页面、ViewModel/Provider、用户交互
lib/application/          用例编排、状态转换、任务生命周期
lib/domain/               Book、Chapter、ReadingProgress、Bookmark 等纯模型/接口
lib/infrastructure/       Rust/FRB、SQLite、文件缓存、WebDAV、HTTP、平台适配
rust/legado_engine/       规则引擎、网络、数据库和可独立测试的核心实现
lib/src/rust/             仅作为生成绑定，不允许被页面和领域层直接扩散依赖
test/contract/             跨层契约和原版行为回归
test/integration/         设备与平台链路验收
```

现有目录不要求一次性搬空。迁移期间先建立新边界，再逐个迁移调用者；禁止为了“整理目录”进行无测试的大规模移动。


### 0.3 重构阶段与固定顺序

#### R0：架构盘点与行为基线

建立实际依赖图、入口清单、数据所有权表和测试基线；标记页面直连数据库/FRB、服务互相循环依赖、重复模型、重复缓存逻辑和全量扫描点。盘点结果记录在 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。本阶段原则上只新增盘点文档、契约测试和必要的观测日志，不改变业务行为。

退出条件：主入口到 Rust/数据库/文件/WebDAV 的调用链已记录；现有测试基线可重复；领域模型字段与数据所有权表已确认；R1 数据库访问清单和迁移测试已建立；模块迁移顺序和禁止跨层依赖清单已确认。

#### R1：领域模型与数据访问边界

统一 `Book`、`Chapter`、阅读进度、书签、缓存元数据和书源模型的归属，拆分纯模型、Repository 接口和 SQLite/Rust 实现；补齐 schema 迁移和旧数据兼容。页面不得继续直接依赖数据库结构。

当前进度：已完成 R1-1“书籍/章节 Repository 接口化”、R1-2“数据库记录映射与旧 schema 迁移契约”、R1-3“RustDatabasePort 与 FRB 适配隔离”、R1-4a“ReadBook 阅读会话 Repository 注入”、R1-4b“LocalBookService Repository 注入”、R1-4c“ReplaceProvider 替换规则 Repository 注入”、R1-4d“BookInfoPage 书籍 Repository 注入”、R1-4e“MainShell 书源 Repository 注入”、R1-4f“SourceProvider 书源 Repository 注入”、R1-5“AppBootstrap 启动编排”。R0 重基线后的 R1-6 至 R1-10 已分别清理 SourceDebugPage、TocSheet、ReplaceProvider、BookProvider、SourceProvider 的 DAO/FRB adapter 直接组合；R1-11 已将 SourceProvider 的校验 FRB adapter 创建移至根组合层。当前工作树的 R1 技术证据已复核：模型/port 契约、Rust v7→v17 旧 schema 可读写、章节 URL 身份与阅读位置迁移、全仓 analyze、串行 Flutter 全量和 Rust workspace 均通过。这里的“旧数据库”仅指本工程先前 Rust schema；原版 Android Kotlin Room 数据库当前版本为 v99（`legado-main/app/src/main/java/io/legado/app/data/AppDatabase.kt`），已确认纳入迁移范围。原版行为核对源码位于仓库根目录 `legado-main/app/src/main/java`。

退出条件：数据模型契约测试通过；本工程 Rust 旧 schema 可读写；章节身份和阅读位置迁移无差异；Kotlin Room v99 数据库探针、字段映射、导入事务、备份/回滚和真实/合成 fixture 回归通过。

当前判定：R1 已重新打开，尚未最终退出。R1-12 当前只按“核心七表业务映射 + 23 个 Room 实体表全量原始归档”描述；本批已补 Kotlin Room v99 版本与 identity hash 强制门禁和正冲突测试，已记录的 Room 定向 `13/13`、Rust 全量、release、Flutter analyze 和 Flutter 全量 `908`（`3` 项既有条件跳过）结果均通过，但最终本轮门禁仍由父 agent 复核。`readRecord` 仍仅登记 warning；非核心表仍为 archive-only，真实非空 `original_legado.db` 证据仍缺失，不能据此宣称 23 张表已全部完成 Rust v17 业务迁移。R1-12 的非核心业务 port、`readRecord` 映射和真实非空数据边界不在本轮擅自决定。R1-12 完成前，不推进新的 R2-R6 实现，也不以历史 R2-R6 记录替代当前退出条件。

##### R1-12：Kotlin Room v99 数据迁移门禁（复核中，部分完成）

目标：支持从原版 Android Kotlin Room 数据库文件安全迁移到 Rust schema，而不是只支持本工程旧 Rust schema。

当前只读基线：

- 原版数据库定义：`legado-main/app/src/main/java/io/legado/app/data/AppDatabase.kt`，`@Database(version = 99)`。
- 手写迁移链：`DatabaseMigrations.kt` 覆盖 10→43；Room auto migration 覆盖 43→99，且 1→9 仍按原版 `fallbackToDestructiveMigrationFrom` 处理。
- 核心迁移对象：`books`、`book_sources`、`chapters`、`bookmarks`、`readRecord`、`detailedReadRecord`、`replace_rules`。

已完成：

- Rust 新增只读探针 `rust/legado_engine/src/db/room_import.rs`，通过只读 SQLite 连接读取 `PRAGMA user_version`、`room_master_table` identity hash，并检查核心表/列形状。
- 建立 Room v99 → Rust v17 核心七表映射；章节使用 UTF-16 FNV-1a 身份，书签歧义不绑定，`readRecord` 聚合时间不猜测。
- Rust v17 增加 `legacy_room_imports` 原始快照归档，保存全部 23 个 Room 实体表的列和值；章节附加字段、替换规则 `group/scope` 等未进入 v17 业务表的字段通过 archive-only 快照保留。
- Rust API 暴露 `db_import_legacy_room_database(path, backupPath, replace)`；导入前写入备份，目标写入单事务执行，失败回滚，快照指纹支持重复导入幂等，并返回计数、冲突、警告和未映射列。
- FRB 2.11.1 绑定、Dart application port/service 和备份页导入入口已接入；页面只调用 application service。
- 定向测试覆盖 v99 探针、字段映射、章节身份、详细阅读记录、书签歧义、全部实体表快照、原始字段保留、备份、回滚和重复导入；Android smoke 覆盖真实文件导入、导入后写入、重启后读取、重复导入幂等和备份恢复。

边界说明（当前仍未关闭）：

- 使用真实非空 Room v99 数据库或非空等价 fixture 验证逐字段迁移：非空等价 fixture 已覆盖当前核心映射；真实 `original_legado.db` 仍为空库，真实非空数据证据缺失。
- 原版 23 个 Room 实体表已纳入快照和报告；非核心表当前采用可恢复的 archive-only 保存，不宣称已有 Rust v17 业务 port。
- `readRecord` 仍仅登记 warning，是否映射其聚合时间需后续按产品语义决策；Android 真实文件导入等历史 smoke 结果不替代当前 R1-12 复核。

R1-12 当前判定：核心七表业务映射与 23 表原始归档已实现，新增 v99 门禁和正冲突测试已记录通过；但整体迁移门禁仍在复核中，不能标记 R1-12 或 R1 最终退出。后续非核心表业务模型、`readRecord` 映射和原版真实非空数据补充采集必须另行按计划执行；本轮没有推进新的 R2-R6 实现。

#### R2：书源引擎与 FRB 适配边界

把搜索、发现、详情、目录、正文和规则调试统一收敛到应用用例；`BookSourceService` 只做门面，Rust API/生成绑定集中在 infrastructure 适配层。网络、规则解析、登录头、Cookie 和错误语义不散落到页面。

当前进度：R2-1 至 R2-7 已完成。核心书源请求和规则调试页面已经通过领域端口调用，FRB 生成类型仅保留在 `lib/infrastructure/engine` 与既有底层兼容桥中。R0 扩展复核后已移除 Rust HTTP 无效证书绕过，书源、规则订阅、书单 URL、RSS 订阅源 URL 和主题 URL 文本抓取均已收敛到统一 Rust HTTP 文本端口；RSS 与主题入口保留各自的 URL trim、SSRF 拒绝和错误契约。字典查询也已移除 Dio 和占位结果，改由 Rust 执行 AnalyzeUrl 与 showRule，当前覆盖 GET/POST、headers/body/charset、`data:`、HTML/JSON/JS、Jsoup 可变 DOM，以及内置规则使用的 `JavaImporter`、Jayway `JsonPath`、`java.base64Encode`、`java.hexDecodeToString` 和 `with(aly)` 包装。当前五条内置字典规则已由离线 fixture 覆盖，百度普通释义和成语分支均已验证。AI 配置与 Obsidian REST API 也已移除 Dio，统一通过 application HTTP port 和 Rust 客户端；AI 固定公网 SSRF 策略，Obsidian 固定允许 localhost/LAN 的本地网络策略，二者共享默认 TLS、逐跳重定向检查、超时和响应大小门禁。统一二进制 HTTP port 已建立，正文图片缓存、阅读样式 ZIP、HTTP TTS 以及书源、漫画、封面、RSS、字典结果等页面远程图片均已迁入；生产代码中的 `Image.network/NetworkImage`、生产/测试 Dio import、pubspec 声明及 lockfile 条目均已清零。书源登录 WebView 已按当前页面读取 Cookie，并按 source key/eTLD+1 持久化到 Rust 网络会话，搜索、详情、目录和正文可跨请求域复用；`enabledCookieJar` 的发送前实际域覆盖、条件式响应保存，以及 source/login/URL option 优先级均已按原版代码路径覆盖测试。Android/iOS/macOS 已通过定域平台端口删除 source host/eTLD+1 WebView Cookie，不使用全局清空；iOS/macOS 真机构建待对应平台执行。`java.startBrowserAwait` 已通过长期 FRB Dart callback 服务接入可见 WebView，支持原版 2/3/4 参数、UTF-16 64 KiB URL 门禁、默认重新抓取、HTML/最终 URL/DOM 返回、Cookie 同步、取消与错误恢复；QuickJS 在专用阻塞线程等待后继续同一脚本上下文。

当前不宣称 R2 已最终退出。书源入口、统一网络/Cookie、规则 fixture、JS 兼容、错误恢复、FRB 适配和可见 WebView 宿主已有历史实现证据；后台 `java.webView*`、文件/压缩及其它未命中的第三方 JS API 仍是兼容性 backlog，且 R1-12 未完成前不得以这些历史记录推进新的 R2 实现。

退出条件：所有书源入口通过统一用例，规则 fixture、JS 兼容和错误恢复测试通过，页面不再直接调用生成绑定。

#### R3：阅读会话、正文处理与缓存链路

将 `ReadBook`、正文清洗、章节文件缓存、数据库正文回落、预加载、位置映射和分页输入拆成可测试的阅读会话与基础设施。正文处理和缓存可以替换，但输入正文、章节边界、字符范围、中文断行和分页必须保持一致。

当前进度：R3-1 至 R3-4 的历史端口迁移已复核；本轮进一步将全局/书源正文替换、标题去重、重新分段和多行正则统一到 Rust 唯一事实源，生产阅读、全文搜索和替换预览共用同一 `ContentProcessingPort`。正文多页支持串行/并行规则顺序、循环终止、下一章 URL 边界和 100 页显式上限；阅读位置按当前页起始 UTF-16 章内位置保存，文件/DB 缓存生命周期保持原布局。远端书籍 ZIP 的格式识别、路径安全、50MB 输入/解压总量和损坏包错误已迁入 Rust，Flutter 只负责平台文件写入。纯 Dart 滚动范围 mapper 仍不接入 ReaderPage，因为原版按已排版行位置而非线性比例计算滚动读位；中文断行继续由 Flutter `TextPainter` 链路负责。

当前判定：R3 已最终退出。Rust workspace 核心 `185/185`、正文/ZIP 真实 Windows FRB `5/5`、Flutter 串行全量 `641` 通过（`3` 项既有条件跳过）、桌面模块 3 门禁 `59/59`、Android 模块 3 门禁 `4/4`、全仓 analyze、Android debug APK 和格式门禁均通过。架构扫描保持既有 `146` 条后续 backlog，无新增违规；Web/WASM/PWA 与真实 Android TTS 暂停条件不变。

退出条件：正文处理契约、缓存生命周期、章节切换和第 3 条断行/分页门禁通过。

#### R4：目录数据流与列表渲染

将目录请求、分页合并、章节持久化、`reverseToc`、当前章定位、字数/书签元数据和列表渲染分离。目录首帧只依赖可见数据；网络、数据库和非首帧元数据不得阻塞 UI。原版目录顺序和 `index` 由 [LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md](./LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md) 的 2A/2B 门禁验收。

当前进度：2A 已完成原版目录顺序、书籍 `readConfig.reverseToc` 持久化、目录切换反转已保存章节并连续重写 0-based `index`、远端目录 index 归一化和目录首帧不等待缓存字数/书签元数据。2B 已在雷电 `emulator-5556` 上完成 2000 章合成冷/热首帧与滚动帧基线、`Book.tocUrl` 持久化、重复详情请求消除、受控目录分页并发和同一本真实线上书的原版/重写版对比；5 轮真实 UI 冷/热请求计数、目录首帧、Release 帧和 PSS 证据已记录。R3 最终退出后再次只读复核目录顺序、章节 `index/identity`、目录分页和可见行元数据，未发现回归，R4 不重开。

退出条件：2B 冷热缓存性能数据和结构性卡顿修复通过，且没有引入跨层依赖。当前已满足，后续按 R5 继续模块 4 收尾。

#### R5：同步、备份和远端存储边界

统一阅读进度、书签、备份和 WebDAV 的 repository、冲突策略、任务门禁和错误传播；UI 不直接控制上传/下载细节。R5 采用两层验收：本地自建 WebDAV 用于开发退出门禁，正式或主流 WebDAV 服务用于发布前真实验收。

开发退出条件：本地数据安全、ETag/冲突重试、备份格式、失败策略和本地自建 WebDAV 应用回归通过。发布前附加条件：必须使用正式或主流 WebDAV 服务至少完成一次真实验收，覆盖 TLS、认证/权限、服务端 ETag/412、MOVE、ZIP 上传下载恢复和失败策略；未完成时不得声明发布验收完成。

当前进度：本地 Web API 的监听、路由、Token 认证、响应和运行状态已迁至 Dart IO；业务查询经 `WebApiDataPort` 和 Repository 进入既有数据库能力。Rust Web Server、FRB 生命周期 API/DTO 和旧 Rust HTTP 集成测试已删除，`/api/*` 兼容行为由 Dart 协议测试及真实 Rust 数据库集成测试覆盖。正式或主流 WebDAV 发布验收仍待执行。

#### R6：Feature UI 与平台适配收敛

按功能域整理页面、Provider/状态和组件，移除页面间的隐式全局状态；Android、Windows、iOS、macOS、Linux、Web 的平台能力集中到适配层。UI 兼容性以原版源码映射、受控状态下的关键流程对照和行为契约验收；历史 UI Task 仅见 `archive/UI_REPLICATION_PLAN.md`，不作为执行清单。

退出条件：核心用户流程在目标平台构建并通过，UI 与原版对照测试通过，平台差异有明确适配记录。

当前进度：R6 功能域目录迁移已完成 `main`、`bookshelf`、`reader`、`book`、`sources`、`rss`、`settings`、`my`、`search`、`cache`、`code_edit`、`explore`、`ai`、`obsidian` 和 `common`；旧 `lib/pages` 下仅保留书架兼容导出。P0-1 至 P1-4 横切基础设施任务均已完成，应用用例依赖继续按 Feature 边界收口；Batch 8 后 Flutter 串行全量 `869` 通过（`3` 项既有条件跳过），analyze、架构扫描和 diff 检查均通过。Batch 9 已完成 `<js>` 兼容证据审查，修复兼容脚本的假绿/离线参数问题，并将 Rust `@JS:`/`@Js:`/`@jS:` 路由及能力判定统一为大小写不敏感；最终 Rust `legado_engine` `186/186`、JS 脚本 Rust `18/18`、Flutter `4/4`、Flutter 全量 `869` 通过，架构扫描和 diff 检查通过。完整宿主 API、真实 FRB 执行链、在线书源和对象返回值语义仍登记为未关闭兼容性 backlog。R6 后续继续处理剩余 Feature 依赖、受控 UI/目标平台和发布门禁；真实 Android TTS、后台音频服务、Web/WASM/PWA、外部 AI 服务及正式/主流 WebDAV 验收继续按暂停/范围外条件处理。

#### 横切基础设施：全局能力与启动可靠性（跨 R1-R6，新增）

原版 Application.onCreate 不只负责业务启动，还注册了全局崩溃处理、应用日志、生命周期管理、卡顿/调度监控、默认数据升级、缓存清理、通知通道和网络/TLS 初始化。当前 Flutter 端已有 AppBootstrap、AppLog、局部生命周期监听、Rust HTTP/TLS、缓存端口和若干偏好迁移，但没有统一的跨平台全局能力边界；这些局部实现不得被当作原版全局能力已完成。

按以下顺序补齐，任务完成前不得在 R6 发布验收中宣称“全局能力与启动行为兼容”：

- P0-1 崩溃防护与启动恢复（已完成）：新增 CrashLogService 或等价 application/infrastructure 边界；在 main 最早阶段安装同步错误、Flutter 框架错误、平台 dispatcher 错误和未处理异步错误捕获；持久化最近一次崩溃摘要、堆栈、平台/版本/引擎信息和启动阶段；下次启动安全读取并显示一次崩溃提示，支持进入日志、清除标记和失败降级。崩溃写入路径自身不得依赖尚未初始化的数据库、WebDAV 或完整 UI。
- P0-2 存储初始化安全（已完成）：新增 SharedPreferences 进程级运行时状态和并发初始化合并；启动关键偏好/崩溃存储 adapter 在未初始化或初始化失败时返回默认值、空值或明确失败结果。Rust DB 记录 `uninitialized/initializing/ready/failed`，初始化失败不阻塞首屏，数据库业务仍以可识别的不可用错误拒绝；文件缓存探测失败返回安全空值。MainShell 隐私偏好、AppConfig、书架布局、主题、WebDAV 和启动 adapter 均不再因存储初始化竞态阻塞首屏。此项不引入 Hive。
- P0-3 启动任务隔离（已完成）：新增 `StartupTaskRunner`，将网络/Web API 恢复、WebDAV 初始化、书架加载后的缓存维护/章节元数据、阅读进度同步、RSS 源加载、替换规则加载、内置书源补齐、书源加载和规则订阅自动更新纳入可观测任务；每项独立超时、捕获错误、记录结果，不阻塞首屏。成功任务同进程不重复，失败任务可重试，条件不满足任务显式跳过。AppConfig 与书架布局偏好仍作为首屏布局输入同步读取，保留默认首页和底栏显隐语义。
- P1-1 全局生命周期边界（已完成）：建立 application 级生命周期协调器，统一承接前后台、暂停/恢复、应用退出和资源释放；Flutter 平台 observer 只在 infrastructure 层注册并由组合根管理；页面只订阅状态，不各自注册同一类全局回调。对照原版 LifecycleHelp，明确 Flutter 多窗口、Android Activity、桌面窗口和 Web 平台的差异。
- P1-2 卡顿与调度监控（已完成）：增加可开关的帧耗时、主 isolate/后台任务超时和应用冻结观测，接入 AppLog/CrashLogService，默认关闭高成本监控；对照原版 AppFreezeMonitor、DispatchersMonitor，不把普通业务异常误记为崩溃。
- P1-3 全局日志与诊断信息（已完成）：统一 AppLog 的错误、异常、启动阶段、设备/平台、应用版本和 Rust 引擎版本格式；限制敏感信息、条数和文件大小；让崩溃日志、运行日志和手动导出日志复用同一诊断模型，但保留清理和脱敏边界。
- P1-4 平台启动能力盘点（已完成）：逐项确认原版通知通道（下载、朗读、Web 服务）、后台任务/服务、WebView 绘制设置、GMS TLS provider、Cronet 预下载和简繁转换预热在 Flutter 各目标平台是否需要等价实现。已由 Rust HTTP 覆盖的网络能力只记录为已覆盖，不重复引入 Cronet；没有产品需求或目标平台支持的能力明确登记为范围差异。

P0-1 当前证据：纯 Dart 报告/存储 port、`FlutterError`/`PlatformDispatcher`/Zone 捕获、启动阶段记录、真实应用/平台/引擎版本和原版顺序的一次性提示均已接入；错误与堆栈有 UTF-16 安全长度上限，存储/元数据失败不阻塞启动。崩溃链定向 `13/13`、启动相关回归 `15/15`、Flutter/Rust 全量与双平台构建通过。

P0-2 当前证据：SharedPreferences 运行时状态/并发竞态/失败重试和三个启动 adapter 定向 `4/4`，AppConfig、主题、书架、网络、文件缓存、MainShell 及备份回归 `43/43`；`flutter analyze --no-pub` 无诊断；Flutter 串行全量 `663` 通过、`3` 项既有条件跳过；Rust workspace 核心 `184/184`，其余集成、WebDAV 和文档测试无失败。全量测试中发现的 mock 存储污染已通过逐测试 reset 修复，未修改任何业务断言。下一项严格进入 P0-3。

P0-3 当前证据：启动任务 runner、启动 WebDAV、阅读进度同步、书架缓存维护、MainShell 和 Welcome 定向 `22/22`；`flutter analyze --no-pub` 无诊断；架构扫描保持 `144` 条既有 backlog，无新增类别；Flutter 串行全量 `667` 通过、`3` 项既有条件跳过；Rust workspace 核心 `184/184`，其余集成、WebDAV 和文档测试无失败。下一项严格进入 P1-1。

P1-1 当前证据：新增 application 级 `AppLifecycleCoordinator`，统一记录生命周期 phase、恢复次数和 resumed 状态；新增 infrastructure 级 `FlutterLifecycleObserver`，只在组合根注册 Flutter `WidgetsBindingObserver` 并在 Provider dispose 时注销；`MyPage` 不再直接注册全局 observer，仅订阅 coordinator 的恢复计数刷新 Web 服务状态。生命周期 coordinator、MyPage 和 MainShell 定向 `5/5`；`flutter analyze --no-pub` 无诊断；架构扫描保持 `144` 条既有 backlog，无新增类别；Flutter 串行全量 `668` 通过、`3` 项既有条件跳过；Rust workspace 核心 `184/184`，其余集成、WebDAV 和文档测试无失败。下一项严格进入 P1-2。

P1-2 当前证据：新增 `AppDiagnosticsMonitor`、`FlutterFrameDiagnosticsObserver` 和 `DiagnosticsPrefs`；默认关闭时不注册帧回调或冻结计时器，开启后记录慢帧、主 isolate 冻结采样、调度超时和启动后台任务超时/失败，并通过组合根写入 AppLog。诊断事件 `isCrash=false`，不写入 CrashLogService 崩溃记录；CrashLogService 仍仅记录未处理异常/平台错误，启动任务结果继续更新启动阶段。诊断 monitor、偏好和启动任务定向 `8/8`；`flutter analyze --no-pub` 无诊断；架构扫描保持 `144` 条既有 backlog，无新增类别；Flutter 串行全量 `672` 通过、`3` 项既有条件跳过；Rust workspace 核心 `184/184`，其余集成、WebDAV 和文档测试无失败。下一项严格进入 P1-3。

P1-3 当前证据：新增纯 domain `DiagnosticRecord` 与 `DiagnosticRuntimeInfo`，统一 AppLog 行文本、卡顿诊断日志和 CrashReport 展示；AppLog 保持最新在前和 100 条环缓冲，并限制持久化总字节数，输出包含平台、应用版本和 Rust 引擎版本。CrashLogService 写入前统一执行敏感字段脱敏和 UTF-16 安全截断，CrashReport 展示复用同一诊断模型但保留 SharedPreferencesCrashReportStore 的待提示/清理语义。组合根把启动阶段同步写入 AppLog，诊断事件继续 `isCrash=false`，不误记为崩溃。诊断 record、AppLog、CrashLogService、AppDiagnosticsMonitor、AppLogPage 和 CrashRecoveryPrompt 定向 `16/16`；`flutter analyze --no-pub` 无诊断；架构扫描保持 `144` 条既有 backlog，无新增类别；Flutter 串行全量 `678` 通过、`3` 项既有条件跳过；Rust workspace 核心 `184/184`，其余集成、WebDAV 和文档测试无失败。下一项严格进入 P1-4。

P1-4 当前证据：只读对照原版 `App.kt`、`AppFreezeMonitor`、`DispatchersMonitor`、通知通道和 GMS TLS provider。原版创建下载/朗读/Web 服务三类通知通道，启用 Android WebView 慢速全量绘制，预下载 Cronet，Android Q 以下尝试插入 GMS Conscrypt，启动简繁转换预热，并在后台执行清理/同步。当前 Android 入口没有通知通道、前台服务、Cronet 或 GMS provider；`webview_flutter` 提供页面宿主但没有全局慢速全量绘制调用；阅读器已有局部简繁转换，不承诺全局词典预热。Rust HTTP 已覆盖主网络 TLS、重定向、SSRF 和超时策略，因此不重复引入 Cronet/GMS TLS。通知、后台音频、WebView 全量绘制和全局简繁预热登记为平台差异/暂停项，待明确产品需求或目标平台验收后单独立项。该审计未修改代码和原版基线；复用 P1-3 门禁：Flutter `678` 通过、`3` 项既有跳过，Rust `184/184`，analyze 无诊断，架构 backlog `144`。下一阶段进入应用用例依赖、受控 UI/目标平台和发布门禁。

横切任务验收：每个任务必须有纯 Dart 单元测试；涉及启动顺序、平台错误或通知/后台能力时补充 Android 和 Windows smoke；至少验证“正常冷启动、初始化失败冷启动、同步任务失败、模拟未处理异常、重启后读取崩溃记录、清理后不重复提示”六条路径。实现应位于 lib/application、lib/infrastructure 和 lib/services，禁止页面直接安装全局 handler。

应用用例依赖当前证据：`AppLogPage` 与 `AppLogDialog` 已通过 `AppLogPort` 读取、清理和导出日志，基础设施 adapter 复用既有静态 AppLog 存储；该子任务定向 `4/4`，全量 Flutter `678` 通过、`3` 项既有跳过，Rust `184/184`，analyze 无诊断。架构边界由 `144` 条降至 `142` 条，剩余 `Feature → service` 依赖继续按单边界、单用例顺序迁移，不登记为例外。

本批完成第四轮业务能力边界：`DonatePage` 通过 application `DonateClipboardPort` 复制文本，`CodeEditPage` 通过 `CodeEditPrefsPort` 读写编辑器偏好与会话日志；保留兼容导出、现有键名、编辑器 UI 和日志行为，不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。相关定向 `13/13`、Flutter 全量 `698` 通过（`3` 项既有跳过）、Rust `184/184`、analyze 无诊断，架构扫描为 `118` 条（Feature 业务 service `118`）。

本批继续收口文件管理、日志复制和书源调试边界：`FileManagePage` 通过 `AppPathsPort` 获取数据根目录，`AppLogPage` 通过 application `ClipboardPort` 复制日志，`SourceDebugPage` 通过 `SourceDebugFormatterPort` 格式化调试日志；添加书籍网址和导入书单对话框也移除 Flutter Clipboard 直接访问，统一使用同一剪贴板端口。组合根注册平台 adapter，旧 `services/clipboard_port.dart` 保留兼容导出；测试宿主补齐此前 ReaderFont、书架显示和 RSS 已读端口依赖。定向 `10/10`、测试宿主回归 `2/2` 与 `6/6`，Flutter 串行全量 `699` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断，架构扫描 `115` 条既有 Feature→service backlog，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口 RSS Tab 与主题设置能力：`RssTabPage` 通过已有 `ReaderFontPort` 读取字体族和 CJK fallback，`ThemeConfigPage` 通过 application `ClipboardPort` 完成主题 JSON 导出/导入，移除 Feature 对 `services/reader_font_loader.dart` 和 `services/clipboard_port.dart` 的直接依赖。主题测试宿主改为显式注入剪贴板 adapter，原有主题预设、复制、粘贴和 JSON 应用断言保持不变。定向 `8/8`，Flutter 串行全量 `699` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断，架构扫描降至 `113` 条 Feature→service backlog，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口源管理与备份配置边界：`SourcesPage` 通过 `ReaderFontPort` 获取字体族和 CJK fallback，`BackupConfigPage` 通过 `AppPathsPort.backupsDir()` 获取本地备份目录；端口 adapter 仅转发既有路径能力，源列表字体、备份列表、导入导出和失败提示行为保持不变。定向 `11/11`，Flutter 串行全量 `699` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断，架构扫描降至 `111` 条 Feature→service backlog，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口阅读记录和 Web API 设置的剪贴板边界：`ReadRecordPage` 与 `WebApiSettingsCard` 通过 application `ClipboardPort` 复制文本，移除 Flutter Clipboard 直接访问；测试宿主显式注入 fake 端口，阅读记录导出内容、API URL、提示文案和设置行为保持不变。定向 `2/2`，Flutter 串行全量 `700` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断，架构扫描保持 `111` 条既有 Feature→service backlog，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口源编辑器、字典规则、TXT 目录规则和正文编辑对话框的剪贴板边界：四个页面统一通过 application `ClipboardPort` 复制/粘贴，保留 JSON、规则文本、标题+正文拼接、提示和原有保存/编辑行为；新增定向测试覆盖源 JSON 双向操作、字典规则复制、TXT 规则复制及正文复制。定向 `5/5`，Flutter 串行全量 `705` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断，架构扫描保持 `111` 条既有 Feature→service backlog，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口规则偏好、点击区域、正文搜索和模拟阅读边界：`DictRulePage`、`TxtTocRulePage` 通过规则偏好端口读写并保留既有 JSON 键名和默认规则；`ClickActionPanel`、`ReaderPage` 通过点击区域端口读写九宫格与首次提示；`SearchContentPage` 通过正文搜索偏好端口读写替换、正则和搜索范围；阅读器、模拟追读对话框和书架未读计算通过模拟阅读端口复用既有 Book/SharedPreferences 迁移语义。新增端口/adapter 与页面定向测试，未改变规则内容、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。定向测试全部通过；Flutter 串行全量 `714` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构扫描由 `110` 降至 `104` 条 Feature→service backlog，`git diff --check` 通过。继续按单一用例收口剩余依赖。

本批继续收口阅读样式偏好边界：`ReaderPage` 和 `ReaderSettingsPanel` 通过 `ReadStylePrefsPort` 读写共享布局、主题槽、主题覆盖和排版映射，SharedPreferences adapter 保留既有键名、默认主题、非法主题校验和 JSON 容错；未改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。新增 adapter 定向测试，现有 service 行为测试继续作为兼容基线。定向 `6/6`；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构扫描保持 `102` 条既有 Feature→service backlog，`git diff --check` 通过。

本批继续收口阅读图片缓存边界：`ReaderPage`、`ReaderMarkup`、`ReaderSelectableText` 和 `ReaderInlineImage` 通过 `ReaderImageCachePort` 访问图片下载、磁盘缓存和尺寸探测；infrastructure adapter 保留 Rust 二进制 HTTP、缓存键、SVG/位图尺寸解析、懒初始化和失败占位行为，不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。图片缓存、正文标记、真实媒体、内联 SVG 和可选文本定向 `22/22`；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，涉及文件 analyze 无诊断，架构扫描由 `102` 降至 `100` 条 Feature→service backlog，`git diff --check` 通过。

本批继续收口 Web API 配置偏好边界：`WebApiSettingsCard` 与 `MyPage` 通过 `WebApiPrefsPort` 读写 enabled、port、token 配置，SharedPreferences adapter 保留既有键名、默认端口和 WebApiConfig 兼容导出；`WebApiService` 的启动、停止、状态、Token 生成和协议行为保持不变。定向 `7/7`；首轮全量暴露 3 个 MainShell 测试宿主缺少新端口注入，补齐 fake 后最终 Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，涉及文件 analyze 无诊断，架构扫描由 `100` 降至 `98` 条 Feature→service backlog，`git diff --check` 通过。

本批继续收口目录笔记读取边界：`TocSheet` 通过可选 application `NotePort` 查询书签，组合根注入 `FrbNotePort`；端口未配置时保留空列表降级，目录顺序和书签筛选语义不变。目录顺序、缓存端口页面和目录性能定向 `8/8`，Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust workspace `184/184`，涉及文件 analyze 无诊断，架构扫描由 `98` 降至 `97` 条 Feature→service backlog，`git diff --check` 通过。

本批继续收口书籍详情页书源搜索边界：`BookInfoPage` 的封面补全通过已有 `BookSourceSearchPort` 查询，组合根暴露与 `BookSourceService` 共用的 `FrbBookSourceSearchPort` 实例；保留精确书名/包含书名匹配、书架封面回写和异常降级语义。书源搜索、BookProvider 自动选源和目录顺序定向 `8/8`，Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，涉及文件 analyze 无诊断，架构扫描由 `97` 降至 `96` 条 Feature→service backlog，`git diff --check` 通过。

本批继续收口书籍详情页漫画类型语义：新增纯 domain `BookSourceTypeSemantics` 扩展，复用原有 `2`、`image`、`漫画`、`图片` 判定，`BookInfoPage` 不再直接依赖 `MangaPrefs`。书源模型、书源搜索、BookProvider 自动选源和目录顺序定向 `12/12`，Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，涉及文件 analyze 无诊断，架构扫描由 `96` 降至 `95` 条 Feature→service backlog，`git diff --check` 通过。

本批由主 agent 与四个子 agent 并行收口五条 Feature 边界：`ExploreListPage` 通过 `BookSourceExplorePort` 和 application mapper 获取发现书籍；`SourceMarketPage` 通过 `SourceMarketPort` 读取内置书源并使用 mapper 分组；`ReadRecordPage` 通过 `ReadingRecordPort` 读取统计/导出；`BgTextConfigPanel` 通过 `ReadStyleZipPort` 处理样式 ZIP；`ReaderSettings` 的系统字体预览通过 `ReaderFontPort` 获取字体族和 CJK fallback。组合根统一注入共享端口实例，保留原有字段映射、市场分组、统计导出、ZIP 错误和字体行为。合并定向 `28/28` 与 SourceMarket Provider `3/3`，Flutter 串行全量 `721` 通过、`3` 项既有条件跳过，架构扫描由 `95` 降至 `91` 条 Feature→service backlog，`git diff --check` 通过。

本批由四个子 agent 并行收口 ReaderSettings 自定义字体、ReplacePage 替换预置、ConfigPage 书架配置和 CacheBookPage 缓存导出边界；主 agent 负责组合根注入和测试宿主集成。ReaderFont、Replace、Config、Cache 子线定向测试及原有回归均通过；ReaderFontPort 扩展导致的 6 个测试 fake 编译缺口已补齐共享测试基类，未削弱断言。最终 Flutter 串行全量 `732` 通过、`3` 项既有条件跳过，涉及文件 analyze、格式和 `git diff --check` 通过，架构扫描由 `91` 降至 `87` 条 Feature→service backlog。

本批继续收口 RSS 阅读/收藏、主题导入和二维码图片解码边界：`RssReadPage` 使用 `RssPort`，`RssFavoritesPage` 使用 `RssStarPrefsPort`，`ThemeConfigPage` 使用 `ThemeImportPort`，`QrCodeCapturePage` 使用 `QrCodePort`；组合根注册共享端口，infrastructure adapter 复用既有实现，保留 RSS 正文回退、收藏顺序、主题 JSON/URL 校验、图库解码失败和桌面无相机回退语义。同步补齐 RSS 测试宿主端口注入和 Android SVG 集成测试的图片缓存端口适配，未削弱断言。最终定向 `19/19`；Flutter 串行全量 `739` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `87` 降至 `83` 条既有 Feature→service backlog。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口 `RssArticlesPage` 收藏写入边界：`RssStarPrefsPort` 增加 `toggle` 契约，文章列表通过 application port 读取收藏状态并执行收藏/取消收藏；SharedPreferences 键名、文章字段、收藏顺序、返回状态和提示文案保持不变。RSS 测试宿主补齐端口注入并新增 toggle 回归。定向 `10/10`；Flutter 串行全量 `740` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `83` 降至 `82` 条既有 Feature→service backlog。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口 `SourceEditorPage` 的二维码能力边界：`QrCodePort` 完整承载二维码 PNG 编码与图片解码，书源编辑页的二维码分享改用 application port，infrastructure adapter 继续复用既有 `QrCodeService`；保留二维码导入、分享图片/字符串、过长内容回退和错误提示语义。定向 `8/8`；Flutter 串行全量 `741` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `82` 降至 `81` 条既有 Feature→service backlog。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口 `SourceEditorPage` 代码编辑偏好与会话日志边界：页面通过已有 `CodeEditPrefsPort` 读取自动补全、保存自动补全开关、追加/读取/清空会话日志；SharedPreferences 键名、默认值、日志上限和 UI 提示保持不变，登录 Cookie 等其他 service 依赖未扩大范围。定向 `15/15`；Flutter 串行全量 `741` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `81` 降至 `80` 条既有 Feature→service backlog。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口 `SourceEditorPage` 书源登录 Cookie 清理边界：新增 `SourceLoginCookieClearPort` 及基础设施 adapter，页面通过完整清理用例处理 SharedPreferences Cookie 桶、Rust CookieJar 和 WebView Cookie；保留清理顺序、域名处理、失败提示和会话日志语义。定向 `6/6`；Flutter 串行全量 `742` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `80` 降至 `79` 条既有 Feature→service backlog。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批由四个子 agent 并行收口 AI 配置、书签页、书架排列和漫画阅读偏好边界：`AiConfigDialog` 使用 AI 配置偏好/HTTP port；`BookmarkPage` 使用书签页面 port；`BookshelfArrangePage` 使用排列偏好与分组目录 port；`MangaReaderPage` 使用 `MangaPrefsPort`。主线在组合根注册共享 adapter，并修正书架页面默认 adapter 造成的 Feature→infrastructure 违规。保留 AI 配置/记忆、书签迁移/同步/导入导出、书架分组与排序、漫画偏好键名/默认值/互斥和阅读行为。子线定向证据：AI `9/9`、书签 `25`、书架端口/服务 `8/8`、漫画 `11`；owner 合并定向 `16/16`；Flutter 串行全量 `755` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `79` 降至 `69` 条既有 Feature→service backlog。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

本批继续收口书架展示、书架配置、MainShell 启动编排和 MyPage 边界：`BookshelfPage`、两种书架样式和书架展示组件改用 `BookshelfDisplayPort`；配置对话框改用 `BookshelfConfigDialogPort`；`MainShell` 改用 `MainShellStartupPort`；`MyPage` 改用 `MyPagePort`。组合根注册共享 adapter，MainShell Provider 按 `SourceProvider`、`ReplaceProvider`、`RssProvider` 依赖顺序注入；测试宿主补齐 `MyPagePort` fake。保留书架配置键名、默认值、排序/手动顺序、启动任务、Web API、备份、引擎/数据库状态和 UI 提示语义。受影响定向 `20/20`；Flutter 串行全量 `769` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `69` 降至 `57` 条既有 Feature→service backlog。首轮全量发现的测试宿主 Provider 缺失已补齐，未削弱断言；Rust 未改动，本批不重复运行 Rust 测试。Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行；后续按剩余 57 条 Feature 依赖继续单边界推进。

本批继续收口书架书单导入/导出和 RemoteBook 远程书籍能力：书架菜单与导入对话框改用 `BookshelfListPort`；RemoteBook 改用 `RemoteArchiveImportPort`、`RemoteBookSortPort` 和 `WebDavPrefsPort`。组合根注册四类 adapter，其中远程 ZIP 导入复用已有 `RemoteArchiveImportService`；保留书单 JSON/URL/文件、剪贴板、远程 ZIP/TXT/EPUB、目录优先排序、WebDAV 配置和错误提示语义。受影响定向 `25/25`，包含 RemoteArchive/Sort 既有回归 `5/5`；Flutter 串行全量 `779` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `57` 降至 `52` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；后续按剩余 52 条 Feature 依赖继续单边界推进。

本批继续收口书架样式的分组/本地导入和“我的”页 WebDAV 配置：两种书架样式改用 `BookGroupStorePort`、`BookshelfLocalBookPort`；`WebDavConfigDialog` 改用 `WebDavConfigDialogPort`，复用已提交的 `WebDavPrefsPort` 读取契约。组合根注册本地书导入 adapter 和 WebDAV 配置 adapter；测试宿主补齐新端口 fake。保留分组同步、本地导入、WebDAV 键名/默认值、凭证校验、连接测试、保存和错误提示语义。定向组合回归 `34/34`，`widget_test.dart` `1/1`，MainShell/书架展示宿主回归 `4/4`；Flutter 串行全量 `788` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描保持 `46` 条既有 Feature→service backlog。首轮全量发现的 4 个测试宿主 Provider 缺失已补齐，未削弱断言；Rust 未改动，本批不重复运行 Rust 测试；后续按剩余 46 条 Feature 依赖继续单边界推进。

本批继续收口 Obsidian 导出和 Reader AI Chat：`ObsidianExportDialog` 改用 `ObsidianExportPort`，组合根复用已有 `NotePort` 与 `ApplicationHttpRequestPort`；`AiChatPage` 改用已有 `AiConfigPrefsPort`，与配置/记忆弹窗共享同一偏好端口。保留 Obsidian 配置键、Markdown 导出、本地文件/REST API、连接测试、AI 配置默认值、请求前置校验、消息和错误提示语义。定向 `8/8`；Flutter 串行全量 `796` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `46` 降至 `41` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；后续按剩余 41 条 Feature 依赖继续单边界推进。

本批继续收口 Web API 设置、AudioPlay/TTS、其它设置和备份配置边界：页面分别通过 `WebApiSettingsPort`、`TtsPort`、`OtherSettingsPort` 和备份状态端口使用既有服务；`TtsPanel` 与 `AudioPlayPage` 共用 TTS application port，组合根注册 infrastructure adapter，测试宿主显式补齐依赖。保留 Web API 启停/Token、TTS 播放模式/章节切换/定时/HTTP TTS、网络代理/DNS/数据目录/缓存清理、WebDAV 备份恢复和 Room 导入行为。定向组合 `24/24`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `41` 降至 `30` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；后续按剩余 30 条 Feature 依赖继续单边界推进。

本小批继续收口 `OtherSettingsCard` 缓存管理边界：页面通过 `CacheManagementPort` 读取统计并执行书籍缓存、引擎缓存、备份和全量清理，infrastructure adapter 复用 `CacheService`，不改变统计格式、清理范围、HTTP TTS 或网络设置行为。定向 `2/2`；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `30` 降至 `29` 条既有 Feature→service backlog。上一批 Flutter 串行全量 `798` 通过、`3` 项既有条件跳过，本小批不重复运行全量；后续按剩余 29 条 Feature 依赖继续单边界推进。

本小批继续收口 `BackupConfigPage` 的备份/WebDAV 操作边界：页面通过 `BackupConfigOperationsPort` 执行本地备份、WebDAV 上传/恢复/删除/重命名和本地恢复，infrastructure adapter 复用 `BackupService`；R5 Android smoke 宿主补齐操作、WebDAV 偏好和状态端口。备份页定向 `4/4`；全仓 `flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `29` 降至 `28` 条既有 Feature→service backlog`。本批未执行 Android 真机 smoke，后续按剩余 28 条 Feature 依赖继续单边界推进。

本批继续收口 RSS 文章获取和 ReaderPage 阅读记录边界：`RssArticlesPage` 改用已有 `RssPort`；`ReaderPage` 改用 `ReadingRecordPort`，纯 Dart 阅读会话计时器迁移到 application 文件，旧 `ReadingRecordService` 保留兼容 export。保留 RSS 分页/刷新/错误、阅读记录增量提交、详细阅读会话的两分钟门槛和正文/位置行为。定向组合 `17/17`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `28` 降至 `26` 条既有 Feature→service backlog`。Rust 未改动，本批后续按剩余 26 条 Feature 依赖继续单边界推进。

本批继续收口 ReaderPage TTS 边界：扩展 `TtsPort` 覆盖选区朗读、连续朗读回调、句子位置和播放模式能力，ReaderPage 改用注入端口；保留系统/HTTP TTS、stub、选区模式、章节切换和正文位置语义。定向 TTS/Reader `29/29`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `26` 降至 `25` 条既有 Feature→service backlog`。Rust 未改动，后续按剩余 25 条 Feature 依赖继续单边界推进。

本批三条并行线收口 RSS 分类排序、RSS 源管理传输和 ReaderPage 书籍阅读偏好：新增 `RssSortUrlsPort`、`RssSourceTransferPort`、`BookReaderPrefsPort` 及基础设施 adapter，组合根统一注入；owner 验收移除 agent fallback 的 Feature→infrastructure 直连。保留 RSS 分类缓存/刷新、源导入导出、文件/剪贴板、阅读动画和重新分段语义。定向 `8/8`；Flutter 串行全量 `802` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `25` 降至 `22` 条既有 Feature→service backlog`。Rust 未改动，后续按剩余 22 条 Feature 依赖继续单边界推进。

### 0.4 重构工作规则

1. 一次只迁移一个边界、一个用例或一条数据链路；完成定向测试并汇报后再进入下一项。
2. 先建立旧实现与新边界之间的契约，再迁移调用者，最后删除旧入口；不允许先删后补。
3. 重构不得顺便改变产品行为。目录顺序、章节 `index`、缓存命中语义、正文内容、断行、分页和同步冲突都属于不可变契约。
4. 测试失败先判断实现缺陷、环境限制、基线错误或 fixture 缺失；不得为了通过而削弱断言或替换原版基线。
5. 每个阶段必须记录迁移前后依赖关系、删除的旧入口、保留的兼容适配和全量测试结果。

### 0.5 当前状态

当前已完成 **R0 架构盘点与行为基线**、**R3 正文/缓存/远端 ZIP**、**R4 目录复核** 和 **R5 本地开发门禁/本地 Web API 归属迁移**；R1 因 Kotlin Room v99 → Rust v17 迁移门禁重新打开，当前只确认核心七表映射与 23 表原始归档，不能标记 R1 最终退出。R2 书源/网络边界与 R6 功能域迁移已有历史实现证据，但当前不据此宣称 R2/R6 阶段退出；R6 应用用例边界仍继续收口。横切基础设施 P0-1 至 P1-4 的历史证据继续保留，架构扫描中的 Feature→service backlog 不得当作例外或完成声明。发布前正式/主流 WebDAV、Web/WASM/PWA 与真实 Android TTS 继续暂停。逐项记录见 [`REFACTOR_ARCHITECTURE_BASELINE.md`](./REFACTOR_ARCHITECTURE_BASELINE.md)，不得改变正文、目录、分页、章节身份、UTF-16 位置和第 3 条断行规则。
本轮并行补充完成 Widget 边界收口：书架分组、书签/书票/笔记、源校验/字典/替换预览和底部导航均通过 application/infrastructure port 使用，组合根已接入 W1-W3 Provider；Widget/Feature 扩展扫描不再发现直接 service 依赖，四个 Provider 依赖保留为下一批 backlog。定向与 owner 组合回归通过，Flutter 串行全量 `829` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过。`read_book_async_test.dart` 增加预加载完成等待以消除 Windows 临时目录 teardown 锁竞争，不改变断言或阅读行为。
本轮继续完成四条 Provider 边界：`ReplaceProvider` 通过 `ReplacePresetPort` 加载四条内置规则，`BookProvider` 使用 application 章节进度迁移策略，`SourceProvider` 使用登录头/校验偏好 ports，`RssProvider` 使用 `RssSourceStorePort` 持久化源列表。组合根显式注入真实 adapter，Provider fallback 仅保留 application 空端口；定向 `42/42`，Flutter 串行全量 `838` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过。扩展扫描仅剩 Provider 的其他 service 依赖，下一批继续按 W4 审查的高风险边界拆分。
本轮 Batch 5 完成 `SourceProvider` 源分组目录/标签 application 边界，组合根注入真实 adapter；owner 定向 `13/13`，Flutter 串行全量 `842` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过。并行只读审查已为 source validation store、BookProvider 聚合与批量进度同步锁定最小契约和兼容风险；扩展扫描剩余五处 Provider→service 依赖，下一批按无冲突写集逐项迁移。
本轮 Batch 6 完成 validation store、批量 WebDAV 进度、本地 TXT/EPUB 导入和 SourceProvider 书源门面四条 application 边界；owner 定向分别为 `20/20`、`20/20`、`26/26`、`32/32`，Flutter 串行全量 `864` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过。扩展扫描仅剩 `BookProvider -> BookSourceService`，下一批先按详情/搜索、目录、正文能力拆分契约，保留 ReadBook 配置和正文降级语义。
本轮 Batch 7 完成 `BookProviderSourcePort` 门面收口，覆盖详情、搜索映射、目录、单章正文和分页正文；`BookProvider`、`AppBootstrap` 与组合根改为 application port，其他 `BookSourceService` 消费者保持不变。owner 定向 `41/41`，Flutter 串行全量 `866` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过，Provider service 扫描为零。R6 Provider 边界 backlog 已完成，下一步按功能域剩余计划推进，不再重复扩大 Provider 写集。
本轮 Batch 8 完成 MainShell 隐私同意持久化端口化：`PrivacyConsentPort` 复用 `SharedPreferencesRuntime`，保留 key、失败重试、post-frame 提示时机、拒绝退出、同意关闭和崩溃恢复顺序；owner 定向 `14/14`，Flutter 串行全量 `869` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过。Feature/Widget/Provider 扩展扫描清零，下一步按剩余功能域和暂停门禁推进。
本轮 Batch 9/10 完成 `<js>` 兼容性最小契约收口：Rust `BookSource`、Flutter `SourceLoginService` 和 `JsCompatAnalyzer` 对 `@js:`/`@JS:`/`@Js:`/`@jS:` 统一大小写不敏感，`<js>`/`<Js>` 标签入口和统计保持一致；测试脚本固定离线锁定参数，架构脚本兼容 Windows PowerShell 5。Batch 9 Rust `186/186`、JS 门禁 Rust `18/18`、Flutter `4/4`；Batch 10 owner 定向 `11/11`、Flutter 全量 `873` 通过、`3` 项既有条件跳过，analyze、架构脚本、Rust 格式和 diff 检查通过。完整宿主 API、执行超时/取消、真实 Dart→FRB→Rust 链路、在线书源和对象返回值语义仍是未关闭兼容性 backlog。
本轮 Batch 11/12 收口 Rust 校验及主请求桥接的登录头/HTTP trace 生命周期：`validateSource` 和搜索、发现、详情、目录、正文均在 `finally` 中按“Rust 操作结束 → 同步登录头 → drain trace”收尾，保留返回值和原始异常；引擎定向与 source debug 集成通过，Flutter 全量 `873` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过。调试搜索、调试目录和裸 HTTP 入口，以及登录头队列先 drain 后持久化的失败重试、空值删除和 Rust `loginCheckJs` 错误响应语义仍按后续独立批次处理。
本轮 Batch 13 补齐 `debugSearch`、`debugToc`、`httpFetch` 的 bridge finally 收尾；调试请求按同步登录头后 drain trace，裸 HTTP 始终 drain trace且仅在有 source 时同步登录头。owner 定向 `4/4`、Flutter 全量 `873` 通过、`3` 项既有条件跳过，analyze、架构脚本和 diff 检查通过。真实登录头持久化链路、trace 错误路径 fixture、队列 ack/重试和空值删除仍不宣称完成。

### 0.6 版本控制与变更追溯状态（2026-07-26）

- 历史逻辑变更已回填到根目录 [`CHANGELOG.md`](../CHANGELOG.md) 的 `[Unreleased]`；具体边界、迁移前后依赖和测试证据仍以 [`REFACTOR_ARCHITECTURE_BASELINE.md`](./REFACTOR_ARCHITECTURE_BASELINE.md) 为准。
- 本次回填只修改文档，没有执行 `git commit` 或 `git push`。当前工作区仍包含此前积累的未提交和未跟踪文件，不能称为已发布版本。
- 后续每个可交付逻辑变更必须单独形成 commit，并在 commit message 中包含 Task/模块和结果；未获明确授权时只报告“未提交”、拟提交文件范围和拟用 commit message。
- 后续完成报告必须绑定实际执行的命令、通过/失败/跳过结果和环境限制；历史记录中缺失的精确命令不得补造，也不得用历史结果冒充当前执行。
- 最近合并回归（2026-07-26）：`flutter test` 为 `509` 通过、`3` 个既有在线 smoke 跳过；本轮涉及文件定向 analyze 无诊断；全仓 analyze 仍因 `46` 条既有诊断返回非零；格式检查和 `git diff --check` 通过。
- 2026-07-27 只读审计：`cargo test --manifest-path rust/Cargo.toml` 通过，Rust 核心库 `117` 通过；`scripts/run_js_compat.ps1` 退出 `0`，Rust JS `18/18`、Flutter JS `4/4`；Android `emulator-5556` 上 2B 目录性能集成通过，模块 3 单章/双章 ReaderPage 快照 `2/2` 通过。真实 WebDAV 协议 smoke、R5-A Android 应用 smoke 和 R5-B 双客户端冲突 smoke 已通过；并发普通 Flutter 全量曾因 7565 在线源时序产生 7 个失败，未修改断言，改用 `flutter test --concurrency=1` 后 `509` 通过、`3` 个既有在线 smoke 跳过；真实外部 WebDAV 和 R5 最终退出证据仍缺失。
- 2026-07-27 R6 功能域迁移回归：`flutter test --no-pub --concurrency=1` 为 `516` 通过、`3` 个既有在线 smoke 跳过；`flutter analyze --no-pub` 无 error，保留 `46` 条既有 warning/info；旧 `book`、`sources`、`rss`、`config`、`settings`、`my` 导入扫描无残留，`git diff --check` 通过。
- 2026-07-27 R6 机械 lint 批次：移除未使用 import、替换等价 `contains` 判断、补齐花括号、修正文档注释和 null-aware 元素，定向 analyze 无诊断，相关本地测试 `14/14` 通过；全仓 analyze 无 error，剩余 `33` 条已登记诊断。
- 2026-07-27 R6 RadioGroup 批次：迁移 bookshelf、my 和 reader 的 Radio 组，定向 analyze 无诊断；MainShell/MyPage/首页及 reader 翻页、快照、分页回归 `45/45` 通过；全仓 analyze 无 error，剩余 `23` 条诊断集中在 cache、manga、obsidian、search 和 flutter_tts 子包配置。
- 2026-07-27 R6 analyze 门禁完成：迁移 cache、search、manga、obsidian 的 RadioGroup，修正 vendored `flutter_tts` 的不可解析 lint include；`flutter analyze --no-pub` 为 `No issues found`，串行 Flutter 全量为 `516` 通过、`3` 个既有在线 smoke 跳过。
- 2026-07-27 R6 本机平台构建：`flutter build apk --debug` 和 `flutter build windows --debug` 均通过；APK 已安装到 `emulator-5556` 并启动 `MainActivity`。iOS/macOS 需 macOS/Xcode，Linux toolchain、Web/WASM/PWA 和真实 Android TTS 仍按暂停项登记。
- 2026-07-27 R6 UI 对照初测：在 `emulator-5556` 同时启动原版 `io.legado.app.debug` 与重构版，采集书架首屏及首次启动隐私协议截图；发现数据、主题和启动状态不一致，已登记缺口，未将本次结果标记为最终 UI 通过。
- 2026-07-27 R6 UI 对照扩展：完成原版/重构版“我的”页面同设备截图，确认结构基本一致但主题、图标、文本空格和设置项集合存在差异，已分类记录，未标记 UI 1:1 通过。
- 2026-07-27 R6 UI 对照扩展：完成原版/重构版书源管理首屏截图；重构版首次帮助弹窗已单独记录，当前因书源数量、主题和工具栏/列表细节不同，未标记最终通过。

## 一、项目现状总览

说明：本节及后续“已完成清单/仍需开发”内容保留为现状盘点和功能库存，不再作为执行顺序。实际重构顺序只以本文件第 0 节 R0-R6 为准；新增功能必须先确认不阻塞当前重构阶段。

### 1.1 核心数据

| 维度 | 状态 |
|------|------|
| Rust 引擎版本 | **v0.5.6** |
| Rust DB Schema | **v17** |
| 原版 Room Schema | **v99**（只读基线：`legado-main/app/src/main/java/io/legado/app/data/AppDatabase.kt`） |
| FRB | **已完成 codegen**，`lib/src/rust/` 18 个生成文件，全部 async |
| Rust crate 数量 | **2**（`legado_engine` + `legado-webdav`） |
| Flutter .dart 文件 | **322 个** |
| 测试文件 | **155 个 Dart 测试文件**；另有 **7 个 Android 集成测试文件** |
| 已构建平台 | Android ✅ / Windows ✅ |
| 未构建平台 | iOS ❌ / macOS ❌ / Linux ❌ / Web（配置未测试）⚠️ |

### 1.2 架构

```
┌──────────────────────────────────────────────┐
│              Flutter UI (Dart)               │
│          Provider / ChangeNotifier           │
│         ~~ #[frb] async FFI ~~               │
├──────────────────────────────────────────────┤
│  flutter_rust_bridge 2.11.1                  │
│  lib/src/rust/ (16 generated dart files)     │
├──────────────────────────────────────────────┤
│           legado_engine (Rust)               │
│                                              │
│  api/   — FRB 导出层（14 个 API 模块）        │
│  rule/  — CSS/XPath/Legado DSL/JSONPath/rquickjs │
│  http/  — reqwest async + Cookie + 限速 + 代理   │
│  db/    — rusqlite (bundled) Schema v9       │
│  web_server.rs — axum HTTP API               │
│  notes_store.rs — 笔记 CRUD                  │
├──────────────────────────────────────────────┤
│           legado-webdav (Rust)               │
│  WebDAV client (list/upload/download/delete) │
└──────────────────────────────────────────────┘
```

---

## 二、已完成清单 ✅（无需继续开发）

### 2.1 Rust 书源引擎 — 完成度 95%

| 模块 | 状态 | 文件 |
|------|:---:|------|
| 搜索（HTML + JSON API） | ✅ | `api/search.rs` + `rule/html_search.rs` + `rule/json_search.rs` |
| 发现（Explore） | ✅ | `api/explore.rs` + `rule/html_explore.rs` + `rule/json_explore.rs` |
| 书籍详情 | ✅ | `api/book_info.rs` + `rule/html_book_info.rs` + `rule/json_book_info.rs` |
| 目录获取（分页/HTML/JSON） | ✅ | `api/toc.rs` + `rule/html_toc.rs` + `rule/json_toc.rs` |
| 正文获取（分页/替换/JS清洗） | ✅ | `api/content.rs` + `rule/html_content.rs` + `rule/json_content.rs` |
| 书源校验 | ✅ | `api/validate.rs`（search→explore→toc→content 串行验证） |
| 书源调试（逐步匹配日志） | ✅ | `api/debug.rs` |
| JS 引擎 (rquickjs 0.12) | ✅ | `rule/js_engine.rs` |
| CSS/XPath/Legado DSL/JSONPath | ✅ | `rule/` 模块 |
| HTTP（代理/DNS/Cookie/Charset/Gzip） | ✅ | `http/` 模块 |
| 限速器 (async tokio) | ✅ | `http/rate_limit.rs` |

### 2.2 Rust 数据库 & 基础设施 — 完成度 95%

| 功能 | 状态 |
|------|:---:|
| SQLite CRUD（全部 5 张表） | ✅ |
| 书籍/书源/章节/替换规则 CRUD | ✅ |
| 阅读记录 CRUD + 统计 + 导出 (CSV/JSON) | ✅ |
| 笔记 CRUD + Markdown 导出 | ✅ |
| 数据库备份/恢复 (JSON) | ✅ |
| WebDAV 客户端 (list/up/down/del) | ✅ |
| Web API 服务器（Dart IO + token auth） | ✅ |
| 网络代理/DNS 配置 | ✅ |
| 本地 TXT/EPUB 解析 | ✅ |

### 2.3 Flutter UI — 完成度 85%

| 页面 | 状态 |
|------|:---:|
| MainShell（4 标签页） | ✅ |
| 书架（列表/网格/分组切换） | ✅ |
| 发现页（书源选择器/分页） | ✅ |
| 搜索页（跨源聚合/历史） | ✅ |
| 书籍详情页 + 目录 Sheet | ✅ |
| 阅读器（分页/主题/字体/亮度/章节切换） | ✅ |
| 阅读器设置（字体/行距/翻页模式/主题） | ✅ |
| 书源管理（CRUD/导入/校验/调试面板） | ✅ |
| 书源编辑器 + 书源市场 | ✅ |
| 替换规则管理（含预览面板） | ✅ |
| RSS 订阅管理 | ✅ |
| 设置中心 + 主题配置 + 备份配置 | ✅ |
| Web API 配置 + 网络配置 | ✅ |
| "我的"页（阅读记录/统计图表） | ✅ |
| AI 聊天页（基础聊天 UI） | ✅ |
| 修改封面/换源功能 | ✅ |
| 隐私协议弹窗 | ✅ |

### 2.4 Flutter 服务层 — 完成度 90%

| 服务 | 状态 |
|------|:---:|
| BookSourceService（Rust 门面） | ✅ |
| DatabaseHelper（→ Rust rusqlite） | ✅ |
| BackupService（本地 + WebDAV） | ✅ |
| CacheService | ✅ |
| LocalBookService（TXT/EPUB 导入） | ✅ |
| ReadingRecordService | ✅ |
| ReplaceService + 预设库（20+） | ✅ |
| BookplateService（数据层） | ✅ |
| NoteService + NoteExportService（Markdown 导出） | ✅ |
| ThemeImportService | ✅ |
| WebApiService + WebApiPrefs | ✅ |
| WebDavPrefs | ✅ |
| NetworkPrefs | ✅ |
| SettingsBackup | ✅ |
| SearchHistory | ✅ |
| AppPaths | ✅ |
| SourceDebugFormatter | ✅ |
| ContentProcessor | ✅ |
| BookHelp（章节文件缓存） | ✅ |

### 2.5 测试

| 类型 | 文件数 |
|------|:---:|
| Rust 单元测试 | `src/tests.rs` |
| Rust 集成测试 | 11 个（Web API 已迁至 Dart 集成测试） |
| Rust 性能基准 | `benches/rule_bench.rs` |
| Dart Widget 测试 | 11 个 |
| Dart Service 测试 | 10 个 |
| Dart Integration 测试 | 5 个 |
| **总计** | **31+** |

---

## 三、仍需开发 ❌ / ⚠️

### 🔴 高优先级 — 核心缺位（6 项）

#### #1 — 多平台构建（iOS / macOS / Linux / Web）

| 平台 | 当前 | 目标 | 工作内容 |
|------|:---:|:---:|------|
| **iOS** | ❌ 从未构建 | 真机 + 模拟器 | `rustup target add aarch64-apple-ios{,sim}` → FRB generate → Xcode 配置 ATS → CocoaPods → TestFlight |
| **macOS** | ❌ 从未构建 | Apple Silicon | `rustup target add aarch64-apple-darwin` → FRB generate → 构建 |
| **Linux** | ❌ 从未构建 | x86_64 | 安装 GTK dev 库 → FRB generate → Snap/AppImage 打包 |
| **Web** | ⚠️ 配置未测试 | PWA | WASM 编译链路验证 → `wasm-pack build` → dart:js interop → Service Worker → PWA deploy |

**详细步骤（iOS 为例）**：
```bash
# 1. iOS target (需要 macOS + Xcode)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
flutter_rust_bridge_codegen generate
cd ios && pod install
# 2. 修复编译错误（如有）
flutter build ios --debug --no-codesign
# 3. Info.plist ATS 例外
# 4. TestFlight 分发

# Web:
cd rust/legado_engine
# 条件编译 wasm32 target
rustup target add wasm32-unknown-unknown
# 配置 WASM 导出（当前 FRB 不支持 web，需要独立 wasm-pack 路线）
wasm-pack build --target web
# Flutter Web 侧集成 WASM 模块
flutter build web
```

#### #2 — <js> 书源兼容性验证 & 提升

| 子任务 | 说明 |
|--------|------|
| 2a. 收集测试书源集 | 从社区收集 50+ 个不同类型的书源（HTML 搜索 / JSON API / @js: URL / <js> 正文清洗） |
| 2b. 批量兼容性测试 | 对每个书源运行 search→toc→content 全流程，记录通过率 |
| 2c. rquickjs 差异修复 | 分析失败案例，补充缺失的 JS API 注入（如 `java.headerMap`、`org.jsoup.Jsoup` 特殊用法） |
| 2d. 建立 CI 回归测试 | 将测试书源集加入 CI，每次 PR 自动运行兼容性检测 |

#### #3 — 书源登录 UI

Legado 支持 `loginUrl` + `loginUi`（自定义表单）实现需要登录的书源。

| 子任务 | 说明 |
|--------|------|
| 3a. Flutter 登录表单页 | 根据书源 `loginUi` JSON 渲染动态表单（text/password/button/toggle/select/checkbox） |
| 3b. JS 登录逻辑执行 | 用户填写表单→拼接 JS 变量→调用 rquickjs 执行登录脚本 |
| 3c. Cookie 持久化 | 登录成功后 Cookie 由 Rust `CookieJar` 自动管理（✅ 已支持），验证手动登录后搜索/正文是否可复用 |

#### #4 — 想法/笔记系统（阅读器内交互）

Rust 端笔记 CRUD 已完成 ✅，缺失的是阅读器内的交互 UI。

| 子任务 | 说明 |
|--------|------|
| 4a. 阅读器长按菜单 | `ReaderSelectableText` 选中文字 → 弹出菜单（复制/划线/写想法） |
| 4b. 想法编辑器 | 半屏 `BottomSheet`：显示选中原文 + 文本输入框 + 保存按钮 |
| 4c. 划线高亮展示 | 阅读器中已保存的想法位置显示下划线/高亮标记 |
| 4d. "我的想法"聚合页 | 按书籍分组展示所有想法，支持编辑/删除 |

#### #5 — AI 助手工具调用

AI 聊天页已完成 ✅，缺失的是 LLM 工具调用能力。

| 子任务 | 说明 |
|--------|------|
| 5a. Rust LLM Client | 实现 OpenAI/Claude 兼容的 chat completions + function calling |
| 5b. 工具定义 | `search_books(kw)` — 搜索书架；`get_book_info(name)` — 书籍详情；`get_reading_stats()` — 阅读统计；`add_note(book, text)` — 添加想法 |
| 5c. 流式输出 UI | `StreamBuilder` 逐 token 渲染，工具调用展示状态卡片（"正在搜索..."→"找到 3 本书"） |
| 5d. 配置页 | API URL + Key + Model 配置，支持 OpenAI / Anthropic / 本地模型 |

#### #6 — 阅读小票卡片 UI

BookplateService（数据层）已完成 ✅，缺失的是 UI 卡片。

| 子任务 | 说明 |
|--------|------|
| 6a. `BookplateOverlay` Widget | 书籍首页/尾部叠加卡片：评分 ⭐ + 阅读时长 + 开始/完成日期 + 阅读章数 |
| 6b. 书架标记 | 书架上已读完的书显示小票图标，点击可查看 |

---

### 🟡 中优先级 — 体验完善（4 项）

#### #7 — 读完/N刷标签

| 子任务 | 说明 |
|--------|------|
| 7a. Book 模型 | 新增 `readStatus` 字段（unread / reading / finished / rereading） |
| 7b. 数据库迁移 | Schema v10：`books` 表添加 `read_status TEXT DEFAULT 'reading'` |
| 7c. 书架 UI | 书籍卡片角标（"已读完" / "N刷"），筛选/分组支持按状态 |

#### #8 — 书签功能完善

页面已存在（`bookmark_page.dart`）✅，需确认功能完整性。

| 子任务 | 说明 |
|--------|------|
| 8a. 阅读器内添加书签 | 点击书签按钮 → 保存 `(chapterIndex, position, text)` |
| 8b. 书签列表跳转 | 书签页点击 → 跳转到对应章节和位置 |

#### #9 — 发现页多源聚合

当前每次只能选一个书源查看发现内容。

| 子任务 | 说明 |
|--------|------|
| 9a. 多源并发发现 | 同时调用多个书源的 `explore()`，结果合并去重 |
| 9b. 统一榜单 UI | 综合榜 / 分类榜 tabs，下拉可以筛选书源 |

#### #10 — Web API 端点扩展

当前有基础端点，对照 Jingshiro 的 `LEGADO_WEB_API.md` 扩展。

| 缺失端点 | 说明 |
|----------|------|
| `GET/POST /api/notes` | 想法 CRUD |
| `GET /api/books/search` | 跨源搜索 API |
| `POST /api/sources/validate` | 远程触发书源校验 |
| `GET /api/export/notes` | 笔记导出下载 |

---

### 🟢 低优先级 — 锦上添花（5 项）

#### #11 — 图片/封面解密

rquickjs 中未注入图片解密相关回调。

| 子任务 | 说明 |
|--------|------|
| 11a. `java.decryptImage(bytes, sourceKey)` | JS 返回解密后的 `ByteArray` → Rust 侧应用解密并缓存 |
| 11b. `java.decryptCover(stream, sourceKey)` | 封面 InputStream 解密 |

#### #12 — 字体解析/替换

| 子任务 | 说明 |
|--------|------|
| 12a. `java.queryTTF(fontPath)` | 解析 TTF 字体元数据 |
| 12b. `java.replaceFont(text, fontFamily)` | 将文本中的字体替换为指定字体 |

#### #13 — Legado Skill 系统

书源自动化脚本引擎（独立功能，不影响核心阅读链路）。

| 子任务 | 说明 |
|--------|------|
| 13a. Skill 模型 | `id, name, trigger (manual/schedule/webhook), actions[]` |
| 13b. Skill 引擎 | 注册 Skills → 触发执行 → Action 链 |
| 13c. Skill 市场 | 从 URL 导入 Skill 包 |

#### #14 — 分享卡片生成

| 子任务 | 说明 |
|--------|------|
| 14a. 想法卡片截图 | `Screenshot` widget → PNG → `share_plus` 分享 |
| 14b. 阅读小票分享 | 书籍评分卡片生成并分享 |

#### #15 — Web PWA 完善

| 子任务 | 说明 |
|--------|------|
| 15a. Service Worker | 离线缓存策略（HTML/JS/WASM + 书籍数据 IndexedDB） |
| 15b. manifest.json | PWA 图标/名称/主题色配置 |
| 15c. 响应式适配 | 移动端/平板/桌面端布局自适应 |

---

## 四、已完成 vs 计划对比

| 计划 Phase | 计划内容 | 实际状态 |
|------------|----------|:---:|
| Phase 0 | FRB codegen + iOS/WASM 编译链 + CI | FRB codegen ✅ / iOS ❌ / WASM ❌ / CI ❌ |
| Phase 1.1 | 规则引擎完整化（XPath/JSONPath/JS） | ✅ **已完成** |
| Phase 1.2 | Rust 业务 API（search/toc/content/book_info） | ✅ **已完成**（远超计划：额外完成 explore/validate/debug/read_record/notes/backup） |
| Phase 1.3 | Flutter UI 核心页面 | ✅ **已完成**（远超计划：额外完成 RSS/AI 聊天/主题配置/备份配置） |
| Phase 2 | 体验增强（本地书籍/阅读记录/调试器/Web API/MD3） | ✅ **全部已完成** |
| Phase 3 | 移除 Dart 引擎 + 发布 | ⚠️ Dart 引擎已移除 ✅ / 多平台发布 ❌ |
| Phase 4 | 增值功能（AI/笔记/小票/备份/主题/Skill） | ⚠️ 备份/WebDAV/主题 ✅ / AI/笔记 部分完成 / Skill ❌ |

---

## 五、详细开发路线图（剩余工作）

### 第一步：补齐缺失的核心功能（4-6 周）

```
Week 1-2:  <js> 书源兼容性验证
  ├── 收集测试书源集（50+）
  ├── 批量兼容性测试
  ├── rquickjs 差异修复
  └── CI 回归测试集成

Week 3-4:  想法/笔记系统（阅读器交互）
  ├── 阅读器长按菜单 + 选择文字
  ├── 想法编辑器 BottomSheet
  ├── 划线高亮展示
  └── "我的想法"聚合页

Week 5-6:  AI 助手工具调用
  ├── Rust LLM Client
  ├── 工具定义 + function calling
  ├── 流式输出 UI
  └── 配置页（API/Key/Model）
```

### 第二步：多平台构建验证（2-3 周）

```
Week 7:    iOS + macOS
  ├── iOS target 编译链配置
  ├── macOS target 编译链配置
  ├── 修复平台兼容问题
  └── 真机/模拟器验证

Week 8:    Linux + Web
  ├── Linux GTK 编译 + AppImage 打包
  ├── Web WASM 编译链路
  ├── WASM ↔ Flutter Web 桥接
  └── PWA 部署验证

Week 9:    全平台 CI
  ├── GitHub Actions 矩阵构建
  ├── 自动发布流水线
  └── 平台特定问题修复
```

### 第三步：体验完善（2-3 周）

```
Week 10-11:
  ├── 读完/N刷标签（模型 + DB + UI）
  ├── 书源登录 UI（动态表单 + JS 登录）
  ├── 发现页多源聚合
  ├── Web API 端点扩展
  └── 阅读小票卡片 UI

Week 12:
  ├── 书签功能完善
  ├── 分享卡片生成
  └── Web PWA 完善
```

### 第四步：锦上添花（按需，2-3 周）

```
  ├── 图片/封面解密（rquickjs 注入）
  ├── 字体解析/替换（rquickjs 注入）
  ├── Legado Skill 系统
  └── Obsidian 一键导出笔记
```

---

## 六、功能完成度总结

| 大类 | 完成度 | 说明 |
|------|:---:|------|
| **Rust 书源引擎** | 95% | 核心全完成，缺图片解密/字体替换（低优） |
| **Rust DB & 远端基础设施** | 95% | rusqlite + WebDAV + 备份 + 笔记；本地 Web API 由 Dart IO 承载 |
| **Flutter UI** | 85% | 核心页面全有，缺笔记交互/小票卡片/登录表单 |
| **Jingshiro 差异化功能** | 60% | 笔记后端✅/AI 基础✅，缺交互+工具调用+小票UI |
| **多平台** | 29% | 仅 Android/Windows 可用 |
| **测试覆盖** | 70% | 31+ 测试文件，缺 <js> 兼容率系统测试 |
| **综合** | **~72%** | 核心引擎极强，缺多平台 + 笔记交互 + AI tool |

---

## 七、时间线预估（剩余工作）

| 步骤 | 内容 | 工期 |
|------|------|:---:|
| 第一步 | <js> 兼容性 + 笔记交互 + AI tool | 4-6 周 |
| 第二步 | iOS/macOS/Linux/Web 构建 | 2-3 周 |
| 第三步 | 体验完善（标签/登录/聚合/Web API/小票） | 2-3 周 |
| 第四步 | 锦上添花（解密/字体/Skill/Obsidian） | 2-3 周 |
| **总计** | | **10-15 周** |

---

> 最后更新：2026-07-11 | 引擎 v0.5.6 | DB Schema v9
