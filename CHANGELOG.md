# Changelog

All notable changes to this project are recorded in this file.

## [Unreleased]

- 架构/模型生成：将 `SearchResultItem` 迁移为 `freezed` + `json_serializable` 模型，保留 Rust 搜索字段、Map 映射和现有空值语义；显式加入 `json_annotation` 运行时依赖。验证：生成器成功，全仓 analyze 无问题，Flutter 全量 `876` 通过、`3` 项既有条件跳过。
- 架构/统一错误边界：新增 Rust `AppError` 枚举并将 `search` FFI API 迁移为结构化错误，重新生成 FRB/Dart `freezed` 错误类型；补齐 `freezed`、`build_runner` 和 `json_serializable` 生成链。验证：Rust `cargo test -p legado_engine` `186` 通过，Flutter 全量 `876` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构扫描和 `git diff --check` 通过。其它 FFI API 的字符串错误仍按批次迁移。
- 设计治理：完成 Phase 0 第一批资产，新增书架/搜索 `api_contract.md`、原 Android 模块迁移映射和统一设计差距报告；下一步先实现 MockCoreApi/RealCoreApi 契约测试，再迁移生产调用者。未修改正文、目录、分页、章节身份、UTF-16 阅读位置或 `legado-main/`。
- 设计治理：将《Legado Flutter + Rust 三端通用重构设计》固化为 `docs/LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md`，补充文档索引和主计划中的严格收敛顺序。后续以该设计稿约束 Riverpod/Notifier、freezed 镜像模型、`CoreApi` 契约、统一 `AppError`、QuickJS 5 秒超时、编码探测和 CI；当前缺口保持显式登记，不宣称已全部符合。
- R6/应用用例依赖：三条并行线收口 RSS 分类排序、RSS 源管理传输和 ReaderPage 书籍阅读偏好。新增 `RssSortUrlsPort`、`RssSourceTransferPort`、`BookReaderPrefsPort` 及基础设施 adapter，组合根统一注入；修正 agent fallback 的 Feature→infrastructure 直连，保留 RSS 分类缓存/刷新、源导入导出、文件/剪贴板、阅读动画和重新分段语义。定向 `8/8`；Flutter 串行全量 `802` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `25` 降至 `22` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。Rust 未改动，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续按暂停门禁执行。
- R6/应用用例依赖：继续收口 ReaderPage 的 TTS 边界。扩展 `TtsPort` 覆盖选区朗读、连续朗读回调、句子位置和播放模式能力，ReaderPage 不再直接依赖 `TtsService`；保留系统/HTTP TTS、stub、选区模式、连续朗读、章节切换和正文位置语义。定向 TTS/Reader `29/29`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `26` 降至 `25` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。Rust 未改动，真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：继续收口 RSS 文章获取和 ReaderPage 阅读记录边界。`RssArticlesPage` 改用已有 `RssPort`；`ReaderPage` 改用 `ReadingRecordPort`，纯 Dart 阅读会话计时器迁移到 application 文件，旧 `ReadingRecordService` 保留兼容 export。保留 RSS 分页/刷新/错误、阅读记录增量提交、详细阅读会话的两分钟门槛和正文/位置行为。定向组合 `17/17`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `28` 降至 `26` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。Rust 未改动；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：继续收口 Web API 设置、音频播放、TTS 面板、其它设置和备份配置边界。新增 `WebApiSettingsPort`、`TtsPort`、`OtherSettingsPort` 与备份状态端口，页面通过 application port 使用既有服务；组合根注册 infrastructure adapter，测试宿主显式补齐依赖。保留 Web API 启停/Token、TTS 播放模式/章节切换/定时/HTTP TTS、网络代理/DNS/数据目录/缓存清理、WebDAV 备份恢复和 Room 导入语义。定向组合 `24/24`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `41` 降至 `30` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：`OtherSettingsCard` 的缓存统计与清理改用 `CacheManagementPort`，infrastructure adapter 继续复用 `CacheService`，保留统计格式、清理范围和 HTTP TTS/网络设置行为。定向 `2/2`；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `30` 降至 `29` 条既有 Feature→service backlog；上一批 Flutter 串行全量 `798` 通过、`3` 项既有条件跳过，本小批不重复运行全量。Rust 未改动；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：`BackupConfigPage` 的备份/WebDAV 操作改用 `BackupConfigOperationsPort`，adapter 继续复用 `BackupService`；R5 Android smoke 测试宿主补齐操作、WebDAV 偏好和状态端口，保留本地备份、WebDAV 上传/恢复/删除/重命名、Room 导入和失败提示语义。备份页定向 `4/4`；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `29` 降至 `28` 条既有 Feature→service backlog；本批未执行 Android 真机 smoke。Rust 未改动；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：`BackupConfigPage` 的备份/WebDAV 操作改用 `BackupConfigOperationsPort`，adapter 继续复用 `BackupService`；R5 Android smoke 测试宿主补齐操作、WebDAV 偏好和状态端口，保留本地备份、WebDAV 上传/恢复/删除/重命名、Room 导入和失败提示语义。备份页定向 `4/4`；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `29` 降至 `28` 条既有 Feature→service backlog；本批未执行 Android 真机 smoke。Rust 未改动；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：`OtherSettingsCard` 的缓存统计与清理改用 `CacheManagementPort`，infrastructure adapter 继续复用 `CacheService`，保留统计格式、清理范围和 HTTP TTS/网络设置行为。定向 `2/2`；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `30` 降至 `29` 条既有 Feature→service backlog；上一批 Flutter 串行全量 `798` 通过、`3` 项既有条件跳过，本小批不重复运行全量。Rust 未改动；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：D1/D2 两条并行线收口 Obsidian 导出和 Reader AI Chat。`ObsidianExportDialog` 改用 `ObsidianExportPort`，组合根复用已有 `NotePort` 与 `ApplicationHttpRequestPort`；`AiChatPage` 改用已有 `AiConfigPrefsPort`，与配置/记忆弹窗共享同一偏好端口。保留 Obsidian 配置键、Markdown 导出、本地文件/REST API、连接测试、AI 配置默认值、请求前置校验、消息和错误提示语义。定向 `8/8`；Flutter 串行全量 `796` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `46` 降至 `41` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：C1/C2 两条并行线收口书架样式的分组/本地导入和“我的”页 WebDAV 配置。两种书架样式改用 `BookGroupStorePort`、`BookshelfLocalBookPort`；`WebDavConfigDialog` 改用 `WebDavConfigDialogPort`，复用已提交的 `WebDavPrefsPort` 读取契约。组合根注册本地书导入 adapter 和 WebDAV 配置 adapter；测试宿主补齐新端口 fake。保留分组同步、本地导入、WebDAV 键名/默认值、凭证校验、连接测试、保存和错误提示语义。定向组合回归 `34/34`，`widget_test.dart` `1/1`，MainShell/书架展示宿主回归 `4/4`；Flutter 串行全量 `788` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描保持 `46` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。首轮全量发现的 4 个测试宿主 Provider 缺失已补齐，未削弱断言；Rust 未改动，本批不重复运行 Rust 测试。Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：两条并行线收口书架书单导入/导出和 RemoteBook 远程书籍能力。书架菜单与导入对话框改用 `BookshelfListPort`；RemoteBook 改用 `RemoteArchiveImportPort`、`RemoteBookSortPort` 和 `WebDavPrefsPort`。组合根注册四类 adapter，其中远程 ZIP 导入复用已有 `RemoteArchiveImportService`；保留书单 JSON/URL/文件、剪贴板、远程 ZIP/TXT/EPUB、目录优先排序、WebDAV 配置和错误提示语义。受影响定向 `25/25`，包含 RemoteArchive/Sort 既有回归 `5/5`；Flutter 串行全量 `779` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `57` 降至 `52` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；Rust 未改动，本批不重复运行 Rust 测试。Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：两条并行线完成书架展示、书架配置、MainShell 启动编排和 MyPage 边界收口。`BookshelfPage`、两种书架样式和书架展示组件改用 `BookshelfDisplayPort`；配置对话框改用 `BookshelfConfigDialogPort`；`MainShell` 改用 `MainShellStartupPort`；`MyPage` 改用 `MyPagePort`。组合根注册共享 adapter，MainShell Provider 按 `SourceProvider`、`ReplaceProvider`、`RssProvider` 依赖顺序注入；测试宿主补齐 `MyPagePort` fake。保留书架配置键名、默认值、排序/手动顺序、启动任务、Web API、备份、引擎/数据库状态和 UI 提示语义，未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。受影响定向 `20/20`；Flutter 串行全量 `769` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `69` 降至 `57` 条既有 Feature→service backlog；`git diff --check` 待本批文档更新后复核。首轮全量发现的测试宿主 Provider 缺失已补齐，未削弱断言；Rust 未改动，本批不重复运行 Rust 测试。Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。
- R6/应用用例依赖：四 agent 并行收口 AI 配置、书签页、书架排列和漫画阅读偏好边界。`AiConfigDialog` 使用 AI 配置偏好/HTTP port；`BookmarkPage` 使用书签页面 port；`BookshelfArrangePage` 使用排列偏好与分组目录 port；`MangaReaderPage` 使用 `MangaPrefsPort`。主线在组合根注册共享 adapter，并修正书架页面默认 adapter 造成的 Feature→infrastructure 违规。保留 AI 配置/记忆、书签迁移/同步/导入导出、书架分组与排序、漫画偏好键名/默认值/互斥和阅读行为。子线定向证据：AI `9/9`、书签 `25`、书架端口/服务 `8/8`、漫画 `11`；owner 合并定向 `16/16`；Flutter 串行全量 `755` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描由 `79` 降至 `69` 条既有 Feature→service backlog，`git diff --check` 待本批文档更新后复核。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口 `SourceEditorPage` 书源登录 Cookie 清理边界。新增 `SourceLoginCookieClearPort` 及基础设施 adapter，页面通过完整清理用例处理 SharedPreferences Cookie 桶、Rust CookieJar 和 WebView Cookie；保留清理顺序、域名处理、失败提示和会话日志语义。定向 `6/6`，Flutter 串行全量 `742` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描由 `80` 降至 `79` 条既有 Feature→service backlog，`git diff --check` 待本批文档更新后复核。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口 `SourceEditorPage` 代码编辑偏好与会话日志边界。页面通过已有 `CodeEditPrefsPort` 读取自动补全、保存自动补全开关、追加/读取/清空会话日志；SharedPreferences 键名、默认值、日志上限和 UI 提示保持不变，登录 Cookie 等其他 service 依赖未扩大范围。定向 `15/15`，Flutter 串行全量 `741` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描由 `81` 降至 `80` 条既有 Feature→service backlog，`git diff --check` 待本批文档更新后复核。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口 `SourceEditorPage` 的二维码能力边界。`QrCodePort` 完整承载二维码 PNG 编码与图片解码，书源编辑页的二维码分享改用 application port，基础设施 adapter 继续复用既有 `QrCodeService`；保留二维码导入、分享图片/字符串、过长内容回退和错误提示语义。定向 `8/8`，Flutter 串行全量 `741` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描由 `82` 降至 `81` 条既有 Feature→service backlog，`git diff --check` 待本批文档更新后复核。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口 `RssArticlesPage` 收藏写入边界。`RssStarPrefsPort` 增加 `toggle` 契约，文章列表改为通过 application port 读取收藏状态和执行收藏/取消收藏；SharedPreferences 键名、文章字段、收藏顺序、返回状态和提示文案保持不变。RSS 测试宿主补齐端口注入并新增 toggle 回归。定向 `10/10`，Flutter 串行全量 `740` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描由 `83` 降至 `82` 条既有 Feature→service backlog，`git diff --check` 待本批文档更新后复核。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口 RSS 阅读/收藏、主题导入和二维码图片解码边界。`RssReadPage` 使用 `RssPort`，`RssFavoritesPage` 使用 `RssStarPrefsPort`；`ThemeConfigPage` 使用 `ThemeImportPort`；`QrCodeCapturePage` 使用 `QrCodePort`。组合根注册共享端口，基础设施 adapter 复用既有 RSS 收藏、主题导入和二维码服务，保留正文回退、收藏顺序、主题 JSON/URL 校验、图库解码失败和桌面无相机回退语义。同步补齐 RSS 集成测试宿主端口注入和 Android SVG 集成测试的图片缓存端口适配，未削弱断言。定向 `19/19`，Flutter 串行全量 `739` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描由 `87` 降至 `83` 条既有 Feature→service backlog，`git diff --check` 待本批文档更新后复核。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：四 agent 并行继续收口四条 Feature 边界。`ReaderSettings` 完成 ReaderFontPort 的自定义字体扫描、路径/显示名解析、加载和 serif/mono 能力；`ReplacePage` 改用 `ReplacePresetPort`；`ConfigPage` 改用 `BookshelfConfigPrefsPort`；`CacheBookPage` 改用 `BookCacheExportPort`。组合根统一注入 ReaderFont、替换预置、书架配置和缓存导出端口，保留原有字体加载、预置规则、书架键名/保存时机、缓存导出和失败回退语义。子线定向全部通过，受 ReaderFont 接口扩展影响的 6 个测试 fake 补齐共享基类后回归 `11/11`；Flutter 串行全量 `732` 通过、`3` 项既有条件跳过，Rust 未改动且沿用核心 `184/184` 结果，架构 backlog 由 `91` 降至 `87`，`git diff --check` 通过。未修改 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：四 agent 并行收口五条 Feature 边界。`ExploreListPage` 改用 `BookSourceExplorePort` 和 application 结果映射；`SourceMarketPage` 改用 `SourceMarketPort`、内置资源 adapter 和市场映射；`ReadRecordPage` 改用 `ReadingRecordPort`；`BgTextConfigPanel` 改用 `ReadStyleZipPort`；`ReaderSettings` 的系统字体预览改用 `ReaderFontPort`。组合根统一复用并注入端口实例，保留发现结果字段/ID、源市场分组、阅读统计导出、阅读样式 ZIP 和字体 fallback 语义。子线定向门禁通过，主线合并定向 `28/28` 与 SourceMarket Provider `3/3`；涉及文件 `dart format`、`flutter analyze` 和 `git diff --check` 通过；Flutter 串行全量 `721` 通过、`3` 项既有条件跳过，Rust 未改动且沿用核心 `184/184` 通过结果，架构 backlog 由 `95` 降至 `91`。未修改 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：收口 `BookInfoPage` 漫画书源类型判断。新增纯 domain `BookSourceTypeSemantics` 扩展，保留 `2`、`image`、`漫画`、`图片` 四种兼容表示；详情页移除对 `MangaPrefs` 的直接依赖，漫画导航分支行为不变。书源模型、书源搜索、BookProvider 自动选源和目录顺序定向 `12/12`；涉及文件格式与 `flutter analyze --no-pub` 通过；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，架构 backlog 由 `96` 降至 `95`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：收口 `BookInfoPage` 书源搜索边界。详情页封面补全改用已有 `BookSourceSearchPort`，组合根向页面 Provider 暴露与 `BookSourceService` 共用的 `FrbBookSourceSearchPort` 实例，移除页面对书源业务门面的直接依赖；搜索结果匹配、封面回写和失败降级语义不变。书源搜索、BookProvider 自动选源和目录顺序定向 `8/8`；涉及文件格式与 `flutter analyze --no-pub` 通过；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，架构 backlog 由 `97` 降至 `96`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：收口 `TocSheet` 笔记读取边界。目录页改用 application `NotePort`，由组合根注入 `FrbNotePort`；未配置端口时保留空书签列表降级，书签筛选语义不变。目录顺序、缓存页面和目录性能定向测试 `8/8`；涉及文件 `dart format --output=none --set-exit-if-changed`、`flutter analyze --no-pub` 均通过；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust workspace `184/184`，架构 backlog 由 `98` 降至 `97`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口 Web API 配置偏好边界。`WebApiSettingsCard`、`MyPage` 通过 `WebApiPrefsPort` 和 SharedPreferences adapter 读写 enabled、port、token，保留 WebApiConfig 兼容导出及 WebApiService 启停、状态和 Token 语义。定向 `7/7`；首轮全量发现 3 个 MainShell 测试宿主缺少新 Provider，补齐 fake 后 Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，涉及文件 `flutter analyze --no-pub` 无诊断，架构 backlog 从 `100` 降至 `98`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口阅读图片缓存边界。`ReaderPage`、`ReaderMarkup`、`ReaderSelectableText` 和 `ReaderInlineImage` 通过 `ReaderImageCachePort` 使用懒初始化 adapter，保留 Rust 二进制 HTTP、本地缓存、缓存键、SVG/位图尺寸解析和失败占位语义。定向 `22/22`；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，涉及文件 `flutter analyze --no-pub` 无诊断，架构 backlog 从 `102` 降至 `100`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口阅读样式偏好边界。`ReaderPage`、`ReaderSettingsPanel` 通过 `ReadStylePrefsPort` 和 SharedPreferences adapter 读写共享布局、主题槽、主题覆盖与排版映射，保留既有键名、默认主题、非法主题校验和 JSON 容错。定向 `6/6`；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构 backlog 保持 `102`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口规则偏好、点击区域、正文搜索和模拟阅读边界。`DictRulePage`、`TxtTocRulePage`、`ClickActionPanel`、`ReaderPage`、`SearchContentPage`、Reader/模拟追读对话框及 `ShelfUnread` 改用 application port 与 SharedPreferences adapter，保留既有规则 JSON 键名、默认值、点击九宫格、首次提示、搜索选项和 Book 迁移语义。相关定向测试通过；Flutter 串行全量 `714` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构 backlog 从 `110` 降至 `104`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口源编辑器、字典规则、TXT 目录规则和正文编辑对话框的剪贴板边界。四个页面统一通过 application `ClipboardPort`，新增定向测试覆盖源 JSON 复制/粘贴、规则复制和标题+正文复制。定向 `5/5`；Flutter 串行全量 `705` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构 backlog 保持 `111`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口阅读记录和 Web API 设置的剪贴板边界。`ReadRecordPage`、`WebApiSettingsCard` 统一通过 application `ClipboardPort` 复制文本，测试宿主注入 fake 端口并保留导出内容、API URL 和提示断言。定向 `2/2`；Flutter 串行全量 `700` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构 backlog 保持 `111`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口源管理与备份配置边界。`SourcesPage` 改用 `ReaderFontPort`，`BackupConfigPage` 改用 `AppPathsPort.backupsDir()`，测试宿主显式注入对应端口并保留源列表、备份列表、导入导出和失败提示断言。定向 `11/11`；Flutter 串行全量 `699` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构 backlog 从 `113` 降至 `111`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口 RSS Tab 和主题设置能力。`RssTabPage` 改用 `ReaderFontPort` 获取字体族与 CJK fallback，`ThemeConfigPage` 改用 application `ClipboardPort` 完成主题 JSON 导出/导入并由测试宿主显式注入 adapter；移除两处 Feature 对 `services/reader_font_loader.dart`、`services/clipboard_port.dart` 的直接依赖。定向 `8/8`；Flutter 串行全量 `699` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，架构 backlog 从 `115` 降至 `113`，`git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：继续收口文件管理、日志复制、书源调试和书架导入剪贴板边界。`FileManagePage` 使用 `AppPathsPort`，`AppLogPage` 使用 application `ClipboardPort`，`SourceDebugPage` 使用 `SourceDebugFormatterPort`；添加书籍网址和导入书单对话框统一通过剪贴板端口，组合根注册平台 adapter，旧 `services/clipboard_port.dart` 保留兼容导出。定向回归 `10/10`，测试宿主回归 `2/2` 与 `6/6`；Flutter 串行全量 `699` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，`flutter analyze --no-pub` 无诊断，`git diff --check` 通过。架构扫描为 `115` 条既有 Feature→service backlog，未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：完成第四轮业务能力边界收口。`DonatePage` 改用 application `DonateClipboardPort` 与平台 adapter，保留旧 service 路径兼容导出、构造注入、复制和提示行为；`CodeEditPage` 改用 `CodeEditPrefsPort` 与 SharedPreferences adapter，覆盖偏好加载、主题/字号/换行/补全设置及会话日志读写清空。定向 `13/13`、Flutter 串行全量 `698` 通过（`3` 项既有跳过）、Rust `184/184`、analyze 无诊断；架构 backlog 从 `120` 降至 `118`，`git diff --check` 通过。未修改 Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：完成第三轮 ReaderFont 边界收口。书架溢出菜单、RSS 源管理页和 RSS 源 tile 改为通过既有 `ReaderFontPort` 获取字体族与 CJK fallback，移除 Feature 对 `services/reader_font_loader.dart` 的直接依赖；现有页面测试宿主补齐 fake port，菜单顺序、RSS UI 和字体 fallback 断言保持不变。定向 `4/4`、Flutter 串行全量 `694` 通过（`3` 项既有跳过）、Rust `184/184`、analyze 无诊断；架构 backlog 从 `123` 降至 `120`，`git diff --check` 通过。未修改 Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：完成第二轮三线边界收口。`SourceEditorPage` 通过 `SourceVariablePort` 保存源变量，`SearchPage` 通过 `SearchHistoryPort` 使用搜索历史，`AppLogPage/AppLogDialog` 通过 `ReaderFontPort` 获取系统字体能力；组合根统一注入 adapter，保留源变量键名、搜索历史最多 20 条/去重/trim、字体族与 CJK fallback 顺序。两个子 agent 的部分服务请求受 `429` 限流影响，主 agent 接管未完成线；未修改 Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。相关定向 `7/7`、Flutter 串行全量 `690` 通过（`3` 项既有跳过）、Rust `184/184`、analyze 无诊断；架构 backlog 从 `128` 降至 `123`，SharedPreferences 直接访问归零，`git diff --check` 通过。
- R6/应用用例依赖：三线并行收口书架显示、下载选项和 RSS 已读状态偏好。新增 application port 与 SharedPreferences infrastructure adapter，`BookshelfStyle1Page`、`DownloadChoiceDialog`、`RssArticlesPage` 不再直接访问 SharedPreferences；组合根统一注入三类端口，保留既有键名、默认值、clamp、已读集合、保存时机和 UI 行为。主 agent 与两个子 agent 均未修改 Rust/正文/目录/分页/章节身份/UTF-16 阅读位置/第 3 条断行规则。定向 `8/8`、Flutter 串行全量 `686` 通过（`3` 项既有跳过）、Rust `184/184`、analyze 无诊断；架构 backlog 从 `138` 降至 `128`（SharedPreferences `2`、Feature 业务 service `126`），`git diff --check` 通过。
- R6/应用用例依赖：继续收口 AppLog 写入边界。`AddBookUrlDialog`、书架导出/导入、`RemoteBookPage` 改用 `AppLogPort`；`BookmarkService` 与 `NoteService` 由组合根注入同一日志端口，移除对 `services/app_log.dart` 的直接依赖，保留日志文本、业务 API、失败返回和异常降级语义。远程页面测试宿主补齐端口注入。定向 `5/5`、书签/笔记服务回归 `7/7`、Flutter 串行全量 `678` 通过（`3` 项既有跳过）、Rust `184/184`、analyze 无诊断；架构 backlog 从 `142` 降至 `138`，`git diff --check` 通过。未修改 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- R6/应用用例依赖：完成 AppLog 页面边界收口。新增 `AppLogPort` 与基础设施 adapter，`AppLogPage`、`AppLogDialog` 不再直接依赖 `services/app_log.dart`，仍保留日志加载、最新在前、复制导出、清空和颜色显示行为。定向 `4/4`、Flutter 串行全量 `678` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断；架构 backlog 从 `144` 降至 `142`，无新增违规。
- R6/P1-4：完成平台启动能力盘点。确认原版下载/朗读/Web 服务通知通道、后台服务、WebView 慢速全量绘制、GMS Conscrypt、Cronet 预下载和简繁转换预热在 Flutter/Android 的覆盖边界：Rust HTTP 已覆盖主网络 TLS/重定向/SSRF，不重复引入 Cronet 或 GMS provider；通知、后台音频、WebView 全量绘制和全局简繁预热登记为当前平台差异/暂停项，不伪装成等价实现。只读审计未修改业务、正文、目录、分页、章节身份或第 3 条断行规则。

- R6/P1-3：完成全局日志与诊断信息边界。新增纯 domain `DiagnosticRecord`/`DiagnosticRuntimeInfo`，统一 AppLog、卡顿诊断和崩溃展示格式；运行日志和崩溃日志均执行敏感字段脱敏、UTF-16 安全截断、条数和持久化字节上限。AppLog 现在携带平台、应用版本和 Rust 引擎版本，启动阶段同步写入运行日志；CrashLogService 写入前统一脱敏，CrashReport 展示复用同一诊断模型但保留待提示/清理边界。定向 `16/16`、Flutter 串行全量 `678` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断、架构扫描保持 `144` 条既有 backlog；未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

- R6/P1-2：完成卡顿与调度监控边界。新增默认关闭的 `AppDiagnosticsMonitor`，覆盖慢帧、主 isolate 冻结采样、调度超时和启动后台任务超时/失败诊断；新增 Flutter 帧/冻结 observer 与 `DiagnosticsPrefs` 开关，组合根仅在开关开启时注册高成本监控，并将诊断事件写入 AppLog，不写入 CrashLogService 崩溃记录。定向 `8/8`、Flutter 串行全量 `672` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断、架构扫描保持 `144` 条既有 backlog；未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

- R6/P1-1：完成全局生命周期边界。新增 application 级 `AppLifecycleCoordinator` 与 infrastructure 级 `FlutterLifecycleObserver`，由组合根统一注册 Flutter 生命周期并在根树销毁时注销；页面不再直接挂 `WidgetsBindingObserver`，`MyPage` 仅订阅 coordinator 的恢复计数并在前台恢复时刷新 Web 服务状态。定向 `5/5`、Flutter 串行全量 `668` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断、架构扫描保持 `144` 条既有 backlog；未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

- R6/P0-3：完成启动任务隔离。新增 `StartupTaskRunner`，将网络/Web API 恢复、WebDAV 初始化、书架加载后的缓存维护/章节元数据、阅读进度同步、RSS 源加载、替换规则加载、内置书源补齐、书源加载和规则订阅自动更新拆为可观测后台任务；每项独立超时、错误捕获、状态报告、不重复执行和失败重试，条件不满足时显式跳过。AppConfig 与书架布局偏好仍同步读取以保留默认首页/底栏语义。定向 `22/22`、Flutter 串行全量 `667` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断、架构扫描保持 `144` 条既有 backlog；未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

- R6/P0-2：完成存储初始化安全。新增 SharedPreferences 进程级状态、并发初始化合并、失败重试和安全降级；启动关键偏好/崩溃 adapter、AppConfig、主题、书架布局、WebDAV、隐私流程和 AppLog 在存储不可用时返回默认值或空写入，不阻塞首屏。Rust DB 增加未初始化/初始化中/就绪/失败状态和失败保留，文件缓存探测失败返回安全值；修复全量串行测试中的 mock 存储污染隔离。定向 `43/43`、Flutter 串行全量 `663` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze 无诊断，未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

- R6/P0-1：完成全局崩溃防护与启动恢复。新增纯 Dart 崩溃报告/存储端口、SharedPreferences 安全适配器及 `CrashLogService`，在 `main` 同一 Zone 内安装 Flutter 框架、平台 dispatcher 和未处理 Zone 错误捕获；记录受限长度且 UTF-16 安全的错误、堆栈、启动阶段及真实应用/平台/Rust 引擎版本。下一次启动按原版隐私流程之后清除待提示标记并显示一次崩溃提示，可查看完整日志；存储、损坏 JSON 和元数据失败均降级且不依赖数据库/WebDAV。崩溃链定向 `13/13`、启动相关回归 `15/15`、Flutter 串行全量 `659` 通过（`3` 项既有跳过）、Rust 核心 `184/184`、analyze、Android/Windows debug 构建及两平台 5 秒冷启动 smoke 通过。并修复 WebDAV 代理测试短暂污染全局 Rust HTTP 客户端的并行隔离问题；架构 backlog 保持 `146`。

- R5：完成本地 Web API 归属迁移。监听、路由、Token 认证、响应和运行状态迁至 Dart IO，业务数据通过 `WebApiDataPort`、Repository 和既有 Rust 数据库能力提供；删除 Rust `axum` Server、FRB 生命周期 API/DTO、旧适配器和旧 Rust HTTP 集成测试。保留 `/api/health`、books、chapters、sources、records 的认证、状态码和错误契约，并由 Dart 协议测试及真实临时 Rust 数据库 HTTP 集成覆盖。Rust HTTP 并发闸改按主机和有效端口隔离，消除并行 fixture 跨端口争抢。Rust workspace 核心 `184/184`、Flutter 串行全量 `648` 通过（`3` 项既有跳过）、analyze、Android/Windows debug 构建通过；架构 backlog 保持 `146`，无新增类别。正式或主流 WebDAV 发布验收仍按暂停条件待执行。

- R3：完成阅读会话、正文处理、缓存和远端书籍 ZIP 的阶段退出门禁。阅读位置按当前页起始 UTF-16 章内位置保存；全局/书源替换、标题去重、重新分段和多行正则统一到 Rust，生产阅读、全文搜索、替换预览共用 `ContentProcessingPort`；正文下一页支持串行/并行规则顺序、循环终止、下一章边界和 100 页显式上限。文件/DB 缓存生命周期、桌面 59 项分页/断行/选区/像素门禁及 Android 4 项真实 ReaderPage/SVG 门禁通过。远端书籍 ZIP 由 Rust 负责格式识别、路径安全、50MB 输入/解压总量和损坏包错误，Flutter 仅写入 Rust 返回的安全文件；固定 FRB `2.11.1` 生成并移除陈旧重复正文出口。Rust workspace 核心 `185/185`、正文/ZIP 真实 Windows FRB `5/5`、Flutter 串行全量 `641` 通过（`3` 项既有跳过）、analyze、Android debug APK、`git diff --check` 均通过；架构 backlog 保持 `146`，无新增违规。

- R2：完成 `java.startBrowserAwait` 可见 WebView 宿主并通过阶段退出门禁。QuickJS 在专用阻塞线程保持同一脚本上下文，Rust 通过长期 FRB Dart callback 服务串行请求 Flutter 导航；支持原版 2/3/4 参数、默认 `refetchAfterSuccess=true`、UTF-16 64 KiB URL 门禁、URL/HTML 两种加载、最终页面 Cookie 同步、DOM 返回、重新抓取和重定向最终 URL。组合根持有 `navigatorKey`，Feature 仅依赖纯 Dart port，取消或宿主错误保留原响应。固定 FRB `2.11.1` 生成与真实 callback 往返通过；Rust 核心 `166/166`、JS compatibility `18/18`、离线规则 fixture `4/4`、Flutter 全量 `629` 通过（`3` 项既有跳过）、analyze、Android debug APK 和三个 Rust ABI 构建通过。架构扫描保持既有 `146` 条 backlog，无新增违规；iOS/macOS 因 Windows 环境未执行 Xcode 构建。

- R2：补齐书源 Cookie 的平台 WebView 定域清除。新增独立平台端口和 `legado_flutter/source_login_cookies` MethodChannel，Rust 通过固定 FRB `2.11.1` 返回 Public Suffix eTLD+1；Android 对 source host/eTLD+1 的 Cookie 逐个写过期值并 flush，iOS/macOS 通过 WK CookieStore 只删除精确目标域，均不调用全局清空。持久/Rust 清除不因平台尽力删除失败而回滚。Rust 核心 `163/163`、Flutter 定向 `5/5`、真实 FRB domain/set/clear 往返、analyze、Flutter 串行全量 `625`（`3` 项既有跳过）和 Android debug APK 构建通过；iOS/macOS 因本机无 Xcode 仅完成静态 API 校验。

- R2：对齐书源 `enabledCookieJar` 与 Cookie 优先级。普通请求按“持久 source-key Cookie < source header < login header < URL option”合并；开关启用时，发送前再由实际请求域 CookieJar 按键覆盖，并仅在启用时保存响应 `Set-Cookie`。搜索请求恢复传递 AnalyzeUrl method/body/charset 之外的 URL option headers，loginCheckJs 与 GE-UA 重试继续走同一请求链。Cookie 策略/响应保存定向 `4/4`、Rust 核心 `162/162`、Flutter 串行全量 `625` 通过（`3` 项既有跳过），analyze 无诊断。

- R2：建立书源登录 WebView Cookie 到 Rust 网络会话的闭环。登录页按原版在 source/login header 合并后加载，不预注入 Rust Cookie；页面开始/完成时读取当前 WebView Cookie，按 `bookSourceUrl` 持久化并通过新领域端口整串写入 Rust。Rust 使用 Public Suffix 将 source key 归一化为 eTLD+1，跨子域共享、跨请求域按 source key 复用，支持整串替换、合并、空串/定域清除，HTTP 会话 Cookie 保持覆盖持久值；删除登录 header 同时清理持久/Rust Cookie，源编辑页“清除 Cookie”不再误清全局 JS 缓存。固定 FRB `2.11.1` 生成绑定，Rust 核心 `160/160`、Cookie/网络定向 `12/12`、Flutter Cookie/登录定向 `20/20`、release DLL 往返、全仓 analyze 与 Flutter 串行全量 `625` 通过（`3` 项既有跳过）。WebView 平台 Cookie 的定域过期、`enabledCookieJar` 优先级和 `java.startBrowserAwait` 真实宿主仍待后续批次。

- R2：移除已无调用者的 Dio 直接依赖及传递的 `dio_web_adapter` lockfile 条目；生产/测试 import、pubspec 声明和 lockfile 条目均为 `0`，其余依赖版本未升级。`flutter pub get`、全仓 analyze 与 Flutter 串行全量 `618` 通过（`3` 项既有跳过）；R2 继续处理书源登录 WebView Cookie 闭环。

- R2：页面远程图片统一迁入 `RemoteBinaryImage` 和 `ApplicationBinaryHttpRequestPort`。书源、漫画、封面、RSS 与正文图片保留 `localNetwork`，漫画继续携带书源 headers；字典结果图片固定 `publicOnly`。统一组件限制 32 MiB 响应，提供 64 MiB/128 项内存 LRU 和同请求并发合并，端口缺失或请求失败时仅显示调用者占位，不再回退 Flutter 网络栈。定向回归 `18/18`、Flutter 串行全量 `618` 通过（`3` 项既有跳过），analyze 无诊断；生产代码中的 `Image.network/NetworkImage` 与生产/测试 Dio import 均清零，Dio 依赖声明待下一批移除。

- R2：迁移剩余三个 Dio 二进制业务入口。正文图片缓存改由统一二进制 port 下载，保留书源/登录 headers、缓存键、并发去重和磁盘缓存，并增加 32 MiB 流式上限；阅读样式 ZIP 改走 binary port，保留 localhost/LAN 与 30 秒行为，增加 64 MiB 下载、32 MiB 单文件、128 MiB 解压总量和路径穿越门禁；HTTP TTS 保留 GET/POST、原始 body、headers、Content-Type 正则、本地网络与 16 MiB 上限，由根组合层配置端口，真实 Android 系统 TTS 不变。三组定向 `28/28`、Flutter 串行全量 `611` 通过（`3` 项既有跳过），analyze 无诊断；生产与测试中的 Dio 导入清零，页面远程图片直连仍待下一批。

- R2：新增统一 `ApplicationBinaryHttpRequestPort` 与 Rust/FRB 二进制 HTTP 入口，复用既有 HTTP/HTTPS、默认 TLS、public/local 策略、逐跳重定向、DNS/IP SSRF、限流和总超时；支持原始请求/响应字节、状态码、Content-Type 与调用者可选的流式响应上限，`0` 保留旧调用者无上限语义。固定 FRB `2.11.1` 生成绑定；Rust `153/153`、Windows release DLL 文本/字节真实往返 `2/2`、Flutter 串行全量 `602` 通过（`3` 项既有跳过），全仓 analyze 无诊断。本批只建立底层端口，三个 Dio 二进制调用者尚待下一批迁移。

- R2：AI 配置与 Obsidian REST API 删除 Dio 直连，统一通过 `ApplicationHttpRequestPort` 和 Rust HTTP 客户端执行 GET/POST/PUT。AI 固定公网策略并对初始 URL、每跳重定向、IPv4/IPv6 字面量和 DNS 解析结果执行 SSRF 防护，直连时固定校验后的解析地址；Obsidian 固定本地网络策略以保留 localhost/LAN。二者均限制 HTTP/HTTPS、默认 TLS、最多 5 次重定向、包含限流等待的总超时和 8 MiB 流式响应上限，非 2xx 保留状态码与正文；AI 模型列表恢复原 Dio 的非 2xx 失败语义。固定 FRB `2.11.1` 重新生成绑定；Rust 核心 `152/152`、Flutter 服务与真实 FRB 往返 `9/9`、串行全量 `601` 通过（`3` 项既有跳过），全仓 analyze 无诊断；架构存量保持 `145`，R2 继续处理二进制网络入口。

- R2：完成当前五条内置字典规则的离线 fixture。Jsoup shim 新增可变 DOM、逗号/`:has` 选择器、Elements 迭代和 Element 构造/修改 API；Jayway shim 保留递归/通配单命中的列表语义并兼容 `[*]field`，Legado DSL 的 `@all` 按原版修正为 outer HTML。海词英文/中文、有道、哔哩、百度普通释义与成语分支经真实 release DLL/FRB `7/7` 验证；Rust 核心 `141/141`、Flutter 串行全量 `592` 通过（`3` 项既有跳过），R2 下一批处理 AI/Obsidian JSON 网络入口。

- R2：补齐字典规则所需的 Rhino/Java 兼容层：新增 `java.base64Encode`、`java.hexDecodeToString`、`JavaImporter`、Jayway `JsonPath`/`Configuration`/`SUPPRESS_EXCEPTIONS`，并兼容字典脚本的 `with(aly)` 包装。Rust 查询管线 fixture 已验证 helper 组合；Rust 核心全量 `135/135`、JS 兼容 Rust `18/18` + Flutter `4/4`、真实 FRB/Dart 字典回归 `12/12`、全仓 analyze 通过。Jsoup DOM 修改 API 和全部内置字典规则仍未完成，R2 未退出。

- R2：字典查询移除 Dart Dio 和“简化测试/JS 未支持”占位，新增 `DictRuleQueryPort`、application 用例、FRB adapter 与 Rust `query_dict_rule`。统一 Rust HTTP 现支持字典 AnalyzeUrl 的 GET、POST、headers/body/charset、`data:` URL、HTML/JSON/JS showRule，并补齐 Rhino `org.jsoup` 别名及 Elements `text/html` 聚合。Rust 核心全量 `132/132`、FRB/Dart 联合 `14/14`、Flutter 串行全量 `587` 通过（`3` 项既有跳过），架构 backlog `146 → 145`；`JavaImporter/JsonPath` 等高级内置规则兼容仍待完成，R2 未退出。

- R2：主题 URL 导入移除 Dio，改为显式使用统一 `PublicTextFetchPort`/Rust HTTP；保留 JSON 解析和主题应用语义，并新增 URL trim、空响应、网络错误和私有地址拒绝测试。主题服务与页面回归 `16/16`、全仓 analyze 和架构脚本 fixture 通过。

- R2：RSS 订阅源 URL 导入移除 Dart `HttpClient` 实现，改由 application adapter 复用统一 `PublicTextFetchPort`/Rust HTTP；保留 URL trim、私有地址拒绝和可空失败契约。RSS 导入定向回归 `6/6`、全仓 analyze 和架构脚本 fixture 通过，真实架构扫描仍为既有 `146` 条后续 backlog。

- R1：完成领域模型归属收尾。`BookProgress` 迁入纯 domain，带时钟的 `fromBook` 创建移入 application factory，WebDAV JSON 字段、UTF-16 章内位置和冲突比较不变；登录行 UI DTO 迁入 application，书源校验结果迁入 domain，默认校验词策略迁入 application，旧 `lib/models` 路径仅保留兼容导出。合并定向回归 `46/46`，Flutter 串行全量 `578` 通过（`3` 项按既有条件跳过），Rust `legado_engine` 全量通过，Android Room v99 两阶段 Driver smoke 再次通过；R1 最终退出，既有 `146` 条 Feature 偏好/服务依赖继续按 R2/R6 处理。

- R1：`BookSource` 与 `RssSource` 迁入纯 domain，旧路径仅兼容导出；保留静态 JSON API，确保嵌套规则、`rawSourceJson`、未知字段、header/login/jsLib、RSS raw 与 engine JSON 往返不变。关键源模型/仓储/端口/RuleSub/RSS 回归 `30/30`，全仓 analyze 通过。

- R1：`Book`、`BookReadConfig` 与 `Chapter` 迁入 `domain/book`，旧模型路径仅兼容导出；阅读轮次中文文案移入 application policy，数据库继续统一经过 `DatabaseRecordCodec`。UTF-16 FNV-1a、无 URL 章节 ID、目录合并、旧 `reverseToc`、模拟追读 clamp 和阅读位置联合回归 `29/29`，全仓 analyze 通过。

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
