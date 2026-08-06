# Legado Flutter — Jingshiro/legado Rust + Flutter 重构开发流程

2026-08-06 Android 标准 APK 启动白屏排查追溯：确认 `integration_test` 运行后生成的 `build/app/outputs/flutter-apk/app-debug.apk` 可能是测试入口产物，不能直接用 `monkey` 当作生产 APK 启动。重新执行 `flutter build apk --debug --no-pub` 后安装同一路径 APK，在 `emulator-5556` 和 `emulator-5558` 均显示隐私协议首屏；日志完整经过 `AppBootstrap 初始化完成`、`正式应用组装完成` 和 `首屏运行`，未发现 Dart 未处理异常。后续手工 UI/功能对照前必须先重新构建标准 APK；集成测试 APK 只用于测试驱动，不作为手工启动验收证据。本批未修改产品代码，不改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。实际验证：`flutter build apk --debug --no-pub`、双设备安装/启动、`flutter analyze --no-pub`、`powershell -ExecutionPolicy Bypass -File scripts/check_architecture_boundaries.ps1`、`flutter test --no-pub --concurrency=1 --reporter compact`（`1305` 通过、`3` 跳过）和 `git diff --check` 均通过。

2026-08-06 Phase 4/R6 RSS 默认规则 JSON 导入追溯：先只读核对原版 `DefaultData.importDefaultRssSources`、DAO 删除条件和 4 条资产，确认其行为为删除精确 `legado` 分组后按 URL `REPLACE`。本批以 application `RssDefaultSourceImportPort` 隔离页面与 Flutter 资产，基础设施适配器读取逐字节一致的默认 JSON，controller 保留现有普通 JSON 导入路径并新增默认导入顺序；页面菜单移除该动作的占位。测试固定旧默认源删除、用户/混合分组源保留、URL 覆盖、raw 字段保留和真实注册资产加载。定向 Flutter `10/10`、Flutter 串行全量 `1305`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式、原版资产 SHA-256 对照和 `git diff --check` 全部通过。只提交本批 RSS application/infrastructure、资产、组合根、页面、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-06 Phase 4/R6 RSS 分组管理边界与 JS 宿主回归追溯：本批将 RSS 分组的读取、创建、重命名和删除统一收口到 `RssSourceGroupManagementPort`，页面不直接写入 controller 或持久化层，生产组合根适配既有 `RssSourceController`；测试固定新建分组归入未分组源、目标分组重命名/删除及其他成员关系保留。远程书籍帮助继续在缺少 WebDAV 帮助状态和完整 Markdown/链接渲染契约时显式占位，不虚构替代页；Rust 仅用 loopback fixture 验证既有 `java.ajax` 的 GET/POST 请求契约。先执行定向 Flutter `9/9`、Rust JS `31/31` 和 Dart/Rust 格式检查，再执行 Flutter 串行全量 `1302`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。只提交本批 RSS application/infrastructure、页面、Rust 回归、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-06 Phase 4/R6 Reader 残余 Provider 清理与 RSS 能力门禁追溯：本批并行审查 Reader、书架菜单和 RSS 源管理三个不重叠写集；`ReaderPage` 移除无业务用途的 `BookProvider` 缓存依赖，RSS 三个缺少后端契约的动作保持显式占位并补回归测试，书架菜单确认既有动作分发和 `BookshelfListPort` 组合根注册完整。先执行 Reader/RSS 定向 `13/13`，再执行 Flutter 串行全量 `1297`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。只提交本批 Reader/RSS 实现、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 Reader 离线缓存、BookInfo 书源访问与缓存页 fallback 边界追溯：本批按三个不重叠调用面移除 `ReaderPage`、`BookInfoPage` 和 `CacheBookPage` 对 `BookProvider`/`SourceProvider` 的页面 fallback，统一解析显式端口、共享端口或明确空实现；生产组合根继续绑定原 Provider 事实源，独立宿主必须显式提供所需能力。先执行 Dart 格式检查和定向联合 `26/26`，再执行 Flutter 串行全量 `1296`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。只提交本批 application 端口、页面、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 Reader 书源访问与 BookInfo 阅读状态/缓存下载端口边界追溯：本批按三个不重叠调用面移除 `ReaderPage` 的 Source/BookProvider fallback，以及 `BookInfoPage` 的阅读状态和缓存下载 fallback；生产组合根继续绑定同一 Provider 事实源，独立宿主缺失能力时使用明确空实现。先执行定向联合 `31/31`，再执行 Flutter 串行全量 `1293`（`3` 项既有条件跳过）、Rust workspace `270` 测试、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。只提交本批 application 端口、页面、测试、Android 快照宿主和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 Reader 模拟追读、当前目录与 BookInfo 元数据端口边界追溯：本批按三个不重叠调用面移除 `ReaderPage` 的模拟追读/当前目录 `BookProvider` fallback，并将 `BookInfoPage` 元数据写入改接 `BookMetadataPort`；生产组合根继续使用同一 Provider 事实源，字段 trim 仍由 `BookMetadataController` 负责。先执行定向联合 `28/28`，再执行 Flutter 串行全量 `1289`（`3` 项既有条件跳过）、Rust workspace `270` 测试、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。只提交本批实现、测试、Android 快照宿主和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 Reader 与 BookInfo 端口 fallback 边界追溯：本批按三个不重叠调用面收口 `ReaderPage` 的进度写入、章节缓存状态和 `BookInfoPage` 的目录加载。生产组合根继续提供真实 application port；独立宿主必须显式注入对应能力，未提供 BookInfo 目录能力时使用明确空实现。保留旧 `BookProvider` 回调行为、Android 快照宿主行为及正文/目录/分页/章节身份语义。先执行定向联合 `26/26`，再执行 Flutter 串行全量 `1288`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。只提交本批实现、测试、Android 快照宿主和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 配置页 AppConfig scope 边界追溯：`ConfigPage` 移除页面内对 `AppConfig.instance` 的局部 Riverpod override，复用父级默认 `appConfigProvider`，保持配置页子页面和 notifier 事实源不变。先执行配置/主题相关测试 `10/10`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Flutter 串行全量 `1284`（`3` 项既有条件跳过）和 `git diff --check`，全部通过。仅提交本批页面和四份追溯文档，不提交用户本地文件，不自动 push。

2026-08-05 Phase 4/R6 全文搜索与 RSS 源编辑/管理页 controller scope 边界追溯：三个不重叠写集分别移除 `SearchContentPage`、`RssSourceEditPage`、`RssSourceManagePage` 的旧 Provider 读取和嵌套 Riverpod scope，生产入口复用父级 controller，测试宿主显式覆盖或注入 controller；同时补齐 `cache_port_pages_test.dart` 两个全文搜索宿主的显式 ReplaceController 注入。先执行受影响定向 `9/9`；首次全量发现两项旧宿主缺少注入，修复后重跑 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Flutter 串行全量 `1284`（`3` 项既有条件跳过）和 `git diff --check`，全部通过。仅提交本批页面、测试和四份追溯文档，不提交用户本地文件，不自动 push。

2026-08-05 Phase 4/R6 替换页、规则订阅与缓存页 controller scope 边界追溯：三个不重叠写集分别移除 `ReplacePage`、`RuleSubPage`、`CacheBookPage` 的旧 Provider 读取和嵌套 Riverpod scope，生产入口复用父级 controller，测试宿主显式覆盖或注入 controller。先执行受影响定向 `15/15`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Flutter 串行全量 `1282`（`3` 项既有条件跳过）和 `git diff --check`，全部通过。仅提交本批页面、测试和四份追溯文档，不提交用户本地文件，不自动 push。

2026-08-05 Phase 4/R6 RSS 收藏页 SourceController 边界追溯：本批将 `RssFavoritesPage` 的源状态读取改为可选 `RssSourceController` 注入，生产入口优先复用父级 Riverpod scope；为保持图片组件独立宿主兼容性，补充无 `ProviderScope` 时的空 controller 回退，未恢复页面对旧 `RssProvider` 的直接依赖。先执行 RSS 收藏/图片定向 `4/4`；首次全量发现独立 RSS 图片宿主缺少 `ProviderScope`，修复后重跑 Flutter 串行全量 `1280`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。仅提交本批页面、测试和四份追溯文档，不提交用户本地文件，不自动 push。

> 本文档定义项目的**正规协作流程**，补齐「有计划、无流程」的缺口。  
> 最后更新：2026-08-05

2026-08-05 Phase 4/R6 书架整理 SourceController 显式注入收口追溯：本批移除 `BookshelfArrangePage` 页面内对旧 `SourceProvider` 的直接依赖，生产组合根继续提供共享 scope，测试宿主显式注入 controller；保留源标签刷新、分组、删除、排序和选择状态。先执行书架整理定向 `18/18`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 Flutter 串行全量 `1280`（`3` 项既有条件跳过），全部通过；随后执行 `git diff --check` 并创建中文本地提交，只提交本批页面、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 书架整理 SourceController 边界追溯：本批将 `BookshelfArrangePage` 的 SourceController 注入改为可选显式端口，移除页面内对旧 `SourceProvider` 的直接依赖；生产环境继续使用组合根共享 scope，测试宿主显式注入 controller，保留源标签刷新、分组、删除、排序和选择状态行为。先执行书架整理定向 `18/18`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 Flutter 串行全量 `1280`（`3` 项既有条件跳过），全部通过；随后执行 `git diff --check` 并创建中文本地提交，只提交本批页面、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 探索页 SourceController 边界追溯：本批移除 `ExploreListPage` 页面内对旧 `SourceProvider` 的直接依赖和嵌套 Riverpod scope，改由生产组合根/测试宿主提供共享 `SourceController`；保留当前书源、探索请求、结果映射和书架过滤行为。先执行探索页定向 `1/1`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 Flutter 串行全量 `1280`（`3` 项既有条件跳过），全部通过；随后执行 `git diff --check` 并创建中文本地提交，只提交本批页面、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 书架导入对话框 SourceController 边界追溯：本批移除 `AddBookUrlDialog` 与 `ImportBookshelfDialog` 页面内对旧 `SourceProvider` 的直接依赖和嵌套 Riverpod scope，改由生产组合根/测试宿主提供共享 `SourceController`；保留源列表读取、网址导入、书单解析、进度和错误提示。先执行对话框定向 `4/4`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 Flutter 串行全量 `1280`（`3` 项既有条件跳过），全部通过；随后执行 `git diff --check` 并创建中文本地提交，只提交本批页面、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 目录持久化边界追溯：本批新增 `TocPersistencePort`，`TocSheet` 的书籍状态读取、倒序目录章节保存和书籍状态保存改通过 application 端口；生产组合根继续委托同一 `BookRepository`，缓存元数据改从已注册 `ChapterContentCachePort` 读取，保留 `bookRepository` 显式兼容参数和目录既有行为。先执行目录/详情定向 `15/15`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 Flutter 串行全量 `1280`（`3` 项既有条件跳过），全部通过；随后执行 `git diff --check` 并创建中文本地提交，只提交本批代码和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 书籍详情阅读启动与书源访问边界追溯：本批将 `BookInfoPage` 的书源匹配改接既有 `ReaderSourceAccessPort`，阅读入口改从 `BookshelfMembershipPort` 读取最新书架书籍，移除对 `BookProvider.books` 的直接读取和未使用的 `Consumer<BookProvider>` 展示包装；保留书源状态刷新、阅读入口、换源行为和原有书籍匹配语义。先执行书籍详情定向 `10/10`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 Flutter 串行全量 `1280`（`3` 项既有条件跳过），全部通过；随后执行 `git diff --check` 并创建中文本地提交，只提交本批代码、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 书籍详情缓存下载边界追溯：本批将 `BookInfoPage` 的“缓存全部”入口接入既有 `CacheBookDownloadPort`，生产组合根继续委托 `BookProvider` 的下载状态、目录加载、批量下载和取消；保留同书取消、书源缺失、空目录提示、缓存过滤、并发参数和完成计数语义。先执行书籍详情定向 `10/10`，再执行 `flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 Flutter 串行全量 `1279`（`3` 项既有条件跳过），全部通过；随后执行 `git diff --check` 并创建中文本地提交，只提交本批代码、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 普通阅读器目录刷新边界追溯：本批新增 `ReaderChapterRefreshPort` 和适配器，`ReaderPage._updateToc` 的强制目录刷新改通过 application 端口获取不可变章节快照，生产组合根继续委托 `BookProvider.loadChapters`；保留当前章节 ID/标题定位、空目录提示、成功提示和异常文案。定向 `5/5`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 全量 `1269`（`3` 项既有条件跳过）并通过。创建中文本地提交，只提交本批代码、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 普通阅读器进度写入边界追溯：本批新增 `ReaderProgressPort` 和回调适配器，`ReaderPage._saveProgress` 通过 application 端口写入章节进度，生产组合根继续委托 `BookProvider.updateProgress`；保留进度比例、章节标题、`pageIndex`、`durChapterIndex` 和原异步时序。定向 `5/5`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 全量 `1268`（`3` 项既有条件跳过）并通过。创建中文本地提交，只提交本批代码、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 书籍详情书架生命周期边界追溯：本批新增 `BookshelfBookLifecyclePort` 和 Provider 回调适配器，`BookInfoPage` 的加入书架、当前目录保存和移除书架通过 application 端口完成；生产组合根继续复用 Provider 的快照、章节元数据、变更总线和通知语义，阅读启动保持原职责。定向 `9/9`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 全量 `1267`（`3` 项既有条件跳过）并通过。创建中文本地提交，只提交本批代码、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 书籍详情分组命令边界追溯：本批将 `BookInfoPage._setGroup` 的单本写入改接已存在的 `BookshelfArrangeGroupCommandPort`，组合根继续绑定 `BookProvider` 适配器，独立宿主缺少能力时使用 application 空实现；保留分组读取、加入书架前置、输入裁剪、取消和原 UI 行为。定向联合 `15/15`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 全量 `1266`（`3` 项既有条件跳过）并通过。创建中文本地提交，只提交本批代码和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 书籍详情阅读状态写入边界追溯：本批只收口 `BookInfoPage._setReadIteration` 的 Provider 写入，新增 `BookReadStatusPort` 和回调适配器，生产组合根继续委托 `BookProvider.updateReadIteration`；保留阅读状态选项、书架内落库条件、异常传播和原 UI 行为。定向 `9/9`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 全量 `1266`（`3` 项既有条件跳过）并通过。已创建中文本地提交，只提交本批代码、测试和追溯文档，不提交 `android/gradle.properties`、`reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 缓存下载与阅读器书源展示边界追溯：三个不重叠写集分别收口缓存页下载状态/命令、漫画菜单书源名和普通阅读器顶栏书源名；主线在组合根复用既有 `BookProvider` 下载状态与 `SourceProvider.findSourceForBook`。缓存页仅在独立宿主未注入端口时保留回调 fallback，生产入口优先读取根端口。合并定向 `21/21`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 串行全量 `1254`（`3` 项既有条件跳过）并通过。代码提交 `cb0e194`，只提交本批代码和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 漫画换源目录读取边界追溯：本批只收口漫画页 `_openChangeSource` 的当前目录读取，新增 `MangaChapterListPort` 和不可变快照适配器，生产组合根继续复用 `BookProvider.currentChapters`。定向 `5/5`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 串行全量 `1241`（`3` 项既有条件跳过）并通过。代码提交 `5ceb4dc`，只提交本批代码和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-05 Phase 4/R6 漫画阅读进度写入边界追溯：本批只收口漫画页 `_persistProgress` 的 Provider 写入，新增 `MangaProgressPort` 和回调适配器，保留 `pageIndex`、`durChapterIndex`、章节标题和进度比例。定向 `7/7`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过后，执行 Flutter 串行全量 `1239`（`3` 项既有条件跳过）并通过。代码提交 `aaf40d1`，只提交本批代码和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 阅读器、书籍详情和缓存页只读边界追溯：三条不重叠写集分别实现图片请求头端口、书架成员查询端口和缓存页书架/本地目录端口；主线统一补齐组合根注册并修正图片端口的延迟依赖构造。定向联合 `13/13` 后执行 Flutter 串行全量 `1236`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check`，全部通过。代码提交 `5e9cc80`，只提交本批代码和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 阅读器与书籍目录读取边界追溯：按三个不重叠写集并行实现漫画正文、阅读器正文搜索和书籍详情目录端口；主线复核后补齐组合根接线，并修正 Feature 对 infrastructure 适配器的直接导入。定向联合 `14/14`，再执行 Flutter 串行全量 `1232`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check`，全部通过。漫画组合根继续调用原 `loadChapterContent`，阅读器搜索复用 `ReaderChapterContentPort`/`ChapterContentCachePort`，详情页目录复用 `BookInfoChapterPort`；代码提交 `96f241a`，只提交本批代码和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 有声页正文读取边界追溯：先通过有声页正文读取端口适配器定向 `1/1`，再执行 Flutter 串行全量 `1228`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`，全部通过。新增 `ReaderChapterContentPort`，`AudioPlayPage` 通过端口读取缓存正文，组合根复用现有 Provider 的书源匹配、缓存读取和原有失败文案；保留正文处理、TTS、章节切换和正文位置语义。代码提交 `6f5c406`，只提交本批 application/infrastructure、组合根、页面和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 书签页阅读跳转边界追溯：先通过书签页与两个端口适配器定向 `4/4`，再执行 Flutter 串行全量 `1227`（`3` 项既有条件跳过）；全量通过后修正适配器测试的显式 `Book?` 类型注解，再复跑书签定向 `4/4`、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。新增 `BookmarkReaderPort`、Provider 回调适配器，书签页复用 `BookshelfMembershipPort`，保留目录回退和 Reader 定位语义。代码提交 `b4580b7`，只提交本批 application/infrastructure、组合根、页面和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 主框架书架更新角标边界追溯：先通过主框架、书架样式和展示状态适配器定向 `18/18`，再执行 Flutter 串行全量 `1226`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。`MainShell` 通过 `BookshelfDisplayStatePort` 读取并监听 `shelfUpdateActiveCount`，组合根复用现有 Provider 适配器，缺少端口时角标回退为 0。代码提交 `5d83fc8`，只提交本批 application/infrastructure、组合根、主框架和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 换源页写入端口边界追溯：先通过换源页与适配器定向 `2/2`，再执行 Flutter 串行全量 `1225`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。新增 `BookSourceChangePort`、Provider 回调适配器和组合根接线；页面保留先换源后强制刷新目录的旧顺序。代码提交 `d6cb52b`，只提交本批 application/infrastructure、组合根、页面和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 发现页书架成员读取边界追溯：先通过发现页与成员端口定向 `2/2`，再执行 Flutter 串行全量 `1224`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。新增 `BookshelfMembershipPort`、Provider 兼容适配器和组合根 `ListenableProvider` 接线；`ExploreListPage` 不再直接依赖 `BookProvider`，保留书架过滤和变化刷新语义。代码提交 `f4ee370`，只提交本批 application/infrastructure、组合根、页面和测试，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 “我的”页缓存入口边界追溯：先通过我的页/缓存定向 `3/3`，再执行 Flutter 串行全量 `1223`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。只提交本批页面和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 书架展示状态边界追溯：先固定 Style1/Style2 的加载、重试、单本目录更新动画回归，再新增可监听 `BookshelfDisplayStatePort`、Provider 适配器和组合根 `ListenableProvider` 接线。定向 `14/14` 后执行 Flutter 串行全量 `1223`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。只提交本批 application/infrastructure、组合根、页面、测试和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 远程书籍书架导入边界追溯：先审查 RemoteBook 现有 WebDAV 控制器与 Provider 依赖，再新增 `RemoteBookImportPort`、适配器和不可变快照/路径导入回归。定向 `4/4` 后执行 Flutter 串行全量 `1223`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。只提交本批 application/infrastructure、页面、测试和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 书架缓存入口边界追溯：将 Style1/Style2 缓存管理入口从 `BookProvider.contentCache` 改为组合根提供的 `ChapterContentCachePort`，生产仍使用同一缓存实例。先通过书架/缓存定向 `19/19`，再执行 Flutter 串行全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。只提交本批页面、组合根和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 书架目录刷新边界追溯：先通过 Style1/Style2 目录刷新定向 `14/14`，再执行 Flutter 串行全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、本批文件格式和 `git diff --check`，全部通过。owner 将刷新结果和运行状态收口到 `BookshelfTocRefreshPort`，组合根用 Provider 兼容适配器接线；空实现仅服务未完整组装的独立宿主。验证固定原有并发去重、源解析、`onlyUpdateRead`、统计和异常语义未变；只提交本批端口、适配器、页面、测试和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 书架整理读取边界追溯：本批先完成整理页三处 `BookProvider.books` 读取的影响分析，再新增同步 `BookshelfArrangeSnapshotPort` 和不可变快照适配器；生产组合根复用 Provider 最新完整快照，测试宿主显式注入快照，未改变初始空态、分组过滤、排序顺序、完整书架书源导出或命令失败语义。联合定向 `19/19` 通过后才执行 Flutter 全量 `1221`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check`，全部通过。只提交本批端口、适配器、测试和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。
2026-08-04 Phase 4/R6 书架菜单导出读取边界追溯：在整理页快照端口通过后，将 `BookshelfMenuActions._exportList` 的完整书架读取改接同一 application 端口；补充导出端口调用回归，固定空书架、成功、失败和日志提示路径未被改变。定向联合 `23/23` 通过后执行 Flutter 全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check`，全部通过。只提交菜单动作、测试和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。
2026-08-04 Phase 4/R6 Style1/Style2 单本命令边界追溯：在分组/删除端口与整理页命令通过后，将 Style1 行内分组及 Style1/Style2 单本删除接入同一 application 端口；测试宿主使用现有 Provider 适配器，验证原确认、取消和移除结果，不触碰目录刷新/缓存职责。定向 `15/15` 通过后执行 Flutter 全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check`，全部通过。只提交本批样式页、测试和追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。
2026-08-04 Phase 4/R6 添加网址入库边界追溯：新增 `BookshelfUrlImportPort`、infrastructure 适配器和组合根接线，页面测试保留共享 SourceController、原 URL、源列表和结果计数断言。先通过定向 `2/2`，再执行 Flutter 全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check`，全部通过。只提交本批 URL 端口、适配器、测试和追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。
2026-08-04 Phase 4/R6 书单条目入库边界追溯：新增 `BookshelfBooklistImportPort`、infrastructure 适配器和组合根接线，页面测试保留 BookshelfListPort 解析、共享 SourceController、原条目、源列表和结果计数断言。先通过定向 `2/2`，再执行 Flutter 全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check`，全部通过。只提交本批书单端口、适配器、测试和追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`，不自动 push。

2026-08-04 Phase 4/R6 书架整理删除命令追溯：三条 lane 分别核对完整删除调用链、设计交互/Provider 测试矩阵和复核独立端口边界；owner 采用 `Future<void>` application 命令以保持原页面局部列表与排序持久化语义，组合根适配现有 Provider。测试先覆盖适配器 ID 固化和异常传播，再覆盖单本/批量成功、取消、失败及排序保存；生命周期测试固定仓储失败不清缓存、缓存失败不回滚仓储；真实 Provider 测试固定批量成功只统一刷新/发布/通知一次，以及第二项仓储失败、缓存失败、最终刷新失败的部分副作用和旧快照。受影响定向 `35/35`、Flutter 全量 `1220`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。只提交本批代码、测试和四份追溯文档，排除本地工具文件。

2026-08-04 Phase 4/R6 书架整理“移除分组”追溯：三条 lane 分别实现适配器契约测试、审查 Widget Finder/失败捕获和复核 Provider/ChangeBus 副作用；owner 扩展既有分组命令端口与适配器，并将页面原逐本 Provider 循环替换为 application 命令。测试先固定 ID 固化、逐项最新快照、精确匹配、空选择通配、缺失跳过、不可变最终快照和第二项失败；再用真实 Provider 验证每本各执行一次仓储刷新、总线发布与 listener 通知，并覆盖成功、通配、取消和失败四类 UI 交互。受影响定向 `37/37`、Flutter 全量 `1205`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。只提交本批代码、测试和四份追溯文档，排除本地工具文件。

2026-08-04 Phase 4/R6 书架整理分组命令追溯：三条只读 lane 分别审查 Widget 行为、架构/文档落点和下一批条件式“移除分组”语义；owner 新增 application port、Provider 回调兼容适配器、组合根接线及三个真实 UI 入口回归。定向验证覆盖委托次数、ID 顺序、不可变快照、成功刷新、选择清理、单/批异常传播和失败保持，结果 `25/25`；随后 Flutter 全量 `1196` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。底层仍由 `BookProvider` 保留 mutation version、变更总线和通知，“移除分组”与删除未混迁。只提交本批代码、测试和四份追溯文档，排除 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`。

2026-08-04 Phase 4/R6 书籍基础信息字段级写入追溯：三条不重叠写集分别实现 Rust、Dart 数据端口和上层接线；Rust lane 先提交底层 `82a860b`，owner 使用 FRB 2.11.1 生成绑定，恢复生成器无关的 lockfile 漂移，并机械补齐 16 个测试 fake。先通过 Rust 定向 `2/2`、Flutter 跨层定向 `20/20` 和 analyze；Rust 全量 `270/270`。Flutter 全量首次因新绑定与旧 release DLL 内容哈希不一致导致 12 个真实 FRB 初始化失败，按现有流程执行 release 重建后原失败定向 `7/7`、第二次全量 `1188`（`3` 项既有条件跳过）通过，未跳过或放宽测试。提交前继续执行架构、格式和 diff 门禁；不提交本地工具文件。

2026-08-03 Phase 4/R6 书架整理排序隔离追溯：三条只读 lane 审查策略别名、Widget 交互和下一批字段级写入；owner 将空保存顺序分支改为复制列表，未调整 Provider getter 或排序持久化。先通过策略/页面定向 `6/6`，再通过 Flutter 全量 `1177`（`3` 项既有条件跳过）；Widget 测试额外断言页面视觉顺序确实改变，排除假阳性。提交前继续执行 analyze、架构边界、格式和 diff 检查，只提交本批策略、测试和追溯文档。

2026-08-03 Phase 4/R6 书籍封面写入追溯：三条只读 lane 分别核对详情页仓储直写、书架整理命令和计划门禁；GitNexus MCP 未提供且本地 CLI 超时，owner 使用全仓静态调用链、测试和计划文档完成同等影响检查。按“一批一个用例”只迁移自动封面保存：新增 `BookMetadataController`，组合根显式注入，`BookProvider` 原位更新最新快照并使旧在途加载失效；非书架不写入、异常静默、阅读位置和其他书籍字段保持不变。先通过定向 `12/12`，再通过 Flutter 全量 `1175`（`3` 项既有条件跳过）、`flutter analyze --no-pub` 和 `scripts/check_architecture_boundaries.ps1`。最终格式与 `git diff --check` 在提交前执行；只提交本批代码、测试和四份追溯文档，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`。

2026-08-03 Phase 4/R6 书架快照同步前置追溯：三个 agent 分别审查 Style1/Style2 与入口、Notifier/Provider 同步风险及文档证据；owner 先收口同步契约，不迁移页面。`BookProvider.loadBooks` 增加 requestId 与 bookshelf mutation version 双重失效保护；`BookshelfChangePort`/`BookshelfChangeBus` 携带不可变书架快照和 revision，由生产组合根共享给 Provider 与 Notifier。Provider 成功加载或写入后发布完整快照，Notifier 直接应用变更并支持从总线最新快照初始化，避免重复数据库读取；后台章节元数据和章节落库也发布新快照，失败写入不发布。书架同步相关七个测试文件定向 `25/25`，命令为 `flutter test --no-pub --enable-experiment=dot-shorthands test/application/bookshelf/bookshelf_change_port_test.dart test/application/bookshelf_notifier_test.dart test/providers/book_provider_bookshelf_change_test.dart test/providers/book_provider_load_request_test.dart test/providers/book_provider_bookshelf_controller_test.dart test/providers/book_provider_group_update_test.dart test/providers/book_provider_chapter_meta_controller_test.dart`；Flutter 全量 `flutter test --no-pub --enable-experiment=dot-shorthands` 为 `1153` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 全部通过。书架页面继续使用 `BookProvider`，未改变 Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`。

2026-08-03 Phase 4/R6 BookProvider 书架读取追溯：在上一批 BookshelfController 边界通过后，将 `BookProvider.loadBooks` 改为委托可注入的 `BookshelfController`，保留 loading、error 文本、notify 顺序、维护开关和全部写入职责。先通过新增回归 `2/2`，再通过 Flutter 全量 `1145`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、其脚本自测和 `git diff --check`。生产默认仍绑定同一 `BookRepository`，测试通过替身验证委托和错误传播；只提交本批代码、测试和追溯文档，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`。

2026-08-03 Phase 4/R6 书架读取边界追溯：先完成 controller/Notifier/组合根定向 `21/21`，再执行 Flutter 全量、analyze、架构边界和 diff 门禁。Flutter 3.44.8/Dart 3.12.2 的测试命令使用显式 `--enable-experiment=dot-shorthands`，不修改项目配置；缓存重建后全量 Flutter `1143` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 清洁通过，架构边界和 `git diff --check` 通过。`BookshelfController` 生产绑定同一 `BookRepository`，旧 CoreApi 仅作 fallback；同时以透明 `Material` 修复 Flutter 3.44 的分组选择 tile 断言，以 `onReorderItem` 保留排序结果。只提交本批代码、测试和追溯文档，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`。

2026-08-03 Phase 4/R6 阅读进度写入边界追溯：先由三个不重叠 lane 完成进度/迁移/同步定向测试、application 分层审查和变更范围审查；owner 随后修正 `bookId` 与 `existingBook.id` 不一致时不得整书 upsert，并补充防误写回归。最终定向 `34/34`、Flutter 全量 `1129`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 全部通过。`BookProgressController` 仅依赖 `BookRepository`，`BookProvider` 继续负责刷新和通知；`pageIndex`、异常传播、UTF-16 章内阅读位置及 R1-12/原版 UI/暂停平台边界不变。本批不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`。

2026-08-03 Phase 4/R6 书架章节元数据边界追溯：三个 agent 分别完成 controller/纯 application 测试、Provider 集成回归和只读并发审查；owner 将 `BookshelfChapterMetaController` 接入 `BookProvider` 与 `AppBootstrap`，并在章节读取期间重新获取最新书籍快照，避免元数据 upsert 覆盖并发阅读进度。先通过定向 `29/29`，再通过 Flutter 全量 `1137`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`。空章节、标题不匹配、异常隔离、通知顺序和 UTF-16 页内位置保持不变；本批不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json`。

设备对照约定（2026-08-02）：原版 UI/功能对照固定使用 `emulator-5556` 上的 `io.legado.app.debug`，目标版本为 `3.26.072317debug`；`com.legado.legado_flutter` 作为重构版包单独验证，不按包名混用。UI 截图、交互、主题、文字、布局和功能验收均以该版本为准，其他原版版本只能作为历史参考。Room 迁移证据现已登记，源库副本为 `.tmp/r1-device-room/original_legado.db`。
R1-12 状态更正（2026-08-03）：archive-only 产品边界及真实非空 Room 证据均已完成登记。副本确认 Room v99、identity hash 与基线一致，包含 `books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`；既有 `emulator-5556` all-phase smoke `1/1` 通过。当前仍未声明的只是 `readRecord` 统计语义和非核心表 Rust v17 业务化，历史记录中“R1-12 仍不退出/真实证据缺失”仅表示当时状态。
2026-08-03 Phase 4/R6 书架分组写入边界追溯：新增 `BookshelfBookGroupController`，将 `BookProvider` 的单本/批量分组写入和刷新委托到 application 层；组合根显式注入控制器，旧 Provider 入口、顺序写入、空输入、异常传播和通知次数保持不变。先通过控制器/Provider 定向 `9/9`，再通过书架相关定向 `12/12`、Flutter 全量 `1113`（`3` 项既有条件跳过）、`flutter analyze`、`scripts/check_architecture_boundaries.ps1`、Rust 全量 `268/268`、`cargo fmt -p legado_engine -- --check` 和 `git diff --check`。本批不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12、原版 UI 基线或暂停平台门禁。
2026-08-03 Phase 4/R6 书架书籍生命周期边界追溯：新增 `BookshelfBookLifecycleController`，将书籍新增和删除时的仓储写入、章节缓存清理顺序收口到 application 层；`BookProvider` 继续负责列表刷新、未读元数据清理、批量循环和通知。先通过生命周期/书架/缓存定向 `16/16`，再通过 Flutter 全量 `1115`（`3` 项既有外部网络条件跳过）、`flutter analyze`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`。本批未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12、原版 UI 基线或暂停平台门禁。
2026-08-03 Phase 4/R6 书籍阅读元数据写入边界追溯：新增 `BookRecordController`，将 `readIteration` 和模拟追读字段的 Book 复制、边界裁剪及仓储 upsert 收口到 application 层；`BookProvider` 继续负责当前书选择、列表刷新、通知和兼容返回值。先通过书籍记录/书架/缓存定向 `20/20`，再通过 Flutter 全量 `1117`（`3` 项既有外部网络条件跳过）、`flutter analyze`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check`。契约明确阅读位置不变，本批未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、第 3 条断行规则、R1-12、原版 UI 基线或暂停平台门禁。
2026-08-03 R1-12 真实非空 Room 证据追溯：`.tmp/r1-device-room/original_legado.db` 作为只读副本纳入记录，Room v99、identity hash 与原版基线一致，计数为 `books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`。既有命令 `flutter test --no-pub integration_test/r1_android_room_import_smoke_test.dart -d emulator-5556` all-phase `1/1` 通过，覆盖真实导入、章节 ID、持久化、重复导入、空备份路径和备份恢复；本条只关闭真实非空数据库证据子项，不扩展未声明的统计和非核心业务化范围。
2026-08-03 Phase 4/R6 第十二批追溯：本批先由三条不重叠 lane 分别补齐 Riverpod provider 依赖声明、清理重复局部 scope、修正 `MainShell` 测试宿主，再由 owner 按顺序执行主壳定向、受影响页面定向、全量 Flutter、analyze、架构边界和 diff 检查。全量首次暴露两个未提供根 `ProviderScope` 的旧书架测试宿主，补齐真实 `SourceProvider.controller` override 后重跑通过；最终 Flutter `1104` 通过、`3` 项既有条件跳过，受影响定向 `19/19`，宿主补充回归 `2/2`。本批不放宽断言、不恢复生产页面局部 scope、不改变旧 Provider 兼容行为；只提交通过 owner 门禁的本批代码、测试和追溯文档，不提交 `reasonix.toml`、`.agents/`、`.tmp/`、`skills-lock.json` 等本地工具文件。
2026-08-02 R1-12 最新 owner 汇总：Room 定向 `29/29`、Rust 全量 `262/262`、Flutter 导入/备份定向 `17/17`、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 全部通过；`emulator-5556` 上原版 `io.legado.app.debug` 的真实 Room v99 非空数据库已完成重构版 all-phase smoke。R1-12 仍不退出，剩余产品边界为 `readRecord` 统计语义、非核心表 Rust v17 业务化和文件级 SQLite 备份目标；在这些边界确认前不推进新的 R2-R6 实现。
2026-08-02 R1-12 产品决策已确认并完成门禁收口：旧版 Legado 数据导入不得因未业务化字段失败；六张核心业务表导入后直接可用，`readRecord` 与非核心表继续无损 archive-only 保存；备份保持原版 JSON 逻辑，不增加文件级 SQLite 备份要求。Room 定向 `29/29`、Rust 全量 `262/262`、Flutter 导入/备份定向 `17/17`、analyze、架构边界和 diff 检查通过，R1-12 按该边界完成；后续不将未业务化字段静默写入 Rust v17 统计或业务表。
2026-08-03 Phase 4/R6 Provider 状态迁移首批：先以控制器状态、共享监听和规则列表不可变契约测试固定行为，再新增 `ReplaceState`/`ReplaceRulesController`、Riverpod `ReplaceNotifier`，最后将 `ReplacePage` 切换到局部 `ProviderScope`；旧 `ReplaceProvider` 只作为共享控制器的 ChangeNotifier 兼容外观。定向控制器/Notifier/Provider `5/5`、Flutter 串行全量 `1057`（`3` 项既有条件跳过）、`flutter analyze --no-pub` 和架构边界检查通过。迁移不改变内置规则、CRUD、按 pattern 去重、正文替换和预览；Book/RSS/Source Provider 及其余页面仍按后续独立写集处理，不据此宣称 Riverpod 全量迁移或 R6 退出。
2026-08-03 Phase 4/R6 Provider 状态迁移第二批：先以 RSS 控制器/Notifier、列表不可变、URL 去重和管理排序契约固定行为，再将 `RssSourceManagePage` 切换到局部 `ProviderScope`；旧 `RssProvider`、`RssTabPage`、启动任务和订阅适配器保持兼容。定向 RSS `9/9`、Flutter 串行全量 `1060`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变 RSS 导入/删除/启用/置顶/分组筛选和源列表顺序；未据此宣称 RSS 全页面或 Riverpod 全量迁移。
2026-08-03 Phase 4/R6 Provider 状态迁移第三批：先以 SourceController/Notifier、不可变嵌套集合、加载/搜索/校验竞态和 JSON 导入契约固定行为，再将 `SourcesPage` 的业务状态订阅切换到局部 `ProviderScope`；旧 `SourceProvider` 与 Riverpod 共享同一 controller，FilePicker、选择排序、分享和未迁移子页保留兼容外观。Source controller/Notifier、旧 Provider 兼容回归 `25/25`，source Feature/Widget `10/10`，Flutter 串行全量 `1066`（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 全部通过。并发请求旧结果不再覆盖新状态，持久化失败仍保留成功校验的内存结果；未迁移 Search/Explore/Book/Reader、启动任务和规则订阅，不据此宣称 Source 全链路或 Riverpod 全量迁移。
2026-08-03 Phase 4/R6 Provider 状态迁移第十一批：三条并行 lane 分别完成 AppConfig 状态桥接、SourceController 根级组合注入和剩余 Provider 风险审查。AppConfig 只新增 application 状态层并迁移 `ConfigPage`，保留 singleton、四个配置键、`load()` 并发去重、乐观写入和启动顺序；组合根将现有 `SourceProvider.controller` 作为唯一 Riverpod source controller，三个书籍页面移除局部桥接，`BookProvider` 事实源不变。先通过 AppConfig `9/9` 与 Source 页面/组合根 `8/8` 定向，再通过 Flutter 全量 `1100`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check`。只读审查确认 BookProvider/Reader 仍是高风险边界，下一批优先处理 SourcesPage 管理动作和 Source scope 清理；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
2026-08-03 Phase 4/R6 Provider 状态迁移第四批：先固定分组管理与书源市场的共享 controller 契约，再将两个子页面接入局部 `ProviderScope`；分组 CRUD、源存在状态和市场导入均通过 `SourceNotifier`，全部导入必须等待 `upsertAll` 完成后才提示和返回。新增市场异步 Widget 测试捕获并修复 scope 外读取 container 的运行时错误。Source 管理相关定向 `38/38`、Flutter 串行全量 `1067`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 全部通过。SourceEditor、SourceDebug、RuleSub、启动任务和规则订阅适配器保持兼容，不据此宣称 Source 全链路或 Riverpod 全量迁移。
2026-08-02 Phase 3 模型契约批次：先新增 `Book`/`BookSource` Freezed 构造、值相等和 `copyWith` 契约测试，再迁移模型实现；保留 `readConfig` 旧 JSON 兼容、嵌套书源规则和 `toEngineJson`。模型及相关书架/书源仓储、Provider 定向测试共 `28/28` 通过；全量 Flutter `922` 项通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过。本批未迁移 UI 页面、Rust 独立书籍 DTO 或 Riverpod 生产页面，不改变正文、目录、分页、章节身份、UTF-16 阅读位置和 R1-12 边界。
2026-08-02 Phase 3 Rust 书源 DTO 批次：在 Flutter 模型契约通过后新增 Rust `BookSourceDto` serde camelCase 投影及 `BookSource::to_dto()`，先用 raw JSON/嵌套规则/分页回退测试固定字段契约，再完成纯内存转换。DTO 定向 `1/1`、Rust 全量 `263/263`、`cargo fmt -p legado_engine` 通过；不新增 FFI 入口，不改变书源解析、网络、正文、目录、分页、章节身份、UTF-16 阅读位置或 R1-12 边界。
2026-08-02 Phase 3 Rust 书籍 DTO 批次：先以 serde 字段与数据库完整行映射测试固定 `BookDto` 契约，再让 `get_books_json()` 委托 DTO 序列化；`db_get_books()`/FRB/Flutter `List<String>` 接口保持不变。定向 `3/3`、Rust 全量 `265/265`、Flutter 全量 `922`（`3` 项既有条件跳过）通过；未改动 Room 导入、正文、目录、分页、章节身份、UTF-16 阅读位置或暂停项。
2026-08-02 Phase 3 替换规则模型批次：先新增旧 JSON 默认值、值相等和 `copyWith` 契约，再将 `ReplaceRule` 改为 Freezed；手写 `fromJson`/`toJson` 保留既有 ID、布尔值和空字符串语义。定向 `11/11`、Flutter 全量 `923`（`3` 项既有条件跳过）通过；不修改替换算法、正文或断行规则。
2026-08-02 Phase 3 阅读统计模型批次：先以可选日期、`readingDays`、日统计列表和 `copyWith` 固定模型契约，再迁移三个统计模型为 Freezed；FRB 书票适配器补齐 Rust `readingDays` 投影，旧构造点继续使用默认 `0`。定向 `12/12`、Flutter 全量 `925`（`3` 项既有条件跳过）通过；不改变统计查询或 UI 语义。

2026-08-02 R1-12 真实 Android owner 门禁：通过 `D:\Android\platform-tools\adb.exe` 只操作 `emulator-5556`，读取原版 debug 包真实 `databases/legado.db`，确认 Room v99、identity hash、`books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`；以只读副本作为重构包 smoke 源库。`flutter test --no-pub integration_test/r1_android_room_import_smoke_test.dart -d emulator-5556` all-phase `1/1` 通过，覆盖真实导入、章节 ID、持久化、重复导入、空备份路径和备份恢复。该证据关闭真实非空 Room 数据缺失子项，但 `readRecord` 产品语义和非核心表业务化仍未决，R1-12 不退出。

2026-08-02 R1-12 并发一致性 owner 门禁：先通过 Room 定向 `26/26` 和数据库定向 `28/28`，再通过 Rust 全量 `259/259`；Room 读取统一为单一只读事务快照，fingerprint 去重检查与导入写入统一纳入 `BEGIN IMMEDIATE`，备份临时文件改为唯一创建和不覆盖提交。所有 Android 操作统一使用 `emulator-5556`；真实非空 Room 源库证据仍未完成，R1-12 不退出。

2026-08-02 当前 R1-12 owner 门禁（当前验证快照）：Rust Room `25/25`、Rust 全量 `256/256`、release 构建、Flutter 导入报告 `10/10`、Flutter 全量 `918`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。新增 detailedReadRecord 新 fingerprint 幂等、readRecord 报告边界和全量 archive-only 代表性行覆盖；emulator-5556 当前在线，但原版 io.legado.app.releaseS 为不可调试 release 包，无法通过 run-as 或直接 pull 读取 /data/user/0/io.legado.app.releaseS/databases/legado.db；外部 backup.zip 仅含配置，不含 Room 数据库，因此 Android smoke 与真实非空 Room 证据仍未完成。历史临时非空等价 fixture 仅证明 fixture 链路，不替代真实原版非空 Room 数据；R1-12 不退出，也不推进新的 R2-R6 实现。
2026-08-02 R1-12 Dart 导入端口契约复核：Rust/FRB 已支持重复导入时 `backupPath=null`，Dart port、use case、FRB adapter 已取消不必要的非空收窄；首次导入缺少备份路径仍由 Rust 事务边界拒绝。Flutter 定向导入测试 `12/12`、Flutter 全量 `917`（`3` 项既有条件跳过）、`flutter analyze --no-pub` 通过。本条不改变真实 Room 数据缺失和 R1-12 未决边界。
2026-08-02 R1-12 跨层报告与 Android smoke 契约复核：主机侧测试固定 Rust serde 报告 13 字段的完整形状、基础类型和 nullable 分支；Android smoke 增加 application → FRB → generated API 的重复导入 `backupPath=null` 断言，并继续校验目标业务数据与归档数量不增加。Flutter 定向导入测试 `13/13`、Flutter 全量 `918`（`3` 项既有条件跳过）、`flutter analyze --no-pub` 通过；真实 Android smoke 因原版 release 包数据库目录无权限读取未执行，R1-12 不退出。

2026-08-02 R1-12 报告失败契约与回滚证据复核：`LegacyRoomImportReport` 对 Rust 报告必需字段执行严格缺失/类型校验，保留可选 identity hash/备份路径兼容和未知字段兼容；Android smoke 增加重复导入不写新备份、目标业务数据与归档数量不增加断言；Rust 失败回滚测试解析导入前备份并确认原有书籍、原有归档和归档内容均保留。owner 门禁：Flutter 报告定向 `10/10`、Rust Room `24/24`、Rust 全量 `255/255`、Flutter 全量 `912`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。Android smoke 因设备不可用未执行；R1-12 继续不退出，也不推进新的 R2-R6 实现。

2026-08-02 R1-12 导入报告与事务边界复核：在前一批 owner 门禁基础上，先完成 Flutter 报告定向 `6/6`、Rust Room `24/24`、数据库 `26/26`，再完成 Rust 全量 `255/255`、Flutter 全量 `912`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check`。报告契约补齐 Room identity hash/备份路径，统一 Rust 实际计数键，并明确重复导入不重复写入备份；Android smoke 增加 23 表精确集合断言；Rust 增加 WAL/SHM 字节只读、`replace=true` 成功替换/旧状态备份和详细记录阈值回归。该历史批次未执行 Android smoke，真实原版非空数据库仍缺失；R1-12 继续不退出，也不推进新的 R2-R6 实现。

2026-08-02 R1-12 owner 门禁复核：先执行 Rust Room 定向测试 `23/23` 和数据库定向测试 `24/24`，再执行 Rust 全量 `252/252`、Flutter 全量 `912`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check`，全部通过。迁移边界同步明确为：`readRecord` 采用 archive-only 保存并纳入原始计数，继续不写入 Rust 阅读统计业务表；`detailedReadRecord` 原始行及 Room 自增 `id` 保留在 `raw_snapshot_json`，业务映射按书名聚合 sessions 且不保留聚合 session 的 Room 自增 `id`；`replace_rules.sortOrder/scope/group` 仅进入原始归档，不进入当前 Rust v17 替换规则业务映射。该批未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。由于真实原版非空数据库和相关产品语义仍未完全闭合，R1-12 及 R1 继续不退出，也不推进新的 R2-R6 实现。

2026-08-02 当前 R1-12 追溯记录：本批由四条互不重叠 lane 补齐 Room 六张核心业务表及 `readRecord` archive-only 逐字段 golden fixture、Flutter 导入报告字段与设备证据边界审查。owner 门禁为 Rust Room `21/21`、Flutter Room `5/5`、Rust 全量 `249/249`、Flutter 串行全量 `911`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 全部通过。修正 `books.originName` 未进入 Rust v17 业务映射却列入已映射白名单的问题，现明确报告为未映射；不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。当前 `emulator-5556` 不可连接，真实原版非空 Room 数据库仍未取得；`readRecord` 统计语义、详细阅读记录聚合、非核心表业务 port 和文件级 SQLite 备份仍按计划保留为未决边界，R1-12 及 R1 不退出，也不推进新的 R2-R6 实现。
2026-08-02 R1-12 报告契约补充：Flutter 导入报告重复导入路径新增归档表/告警/未映射列空集合断言，未知 JSON 字段向前兼容断言通过，Room 定向测试 `6/6`。本批仍不改变 Rust 迁移语义或阶段退出条件。
2026-08-02 R1-12 书源规则落库追溯：本批先补目标 `book_sources` 扁平列断言，再修复 `upsert_source_json` 对嵌套规则的兼容回退；保留已有扁平字段优先级，`rulePageNext` 按扁平/目录/正文顺序回退。新增书源规则、目标表落库和 archive-only 字段断言，Rust Room `22/22`、数据库 `24/24`、Rust 全量 `251/251`、Flutter 全量 `912`（`3` 项既有条件跳过）、analyze、架构扫描和 `git diff --check` 通过。真实原版非空数据库仍缺失，R1-12 不退出。

2026-08-01 历史状态复核：R1 因 Kotlin Room v99 → Rust v17 数据库迁移门禁重新打开。R1-12 当时只确认六张核心业务表映射、`readRecord` archive-only 保存与 23 个 Room 实体表全量原始归档；本批新增 v99 版本/identity hash 门禁、备份保护、正冲突、归档恢复、JSON 恢复事务性、既有数据回滚、非核心 fingerprint 稳定性、缺失实体表结构、实体 table-only、非法 UTF-8 无损和源库文件字节级只读边界测试，Room 定向 `21/21`、Rust 全量 `249`、release、`flutter analyze --no-pub` 和 Flutter 全量 `908`（`3` 项既有条件跳过）通过。缺失实体表或 view 冒充实体会在读行前拒绝，非法 UTF-8 不进行 lossy 替换且不产生目标写入。当前六张核心业务表及 `readRecord` 均为空，`book_groups` 有 7 行，`keyboardAssists` 有 14 行；非核心表仍 archive-only。该历史时点记录的 `emulator-5556` 状态为只安装原版包、未安装重构 APK，真实非空迁移验收无法执行；因此不把 23 张表写成全部 Rust v17 业务迁移，也不把 R1/R2/R6 历史实现记录写成当前阶段退出。R1-12 复核完成前不推进新的 R2-R6 实现。
只读 schema 形状审计进一步确认：原版 `99.json` 与仓库 `original_legado.db` 的 23/23 个实体表列集合一致，无缺列/额外列；唯一 view 为 `book_sources_part`。当前六张核心业务表及 `readRecord` 均为空，`book_groups` 有 7 行，`keyboardAssists` 有 14 行，因此不构成真实非空核心数据迁移证据。
最新 owner 门禁补强：`readRecord.lastRead` 已纳入结构探针，导入前备份写入失败会清理临时路径且保留预存在路径；Room 定向 `21/21`、Rust 全量 `249`、release、架构扫描和 `git diff --check` 通过。`readRecord` 仍不做业务映射。
归档链路新增合法 BLOB 字节数组的 snapshot/export/restore 回归，以及成功导入和非法 UTF-8 失败时源库主文件及 `-wal`/`-shm` 侧文件状态不变回归；`emulator-5556` 已安装 debug 重构 APK，临时非空等价 fixture 的 import/verify 两阶段通过，覆盖关键字段、章节身份、重启、幂等和备份恢复；真实原版非空数据库仍未取得。Dart 导入报告解析定向 `3/3` 通过。
并行 owner 回归继续补齐 `readRecord` 四字段只归档和重复 fingerprint 备份 no-op；Room `21/21`、数据库 `23/23`、Rust 全量 `249`、release、架构扫描和 `git diff --check` 通过。

2026-08-01 当前追溯记录：本批将 `serve_source_browser_host`、`probe_source_browser_host` 迁移到 Rust `AppError`，保留成功回调 DTO、`startBrowserAwait` Dart 回调链和错误原文；取消映射 `Cancelled`，不支持平台映射 `Unsupported`，宿主停止/锁失败/线程失败映射 `Unknown`。`browser_host` 增加 abort/clear 生命周期守卫，避免 stale sender；`AppWebViewPage` 在 dispose 后不再派发新的 Cookie 回调，成功完成路径仍等待 Cookie、抓 DOM 并返回 finalUrl/body。验证为 Rust `browser_host` 定向 `7/7`、Dart 浏览器宿主/WebView 定向 `8/8`、Rust 全量 `234`、release 构建、Flutter 串行全量 `908`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。本批不改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、WebDAV、平台验收或阶段退出。
2026-08-01 当前追溯记录：本批将 `process_content_for_reading` 同步 FFI 入口映射到 `AppError::Parse`，先执行 Rust 定向 `2/2` 和 Dart FRB mock 契约 `2/2`，再执行 Rust 全量 `228`、release 构建、Flutter 全量 `903`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check`，全部通过。正文处理成功输出、替换、缩进、标题合并和重新分段行为保持不变；本批不迁移 UI/application 调用者，不覆盖浏览器宿主、重复公开 FRB 子模块入口、WebDAV、平台验收或阶段退出。
2026-08-01 当前追溯记录：本批将 `search/explore/toc/debug/validate` 子模块实现标记为 `frb(ignore)` 并降为 `pub(crate)`，根 `api/mod.rs` wrapper 作为唯一公开 FRB 契约；重新生成绑定后移除重复子模块 Dart/Rust wire 导出，并删除陈旧子模块 Dart wrapper。实际门禁：`cargo fmt -p legado_engine` 通过，Rust 全量 `228` 通过，release 构建、`flutter analyze --no-pub`、Flutter 全量 `903` 通过且 `3` 项既有条件跳过，架构边界扫描和 `git diff --check` 均通过。本批不改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、浏览器宿主、WebDAV、平台验收或阶段退出。
2026-08-01 当前追溯记录：本批按“先完成实现、再执行定向门禁、最后记录边界”推进 QuickJS 执行预算和 Rust 数据库初始化契约。`cargo fmt -p legado_engine` 通过；QuickJS 定向 `29/29`、数据库定向 `19/19` 通过。QuickJS 5 秒 interrupt 仅覆盖纯 QuickJS 执行，`java.ajax`、`getStrResponse` 和 WebView 宿主阻塞不在本批保证范围；`init(app_dir)` 固定 `app_dir/legado.db`、事务初始化失败不发布，初始化锁覆盖首次并发调用，并已覆盖同目录幂等/异目录拒绝。FRB 已重新生成，`LegadoDbBridge` 已切换到应用数据目录入口；release DLL 重建后备份服务定向测试 `10/10` 通过，`flutter analyze --no-pub` 无诊断。最终 Rust 全量 `208` 项通过，Flutter 串行全量 `894` 项通过、`3` 项既有条件跳过，架构边界扫描和 `git diff --check` 均通过；本条不把定向证据扩展为 R1-12、R2 或 R6 阶段退出证据。
2026-08-01 当前追溯记录：本批将 `get_book_info`、`query_dict_rule`、笔记和书签公开 FFI 入口迁移到 Rust `AppError`，保留成功结果与既有错误原文/位置语义；目录/校验内部以 `into_legacy` 维持过渡链。FRB 已重新生成，Rust 全量 `218` 项、Flutter 串行全量 `894` 项通过，`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。RSS、EPUB、浏览器宿主及其它公开 `Result<T, String>` 入口仍按顺序排队，本条不扩展 R1-12、R2 或 R6 阶段退出证据。

2026-08-01 当前追溯记录：本批先完成 Rust EPUB/远程 ZIP/RSS 错误映射和定向测试，再同步生成 FRB，并在 Flutter 适配层提取 `AppError.field0` 保留用户可见错误原文；非 Rust 异常继续原样传播。`cargo fmt -p legado_engine`、Rust RSS 定向 `4/4`、Flutter 适配器定向 `10/10`、Rust 全量 `224`、release 构建、Flutter 全量 `897`（另有 `3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。RSS 分类新增“解析文本包含 network 仍为 Parse”的回归；本批只处理公开错误边界，没有迁移 UI/application 的 RSS/本地书籍用例，也不覆盖浏览器宿主、QuickJS 宿主阻塞或其它公开字符串错误入口。

2026-08-01 当前追溯记录：本批将 `eval_js` 同步 FFI 入口映射到 `AppError::JsExecution`，先执行 Rust 定向 `2/2` 和 Dart FRB 定向 `2/2`，再执行 Rust 全量 `226`、release 构建、Flutter 全量 `899`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check`，全部通过。生成绑定保持成功返回和错误原文；QuickJS 既有纯执行 interrupt/输入上限测试继续作为门禁，不据此宣称宿主调用超时或取消已完成。本批只处理公开 FFI 错误边界，不迁移 UI/application 调用者。

2026-08-01 当前追溯记录：本批将 `seed_login_header` 同步 FFI 入口映射到 `AppError`，先执行 Rust 定向 `3/3` 和 Dart FRB 定向 `2/2`，再执行 Rust 全量 `226`、release 构建、Flutter 全量 `901`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check`，全部通过。生成器尝试运行时在 Windows rustfmt 阶段遇到文件映射锁警告并产生无关全量漂移，未纳入；最终按已验证 FRB codec 模式保留三处最小绑定差异。本批只处理公开 FFI 错误边界，不迁移 UI/application 调用者。

2026-07-31 当前 R6 记录：Batch 5 将 `SourceProvider` 的源分组目录 CRUD 与标签规则迁移到 `SourceGroupCatalogPort`，组合根注入 legacy adapter；owner 定向 `13/13`，Flutter 串行全量 `842` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构脚本和 `git diff --check` 通过。三条只读 lane 同时完成 validation store、BookSource/LocalBook 聚合和批量进度同步契约审查；剩余五处 Provider→service 依赖继续按先审查后实现的顺序处理。Rust 未改动，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续暂停。

2026-08-01 当前 R6 记录：Batch 6 四条不重叠 lane 完成 Provider 边界收口。`SourceProvider` 接入 validation store 和 source-management book-source facade；`BookProvider` 接入批量进度与本地导入 ports；组合根统一注入真实 adapter，保留 BookSource/LocalBook/BookProgress legacy 实现语义。owner 定向 `20/20`、`20/20`、`26/26`、`32/32`；首轮全量发现 legacy 本地导入异常兼容分支，补充双异常映射后最终 Flutter 串行全量 `864` 通过、`3` 项既有条件跳过；全仓 analyze、架构脚本、diff 检查通过。扩展 Provider 扫描仅剩 BookProvider 的 BookSourceService 聚合依赖。Rust 未改动，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续暂停。

2026-08-01 当前 R6 记录：Batch 7 完成最后一处 `BookProvider -> BookSourceService` 边界。新增 `BookProviderSourcePort` 及 legacy adapter，覆盖详情、搜索/结果映射、目录、普通正文和分页正文；`BookProvider` 与 `AppBootstrap` 通过 application port 接入，`ReadBook` 保持原缓存、DB 回落、分页 next-chapter 和失败文案语义，其他 service 消费者未迁移。owner 定向 `41/41`；Flutter 串行全量 `866` 通过、`3` 项既有条件跳过；全仓 analyze、架构脚本和 `git diff --check` 通过，Provider service 扩展扫描为零。Rust、真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续按暂停门禁执行。

2026-08-01 当前 R6 记录：Batch 8 将 MainShell 隐私协议持久化改为 `PrivacyConsentPort`，SharedPreferences adapter 继续复用 `SharedPreferencesRuntime`，并保留失败后重试；MainShell 的 post-frame 时机、协议弹窗、同意/拒绝操作和崩溃恢复顺序保持不变。owner 定向 `14/14`；Flutter 串行全量 `869` 通过、`3` 项既有条件跳过；全仓 analyze、架构脚本和 `git diff --check` 通过，Feature/Widget/Provider 扩展扫描清零。Rust、真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续暂停。

2026-08-01 当前 R6 记录：Batch 9 先完成四线 `<js>` 兼容证据审查，再只修复有明确复现的最小缺口。`run_js_compat.ps1` 固定 Rust `--locked --offline`、Flutter `--no-pub`，Cargo/Flutter 缺失时直接失败；`check_architecture_boundaries.ps1` 修复 Windows PowerShell 5 的默认参数路径解析问题并重跑通过；`JS_COMPAT.md` 更新为 Rust `18` 项并区分离线门禁与可选在线探测。原版对照确认 `@js:`/`@JS:` 路由应大小写不敏感，Rust `BookSource` 已统一判定并补回归测试；普通 JS 宿主变量、完整 API、FRB 真链路、在线书源和对象返回值语义不以占位实现关闭，继续登记为兼容性 backlog。最终 Rust `legado_engine` `186/186`、JS 脚本 Rust `18/18`、Flutter `4/4`、Flutter 全量 `869` 通过，analyze 和架构扫描通过，7565 在线探测 HTTP 400 按既有可选契约跳过。本批仍未修改 `legado-main/`，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续暂停。

2026-08-01 当前 R6 记录：Batch 10 将同一 JS 大小写契约收口到 Flutter 登录入口和兼容性分析器。`SourceLoginService.extractScript/isJsUrl` 支持 `@js:` 的 ASCII 混合大小写，并统一识别 `<js>`/`<Js>`；`JsCompatAnalyzer` 对 `@js:` 统计、字段归类和 `<js>` 计数使用大小写不敏感规则。owner 定向 `11/11`；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构脚本和 Rust 格式检查通过，JS 兼容在线 7565 HTTP 400 按既有可选契约跳过。未修改 `legado-main/`、Rust 正文/目录/分页/章节身份/UTF-16 阅读位置和暂停中的平台能力；完整 JS 宿主 API、超时/取消、真实 FRB 链路和在线书源继续作为 backlog。

2026-07-31 当前 R6 记录：四条 Provider 线继续推进。P0 将 `ReplaceProvider` 内置四条规则改为 `ReplacePresetPort`；P1 将 `ChapterProgressMigrator` 移至 application；P2 将 `SourceProvider` 登录头和校验偏好改为既有 application ports；P3 新增 `RssSourceStorePort` 移除 RSS 源列表的 SharedPreferences 直连。主线补齐组合根绑定，并将 Provider fallback 限制为 application 空端口，避免恢复 infrastructure 直连。定向与 owner 组合回归通过（P0 `4/4`、P1 `8/8`、P2 `24/24`、P3 `10/10`、组合 `42/42`）；扩展扫描仅剩明确 Provider→service backlog。Flutter 串行全量 `838` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构脚本和 `git diff --check` 通过。Rust 未改动，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续按暂停门禁执行。

---

## 官方 UI 对标目标

本项目的总体目标是将 [Jingshiro/legado](https://github.com/Jingshiro/legado) 的 Android/Kotlin 实现重构为 Rust + Flutter 跨平台实现。Jingshiro/legado 源码用于行为、数据格式和 UI 的兼容性验收；UI 复刻只是其中一个验收维度。

| 项 | 值 |
|----|-----|
| **对标项目** | [Jingshiro/legado](https://github.com/Jingshiro/legado) |
| **权威说明** | 原 `gedoor/legado` 已不在 GitHub；**Jingshiro fork 为 UI 布局与 Activity 源码的唯一参照** |
| **布局源码** | `app/src/main/java/io/legado/app/ui/` |
| **XML 布局** | `app/src/main/res/layout/` |
| **本地基线** | `legado-main/`（唯一只读 Kotlin 行为基线；不得修改或参与构建） |
| **历史副本** | `reference/Jingshiro-legado/`（如存在，仅作历史离线副本） |
| **功能验收** | [语雀 Wiki](https://www.yuque.com/legado/wiki)（用户向交互；**布局仍以 Jingshiro 源码为准**） |

---

## 一、现状诊断

### 已有

| 类别 | 资产 |
|------|------|
| 技术路线图 | `REFACTOR_PLAN.md`；历史 UI 功能库存见 `archive/UI_REPLICATION_PLAN.md` |
| Phase 设计 | `superpowers/specs/`、`superpowers/plans/` |
| 发布说明 | `RELEASE.md` |
| 专题文档 | `JS_COMPAT.md`、`LEGADO_ARCH_REFERENCE.md` |
| 外部参考 | [Jingshiro/legado](https://github.com/Jingshiro/legado)（UI 权威）、[语雀 Wiki](https://www.yuque.com/legado/wiki) |
| CI | `.github/workflows/apple-build.yml`（仅 macOS/iOS） |
| 测试脚本 | `scripts/run_js_compat.ps1`、`flutter test`、`cargo test` |

### 缺失（本流程要补的）

| 缺口 | 影响 |
|------|------|
| **无统一流程文档** | 每人/每次 AI 会话做法不一致，容易跳步 |
| **无文档索引** | 计划散落，不知道先看哪份 |
| **无质量门禁** | 合并前跑什么测试、什么叫「做完」不明确 |
| **无 CONTRIBUTING.md** | 贡献入口和协作约定仍需单独整理 |
| **无 Issue/PR 模板** | 需求描述、测试说明格式不统一 |
| **CI 不完整** | 仅 Apple Build，Windows/Android 测试无自动跑 |
| **Phase 完成标准模糊** | REFACTOR / UI 计划里的 checkbox 与代码状态易脱节 |

---

## 二、文档体系与职责

### 2.1 写哪份、何时更新

| 文档 | 谁维护 | 何时更新 |
|------|--------|----------|
| `REFACTOR_PLAN.md` | 负责人 | 引擎版本变更、大功能完成/新增、多平台状态变化 |
| `archive/UI_REPLICATION_PLAN.md` | 归档 | 历史 UI Task 与旧差距记录，不作为新重构任务入口 |
| `superpowers/specs/*.md` | 设计阶段 | **新 Phase 或大改前**写规格，批准后不动（除非变更） |
| `superpowers/plans/*.md` | 实施阶段 | 拆 Task、记步骤；可与 UI/REFACTOR 计划合并维护 |
| `JS_COMPAT.md` 等专题 | 专题负责人 | 该主题测试/规则变化时 |
| `DEVELOPMENT_PROCESS.md` | 全员 | 流程本身变更时 |
| `CHANGELOG.md` | 负责人 | **每个逻辑变更完成时**更新；对外发布时整理为版本条目 |

### 2.2 单一事实来源

- **引擎能力与版本** → `REFACTOR_PLAN.md` + `rust/legado_engine` 中 `engine_version()`
- **当前 UI/架构验收** → `REFACTOR_PLAN.md` 的 R0-R6、`LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md` 和 `R0_REBASELINE.md`；`UI_REPLICATION_PLAN.md` 仅保留历史功能库存。
- **怎么开发** → 本文档
- **怎么发布** → `RELEASE.md`
- **每次变更记录** → `CHANGELOG.md`

避免在 README 里维护长进度表；README 只保留快速开始 + 指向 `docs/README.md`。

---

## 三、标准开发流程

适用于每一个 Task（如 UI-1、JS 兼容 2a、引擎 Phase 2C）。

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│ 1.选题  │ → │ 2.对齐  │ → │ 3.实现  │ → │ 4.自测  │ → │ 5.记录  │ → │ 6.合并  │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### Step 1 — 选题

1. 在 `REFACTOR_PLAN.md` 的当前 R0-R6 阶段中找到迁移单元；历史 `UI-*` Task ID 只能用于追溯已有功能。
2. 确认依赖已满足（例如 UI-2 依赖 UI-1 底栏骨架）。
3. 大功能（新 Phase、跨 Rust+Flutter）先查 `superpowers/specs/` 是否已有规格；没有则先写简短设计再动手。

### Step 2 — 对齐

开工前明确三件事（可写在 PR 或 commit 说明里）：

| 项 | 说明 |
|----|------|
| **对标** | UI：Jingshiro 哪个 XML/Activity；引擎：哪条 legado 行为 |
| **范围** | 本 Task 做啥、**不做啥**（防止 scope creep） |
| **验收** | 可检查的条目（语雀 checklist、测试命令、截图） |

### Step 3 — 实现

原则（与 `.cursorrules` / 用户约定一致）：

- **最小 diff**：只改本 Task 相关文件
- **沿用现有风格**：命名、Provider、页面结构跟周边代码一致
- **引擎优先 Rust**：UI 不引入 Dart 规则引擎
- **占位要可见**：未实现功能用明确文案（如「开发中」），不要静默失败

### Step 4 — 自测（质量门禁）

合并前**至少**通过下表对应项：

| 改动类型 | 必跑命令 |
|----------|----------|
| 任意 Dart | `flutter analyze` + `flutter test` |
| Rust 引擎 | `cd rust/legado_engine && cargo test` |
| JS 兼容相关 | `.\scripts\run_js_compat.ps1` |
| UI 阅读器/书源 | 手动：`flutter run -d windows`，走一遍主路径 |
| Apple 相关 | 本地或等 CI `apple-build.yml` |

**Definition of Done（单个 Task）**

- [ ] 计划文档中对应条目已勾选或注明「部分完成 + 剩余项」
- [ ] 上述测试通过（或注明平台限制，如 Web 无 Rust）
- [ ] 无无关文件进提交（调试 xml、analyze 输出等）
- [ ] 若改引擎版本，`engine_version()` 与 `REFACTOR_PLAN.md` 一致

### Step 5 — 记录

1. 更新对应阶段记录（`REFACTOR_PLAN.md`、`R0_REBASELINE.md` 或专题兼容计划）；不再以历史 UI Task 清单声明重构完成。
2. 若行为/用法变化，更新专题 doc（如 `JS_COMPAT.md`）。
3. 按本文“变更可追溯规则”更新 `CHANGELOG.md`，写明变更、测试和已知限制。

### Step 5A — 变更可追溯规则（强制）

以下规则适用于代码、测试、配置、文档、数据库 schema、Rust 引擎和 Flutter UI 的每一个逻辑变更；“只改了一点”不能豁免。

1. **先确认范围。** 开始工作前确认当前分支和工作区状态；已有未提交修改必须保留、识别归属，不能把无关修改混入本次变更。
2. **必须记录计划。** 在 `REFACTOR_PLAN.md`、`R0_REBASELINE.md` 或对应专题文档中更新当前迁移状态。未完成项、平台限制和外部依赖必须明确写出，不能只写“完成”。
3. **必须更新日志。** 每个逻辑变更都在根目录 `CHANGELOG.md` 的 `[Unreleased]` 下记录，至少包含：变更内容、影响范围、验证命令/结果、已知限制。修复问题还要写明问题表现和修复结果。
4. **必须可由 Git 追溯。** 每个可交付逻辑变更应形成独立 Git commit，commit message 必须能说明 Task/模块和结果。未获得提交授权时，不得擅自 commit；此时必须明确报告“未提交”，并提供拟提交文件和 commit message。
5. **测试结果必须和变更绑定。** 报告“已完成”前必须列出实际执行的测试/构建命令及结果；跳过、失败和环境限制必须原样记录，不能用历史结果冒充当前结果。
6. **发布必须有版本标识。** 对外发布前必须递增 `pubspec.yaml` 的 App 版本，核对 Rust engine/schema 版本，更新 `CHANGELOG.md` 的版本条目，并创建对应 Git tag。没有版本号和 tag 的工作区只能称为开发中或未发布版本。
7. **禁止虚假完成。** 脏工作区、未更新日志、未记录测试、存在未披露失败门禁或未完成外部验收时，不得把本次变更描述为“全部完成”或“已发布”。

本规则优先于旧文档中“CHANGELOG 待建”“发布时再记录”等过渡性描述；旧文档与本规则冲突时，以本规则为准。

### Step 6 — 合并

- 默认分支：`master`
- 功能分支命名建议：`feat/ui-1-reader-chrome`、`fix/apple-ci-link` 等
- **仅用户明确要求时** `git commit` / `git push` / 开 PR
- PR 描述建议包含：Task ID、对标、测试命令、截图（UI 改动）

---

## 四、Phase 门控

Phase 不是「写了很多代码」，而是满足**退出标准**才能进下一 Phase。

### Phase F（UI 复刻）示例

| 阶段 | 进入条件 | 退出标准 |
|------|----------|----------|
| **S1** | 主框架可导航 | UI-1～UI-7 验收 checklist 通过；`flutter test` 绿 |
| **S2** | S1 完成 | 缺失页面有入口非占位；备份/Web 服务可配置 |
| **S3** | S2 完成 | 换源/AI/DB 扩展可用 |
| **S4** | 用户排期 | RSS 阅读链路可用 |

### 引擎 Phase 示例

| 标记 | 退出标准 |
|------|----------|
| JS 兼容 2a | 50+ 源离线清单 + 通过率报表 |
| JS 兼容 2d | CI 回归 job 绿 |
| 多平台 | `RELEASE.md` 中该平台构建命令本地验证通过 |

---

## 五、测试策略

### 5.1 测试金字塔

```
        ┌─────────────┐
        │  手动探索   │  UI 1:1 对照、真机
        ├─────────────┤
        │  集成测试   │  test/integration/
        ├─────────────┤
        │  服务/Widget│  test/services/ test/widgets/
        ├─────────────┤
        │  Rust 单元  │  rust/legado_engine/tests/
        └─────────────┘
```

### 5.2 关键回归套件

| 套件 | 路径 | 用途 |
|------|------|------|
| Flutter 全量 | `flutter test` | Dart 逻辑回归 |
| Phase 3 对齐 | `cargo test --test phase3_alignment` | 引擎规则对齐 |
| JS 兼容 | `scripts/run_js_compat.ps1` | `<js>` / jsLib 回归 |
| Apple 构建 | `.github/workflows/apple-build.yml` | macOS/iOS 链接 |

### 5.3 新功能测试要求

- 修 bug：**先复现再修**，能写测试则写（不强制 widget 烟测）
- 新引擎规则：Rust 单元测试 + fixture HTML/JSON
- 新 UI 页：至少手动主路径；复杂交互记入 `UI_REPLICATION_PLAN` 验收项

---

## 六、分支与版本

### 6.1 版本号约定（建议）

| 层级 | 位置 | 规则 |
|------|------|------|
| App 版本 | `pubspec.yaml` `version:` | `主.次.补丁+build` |
| 引擎版本 | Rust `engine_version()` | 与 `REFACTOR_PLAN.md` 同步，功能变更时 bump |
| DB Schema | 迁移脚本版本号 | 破坏性变更才 +1，写迁移说明 |

### 6.2 发布流程（摘要）

完整步骤见 `RELEASE.md`。发布前检查：

1. `flutter test` + 相关 `cargo test` 通过
2. 目标平台构建成功
3. `CHANGELOG.md` 已更新，版本条目与 `pubspec.yaml`、引擎版本和 schema 一致
4. 打 tag（若对外发布）

---

## 七、对标验证流程

### UI 改动

1. **布局**：优先核对本地只读基线 `legado-main/` 的 `app/src/main/res/layout/` + `app/src/main/java/io/legado/app/ui/`；外部 Jingshiro 仓库和 `reference/Jingshiro-legado/` 仅作历史/补充参考
2. **功能完整性**：[语雀 Wiki](https://www.yuque.com/legado/wiki) 对应章节（历史对照库存见 `archive/UI_REPLICATION_PLAN.md`）
3. **截图对比**：同一状态（书架/阅读器/设置）并排对比

### 引擎改动

1. 原 legado / Jingshiro 行为描述
2. fixture 或在线 probe 测试
3. `phase3_alignment` / `js_compatibility` 无回归

---

## 八、待补齐清单

按优先级建议实施：

| 优先级 | 资产 | 说明 |
|:---:|------|------|
| P0 | ✅ `docs/README.md` | 文档索引 |
| P0 | ✅ `docs/DEVELOPMENT_PROCESS.md` | 本文档 |
| P1 | `CONTRIBUTING.md` | 贡献者入口，链到本文档 |
| P1 | ✅ `CHANGELOG.md` | 版本变更记录 |
| P1 | ✅ `.github/workflows/ci.yml` | Flutter/Rust/架构/diff 基础 CI 已存在；平台发布矩阵另列 |
| P2 | `.github/pull_request_template.md` | Task ID + 测试说明 |
| P2 | `.github/ISSUE_TEMPLATE/` | bug / feature 模板 |
| P3 | ADR 目录 `docs/adr/` | 重大架构决策记录 |

---

## 九、历史流程基建建议（不作为当前执行队列）

在继续 UI-1 等实现任务之前，建议用 **1～2 天** 完成流程基建：

```
Day 1  流程文档 ✅（本文 + docs/README）
       CHANGELOG.md ✅；CONTRIBUTING.md 初稿
       基础 CI（flutter test + cargo test）

Day 2  PR/Issue 模板
       统一 REFACTOR_PLAN / UI_REPLICATION_PLAN 顶部「状态」字段
       选定下一个 S1 Task（建议 UI-1）并按 § 三 走一遍完整流程
```

这样后续每个 Task 都有章可循，避免「直接写代码、计划文档越来越滞后」。

2026-07-30 当前 R6 记录：AppLog 页面及书架/书签/笔记写入边界、四轮 Feature 偏好/展示/业务能力端口，以及本轮 AppPaths/Clipboard/SourceDebug、RSS ReaderFont、主题 Clipboard、Sources ReaderFont、Backup AppPaths、ReadRecord Clipboard、Web API Clipboard、SourceEditor Clipboard、DictRule Clipboard、TxtToc Clipboard 和 ContentEdit Clipboard 边界均按“先定向测试、再全量门禁、最后记录”流程完成；本批由主 agent 与四个子 agent 并行完成规则偏好、点击区域、正文搜索、模拟阅读、阅读样式、阅读图片缓存、Web API 配置偏好、TocSheet 笔记读取、BookInfoPage 书源搜索/类型语义、Explore、SourceMarket、ReadRecord、阅读样式 ZIP、ReaderSettings 字体、ReplacePage、ConfigPage 和 CacheBookPage 端口，架构扫描由 `110` 降至 `87` 条既有 Feature→service backlog，未将剩余 Feature 依赖白名单化。四子线定向均通过；ReaderFont fake 接口缺口已修复后受影响宿主 `11/11`；Flutter 全量 `732` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，analyze 和 `git diff --check` 通过。相关实际命令和结果以 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 与 `docs/REFACTOR_ARCHITECTURE_BASELINE.md` 为准。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 RSS 阅读/收藏、主题导入和二维码图片解码端口。新增端口由组合根注入，测试宿主显式补齐依赖；Android SVG 集成测试改用图片缓存端口薄适配器，未削弱断言。实际验证为：受影响定向 `19/19`；`flutter test --no-pub --concurrency=1 --reporter compact` 为 `739` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描 `83` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `RssArticlesPage` 收藏写入端口。`RssStarPrefsPort` 增加 `toggle` 契约，页面和测试宿主改用注入端口，保留既有 SharedPreferences 和 UI 语义；定向 `10/10`，Flutter 串行全量 `740` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `82` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `SourceEditorPage` 二维码能力端口。`QrCodePort` 完整承载 PNG 编码与图片解码，页面和测试宿主改用注入端口，保留既有二维码导入/分享语义；定向 `8/8`，Flutter 串行全量 `741` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `81` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `SourceEditorPage` 代码编辑偏好与会话日志端口。页面改用已有 `CodeEditPrefsPort`，测试宿主注入 fake store adapter，保留自动补全和会话日志语义；定向 `15/15`，Flutter 串行全量 `741` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `80` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `SourceEditorPage` 书源登录 Cookie 清理端口。新增完整清理用例端口，adapter 保留 SharedPreferences、Rust CookieJar 和 WebView 清理语义；定向 `6/6`，Flutter 串行全量 `742` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `79` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：四个子 agent 按不重叠写入范围并行推进 AI 配置、书签页、书架排列和漫画阅读偏好；主线完成组合根接入、书架默认 adapter 边界修正和 owner 验收。子线定向证据 AI `9/9`、书签 `25`、书架 `8/8`、漫画 `11`，owner 合并定向 `16/16`；Flutter 串行全量 `755` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `69` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：两条不重叠 agent 线完成书架展示/配置和 MyPage，主线完成 MainShell 启动端口及组合根接入。受影响定向 `20/20`；Flutter 串行全量 `769` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `69` 降至 `57` 条既有 Feature→service backlog。首轮全量发现测试宿主缺少 `MyPagePort`，补齐 fake 后最终门禁通过，未削弱断言。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：两条不重叠 agent 线完成书架书单导入/导出和 RemoteBook，主线完成四类 adapter 的组合根接入。受影响定向 `25/25`，RemoteArchive/Sort 既有回归 `5/5`；Flutter 串行全量 `779` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `57` 降至 `52` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：C1/C2 两条不重叠 agent 线完成书架样式分组/本地导入和 WebDAV 配置，主线完成两个 Provider 接入及测试宿主补齐。定向组合回归 `34/34`，`test/widget_test.dart` `1/1`，MainShell/书架展示宿主回归 `4/4`；Flutter 串行全量 `788` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描保持 `46` 条既有 Feature→service backlog。首轮全量发现 4 个测试宿主缺少 `BookGroupStorePort`，补齐 fake 后最终门禁通过，未削弱断言。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：D1/D2 两条不重叠 agent 线完成 Obsidian 导出和 Reader AI Chat，主线完成 Obsidian port 的组合根接入。定向 `8/8`；Flutter 串行全量 `796` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `46` 降至 `41` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 Web API 设置、AudioPlay/TTS、其它设置和备份配置的 application/infrastructure 端口化。新增 `WebApiSettingsPort`、`TtsPort`、`OtherSettingsPort`、备份状态端口；组合根注册 adapter，测试宿主补齐端口依赖；TTS 面板与 AudioPlay 共用同一端口，保留播放模式、章节切换、定时、HTTP TTS 和系统 stub 行为。定向组合 `24/24`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `41` 降至 `30` 条既有 Feature→service backlog。全仓 analyze 首次因执行时限 `124` 终止，延长时限重跑通过；未削弱断言。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。

2026-07-31 当前 R6 记录：继续收口 `OtherSettingsCard` 缓存管理边界。新增 `CacheManagementPort` 与 infrastructure adapter，页面改用缓存统计/清理端口，保留统计格式、清理范围和既有 UI 行为。定向 `2/2`；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `30` 降至 `29` 条既有 Feature→service backlog。上一批 Flutter 串行全量为 `798` 通过、`3` 项既有条件跳过，本小批未重复全量；未削弱断言，Rust 未改动。

2026-07-31 当前 R6 记录：继续收口 `BackupConfigPage` 备份/WebDAV 操作边界。新增 `BackupConfigOperationsPort` 与 infrastructure adapter，R5 Android smoke 宿主补齐操作、WebDAV 偏好和状态端口；备份页定向 `4/4`，`flutter analyze --no-pub` 为 `No issues found`，架构扫描由 `29` 降至 `28` 条既有 Feature→service backlog。全仓 analyze 通过；本批未执行 Android 真机 smoke，未削弱断言，Rust 未改动。

2026-07-31 当前 R6 记录：继续收口 RSS 文章获取和 ReaderPage 阅读记录边界。`RssArticlesPage` 改用已有 `RssPort`；`ReaderPage` 改用 `ReadingRecordPort`，阅读会话计时器迁移至 application，`ReadingRecordService` 保留兼容 export。定向组合 `17/17`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `28` 降至 `26` 条既有 Feature→service backlog。未削弱断言，Rust 未改动；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。

2026-07-31 当前 R6 记录：继续收口 ReaderPage TTS 边界。扩展 `TtsPort` 覆盖选区朗读、连续朗读回调、句子位置和播放模式能力，ReaderPage 改用注入端口，保留系统/HTTP TTS、stub、选区模式、章节切换和正文位置语义。定向 TTS/Reader `29/29`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `26` 降至 `25` 条既有 Feature→service backlog。Rust 未改动，真实 Android TTS 继续按暂停门禁执行。

2026-07-31 当前 R6 记录：三条并行线收口 RSS 分类排序、RSS 源管理传输和 ReaderPage 书籍阅读偏好。新增 `RssSortUrlsPort`、`RssSourceTransferPort`、`BookReaderPrefsPort`，组合根统一注入；owner 验收移除 agent fallback 的 Feature→infrastructure 直连。定向 `8/8`；Flutter 串行全量 `802` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `25` 降至 `22` 条既有 Feature→service backlog。Rust 未改动，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续按暂停门禁执行。

2026-07-31 当前 R6 记录：四条协作线完成 Widget 边界收口。W1 将书架分组编辑/管理/选择对话框迁移到 `BookGroupManagementPort`；W2 将书签编辑、书票和笔记编辑迁移到 annotation ports；W3 将源校验、字典查询和替换预览 helper 迁移到 source-rule ports；W4 只读审查确认剩余 service 依赖集中在四个 Provider。主线完成组合根 Provider 接入，并按审查建议完成 `legado_bottom_nav.dart` 的 `ReaderFontPort` 迁移。定向与 owner 组合回归通过（W1 `11/11`、W2 `10/10`、W3 `14/14`、W4-W0 `4/4`、组合 `33/33`）；扩展 Widget/Feature 扫描无直接 service 依赖，Provider backlog 保持未修改。`flutter test --no-pub --concurrency=1 --reporter compact` 为 `829` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构脚本和 `git diff --check` 通过。另修复 `read_book_async_test.dart` 在 Windows teardown 删除临时目录时的预加载文件锁竞态，未修改断言或阅读行为。Rust 未改动，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续按暂停门禁执行。
2026-08-01 当前 R6 记录：Batch 11/12 将 Rust 校验及主请求桥接的收尾统一为 `finally`：`validateSource`、搜索、发现、详情、目录、正文均在 Rust 操作结束后先同步登录头，再 drain HTTP trace，保持返回值、原始异常和下一轮 trace 初始化语义。引擎/source debug 定向 `2` 个可运行测试通过、`2` 个在线 smoke 按开关跳过；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构脚本和 `git diff --check` 通过。调试搜索/目录、裸 HTTP、登录头队列失败重试/空值删除及 Rust loginCheckJs 错误语义继续作为后续 backlog，未修改 `legado-main/`。
2026-08-01 当前 R6 记录：Batch 13 补齐 `debugSearch`、`debugToc`、`httpFetch` 的 bridge finally 收尾；调试入口按同步登录头后 drain trace，裸 HTTP 始终 drain trace且有 source 时执行防御性登录头同步。owner 定向 `4/4`；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构脚本和 `git diff --check` 通过。未修改 Rust/`legado-main/`；真实登录头持久化链路、trace 异常 fixture、队列 ack/重试和空值删除继续作为 backlog。

2026-08-01 当前 R2/R6 追溯记录：网络文本与二进制 HTTP 的三个公开 FFI 入口统一为 Rust `AppError`，同步更新 FRB 绑定，未改变网络策略、请求体/头、超时、大小限制和非 2xx 响应。新增分类回归后 `cargo test -p legado_engine api::network::tests -- --nocapture` 为 `9/9`；`cargo test -p legado_engine` 为 `199` 通过；Windows FRB HTTP 集成为 `2/2`；Flutter 串行全量为 `894` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 已通过。架构边界和最终 diff 检查随后执行。其余公开 `Result<T, String>` 入口、QuickJS 超时、初始化合并、编码事实源和生产书架 Riverpod 切换保持未完成状态。

2026-08-01 当前 R2 追溯记录：裸 `http_fetch`、网络配置、Cookie 和 HTTP trace 入口统一为 Rust `AppError`，同步更新 FRB 绑定；`cargo test -p legado_engine api:: -- --nocapture` 为 `57/57`，保留网络参数、Cookie 域、限流和 trace 行为。`cargo test -p legado_engine` 为 `202` 通过；Windows FRB HTTP 集成为 `2/2`；Flutter 串行全量为 `894` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 均通过。QuickJS 超时、统一初始化、编码事实源、书架生产 Riverpod 和其它公开字符串错误入口仍未完成。
2026-08-03 当前 R6 追溯记录：三个并行开发线完成 `SourceEditorPage`、`SourceDebugPage` 和 `RuleSubPage` 的 Riverpod/Controller 调用边界迁移，主线复核共享控制器、原版行为边界和测试宿主。三页面定向 `19/19`；Flutter 串行全量 `1071` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 Rust 或 `legado-main/`，正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁保持不变。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。
2026-08-03 当前 R6 追溯记录：三个并行开发线完成 RSS 消费、搜索/探索和书籍详情/换源页面的 Riverpod/Controller 调用边界迁移，主线修复未注入旧版 `RssProvider` 的图片回归宿主兼容性。受影响定向 `11/11`；Flutter 串行全量 `1078` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 Rust 或 `legado-main/`，正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁保持不变。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。
2026-08-03 当前 R6 追溯记录：三个并行开发线完成书签页、RSS 源编辑页和书架 URL 导入对话框的 Riverpod/Controller 调用边界迁移。受影响定向 `8/8`；Flutter 串行全量 `1080` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 Rust 或 `legado-main/`，正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁保持不变。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。
2026-08-03 当前 R6 追溯记录：三个并行开发线完成 `CacheBookPage`、`BookshelfArrangePage` 和 `ImportBookshelfDialog` 的 Riverpod/Controller 调用边界迁移，主线复核共享 `SourceController`、`BookProvider` 兼容职责和测试宿主。受影响定向 `7/7`；Flutter 串行全量 `1083` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 Rust 或 `legado-main/`，正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁保持不变。`BookProvider` 生产状态尚未全量迁移，后续继续按不重叠写集推进。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。
2026-08-03 当前 R6 追溯记录：三个并行开发线完成 `SearchContentPage`、`BookshelfStyle1Page` 和 `BookshelfStyle2Page` 的 Riverpod/Controller 调用边界迁移，主线复核 `ReplaceController`、`SourceController`、`BookProvider` 兼容职责及书架测试宿主。受影响定向 `8/8`；Flutter 串行全量 `1086` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。RemoteBook 仅完成只读边界审查，未修改 Rust 或 `legado-main/`，正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁保持不变。后续按 RemoteBook 审查结论单独处理页面状态，不替换 `BookProvider` 书架事实源。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。
2026-08-03 当前 R6 追溯记录：三个并行开发线完成 RemoteBook 与 `MyPage` 的 Riverpod/Controller 状态边界迁移，主线复核 Freezed 生成文件、WebDAV 请求失效保护、备份状态和 `BookProvider` 兼容职责。受影响定向 `11/11`；Flutter 串行全量 `1093` 通过、`3` 项既有条件跳过；Freezed 生成、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。AppConfig 仅完成只读审查，未修改 Rust 或 `legado-main/`，正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁保持不变。后续继续按不重叠写集推进，不直接替换书架事实源或启动配置单例。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-08-03 当前 R6 追溯记录：完成 `BookshelfStyle1Page`、`BookshelfStyle2Page` 的 `BookshelfState` 只读消费迁移，并扩展 `BookshelfChangeBus` 失败快照，使生产启动书架读取失败进入 `BookshelfNotifier.failure`；目录刷新、更新中状态、缓存、删除和分组写入继续由 `BookProvider` 兼容边界承载。书架相关定向 `39/39`；Flutter 全量 `1165` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 Rust、`legado-main/`、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；不宣称 BookProvider 全量迁移或 R6 退出。

 2026-08-03 当前 R6 追溯记录：Style1/Style2 错误态重试统一调用 `BookProvider.loadBooks()`，共享变更总线负责最终快照同步，页面同时观察 Provider loading 状态；新增延迟重试 loading 回归，书架相关定向 `41/41`，Flutter 全量 `1167` 通过、`3` 项既有条件跳过。未修改 Rust、`legado-main/`、目录刷新、缓存、删除、分组写入、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；不宣称 R6 全量退出。
 2026-08-05 当前 R6 追溯记录：普通阅读器模拟追读书籍查询和字段写入收口到 `ReaderSimulatedReadingPort`；组合根以 `BookProvider` 回调适配器接入，页面保留 SharedPreferences 配置、旧书字段迁移、参数裁剪、阅读限制和原 UI 时序。先执行模拟追读适配器与 Reader 宿主定向 `6/6`，再执行 `flutter analyze --no-pub`、架构边界、Flutter 全量 `1271`（`3` 项既有条件跳过）和 `git diff --check`，全部通过。未修改 Rust、`legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
 2026-08-05 当前 R6 追溯记录：普通阅读器离线缓存入口复用已有 `CacheBookDownloadPort`，页面不再直接读取 `BookProvider` 的下载状态或调用目录加载、取消、批量下载；生产组合根继续接入同一 Provider 事实源，保留缓存选择、同书取消、并发参数、完成计数和提示语义。先执行 Reader 注入与缓存适配器定向 `7/7`，再执行 `flutter analyze --no-pub`、架构边界、Flutter 全量 `1272`（`3` 项既有条件跳过）和 `git diff --check`，全部通过。未修改 Rust、`legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
 2026-08-05 当前 R6 追溯记录：普通阅读器三个当前目录只读调用面收口到 `ReaderChapterListPort`，目录面板、手动换源后导航和自动换源后导航都读取不可变快照，换源命令仍由 Provider 承载。先执行目录适配器与 Reader 宿主定向 `8/8`，再执行 `flutter analyze --no-pub`、架构边界、compact reporter Flutter 全量 `1274`（`3` 项既有条件跳过）和 `git diff --check`，全部通过；首次默认 reporter 因 `120s` 工具时限终止，未产生测试失败，延长后重跑通过。未修改 Rust、`legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
 2026-08-05 当前 R6 追溯记录：完成 Reader 外部访问边界收口。`ReaderSourceAccessPort` 承载书源匹配、可用书源快照和自动换源；`ReaderChapterListPort` 按 `bookId` 校验目录快照；Reader 缓存章节 ID/清洗改用 `ChapterContentCachePort`。先执行相关适配器与 Reader 宿主定向 `10/10`，再执行 `flutter analyze --no-pub`、架构边界、compact reporter Flutter 全量 `1276`（`3` 项既有条件跳过）和 `git diff --check`，全部通过。未修改 Rust、`legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
 2026-08-05 当前 R6 追溯记录：普通阅读器正文加载改用既有 `ReaderChapterContentPort`，章节成功后的内存缓存状态更新收口到 `ReaderChapterCacheStatusPort`；`ReadBook` 的缓存失效、正文处理和编辑职责保持不变。先执行正文端口、缓存状态适配器与 Reader 宿主定向 `11/11`，再执行 `flutter analyze --no-pub`、架构边界、compact reporter Flutter 全量 `1278`（`3` 项既有条件跳过）和 `git diff --check`，全部通过。未修改 Rust、`legado-main/`、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。

---

> 相关：[文档索引](./README.md) | [历史 UI 功能库存](./archive/UI_REPLICATION_PLAN.md) | [重构计划](./REFACTOR_PLAN.md)
> 当前执行顺序以 `docs/REFACTOR_PLAN.md` 第 0 节和当前 R1-12 门禁为准；本节只保留流程基建历史建议。
