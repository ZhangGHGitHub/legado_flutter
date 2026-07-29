# Legado Flutter — 项目重构主计划

> **开发流程：** [DEVELOPMENT_PROCESS.md](./DEVELOPMENT_PROCESS.md) · **文档索引：** [README.md](./README.md)  
> **主目标：** 在不改变 [Jingshiro/legado](https://github.com/Jingshiro/legado) 可观察行为的前提下，将其 Android/Kotlin 工程重构为 Rust + Flutter 跨平台工程，并收敛模块边界、数据流、缓存链路和 UI 组织方式。
> **行为验收：** [LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md](./LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md) 是本计划的验收子计划，不是独立的功能开发主线。
> **重构来源与基线：** [Jingshiro/legado](https://github.com/Jingshiro/legado)；UI 1:1 对齐和行为兼容是重构验收子目标，不是独立产品定位。
> **本地原版基线：** 根目录 `legado-main/` 是只读的原版行为、数据结构、UI 和错误语义核对目录，不是本项目的主源码目录，也不参与 Flutter/Rust 构建。
> 目标平台：Android / iOS / Windows / macOS / Linux / Web (WASM)  
> 最后更新：2026-07-29
> 引擎版本：**v0.5.6** | Rust DB Schema：**v17** | 原版 Room：**v99** | FRB：**2.11.1**
>
> 当前暂停项（2026-07-26）：Web 平台/WASM/PWA 构建、Web 平台适配和相关验收；TTS 真实 Android 引擎验收。除这两类门禁外，Android/Windows 重构继续按固定顺序推进。

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
  正文/替换/压缩包、R5 的本地 Web 服务归属和 R6 应用用例依赖重新进入迁移队列。正式/主流
  WebDAV 与目标平台/UI 发布验收仍未完成。
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

当前判定：R1 已最终退出。R1-12 的 Kotlin Room v99 数据库迁移门禁已通过：探针、核心字段映射、全部 23 个 Room 实体表的原始快照、archive-only 非核心表保存、事务式导入、导入前备份、失败回滚、指纹幂等、冲突统计、FRB/Dart application、备份页入口和 Android 两阶段设备验收均已完成。真实 `original_legado.db` 已确认 v99，但其实体表当前为空；非空等价 fixture 已覆盖字段映射和非核心数据归档。非核心表尚未建立产品业务 port，但不会在迁移中丢失，作为后续独立产品语义工作，不阻塞 R1-12 门禁。扩展边界复核后的默认适配器、组合根、阅读配置、叶子领域模型、Book/Chapter、BookSource/RssSource、阅读进度、登录 UI DTO 和书源校验结果归属均已收敛；旧 `lib/models` 文件全部为兼容导出，`lib/model/read_book.dart` 仅保留阅读会话对象。最终合并定向回归 `46/46`，Flutter 串行全量 `578` 通过、`3` 项按既有条件跳过，Rust `legado_engine` 全量和 Android Room 两阶段 Driver smoke 通过。静态检查中的 domain/model 纯度与核心具体基础设施违规为 `0`；剩余 `146` 条 Feature 偏好/服务依赖是后续 R2/R6 阶段 backlog，不回写为 R1 例外。

##### R1-12：Kotlin Room v99 数据迁移门禁（已通过）

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

边界说明（不阻塞 R1-12 退出）：

- 使用真实非空 Room v99 数据库或非空等价 fixture 验证逐字段迁移：非空等价 fixture 已通过；真实 `original_legado.db` 仍为空库，但已完成真实文件读取验收。
- 原版 23 个 Room 实体表均已纳入快照和报告；非核心表当前采用可恢复的 archive-only 保存，不宣称已有 Rust v17 业务 port。
- Android 设备已完成真实文件导入、重启后继续读取、重复导入幂等和再次备份/恢复验收。

R1-12 退出判定：已满足当前计划的数据库迁移门禁。后续非核心表业务模型、原版真实非空数据补充采集和 R2-R6
阶段推进必须另行按计划执行；本轮没有推进新的 R2-R6 实现。

#### R2：书源引擎与 FRB 适配边界

把搜索、发现、详情、目录、正文和规则调试统一收敛到应用用例；`BookSourceService` 只做门面，Rust API/生成绑定集中在 infrastructure 适配层。网络、规则解析、登录头、Cookie 和错误语义不散落到页面。

当前进度：R2-1 至 R2-7 已完成。核心书源请求和规则调试页面已经通过领域端口调用，FRB 生成类型仅保留在 `lib/infrastructure/engine` 与既有底层兼容桥中。R0 扩展复核后已移除 Rust HTTP 无效证书绕过，书源、规则订阅、书单 URL、RSS 订阅源 URL 和主题 URL 文本抓取均已收敛到统一 Rust HTTP 文本端口；RSS 与主题入口保留各自的 URL trim、SSRF 拒绝和错误契约。字典查询也已移除 Dio 和占位结果，改由 Rust 执行 AnalyzeUrl 与 showRule，当前覆盖 GET/POST、headers/body/charset、`data:`、HTML/JSON/JS、Jsoup 可变 DOM，以及内置规则使用的 `JavaImporter`、Jayway `JsonPath`、`java.base64Encode`、`java.hexDecodeToString` 和 `with(aly)` 包装。当前五条内置字典规则已由离线 fixture 覆盖，百度普通释义和成语分支均已验证。AI 配置与 Obsidian REST API 也已移除 Dio，统一通过 application HTTP port 和 Rust 客户端；AI 固定公网 SSRF 策略，Obsidian 固定允许 localhost/LAN 的本地网络策略，二者共享默认 TLS、逐跳重定向检查、超时和响应大小门禁。统一二进制 HTTP port 已建立，正文图片缓存、阅读样式 ZIP、HTTP TTS 以及书源、漫画、封面、RSS、字典结果等页面远程图片均已迁入；生产代码中的 `Image.network/NetworkImage`、生产/测试 Dio import、pubspec 声明及 lockfile 条目均已清零。书源登录 WebView 已按当前页面读取 Cookie，并按 source key/eTLD+1 持久化到 Rust 网络会话，搜索、详情、目录和正文可跨请求域复用；`enabledCookieJar` 的发送前实际域覆盖、条件式响应保存，以及 source/login/URL option 优先级均已按原版代码路径覆盖测试。Android/iOS/macOS 已通过定域平台端口删除 source host/eTLD+1 WebView Cookie，不使用全局清空；iOS/macOS 真机构建待对应平台执行。`java.startBrowserAwait` 已通过长期 FRB Dart callback 服务接入可见 WebView，支持原版 2/3/4 参数、UTF-16 64 KiB URL 门禁、默认重新抓取、HTML/最终 URL/DOM 返回、Cookie 同步、取消与错误恢复；QuickJS 在专用阻塞线程等待后继续同一脚本上下文。

当前判定：R2 已最终退出。书源入口、统一网络/Cookie、规则 fixture、JS 兼容、错误恢复、FRB 适配和可见 WebView 宿主门禁均通过；架构扫描没有新增违规。后台 `java.webView*`、文件/压缩及其它未命中的第三方 JS API 继续作为兼容性 backlog，不回写为 R2 已完整支持全部原版宿主 API。

退出条件：所有书源入口通过统一用例，规则 fixture、JS 兼容和错误恢复测试通过，页面不再直接调用生成绑定。

#### R3：阅读会话、正文处理与缓存链路

将 `ReadBook`、正文清洗、章节文件缓存、数据库正文回落、预加载、位置映射和分页输入拆成可测试的阅读会话与基础设施。正文处理和缓存可以替换，但输入正文、章节边界、字符范围、中文断行和分页必须保持一致。

当前进度：R3-1 至 R3-4 的历史端口迁移已复核；本轮进一步将全局/书源正文替换、标题去重、重新分段和多行正则统一到 Rust 唯一事实源，生产阅读、全文搜索和替换预览共用同一 `ContentProcessingPort`。正文多页支持串行/并行规则顺序、循环终止、下一章 URL 边界和 100 页显式上限；阅读位置按当前页起始 UTF-16 章内位置保存，文件/DB 缓存生命周期保持原布局。远端书籍 ZIP 的格式识别、路径安全、50MB 输入/解压总量和损坏包错误已迁入 Rust，Flutter 只负责平台文件写入。纯 Dart 滚动范围 mapper 仍不接入 ReaderPage，因为原版按已排版行位置而非线性比例计算滚动读位；中文断行继续由 Flutter `TextPainter` 链路负责。

当前判定：R3 已最终退出。Rust workspace 核心 `185/185`、正文/ZIP 真实 Windows FRB `5/5`、Flutter 串行全量 `641` 通过（`3` 项既有条件跳过）、桌面模块 3 门禁 `59/59`、Android 模块 3 门禁 `4/4`、全仓 analyze、Android debug APK 和格式门禁均通过。架构扫描保持既有 `146` 条后续 backlog，无新增违规；Web/WASM/PWA 与真实 Android TTS 暂停条件不变。

退出条件：正文处理契约、缓存生命周期、章节切换和第 3 条断行/分页门禁通过。

#### R4：目录数据流与列表渲染

将目录请求、分页合并、章节持久化、`reverseToc`、当前章定位、字数/书签元数据和列表渲染分离。目录首帧只依赖可见数据；网络、数据库和非首帧元数据不得阻塞 UI。原版目录顺序和 `index` 由 [LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md](./LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md) 的 2A/2B 门禁验收。

当前进度：2A 已完成原版目录顺序、书籍 `readConfig.reverseToc` 持久化、目录切换反转已保存章节并连续重写 0-based `index`、远端目录 index 归一化和目录首帧不等待缓存字数/书签元数据。2B 已在雷电 `emulator-5556` 上完成 2000 章合成冷/热首帧与滚动帧基线、`Book.tocUrl` 持久化、重复详情请求消除、受控目录分页并发和同一本真实线上书的原版/重写版对比；5 轮真实 UI 冷/热请求计数、目录首帧、Release 帧和 PSS 证据已记录。

退出条件：2B 冷热缓存性能数据和结构性卡顿修复通过，且没有引入跨层依赖。当前已满足，后续按 R5 继续模块 4 收尾。

#### R5：同步、备份和远端存储边界

统一阅读进度、书签、备份和 WebDAV 的 repository、冲突策略、任务门禁和错误传播；UI 不直接控制上传/下载细节。R5 采用两层验收：本地自建 WebDAV 用于开发退出门禁，正式或主流 WebDAV 服务用于发布前真实验收。

开发退出条件：本地数据安全、ETag/冲突重试、备份格式、失败策略和本地自建 WebDAV 应用回归通过。发布前附加条件：必须使用正式或主流 WebDAV 服务至少完成一次真实验收，覆盖 TLS、认证/权限、服务端 ETag/412、MOVE、ZIP 上传下载恢复和失败策略；未完成时不得声明发布验收完成。

#### R6：Feature UI 与平台适配收敛

按功能域整理页面、Provider/状态和组件，移除页面间的隐式全局状态；Android、Windows、iOS、macOS、Linux、Web 的平台能力集中到适配层。UI 兼容性以原版源码映射、受控状态下的关键流程对照和行为契约验收；历史 UI Task 仅见 `archive/UI_REPLICATION_PLAN.md`，不作为执行清单。

退出条件：核心用户流程在目标平台构建并通过，UI 与原版对照测试通过，平台差异有明确适配记录。

当前进度：R6 功能域目录迁移已完成 `main`、`bookshelf`、`reader`、`book`、`sources`、`rss`、`settings`、`my`、`search`、`cache`、`code_edit`、`explore`、`ai`、`obsidian` 和 `common`；其中 Dict/TXT 目录规则、替换净化、捐赠页归入 `my`，二维码归入 `sources`，漫画阅读归入 `reader`，启动页归入 `main`。相关定向回归、Flutter 全量 `540` 项（3 个既有条件测试跳过）、全仓 analyze 和架构边界检查均通过；Rust workspace 核心 `127` 项通过。旧 `lib/pages` 下仅保留 `home/home_page.dart` 这一兼容导出入口，主实现已在 `features/bookshelf`；同步能力无独立 UI 页面，继续由现有 application/domain/service 边界承载。R6 剩余工作是 UI 与原版对照、目标平台构建及发布前正式/主流 WebDAV 验收；真实 Android TTS、后台音频服务、Web/WASM/PWA 和外部 AI 服务继续按暂停/范围外条件处理。

#### 横切基础设施：全局能力与启动可靠性（跨 R1-R6，新增）

原版 Application.onCreate 不只负责业务启动，还注册了全局崩溃处理、应用日志、生命周期管理、卡顿/调度监控、默认数据升级、缓存清理、通知通道和网络/TLS 初始化。当前 Flutter 端已有 AppBootstrap、AppLog、局部生命周期监听、Rust HTTP/TLS、缓存端口和若干偏好迁移，但没有统一的跨平台全局能力边界；这些局部实现不得被当作原版全局能力已完成。

按以下顺序补齐，任务完成前不得在 R6 发布验收中宣称“全局能力与启动行为兼容”：

- P0-1 崩溃防护与启动恢复：新增 CrashLogService 或等价 application/infrastructure 边界；在 main 最早阶段安装同步错误、Flutter 框架错误、平台 dispatcher 错误和未处理异步错误捕获；持久化最近一次崩溃摘要、堆栈、平台/版本/引擎信息和启动阶段；下次启动安全读取并显示一次崩溃提示，支持进入日志、清除标记和失败降级。崩溃写入路径自身不得依赖尚未初始化的数据库、WebDAV 或完整 UI。
- P0-2 存储初始化安全：盘点 SharedPreferences、Rust DB、文件缓存和所有静态服务的同步 getter/配置入口；统一“未初始化、初始化失败、已就绪”状态。未就绪时只返回明确默认值/空集合/不可用状态，业务操作返回可识别错误，不因 StateError、数据库未就绪或异步初始化竞态导致首屏崩溃。此项不引入 Hive，除非后续明确需要；当前工程的实际存储是 SharedPreferences、Rust SQLite 和文件系统。
- P0-3 启动任务隔离：将默认数据升级、过期缓存/搜索清理、书源排序修复、阅读进度同步、WebDAV 初始化和其它非首屏任务纳入可观测的启动任务清单；每项独立超时、捕获错误、记录结果，不阻塞首屏，不重复执行，支持重启后重试。保留原版键名、版本门禁、排序和清理语义。
- P1-1 全局生命周期边界：建立 application 级生命周期协调器，统一承接前后台、暂停/恢复、应用退出和资源释放；页面只订阅状态，不各自注册同一类全局回调。对照原版 LifecycleHelp，明确 Flutter 多窗口、Android Activity、桌面窗口和 Web 平台的差异。
- P1-2 卡顿与调度监控：增加可开关的帧耗时、主 isolate/后台任务超时和应用冻结观测，接入 AppLog/CrashLogService，默认关闭高成本监控；对照原版 AppFreezeMonitor、DispatchersMonitor，不把普通业务异常误记为崩溃。
- P1-3 全局日志与诊断信息：统一 AppLog 的错误、异常、启动阶段、设备/平台、应用版本和 Rust 引擎版本格式；限制敏感信息、条数和文件大小；让崩溃日志、运行日志和手动导出日志复用同一诊断模型，但保留清理和脱敏边界。
- P1-4 平台启动能力盘点：逐项确认原版通知通道（下载、朗读、Web 服务）、后台任务/服务、WebView 绘制设置、GMS TLS provider、Cronet 预下载和简繁转换预热在 Flutter 各目标平台是否需要等价实现。已由 Rust HTTP 覆盖的网络能力只记录为已覆盖，不重复引入 Cronet；没有产品需求或目标平台支持的能力明确登记为范围差异。

横切任务验收：每个任务必须有纯 Dart 单元测试；涉及启动顺序、平台错误或通知/后台能力时补充 Android 和 Windows smoke；至少验证“正常冷启动、初始化失败冷启动、同步任务失败、模拟未处理异常、重启后读取崩溃记录、清理后不重复提示”六条路径。实现应位于 lib/application、lib/infrastructure 和 lib/services，禁止页面直接安装全局 handler。

### 0.4 重构工作规则

1. 一次只迁移一个边界、一个用例或一条数据链路；完成定向测试并汇报后再进入下一项。
2. 先建立旧实现与新边界之间的契约，再迁移调用者，最后删除旧入口；不允许先删后补。
3. 重构不得顺便改变产品行为。目录顺序、章节 `index`、缓存命中语义、正文内容、断行、分页和同步冲突都属于不可变契约。
4. 测试失败先判断实现缺陷、环境限制、基线错误或 fixture 缺失；不得为了通过而削弱断言或替换原版基线。
5. 每个阶段必须记录迁移前后依赖关系、删除的旧入口、保留的兼容适配和全量测试结果。

### 0.5 当前状态

当前已完成 **R0 架构盘点与行为基线**、**R1（含 R1-12 Kotlin Room v99 数据迁移门禁）** 和 **R2 书源引擎与 FRB 适配边界**。R1 扩展边界复核后的默认适配器、组合根和领域模型归属均已收敛，核心层具体基础设施违规为 `0`；R2 的统一文本/应用/二进制网络、Dio 清理、页面远程图片、Cookie 生命周期和 `java.startBrowserAwait` 可见 WebView 宿主均已通过退出门禁。下一步按固定顺序复核并推进 R3；R3-1 至 R3-4、R4-2A/2B、R5 本地 WebDAV/备份和 R6 功能域/analyze/构建记录保留为历史迁移证据，不自动替代当前阶段退出条件。发布前正式或主流 WebDAV 真实验收仍待执行；Web/WASM/PWA 与真实 Android TTS 继续暂停。逐项记录见 [`REFACTOR_ARCHITECTURE_BASELINE.md`](./REFACTOR_ARCHITECTURE_BASELINE.md)。不得用线性近似替换原版行布局或改变第 3 条断行规则。

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
| Web API 服务器 (axum + token auth + CORS) | ✅ |
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
| Rust E2E 测试 | 3 个（builtin / phase3 / web_api） |
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
| `GET /api/records` | 阅读记录查询 |
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
| **Rust DB & 基础设施** | 95% | rusqlite + WebDAV + Web API + 备份 + 笔记 全部完成 |
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
