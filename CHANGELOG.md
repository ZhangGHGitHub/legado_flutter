# Changelog

All notable changes to this project are recorded in this file.

## [Unreleased]

- R1：扩展架构门禁到 `domain/model/models`，清除 `ReadBook` 对书源服务门面的依赖；阅读样式、主题排版、点击区及 6 个叶子实体迁入纯领域目录，Flutter 颜色/中文展示/时间戳 ID 创建策略留在 application/Feature。联合定向回归 `90/90`、全仓 analyze 通过，domain/models 纯度违规由 `2` 降为 `0`。

- R0/R1/R6：新增“横切基础设施：全局能力与启动可靠性”计划。根据原版 Application.onCreate 对照审计，登记 P0 全局崩溃捕获/启动恢复、存储初始化安全、启动任务隔离，以及 P1 生命周期协调、卡顿/调度监控、统一诊断日志和通知/后台/TLS/WebView 等平台能力盘点；本次仅更新计划与架构证据，未宣称这些能力已实现。

- R0：扩展架构边界检查到 `application/model/services`，并检查 Feature 对业务服务和 SharedPreferences 的直接依赖；原有展示层规则仍保持，当前新增违规作为 R1-R6 迁移队列，不以旧版 `0` 条结果替代总架构门禁。
- R1：`ReadBook` 移除 DAO、数据库、文件缓存和正文适配器默认构造，由 `AppBootstrap` 根组合层显式注入书籍仓储、正文处理和章节缓存端口；定向 analyze 和 8 项回归通过。
- R2：书源 URL 与规则订阅文本抓取改走统一 Rust HTTP 端口，移除 Dart Dio/HttpClient 与证书绕过；Rust 客户端不再接受无效证书，并对每次重定向执行 SSRF 校验。Rust HTTP 16 项、Flutter 网络/订阅 12 项定向回归通过。
- R1：新增独立 `bootstrap` 组合根，`AppBootstrap`、书源、备份、同步、缓存和静态业务服务不再默认构造 FRB、DAO、文件或 SharedPreferences 适配器；核心层具体基础设施违规由 `78` 降为 `0`。联合定向回归 `73/73`、RuleSub 网络回归 `12/12`、串行 Flutter 全量 `563` 通过（3 项按既有条件跳过），全仓 analyze 通过。
- R2：书单 URL 导入改走显式 `PublicTextFetchPort`；在线三书源 smoke 在远端只返回不完整列表时按既有说明回退到完整本地 fixture，仍保持三源数量和全链路断言，`4/4` 通过。

- R0：明确根目录 `legado-main/` 仅作为只读原版核对基线，不作为主源码目录，也不参与 Flutter/Rust/Gradle/CI 构建。
- R0：新增架构残留/工件分类记录和 `scripts/check_architecture_boundaries.ps1`；脚本当前报告 21 项待迁移越界，`flutter analyze --no-pub` 与 `git diff --check` 通过。未删除、提交或覆盖既有工作树改动。
- R0：将未修改的 UI 复刻计划归档到 `docs/archive/` 并更新活跃文档入口；含未提交内容的 Phase/Wave 历史资料保留原位，待可追溯拆分后处理。
- R0：新增现有工作树的阶段化提交分组，明确本地基线、探针、凭证和运行产物不得混入提交；未执行暂存、提交或推送。
- R0：完成重基线、静态边界检查、迁移追踪、历史 UI 入口归档和工作树分组；R0 基线退出就绪，进入 R1 前等待确认。
- R1-6：`SourceDebugPage` 改为从根组合层获取 `BookSourceDebugPort`，移除 Feature 对 FRB adapter 的直接构造；定向测试 `6/6` 和涉及文件 analyze 通过。原版统一调试会话、增量事件与取消 API 仍未迁移，未宣称兼容完成。
- R1-7：`TocSheet` 改为从 `BookProvider` 获取书籍仓储和章节缓存端口，移除 Feature 对 DAO 和文件缓存 adapter 的直接构造；目录顺序、持久化翻转和连续章节索引测试 `5/5` 通过。
- R1-8：`ReplaceProvider` 改为要求 `ReplaceRuleRepository`，由根组合层创建 DAO；替换规则 CRUD 与 MainShell 回归 `3/3` 通过。
- R1-9：`BookProvider` 改为要求书籍仓储和章节缓存端口，启动层显式组装原 adapter；串行 Flutter 全量回归 `519` 通过、`3` 个既有在线 smoke 跳过。
- R1-10：`SourceProvider` 改为要求书源仓储，根组合层显式创建 DAO；内置源启动/失败策略与校验 fake 回归通过，串行 Flutter 全量 `519` 通过、`3` 个既有在线 smoke 跳过。
- R1-11：`SourceProvider` 改为要求书源校验 port，根组合层创建 FRB adapter；当前工程 Rust 旧 schema、章节身份与阅读位置退出证据已复核。原版 Room 当前为 v99，Kotlin Room 数据库文件导入此前仍未实现，未表述为已支持。
- R1-12：完成并通过 Kotlin Room v99 → Rust v17 数据库迁移门禁：只读探针、23 个 Room 实体表稳定快照、核心字段映射、UTF-16 FNV-1a 章节身份、书签歧义报警、archive-only 原始字段保存、单事务写入、导入前备份、失败回滚、指纹幂等、冲突统计、FRB/Dart application port/service 和备份页入口。`cargo test -p legado_engine db::room_import::tests -- --nocapture` 为 `10/10` 通过，Rust 全量为 `127` 个测试通过；`flutter analyze --no-pub` 通过，Flutter 全量为 `521` 通过、3 个既有在线测试跳过。真实 `original_legado.db` 为 Room v99 但为空库，非空等价 fixture 和 Android 两阶段真实文件/重启/备份恢复 smoke 已通过。非核心表仍为 archive-only，尚未建立产品业务 port，但迁移不丢失其原始数据。
- R5：补充本地 Android 备份恢复和失败策略 smoke，验证书籍/书源 ZIP 恢复以及损坏备份、缺字段和 404 失败时本地数据不被破坏。
- R5：本地 R5-A/R5-B/备份恢复 Android 合并门禁全部通过；真实外部 WebDAV 仍因缺少凭证保持阻塞。
- R5：调整验收条件：本地自建 WebDAV 通过即可完成开发退出门禁；发布前仍必须使用正式或主流 WebDAV 服务完成真实验收。
- R5-C：新增可配置的外部 WebDAV Android 验收夹具，覆盖认证、可选权限失败、ETag/412、MOVE 和 ZIP 往返；无外部凭证时明确跳过，不把本地服务结果记为外部验收。
- R6：完成 `main`、`bookshelf`、`reader` 和 `book` 功能域目录迁移；`book` 定向 analyze 无诊断，目录和书签回归 `8/8` 通过，旧 `pages/book` 导入已清理。
- R6：完成 `sources` 功能域目录迁移；规则补全回归 `4/4` 通过，迁移后仅保留 2 条已登记的既有 analyze 诊断。
- R6：完成 `rss` 功能域目录迁移；RSS 定向回归 `3/3` 通过，旧 `pages/rss` 导入已清理。
- R6：完成 `settings` 功能域目录迁移；备份、主题、其他设置、失败策略和我的页面回归 `17/17` 通过，定向 analyze 无诊断。
- R6：完成 `my` 功能域目录迁移；我的页面和阅读记录回归 `2/2` 通过；确认 `sync` 无独立 UI 目录，不创建空功能目录。
- R6：功能域迁移合并回归完成；串行 `flutter test --no-pub --concurrency=1` 为 `516` 通过、`3` 个既有在线 smoke 跳过；全仓 analyze 无 error，保留 `46` 条既有诊断。
- R6：完成第一批机械 lint 清理；定向回归 `14/14` 通过，全仓 analyze 无 error，既有诊断降至 `33` 条。
- R6：完成 bookshelf、my、reader 的 RadioGroup 迁移；定向回归 `45/45` 通过，全仓 analyze 无 error，剩余诊断降至 `23` 条。
- R6：完成 cache、search、manga、obsidian 的 RadioGroup 迁移并清理 flutter_tts lint 配置；全仓 analyze `No issues found`，串行 Flutter 全量 `516` 通过、`3` 个既有在线 smoke 跳过。
- R6：Android/Windows debug 构建通过；APK 已安装并在 `emulator-5556` 启动 `MainActivity`。iOS/macOS/Linux/Web/TTS 仍按平台条件或暂停项登记。
- R6：新增 Android 原版/重构版 UI 对照记录；已采集书架首屏证据，但因数据、主题和首次启动状态不一致，暂不宣称最终像素验收通过。
- R6：扩展 Android UI 对照记录至“我的”页面；结构基本一致，但图标、主题、文本和设置项差异已登记，尚未通过 1:1 UI 验收。
- R6：扩展 Android UI 对照记录至书源管理页面；已分别记录首次帮助弹窗和关闭后的列表状态，当前仍存在数据、主题和控件细节差异。
- R6：将 `RemoteBookPage` 的 WebDAV FRB adapter 组装移至 `main.dart` 根组合层，页面仅依赖 `WebDavRepository`；注入 fake 页面测试通过，静态架构违规由 `6` 条降至 `4` 条。
- R6：将 `SearchContentPage` 的章节缓存改为必填 `ChapterContentCachePort`，由 `ReaderPage` 显式传入已有缓存端口；缓存页面回归 `3/3` 通过，静态架构违规由 `4` 条降至 `3` 条。
- R6：将 `BackupConfigPage` 的 `BackupLocalFilePort`、`BackupService` 和 Room 导入用例改为根组合层注入；Room 报告/用例契约下沉至 domain，备份页与 application service 联合回归 `7/7` 通过，静态架构违规由 `3` 条降至 `1` 条。
- R6：将 `RssProvider` 的 RSS URL 抓取、重定向 SSRF 校验、超时和大小限制移至 `IoRssSourceImportPort`；Provider 仅依赖 domain port，RSS 端口/管理页回归 `4/4` 通过，静态架构边界检查已通过（`0` 条违规）。

### Added

- Added the mandatory change traceability rule to `docs/DEVELOPMENT_PROCESS.md`.
- Added the R5-A Android WebDAV application smoke test covering startup
  directory initialization, bookmark merge, reading-progress roundtrip,
  backup upload, and the real `BackupConfigPage` upload action. The test uses
  `R5_WEBDAV_URL` so LDPlayer can use a reachable host LAN address.
- Added the R5-B Android cross-client WebDAV conflict smoke test covering
  stale ETag `412` rejection, bookmark union merge, progress conflict policy,
  and successful retry with the latest ETag.

### Changed

- Historical traceability backfill for the refactor boundaries recorded in
  `docs/REFACTOR_ARCHITECTURE_BASELINE.md`:
  - `R1-1`: introduced the book/chapter repository boundary. The Provider
    targeted suite passed `6/6`; Flutter full regression passed `384`, with
    `3` existing online smoke tests skipped; Rust baseline passed `114`.
  - `R1-2`: centralized database record codecs and the legacy schema migration
    contract. Codec tests passed `3/3`, the Rust migration test passed `1/1`,
    Flutter full regression passed `387`, and Rust passed `115`.
  - `R1-3`: isolated the Rust database port and FRB adapter. Targeted tests
    passed `5/5`; Flutter full regression passed `388`; Rust passed `115`.
  - `R1-4a`: injected the repository into `ReadBook`, preserving the file
    cache -> database -> network fallback order. Targeted tests passed `10/10`.
  - `R1-4b`: injected the repository into `LocalBookService`. Targeted tests
    passed `13/13`; Flutter full regression passed `389`.
  - `R1-4c`: injected the replace-rule repository into `ReplaceProvider`.
    Targeted tests passed `12/12`; Flutter full regression passed `390`.
  - `R1-4d`: moved `BookInfoPage` book writes behind `BookProvider.repository`.
    Targeted tests passed `10/10`; Flutter full regression passed `390`.
  - `R1-4e`: moved `MainShell` source initialization behind the source
    repository. Targeted tests passed `10/10`; Flutter full regression passed
    `391`.
  - `R1-4f`: injected the source repository into `SourceProvider`. Targeted
    tests passed `11/11`; Flutter full regression passed `392`.
  - `R1-5`: moved startup orchestration into `AppBootstrap`. Targeted tests
    passed `8/8`; Flutter full regression passed `392`.
  - `R2-1`: isolated the book-source search port. Targeted tests passed
    `16/16`; Flutter full regression passed `393`.
  - `R2-2`: isolated the book-info port. Targeted tests passed `14`; Flutter
    full regression passed `394`; `1` existing online smoke was skipped.
  - `R2-3`: isolated the TOC port while preserving order, chapter identity and
    zero-based indexes. Targeted tests passed `25`; Flutter full regression
    passed `395`; one parallel fixture run was retried serially and passed.
  - `R2-4`: isolated the content port while preserving CRLF/LF text. Targeted
    tests passed `26`; Flutter full regression passed `396`.
  - `R2-5`: isolated the explore port and removed the obsolete service-level
    Rust preflight. Targeted tests passed `13`; Flutter full regression passed
    `397`.
  - `R2-6`: isolated source validation and its result snapshot. Targeted tests
    passed `9`; Flutter full regression passed `398`.
  - `R2-7`: isolated source debugging and log formatting behind domain
    snapshots. Targeted tests passed `3`; Flutter full regression passed
    `400`.
  - `R3-1`: isolated reading-session content processing and chapter-file cache
    ports. The recorded targeted cache/content suites passed; no text,
    line-breaking or pagination behavior was changed.
  - `R3-2`: moved ReaderPage, search, cache management and download filtering
    to the cache port. The recorded targeted suites passed; Flutter full
    regression passed `420`.
  - `R3-3`: added reading-position mapping and reading-record ports while
    preserving UTF-16 chapter positions. The recorded targeted suites passed;
    the baseline explicitly notes that the post-change full regression was not
    rerun at that point.
  - `R3-4`: isolated bookmarks and aligned `reverseToc` persistence and
    continuous zero-based indexes with the reference app. Bookmark tests
    passed `5`, TOC contract tests passed `6`, and the recorded Flutter/Rust
    workspace and format checks passed.
  - `R6-1`: isolated Web API settings behind `WebApiPort`. Targeted tests
    passed `7/7`; modified-file analysis and `git diff --check` passed.
  - `R6-2`: isolated reading statistics and exports behind
    `ReadingRecordPort`. Targeted tests passed `6/6`; modified-file analysis
    and `git diff --check` passed.
  - `R6-3`: isolated bookplate statistics behind `BookplatePort`. Targeted
    tests passed `7/7`; modified-file analysis and `git diff --check` passed.
  - `R6-4`: isolated notes/bookmark UI DTOs behind domain ports. Targeted tests
    passed `9/9`; modified-file analysis and `git diff --check` passed.
  - `R6-5`: isolated RSS article/content requests behind `RssPort`. Targeted
    tests passed `3/3`; modified-file analysis and `git diff --check` passed.
  - `R6-6`: isolated RSS sort-url JavaScript execution behind a port. Targeted
    tests passed `5/5`; modified-file analysis and `git diff --check` passed.
  - `R6-7`: isolated network preferences behind `NetworkEnginePort`; existing
    keys, defaults and startup restore semantics were preserved.
  - `R6-8`: restricted debug-log formatting to domain snapshots and kept FRB
    mapping in the infrastructure adapter.
  - `R6-9`: routed engine-cache cleanup through `NetworkEnginePort` without
    changing file-cache or backup cleanup behavior.
  - `R6-10`: isolated login JavaScript evaluation behind `JsEvalPort` while
    preserving script wrapping and host-command behavior.
  - `R6-11`: changed note-file export to consume `NoteSnapshot` while
    preserving Markdown file naming, metadata and selected-text quoting.
  - `R6-12`: isolated TXT/EPUB parsing behind `LocalBookParserPort` while
    preserving import limits, IDs, write order and chapter content.
  - `R6-13`: isolated page engine-status reads behind `EngineStatusPort`.
    Targeted tests passed `4/4`.
  - `R6-14`: introduced the `SettingsStore` port and
    `SharedPreferencesSettingsStore` adapter; `SettingsBackup` now supports
    replacement storage while preserving default behavior. The new targeted
    test was attempted but timed out during Windows sandbox startup; the
    extended retry was blocked by the approval service returning `503`, so
    this boundary is not yet verified.
  - `R6-15`: moved RSS source file and clipboard transfer behind an injected
    platform port. `dart format` passed, the targeted RSS page suite passed
    `2/2`, involved-file `flutter analyze` reported `No issues found`, and
    `git diff --check` passed.
  - `R5-1`: moved WebDAV setup orchestration behind a `WebDavRepository` port
    and kept the FRB implementation in infrastructure. Targeted tests passed
    `7/7`; involved-file analyze, format and `git diff --check` passed. Real
    WebDAV smoke was not run because no usable server endpoint was available.
  - `R5-2`: moved progress-sync timestamp persistence behind
    `BookProgressSyncStore` while preserving WebDAV, ETag/412 retry, conflict,
    chapter-position and `durChapterPos` behavior. Targeted sync tests passed;
    the merged regression suite passed `23/23`, involved-file analyze and
    format passed, and `git diff --check` passed.
  - `R6-16`: moved RSS source editing save orchestration behind
    `RssSourceEditPort`. Targeted tests passed `1/1`; involved-file analyze,
    format and `git diff --check` passed.
  - `R6-17`: moved BackupConfigPage local backup file operations behind a
    replaceable port and filesystem adapter. Targeted tests passed `4/4`.
  - `R6-18`: moved DonatePage clipboard access behind a replaceable port.
    Targeted tests passed `2/2`; copy content and toast behavior were retained.
  - `R6-19`: moved BookshelfArrangePage preference access behind a replaceable
    port while preserving the established key and layout preference behavior.
    Targeted tests passed `2/2`.
  - `R6-20`: moved BookGroupStore preference access behind
    `BookGroupPrefsPort` while preserving `book_groups_v1`, JSON and default
    group semantics. Targeted tests passed `4/4`.
  - `R6-21`: moved CodeEditPrefs preference access behind `CodeEditPrefsStore`
    while preserving keys, defaults and log limits. CodeEditPrefs and
    CodeEditPage regression tests passed `4/4` each.
  - `R6-22`: unified AppLogPage and ThemeConfigPage clipboard operations behind
    `ClipboardPort`. Targeted tests passed `8/8`; copy/paste and theme import/
    export behavior were preserved.
  - `R6-book`: moved the book feature pages behind `lib/features/book` and
    updated all callers without changing book detail, directory, bookmark,
    reader wrapping, pagination, or chapter-position behavior. Targeted tests
    passed `8/8`; feature analyze reported `No issues found` and old book import
  paths were absent.
  - `R6-sources`: moved source management, editing, login, debug, market and
    rule-completion pages behind `lib/features/sources` without changing source
    behavior. Rule-completion tests passed `4/4`; the remaining two analyze
    diagnostics are recorded for the shared R6 lint batch.
  - `R6-rss`: moved RSS pages and widgets behind `lib/features/rss`, preserving
    RSS search, reading, favorites, source management and login behavior.
    Targeted regression tests passed `3/3`; involved-file analyze reported
    `No issues found`.
  - `R6-settings`: moved configuration and settings pages behind
    `lib/features/settings`, preserving backup, WebDAV, theme and settings
    behavior. Targeted regression tests passed `17/17`; involved-file analyze
    reported `No issues found`.
  - `R6-my`: moved MyPage, file management, reading records, reading skills and
    WebDAV configuration behind `lib/features/my`, preserving status and sync
    entry behavior. Targeted tests passed `2/2`; the two existing Radio
    deprecation diagnostics remain recorded for the shared R6 lint batch.

All R3/R6 reading-related changes explicitly preserve the original text,
Chinese line-breaking, pagination input, chapter-position mapping and TTS
behavior. The R6-7 through R6-13 batch was additionally recorded as Flutter
full regression `488` passed with `3` existing online smoke tests skipped; no
Rust code was changed in that batch, and the APK build/install smoke on
`emulator-5556` succeeded.

### Fixed

- None.

### Verification

- Historical records above are backfilled from the architecture baseline. For
  R1-1 through R6-6, the baseline contains the test results and the standard
  commands `flutter test`, `flutter analyze`, `dart format --output=none
  --set-exit-if-changed`, and `git diff --check`; several targeted test
  invocations were not preserved verbatim and are marked by their recorded
  result rather than reconstructed here.
- For R6-7 through R6-13, the recorded batch verification is Flutter full
  regression `488` passed, `3` existing online smoke tests skipped, R6-13
  targeted tests `4/4` passed, and APK build/install smoke succeeded on
  `emulator-5556`. Rust was not modified in that batch.
- Going forward, each logical change must record the exact command line,
  result, skipped tests, failures and environment limits before it is called
  complete.
- Latest combined verification after R5-1, R5-2 and R6-14 through R6-22:
  `flutter test` passed `509` tests with `3` existing online smoke tests
  skipped; involved-file `flutter analyze` reported `No issues found`; full
  `flutter analyze` returned non-zero with `46` existing diagnostics; format
  and `git diff --check` passed.
- 2026-07-27 audit verification: `cargo test --manifest-path rust/Cargo.toml`
  passed with Rust core `117` tests passing; `scripts/run_js_compat.ps1`
  exited `0` with Rust JS `18/18` and Flutter JS `4/4`. On `emulator-5556`,
  `integration_test/module2_android_toc_performance_test.dart` passed and the
  combined module 3 single-/multi-chapter ReaderPage snapshot tests passed
  `2/2`. The local WebDAV protocol smoke passed authentication, PUT/GET,
  stale `If-Match` `412`, MOVE and DELETE. Flutter application-level WebDAV,
  cross-device conflict and real external WebDAV server evidence remain
  outstanding.

### Known limitations

- This is an unreleased development worktree. Web/WASM/PWA and real Android
  TTS engine acceptance remain paused. Real WebDAV acceptance and the final
  release gate remain incomplete.
- The workspace contains pre-existing and current uncommitted changes. No
  commit or push was performed during this documentation backfill.
- The historical targeted-test command lines for some earlier boundaries were
  not retained, so those entries must not be treated as fresh test execution.
- `R5-1` still requires an online WebDAV smoke against a real server endpoint;
  the current port-contract tests do not replace that external acceptance.

## Release format

Each release entry must include the release date, the App version from `pubspec.yaml`,
the Rust engine version, the database schema version, user-visible changes,
breaking or migration notes, and verification results. Keep unreleased work under
`[Unreleased]` until it is committed and tagged.
