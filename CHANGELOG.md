# Changelog

All notable changes to this project are recorded in this file.

## [Unreleased]

- 架构/Phase 4/R6 普通阅读器正文读取边界：`ReaderPage` 正文加载改用既有 `ReaderChapterContentPort`，章节成功缓存标记新增 `ReaderChapterCacheStatusPort`；组合根继续复用 `BookProvider` 缓存正文和目录状态事实源。定向 `11/11`，Flutter 全量 `1278` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。保留正文失败文案、缓存失效、正文处理、分页和章节身份语义；R6 尚未退出。
- 架构/Phase 4/R6 Reader 外部访问边界：新增 `ReaderSourceAccessPort`，普通阅读器的书源匹配、可用书源快照和自动换源改经 application 端口；`ReaderChapterListPort` 增加按 `bookId` 校验并返回不可变目录快照；缓存章节 ID/清洗改用 `ChapterContentCachePort`。定向 `10/10`，Flutter 全量 `1276` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 普通阅读器目录快照边界：新增 `ReaderChapterListPort` 及不可变快照适配器，目录面板、手动换源后导航和自动换源后导航改通过 application 端口读取当前目录；换源命令仍由既有 Provider 负责。定向 `8/8`，Flutter 全量 `1274` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 普通阅读器离线缓存边界：`ReaderPage` 的缓存状态、取消下载、空目录加载和批量章节下载改用已有 `CacheBookDownloadPort`，组合根继续复用 `BookProvider` 下载事实源。定向 `7/7`，Flutter 全量 `1272` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 普通阅读器模拟追读边界：新增 `ReaderSimulatedReadingPort` 及 Provider 回调适配器，模拟追读的书籍查询和字段写入改经 application 端口；保留 SharedPreferences 配置存储、旧书字段迁移、日期/章节/每日章节参数和阅读限制语义。定向 `6/6`，Flutter 全量 `1271` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 缓存下载与阅读器书源展示边界：`CacheBookPage` 新增 `CacheBookDownloadPort`，目录加载、下载、取消和进度改经可监听端口，组合根继续复用 `BookProvider` 下载事实源；普通阅读器和漫画菜单分别新增书源展示端口，保留书源名称、URL host、空值和“书源”回退语义。定向 `21/21`，Flutter 全量 `1254` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 漫画换源目录读取边界：新增 `MangaChapterListPort` 及不可变快照适配器，漫画阅读页换源后的目录读取不再直接依赖 `BookProvider.currentChapters`；组合根继续复用同一 Provider 快照，保留空目录提示、索引裁剪和换源导航语义。定向 `5/5`，Flutter 全量 `1241` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 漫画阅读进度写入边界：新增 `MangaProgressPort` 及 Provider 回调适配器，漫画页章节进度保存不再直接调用 `BookProvider.updateProgress`；保留进度比例、章节标题、页内位置、章节索引、异常传播和原 UI 行为。定向 `7/7`，Flutter 全量 `1239` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 阅读器、书籍详情和缓存页只读边界：`ReaderPage` 图片请求头改用 `ReaderImageHeadersPort`；`BookInfoPage` 的书架成员只读查询复用 `BookshelfMembershipPort`；`CacheBookPage` 的书架快照、本地章节数和缓存导出章节读取改用 `CacheBookShelfPort`。组合根注入现有 Provider/SourceController 适配器，保留请求代数、书架匹配、缓存统计、下载/取消、导出和 UI 行为。定向联合 `13/13`，Flutter 全量 `1236` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 阅读器与书籍目录读取边界：漫画页新增 `MangaChapterContentPort`，继续复用原 `loadChapterContent` 非缓存正文语义；普通阅读页的正文搜索改用 `ReaderChapterContentPort` 与 `ChapterContentCachePort`；书籍详情页的目录读取、加载、强制刷新、目录打开和阅读定位改用 `BookInfoChapterPort`。组合根分别注入 Provider 回调适配器，保留书源匹配、缓存优先、失败文案、正文图片提取、TTS/章节导航和目录行为。定向联合 `14/14`，Flutter 全量 `1232` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 有声页正文读取边界：新增 `ReaderChapterContentPort` 及 Provider 回调适配器，`AudioPlayPage` 不再直接依赖 `BookProvider`/`SourceProvider`，组合根继续复用缓存正文读取、书源匹配和原有“未找到匹配的书源”文案。保留缓存、正文处理、TTS、章节切换和失败语义；适配器定向 `1/1`，Flutter 全量 `1228` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未改变正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 书签页阅读跳转边界：新增 `BookmarkReaderPort` 及 Provider 回调适配器，书签页不再直接依赖 `BookProvider`，书架快照复用 `BookshelfMembershipPort`；保留找书、目录网络加载/本地回退、章节定位和 Reader 参数语义。Flutter 全量 `1227` 通过（`3` 项既有条件跳过），类型注解修正后书签定向 `4/4`、`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。正文、目录、分页、章节身份、R1-12 或暂停平台门禁未改变；R6 尚未退出。
- 架构/Phase 4/R6 主框架书架更新角标边界：`MainShell` 改从可监听 `BookshelfDisplayStatePort` 读取书架待更新角标，适配器转发现有 `BookProvider.shelfUpdateActiveCount` 与通知，端口缺失时回退 0；角标显示条件和书架写入/目录职责不变。定向 `18/18`，Flutter 全量 `1226` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁未改变；R6 尚未退出。
- 架构/Phase 4/R6 换源页写入端口边界：新增 `BookSourceChangePort` 及 Provider 回调适配器，`ChangeSourcePage` 不再直接调用 `BookProvider.changeSource/loadChapters`；保留先换源、强制刷新目录、成功返回和失败提示语义。定向 `2/2`，Flutter 全量 `1225` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。未改变书源搜索、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 发现页书架成员读取边界：新增只读可监听 `BookshelfMembershipPort` 及 Provider 兼容适配器，`ExploreListPage` 不再直接读取 `BookProvider`，通过不可变书架快照过滤已在书架书籍并响应书架变化；生产组合根以 `ListenableProvider` 接入现有事实源。定向 `2/2`，Flutter 全量 `1224` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。未改变书源探索、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 “我的”页缓存入口边界：离线缓存入口改从组合根提供的 `ChapterContentCachePort` 获取缓存对象，不再直接读取 `BookProvider.contentCache`；生产继续使用同一缓存实例，缓存管理、下载、清理和导出行为不变，未完整组装宿主缺少端口时提示不可用。定向 `3/3`，Flutter 全量 `1223` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；书架、远程导入、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 和暂停平台门禁不变，R6 尚未退出。
- 架构/Phase 4/R6 书架展示状态边界：新增可监听 `BookshelfDisplayStatePort` 及 Provider 适配器，Style1/Style2 的加载、重试、单本目录更新动画不再直接读取 `BookProvider`；组合根使用 `ListenableProvider` 接入现有 ChangeNotifier，保留重试 loading、更新中状态和原书架事实源。定向 `14/14`，Flutter 全量 `1223` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；远程导入、缓存、目录刷新、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 和暂停平台门禁不变，R6 尚未退出。
- 架构/Phase 4/R6 远程书籍书架导入边界：新增 `RemoteBookImportPort` 及 Provider 兼容适配器，`RemoteBookPage` 通过端口读取本地书架快照、判断已在书架状态并按路径导入 TXT/EPUB/ZIP 解包文件；WebDAV 目录状态仍由 `RemoteBookController` 管理，原导入计数、日志、错误和导航语义保持不变。适配器与远程页面定向 `4/4`，Flutter 全量 `1223` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；目录刷新、缓存、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 和暂停平台门禁不变，R6 尚未退出。
- 架构/Phase 4/R6 书架缓存入口边界：Style1/Style2 打开缓存管理页时改从组合根提供的 `ChapterContentCachePort` 获取缓存对象，不再直接读取 `BookProvider.contentCache`；生产仍注入同一 `FileChapterContentCache` 实例，缓存管理、下载、清理和导出行为不变。未完整组装的独立宿主缺少端口时提示缓存引擎不可用。定向 `19/19`，Flutter 全量 `1222` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；目录刷新、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 和暂停平台门禁不变，R6 尚未退出。
- 架构/Phase 4/R6 书架目录刷新边界：新增 `BookshelfTocRefreshPort`、结果模型和 Provider 兼容适配器，Style1/Style2 的目录刷新命令与运行中状态改由 application 端口承载；组合根继续委托现有 `BookProvider.refreshShelfToc`，保留并发去重、源解析、`onlyUpdateRead`、成功/失败/跳过统计和异常语义。独立宿主未注册端口时使用明确空实现，不影响生产组合。目录刷新定向 `14/14`，Flutter 全量 `1222` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；缓存、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 和暂停平台门禁不变，R6 尚未退出。
- 架构/Phase 4/R6 书单条目入库边界：新增 `BookshelfBooklistImportPort` 及兼容适配器，`ImportBookshelfDialog` 通过 application 端口执行解析后的书单入库；保留 JSON/URL 解析、共享书源列表、进度、added/skipped/failed 计数、日志和错误提示。定向 `2/2`，Flutter 全量 `1222` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。添加网址、目录刷新、缓存、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁未改变；R6 尚未退出。
- 架构/Phase 4/R6 添加网址入库边界：新增 `BookshelfUrlImportPort` 及兼容适配器，`AddBookUrlDialog` 不再直接读取 `BookProvider`；保留共享书源列表、逐 URL 进度、成功/失败计数、日志和异常提示。定向 `2/2`，Flutter 全量 `1222` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。书单导入、目录刷新、缓存、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁未改变；R6 尚未退出。
- 架构/Phase 4/R6 Style1/Style2 单本命令边界：书架样式页的行内分组与移除操作改用已验证的 `BookshelfArrangeGroupCommandPort`/`BookshelfArrangeDeleteCommandPort`，保留目录刷新、缓存访问和展示状态由 `BookProvider` 承担；组合根和测试宿主注入现有 Provider 适配器。Style 定向 `15/15`，Flutter 全量 `1222` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。未改变确认/取消、通知、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 书架菜单导出读取边界：`BookshelfMenuActions._exportList` 改用共享 `BookshelfArrangeSnapshotPort` 获取完整书架，保留空书架提示、JSON 导出端口、日志和成功/失败提示语义。新增导出行为回归；受影响定向 `23/23`，Flutter 全量 `1222` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。未改变添加网址、书单导入、书架写入、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 书架整理读取边界：新增同步 `BookshelfArrangeSnapshotPort`，整理页的初始化、分组过滤、排序和“导出全部书源”统一读取完整书架快照，不再直接读取 `BookProvider.books`；生产组合根通过兼容适配器接入现有 Provider 快照，独立测试宿主保留空快照和显式注入能力。新增不可变快照/动态快照回归，受影响定向 `19/19`；Flutter 全量 `1221` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。未改变分组过滤、排序隔离、导出完整书架、删除/分组命令、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 书架整理删除命令边界：新增独立 `BookshelfArrangeDeleteCommandPort` 及 Provider 回调适配器，整理页单本和批量删除不再直接读取 `BookProvider`。端口保持 `Future<void>`，成功后页面继续按原局部/筛选列表移除、清理对应选择并保存剩余顺序；取消或命令失败不改页面、不写排序。底层仍由 Provider/lifecycle controller 按输入顺序执行每本仓储删除与章节缓存清理，批量全部成功后只刷新、发布总线和通知一次；仓储、缓存或最终刷新中途失败时保留已完成副作用、停止后续且不伪造成功状态。受影响定向 `35/35`、Flutter 全量 `1220` 通过（`3` 项既有条件跳过），analyze、架构边界、Dart 格式和 diff 门禁通过。其他页面删除入口未迁移，R6 尚未退出。
- 架构/Phase 4/R6 书架整理“移除分组”命令边界：`BookshelfArrangeGroupCommandPort` 新增条件式 `clearBooksGroup`，页面不再直接循环调用 Provider；适配器保持输入顺序，并在每个 ID 前读取最新书架快照，非空条件精确匹配、空选择通配清空、不存在 ID 静默跳过。命中项仍逐本委托 `BookProvider.updateBookGroup`，因此每本成功分别刷新、递增 mutation version、发布 `BookshelfChangeBus` 并通知；中途失败保留前项副作用、停止后续并原样传播异常，不宣称原子批量操作。受影响定向 `37/37`、Flutter 全量 `1205` 通过（`3` 项既有条件跳过），analyze、架构边界、Dart 格式和 diff 门禁通过。删除命令仍保留兼容入口，R6 尚未退出。
- 架构/Phase 4/R6 书架整理分组命令边界：新增 `BookshelfArrangeGroupCommandPort` 及 Provider 回调适配器，行内单本“分组”、批量“移入分组”和“加入分组”经组合根注入的 application 端口执行，并使用写入后的不可变完整书架快照刷新页面。底层仍委托 `BookProvider`，保留 mutation version、`BookshelfChangeBus`、通知和异常传播；条件式“移除分组”与删除继续保留兼容入口。受影响定向 `25/25`、Flutter 全量 `1196` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。未修改 Rust、数据库、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；R6 尚未退出。
- 架构/Phase 4/R6 书籍基础信息字段级写入：新增 Rust/FRB/Dart `updateBookDetails` 链路，SQL 仅更新书名、作者、简介；详情页不再用旧页面快照整书 upsert，application 统一 trim/空书名回退，Provider 以最新书架记录合并三字段并发布快照。封面、来源、阅读配置、进度、章节索引和 UTF-16 章内位置保持不变；非书架不落库、失败不发布。Rust 定向 `2/2`、Rust 全量 `270/270`、Flutter 定向 `20/20`、Flutter 全量 `1188` 通过（`3` 项既有条件跳过）。FRB 生成后重建 release DLL，修复绑定内容哈希不一致，不改变业务测试。
- 修复/Phase 4/R6 书架整理排序隔离：`BookshelfArrangeOrderPolicy` 在没有已保存顺序时也返回独立列表，避免“全部分组 + 首次手动排序”直接修改 `BookProvider.books` 内部集合而绕过 mutation version、变更总线和通知。策略与真实拖动定向 `6/6`，Widget 回归同时证明页面顺序已改变且 Provider 顺序/数量不变；Flutter 全量 `1177` 通过（`3` 项既有条件跳过）。不改变排序持久化、分组、删除或书架快照语义。
- 架构/Phase 4/R6 书籍封面写入边界：新增 `BookMetadataController`，将详情页自动补全封面的字段级写入收口到 application 层；`BookProvider.updateBookCover()` 原位更新最新书架记录、递增 mutation version、发布完整快照并通知，防止在途旧 `loadBooks()` 覆盖新封面。页面保留非书架不落库和异常静默降级语义。定向 `12/12`，Flutter 全量 `1175` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub` 和架构边界通过。未修改 Rust、数据库 schema、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；整书基础信息保存留待下一独立批次。
- 架构/Phase 4/R6 书架重试命令统一：Style1/Style2 错误态重试统一调用 `BookProvider.loadBooks()`，通过共享快照回流 `BookshelfNotifier`，避免页面只更新 Riverpod 状态而留下 Provider 旧列表；重试期间页面同时观察 `BookProvider.isLoading`，保留原 loading 视觉语义。新增 Style1/Style2 延迟重试 loading 回归，书架相关定向 `41/41`，Flutter 全量 `1167` 通过（`3` 项既有条件跳过）。未改变目录刷新、缓存、删除、分组写入、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 书架只读状态与启动失败同步收口：`BookshelfStyle1Page`、`BookshelfStyle2Page` 的列表、分组、加载、错误、重试和空态改用共享 `BookshelfState`；目录刷新、更新中状态、缓存、删除和分组写入继续保留在 `BookProvider`。`BookshelfChangeBus` 增加带不可变书架快照和堆栈的失败事件，生产启动加载失败也能进入 `BookshelfNotifier.failure`，同时保留旧 `BookProvider.loadError` 和启动任务报告语义。书架相关定向 `39/39`，Flutter 全量 `1165` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 `legado-main/`、Rust、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁；当前提交不代表 BookProvider 写入/目录职责或 R6 全量退出。
- 架构/Phase 4/R6 书架快照同步前置收口：`BookshelfChangePort`/`BookshelfChangeBus` 携带不可变 `List<Book>` 快照和 revision，生产组合根将同一变更总线注入 `BookProvider` 与 `BookshelfNotifier`；Provider 在书架成功加载或写入并刷新完整列表后发布，Notifier 直接应用外部快照，并可从总线最新快照初始化而不重复读取数据库。`BookProvider.loadBooks()` 以请求号和 bookshelf mutation version 双重保护，旧异步读取不能覆盖较新的书架写入或内存维护结果；后台章节元数据和章节落库路径同步发布最新快照，失败写入不发布。书架同步相关定向命令覆盖七个测试文件，`25/25` 通过；Flutter 全量命令 `flutter test --no-pub --enable-experiment=dot-shorthands` 为 `1153` 通过（`3` 项既有条件跳过）；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。书架页面仍使用 `BookProvider`，尚未迁移 UI 只读状态；未修改 Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 书架读取职责继续收口：`BookProvider.loadBooks` 通过可选注入的 `BookshelfController` 读取书架，生产默认使用同一 `BookRepository` 的 `RepositoryBookshelfPort`，测试可注入隔离 controller；保留 loading、error、notify、维护开关及全部写入职责，旧调用方无需改动。新增读取委托与错误文本回归，定向 `2/2`，Flutter 全量 `1145` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未迁移书架页面、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 书架读取 application 边界：新增 `BookshelfPort`、`BookshelfController` 及 `RepositoryBookshelfPort`/`CoreApiBookshelfPort`，`BookshelfNotifier` 委托 controller 读取并保留 requestId、刷新旧列表、异常堆栈和不可变列表语义；生产组合根绑定同一 `BookRepository`，CoreApi 仅作为迁移/隔离测试 fallback。新增 controller 委托与异常传播回归，定向 `21/21`，Flutter 全量 `1143` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未迁移书架页面、BookProvider 其他职责、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 或暂停平台门禁。
- Flutter 3.44 兼容性收口：选择分组弹窗为 `CheckboxListTile` 增加透明 `Material`，排序列表切换到 `onReorderItem` 并移除旧回调重复索引修正；不改变布局、点击、分组或排序语义。相关定向 `10/10` 通过。
- 架构/Phase 4/R6 书架章节元数据 application 边界：新增 `BookshelfChapterMetaController`，统一章节数量与当前章节标题索引计算及最小字段 upsert；`BookProvider` 继续负责元数据缓存、书籍列表、后台异常隔离和通知。空章节仍清除公开缓存且不写入 `0`，标题不匹配仍回退持久化 `durChapterIndex`；写入前重新取当前书籍快照，防止启动维护覆盖并发更新的进度、页内 UTF-16 位置和正文相关字段。定向 `29/29`，Flutter 全量 `1137` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 `legado-main/`、Rust、目录刷新、正文、分页、章节身份、第 3 条断行规则、R1-12 和暂停平台门禁。
- 架构/Phase 4/R6 阅读进度写入 application 边界：新增 `BookProgressController`，当 `durChapterIndex` 非空且 `bookId` 与现有书籍一致时整书 upsert，否则调用仓储局部 `updateProgress`；`BookProvider` 继续负责列表刷新、章节元数据刷新和通知。`pageIndex` 原样保留，异常传播和 UTF-16 章内阅读位置语义不变；新增不一致身份回归，防止 upsert 错误书籍。进度/迁移/同步定向 `34/34`，Flutter 全量 `1129` 通过（`3` 项既有条件跳过），`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、第 3 条断行规则、R1-12 和暂停平台门禁。
- 架构/Phase 4/R6 书籍阅读元数据写入边界：新增 `BookRecordController`，统一 `readIteration` 和模拟追读字段的 Book 复制与仓储 upsert；`BookProvider` 保留当前书选择、列表刷新、通知和兼容返回值。书籍记录/书架/缓存定向 `20/20`，Flutter 全量 `1117` 通过（`3` 项既有外部网络条件跳过），`flutter analyze`、架构边界和 `git diff --check` 通过。契约验证阅读位置保持不变，未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、第 3 条断行规则、R1-12 和暂停平台门禁。
- 架构/Phase 4/R6 书架书籍生命周期边界：新增 `BookshelfBookLifecycleController`，统一书籍新增、删除时的仓储写入和章节缓存清理顺序；`BookProvider` 保留列表刷新、未读元数据清理、批量失败语义和通知职责，组合根显式注入 controller。生命周期/书架/缓存定向 `16/16`，Flutter 全量 `1115` 通过（`3` 项既有外部网络条件跳过），`flutter analyze`、架构边界和 `git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁。
- 架构/Phase 4/R6 书架分组写入边界：新增 `BookshelfBookGroupController`，由 application 层统一承载单本与批量分组写入及刷新；`BookProvider` 保留兼容入口并在组合根显式注入控制器，保持顺序写入、空批量刷新、异常传播和单次通知语义。控制器/Provider 定向 `9/9`，书架相关定向 `12/12`，Flutter 全量 `1113` 通过（`3` 项既有条件跳过），`flutter analyze`、架构边界、Rust 全量 `268/268`、`cargo fmt -p legado_engine -- --check` 和 `git diff --check` 通过。未修改 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 和暂停平台门禁。
- 架构/R1-12 真实非空 Room 证据补录：纳入 `.tmp/r1-device-room/original_legado.db` 只读副本，确认 Room v99、identity hash 与原版基线一致，且 `books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`。既有 `emulator-5556` all-phase smoke（`flutter test --no-pub integration_test/r1_android_room_import_smoke_test.dart -d emulator-5556`）通过 `1/1`，覆盖真实文件导入、章节 ID、持久化、重复导入、空备份路径和备份恢复。该证据关闭真实非空 Room 数据库缺失子项；不宣称 `readRecord` 统计语义或非核心 Room 表 Rust v17 业务化完成。
- 架构/Phase 4/R6 Provider 状态迁移第十二批：补齐 `SourceNotifier`、`RssNotifier`、`ReplaceNotifier`、`MyPageNotifier`、`AppConfigNotifier` 和 `RemoteBookNotifier` 的 Riverpod `dependencies`；清理已由组合根提供共享 controller 的重复局部 scope，Sources 管理、书源市场/编辑/调试和旧 Provider 兼容外观保持原行为。补齐两个直接挂载书架页面的测试宿主根 `ProviderScope`，最终受影响定向 `19/19`、宿主回归 `2/2`、Flutter 全量 `1104`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。
- 架构/R1-12 archive-only 产品边界状态统一：确认六张核心表导入后直接可用，`readRecord` 与非核心 Room 表无损归档，JSON 备份、事务回滚和幂等导入纳入完成范围；Room 定向 `29/29`、Rust 全量 `268/268`、`cargo fmt -- --check` 通过。明确不宣称 `readRecord` 统计语义、非核心表 Rust v17 业务化和真实原版非空数据库证据完成，真实证据补齐前不新增 R2-R6 生产实现。
- 架构/Phase 4/R6 Provider 状态迁移第十一批：AppConfig 新增 Freezed `AppConfigState`、共享 `AppConfigController` 和 `AppConfigNotifier`，`ConfigPage` 改用 Riverpod 订阅四项配置状态；保留既有 `AppConfig` 单例、SharedPreferencesRuntime、`load()` 并发去重、乐观持久化和启动兼容顺序。组合根将 `SourceController` 绑定到唯一 `SourceProvider.controller`，`BookInfoPage`、`BookmarkPage`、`ChangeSourcePage` 移除局部桥接，改用根级 Riverpod 状态；`BookProvider` 继续负责书籍、章节、阅读、目录和入库事实源。AppConfig 定向 `9/9`、Source 页面/组合根定向 `8/8`、Flutter 串行全量 `1100`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过；不改变 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 Provider 状态迁移第十批：RemoteBook 页面新增 Freezed `RemoteBookState`、共享 `RemoteBookController` 和 `RemoteBookNotifier`，集中管理 WebDAV 目录、筛选、排序、选择、请求失效保护和导入进度；`MyPage` 新增 Freezed `MyPageState`、`MyPageController` 和 `MyPageNotifier`，集中管理 Web 服务与本地备份状态。保留 `BookProvider` 书架事实源、本地文件/ZIP 导入、部分成功语义、页面生命周期和平台调用。受影响定向 `11/11`、Flutter 串行全量 `1093`（`3` 项既有条件跳过）、Freezed 生成、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过；AppConfig 仅完成只读边界审查，未迁移；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 Provider 状态迁移第九批：`SearchContentPage` 接入共享 `ReplaceController`，`BookshelfStyle1Page` 和 `BookshelfStyle2Page` 接入共享 `SourceController`；搜索页面继续保留搜索结果、取消、缓存和分页相关本地状态，书架样式继续由 `BookProvider` 负责书籍、分组、排序、目录刷新和持久化。新增回归测试并补齐书架测试宿主依赖。受影响定向 `8/8`、Flutter 串行全量 `1086`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过；RemoteBook 仅完成只读边界审查，未迁移；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 Provider 状态迁移第八批：`CacheBookPage`、`BookshelfArrangePage` 和 `ImportBookshelfDialog` 接入局部 Riverpod `ProviderScope`，书源查找、书源显示和书单导入前的书源选择复用共享 `SourceController`；`BookProvider` 继续负责书籍、缓存、导入、排序和持久化职责。新增页面回归测试并补齐未注入 `SourceProvider` 的测试宿主。受影响定向 `7/7`、Flutter 串行全量 `1083`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 Provider 状态迁移第七批：书签页、RSS 源编辑页和书架 URL 导入对话框接入共享 Riverpod Controller；书源查找、RSS 源保存和 URL 导入前的书源选择分别由对应 Notifier/Controller 提供状态，BookProvider 继续负责书签、书籍导入及入库职责。新增页面回归测试。受影响定向 `8/8`、Flutter 全量 `1080`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 Provider 状态迁移第六批：RSS 消费页、搜索/探索页、书籍详情页和换源页接入共享 Riverpod Controller；RSS 源筛选/收藏、书源搜索/探索、详情源信息和换源搜索分别由对应 Notifier/Controller 提供状态，BookProvider 继续负责书籍、章节、阅读和缓存。补充页面回归测试，并为未注入旧版 RssProvider 的图片测试宿主保留空 application controller fallback。受影响定向 `11/11`、Flutter 全量 `1078`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 Provider 状态迁移第五批：`SourceEditorPage`、`SourceDebugPage` 和 `RuleSubPage` 接入局部 Riverpod `ProviderScope`，复用共享 `SourceController`、`RssSourceController` 和 `ReplaceRulesController`；保存、书源校验及规则订阅导入改由对应 Notifier 驱动，保留六个编辑 Tab、调试参数/日志、规则订阅 JSON、自动更新、编辑删除重排和原版 UI 行为。新增三页面 Widget 回归测试。三页面定向 `19/19`、Flutter 全量 `1071`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。
- 架构/Phase 4/R6 书源管理子页面迁移：分组管理弹窗和书源市场接入同一 `SourceController` 的局部 Riverpod `ProviderScope`，分组 CRUD、市场源存在状态、单个添加和全部导入由 `SourceNotifier` 驱动；全部导入等待持久化完成后才提示和返回。新增异步市场 Widget 测试并修复局部 scope 外读取 Riverpod container 的运行时错误。Source 管理定向 `38/38`、Flutter 全量 `1067`（3 项既有条件跳过）、flutter analyze、架构边界检查和 git diff --check 通过；SourceEditor、SourceDebug、RuleSub、启动任务和规则订阅适配器继续使用兼容外观，不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、Room 导入或暂停平台门禁。
- 架构/Phase 4/R6 SourceProvider 状态迁移：新增 Freezed `SourceState`、共享 `SourceController` 和 Riverpod `SourceNotifier`，统一书源加载、CRUD、分组、JSON/URL 导入、搜索、图片请求头和校验状态；增加 load/search/validate 请求失效保护、内置源 single-flight 和嵌套不可变快照。旧 `SourceProvider` 保留共享 controller 的 ChangeNotifier 兼容外观，`SourcesPage` 改为在局部 `ProviderScope` 订阅 Riverpod 状态；选择排序、FilePicker、分享及未迁移消费者保持原边界。Source controller/Notifier/Provider 兼容定向 `25/25`、source Feature/Widget `10/10`、Flutter 全量 `1066`（3 项既有条件跳过）、flutter analyze、架构边界检查和 git diff --check 通过；不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、Room 导入或暂停平台门禁。
- 架构/Phase 3/5 并行批次：ReadStyleConfig、BookmarkSnapshot、NoteSnapshot 改为 Freezed 值对象，保留 JSON 默认值、构造参数、copyWith 和主题导入行为；init_engine 公开 FFI 错误统一为 AppError，FRB 生成绑定同步更新；QuickJS java.ajax 使用独立客户端和 5 秒 deadline，超时取消请求 future 并回收连接。新增模型、FFI 和 Windows 慢响应连接回归；Rust 全量 268/268、Flutter 全量 934（3 项既有条件跳过）、flutter analyze --no-pub 通过。getStrResponse、WebView 宿主阻塞、Riverpod 生产页面、编码统一和暂停平台仍未完成；不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- 架构/Phase 3 剩余领域模型并行收敛：ClickZoneLayout、RuleSub、BookSourceValidationSnapshot 和 LegacyRoomImportReport 改为 Freezed，保留点击区行为、规则订阅 JSON/ID 语义、源校验聚合 getter，以及 Room 导入报告的严格解析和中文错误文本。定向 `42/42`、Flutter 全量 `997`（3 项既有条件跳过）、build_runner、flutter analyze、架构边界检查和 git diff --check 通过。本批不改变 Room 导入、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则或暂停平台。
- 架构/Phase 3 端口 DTO 并行收敛：应用 HTTP 文本/二进制响应、书源调试、本地 TXT/EPUB 解析与远端 ZIP 文件 DTO 改为 Freezed，保留端口签名、原始字节、顺序和异常文本。定向及既有 FRB/服务回归 `21/21`、Flutter 全量 `1009`（3 项既有条件跳过）、build_runner、flutter analyze、架构边界检查和 git diff --check 通过；不改变 HTTP 请求、调试、解析、正文、目录、分页、章节身份或 UTF-16 阅读位置。
- 架构/Phase 3 端口 DTO 并行收敛续批：本地备份条目、正文替换规则输入、RSS 结果和书源网页验证请求/结果改为 Freezed，保留端口签名、默认值、取消异常和正文处理边界。修复可再生 build_runner 资产图缓存后，owner 定向/既有回归 `24/24`、Flutter 全量 `1021`（3 项既有条件跳过）、flutter analyze、架构边界检查和 git diff --check 通过；不改变正文、断行、第 3 条断行规则、分页、章节身份或 Room 导入。
- 架构/Phase 3 application 模型并行收敛：章节进度、诊断、漫画配置和书源登录模型改为 Freezed；保留 UTF-16 章节位置裁剪、诊断敏感信息隔离、漫画配置默认值与 `isIdentity`、登录表单/脚本默认参数及端口签名。补齐 Freezed 默认参数标注后，owner 定向 `14/14`、Flutter 全量 `1035`（3 项既有条件跳过）、build_runner、flutter analyze、架构边界检查和 git diff --check 通过；不改变正文、目录、分页、章节身份、第 3 条断行规则或 Room 导入。
- 架构/Phase 3 application 状态模型并行收敛：阅读页范围、主题槽覆盖、订阅导入结果和启动任务报告改为 Freezed，保留 UTF-16 半开区间、图片路径清除、订阅顺序/名称回退及任务并发/超时/重试。owner 定向 `20/20`、Flutter 全量 `1048`（3 项既有条件跳过）、flutter analyze、架构边界检查和 git diff --check 通过。
- 架构/Phase 3 application 状态模型并行收敛续批：BookshelfState、ReadingSessionDelta 和 DetailedReadingSession 改为 Freezed，保留书架刷新/并发状态、列表防御性复制、UTF-16 阅读会话和 120 秒阈值。owner 定向 `14/14`、Flutter 全量 `1054`（3 项既有条件跳过）、flutter analyze、架构边界检查和 git diff --check 通过；AppBootstrapResult 保持组合根容器边界。
- 架构/Phase 3 领域模型并行收敛：WebApiStatus、WebDavEntry、BookProgress、ThemeTypography、RssArticle、RssSource、DictRule、TxtTocRule、CrashReport 和 DiagnosticRecord 改为 Freezed，保留原有 JSON、默认值、兼容解析、规则身份和 UTF-16 阅读位置语义；CrashRuntimeMetadata、DiagnosticRuntimeInfo 保留 `const ...unavailable()` 兼容构造并补齐值语义。owner 定向 `23/23`、Flutter 全量 `955`（3 项既有条件跳过）、build_runner、flutter analyze、架构边界检查和 git diff --check 通过。本批不改变 Rust/R1-12、正文、目录、分页、章节身份、第 3 条断行规则、真实 Android TTS 或暂停中的 Web/WASM/PWA。

- 架构/Phase 3 阅读统计模型：`BookReadingStats`、`ReadingStats`、`DailyReadingStat` 改为 Freezed；新增值语义契约，`BookReadingStats.readingDays` 默认 `0` 并由 FRB 书票适配器原样转发 Rust 值。定向 `12/12`、Flutter 全量 `925`（`3` 项既有条件跳过）通过；不改变统计查询、页面计算或正文行为。
- 架构/Phase 3 替换规则模型：`ReplaceRule` 改为 Freezed 值对象，保留旧 JSON 默认值、构造参数与 `toJson` 输出，新增值相等和 `copyWith` 契约测试。替换规则定向 `11/11`、Flutter 全量 `923`（`3` 项既有条件跳过）通过；不改变替换规则匹配、正文净化、断行、第 3 条断行规则或 Rust FFI。
- 架构/Phase 3 Rust 书籍 DTO：新增 `BookDto` camelCase serde 投影，`get_books_json()` 改为通过 DTO 输出，保留 `db_get_books()` 的 `Vec<String>` FRB/Flutter 兼容接口。新增 DTO serde 与完整数据库行映射测试，覆盖 `readConfig`、阅读位置、模拟阅读和 `updatedAt`；定向 `3/3`、Rust 全量 `265/265`、Flutter 全量 `922`（`3` 项既有条件跳过）通过。本批未新增 typed FFI，不改变 Room 导入、正文、目录、分页、章节身份或 UTF-16 阅读位置。
- 架构/Phase 3 Flutter 模型契约：`Book` 与 `BookSource` 改为 Freezed 领域模型，保留原版 JSON 字段、`readConfig` 兼容解析、嵌套书源规则和 `toEngineJson`；新增 const/值相等/`copyWith` 契约测试。模型及相关书架/书源仓储、Provider 定向回归 `28/28`，全量 Flutter `922` 项通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过。Rust 独立书籍 DTO、Riverpod 生产页面和其余手写模型仍未迁移，本批不改变 Room 导入、正文、目录、分页、章节身份或 UTF-16 阅读位置。
- 架构/Phase 3 Rust 书源 DTO：新增 `BookSourceDto` serde camelCase 投影和 `BookSource::to_dto()`，与 Flutter `BookSource` 共享稳定字段；`rawSourceJson` 原样保留，分页字段按既定回退顺序映射。DTO 定向 `1/1`、Rust 全量 `263/263`、`cargo fmt -p legado_engine` 通过；暂不新增 FFI 入口，Rust `Book` DTO、生产联调和其余手写模型仍未完成。
- 架构/R1-12 产品决策与门禁收口：旧版 Legado 数据必须能够导入，六张核心业务表导入后直接可用；`readRecord` 与非核心 Room 表暂不业务化，但必须无损 archive-only 保存，不得因未映射而拒绝导入或丢弃原始行；导入前备份沿用原版 JSON 逻辑备份，不增加文件级 SQLite 备份要求。Room 定向 `29/29`、Rust 全量 `262/262`、Flutter 导入/备份定向 `17/17`、analyze、架构边界和 diff 检查通过，R1-12 按该边界完成。
- 架构/R1-12 真实 Android Room v99 证据：使用 `emulator-5556` 上原版 `io.legado.app.debug` `3.26.072317debug` 的真实 `databases/legado.db`，确认 `user_version=99`、identity hash 正确，源数据包含 `books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`。重构版 all-phase smoke 通过，覆盖真实字段映射、876 个章节 UTF-16 FNV-1a ID、持久化、重复导入幂等、`backupPath=null` 和备份恢复。验证：`flutter test --no-pub integration_test/r1_android_room_import_smoke_test.dart -d emulator-5556` 通过 `1/1`。R1-12 仍不最终退出，`readRecord` 产品统计语义和非核心表业务化保持 archive-only 边界。
- 架构/R1-12 类型降级端到端证据：新增真实 SQLite 文件导入回归，确认异常数值、REAL 布尔列和非法时间会进入 `LegacyRoomImportReport.warnings`，而 `rawSnapshotJson` 保留原始 SQLite 值。验证：Room 定向 `29/29`、Rust 全量 `262/262`、`cargo fmt -p legado_engine` 通过。本批不关闭 R1-12。
- 架构/R1-12 映射安全补强：章节继续使用与 Flutter `Chapter.idFor` 一致的 UTF-16 FNV-1a ID，并拒绝同一批次中相同 ID 对应不同书籍/URL/标题，避免静默覆盖；核心 Room 字段遇到异常 SQLite 类型时保留兼容映射结果，同时在导入报告登记包含表、列、稳定行标识、期望/实际类型的 warning，原始快照不改写。新增回归覆盖非法数值、REAL 布尔列、数组文本、非法时间和布尔字符串；`cargo fmt -p legado_engine`、Room 定向 `28/28`、Rust 全量 `261/261` 通过。本批不关闭 R1-12；真实非空 Room 数据库证据、`readRecord` 产品统计语义和非核心表业务化仍未完成。
- 架构/R1-12 并发一致性补强：Room 源库读取统一使用单一只读事务快照；fingerprint 去重检查与导入写入统一纳入 `BEGIN IMMEDIATE`；导入前备份使用唯一临时文件、`sync_all` 和不覆盖提交，避免并发覆盖与 TOCTOU。验证：Room 定向 `26/26`、数据库定向 `28/28`、Rust 全量 `259/259`、`cargo fmt -p legado_engine` 通过。所有 Android 操作统一使用 `emulator-5556`，真实非空 Room 源库证据仍未完成。
- 架构/R1-12 幂等与归档覆盖补强：完全相同的 `detailedReadRecord` 会话在新的 Room snapshot fingerprint 下不重复写入；报告明确 `readRecord` 原始计数、archive-only 表归属、四个未映射列和 warning；非核心 archive-only fixture 为每张归档表补充代表性非空行，冲突统计明确不包含 `readRecord`、`readingRecords`、`detailedReadRecords`。验证：Rust Room `25/25`、Rust 全量 `256/256`、release 构建、Flutter 导入报告 `10/10`、Flutter 全量 `916`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。emulator-5556 当前在线，但原版 `io.legado.app.releaseS` 为不可调试 release 包，数据库目录无权限读取；外部 `backup.zip` 仅含配置，不含 Room 数据库，Android smoke 与真实原版非空 Room 证据仍未完成，真实数据和 R1-12 产品决策边界仍未关闭。
- 架构/R1-12 Dart 导入端口契约补强：`backupPath` 在 Dart port、use case 和 FRB adapter 中与 Rust `Option<String>` 对齐；重复导入允许 `backupPath=null` 并保留 `backupWritten=false`，首次导入缺少备份路径仍由 Rust 拒绝。新增 application 定向测试覆盖可空路径转发和下游拒绝。验证：Flutter 导入报告 `12/12`、Flutter 全量 `917`（`3` 项既有条件跳过）、`flutter analyze --no-pub` 通过。本条不关闭 R1-12。
- 架构/R1-12 跨层报告与 Android smoke 契约补强：主机侧报告测试固定 Rust serde 输出的 13 个字段、基础类型和 nullable 分支；Android smoke 增加真实 application → FRB → generated API 的重复导入 `backupPath=null` 断言，保留目标业务书籍和 `legacyRoomImports` 归档数量不增加断言。验证：Flutter 导入报告 `13/13`、Flutter 全量 `918`（`3` 项既有条件跳过）、`flutter analyze --no-pub` 通过；真实 Android smoke 因原版 release 包数据库目录无权限读取未执行，本条不关闭 R1-12。
- 架构/R1-12 报告失败契约与回滚证据补强：`LegacyRoomImportReport` 对 Rust 输出的必需字段执行严格类型/缺失校验，避免损坏报告静默显示为零行成功；`sourceRoomIdentityHash`、`backupPath` 仍保持旧报告缺失兼容，未知字段继续向前兼容。Android smoke 补充重复导入 `backupWritten=false`、不创建新备份且目标书籍/归档数量不增加的断言；Rust 失败回滚测试解析导入前备份并确认原有书籍和归档内容保留。验证：报告定向 `10/10`、Rust Room `24/24`、Rust 全量 `255/255`、Flutter 全量 `912`（`3` 项既有条件跳过）、analyze、架构边界扫描和 `git diff --check` 通过；Android smoke 因设备不可用未执行。真实原版非空数据库和 R1-12 产品决策边界仍未关闭。
- 架构/R1-12 导入报告与事务边界补强：Flutter 报告模型补齐 `sourceRoomIdentityHash`、`backupPath` 并保持旧 JSON 向前兼容，测试键名统一为 Rust 实际输出的 `sources`、`detailedReadRecords`、`replaceRules`，重复导入明确断言 `backupWritten=false`。Android smoke 增加 23 张 Room v99 实体表精确集合、逐表行数和 archive-only 集合校验。Rust 增加未 checkpoint WAL/SHM 源库字节级只读回归、`replace=true` 成功替换及导入前备份内容回归；保留 `readRecord` archive-only、详细阅读记录阈值和原始快照边界。验证：Flutter 报告定向 `6/6`、Rust Room `24/24`、数据库 `26/26`、Rust 全量 `255/255`、Flutter 全量 `912`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。Android smoke 因设备不可用未执行；真实原版非空 Room 数据库、阅读统计产品语义、非核心表业务化和文件级 SQLite 备份目标仍未关闭。
- 架构/R1-12 阅读记录与替换规则归档边界复核：owner 工作树完成 Room 定向 `23/23`、数据库定向 `24/24`、Rust 全量 `252/252`、Flutter 全量 `912`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构扫描和 `git diff --check`。Rust v17 阅读记录 CRUD、统计和导出能力已完成；legacy Room `readRecord` 明确采用 archive-only 保存并纳入导入报告原始计数，继续不写入 Rust v17 阅读统计业务表。`detailedReadRecord` 原始行及 Room 自增 `id` 保留在 `raw_snapshot_json`，业务映射按书名聚合为 sessions，聚合后的 session 不保留 Room 自增 `id`；`replace_rules.sortOrder`、`scope`、`group` 仅保留在原始归档，不进入当前 Rust v17 替换规则业务映射。真实原版非空数据库、legacy `readRecord` 最终产品统计语义、非核心表业务化和文件级 SQLite 备份目标仍未关闭，因此 R1-12 继续处于复核中。
- 架构/R1-12 书源规则落库补强：`upsert_source_json` 现在在保留 `rawSourceJson` 的同时，将嵌套 `ruleSearch`、`ruleBookInfo`、`ruleToc`、`ruleContent` 规则按“已有扁平字段优先、嵌套字段回退”写入 Rust v17 已有业务列；`rulePageNext` 支持扁平字段、目录分页和正文分页的确定性回退。新增书源规则扁平列断言、书籍/章节/书源实际落库断言，并明确章节 `wordCount` 仅保留在 Room 原始归档。Rust Room `22/22`、数据库 `24/24`、Rust 全量 `251/251`、Flutter 全量 `912`（`3` 项既有条件跳过）、analyze、架构扫描和 `git diff --check` 均通过；真实原版非空数据库、阅读统计语义、非核心表业务化和文件级备份目标仍未关闭。
- 架构/R1-12 Dart 报告契约补强：重复导入报告新增 `archiveOnlyTables`、`warnings`、`unmappedColumns` 空集合断言，并验证未知字段可向前兼容且不改变已支持字段。Flutter Room 定向测试 `6/6` 通过。
- 架构/R1-12 迁移证据继续补强：Rust Room 七张核心表新增逐字段 golden 断言，覆盖书籍、书源规则、章节身份与元数据、书签、`readRecord`、详细阅读记录和替换规则；Flutter 导入报告补充核心表计数、保留行、归档表、告警、未映射列、指纹及重复导入幂等断言。修正 `books.originName` 未进入 Rust v17 业务映射却被报告为已映射的问题，现明确列入 `unmappedColumns`。Rust `21/21`、Flutter Room 定向 `5/5`、Rust 全量 `249/249`、Flutter 全量 `911`（`3` 项既有条件跳过）、analyze、架构扫描和 `git diff --check` 均通过；真实原版非空 Room 数据库、`readRecord` 业务语义、非核心表业务 port 和文件级 SQLite 备份仍未关闭。
- 架构/R1-12 并行测试补强：Room 成功/失败导入回归同时比较主库、`-wal`、`-shm` 文件状态；Dart 导入报告新增 `counts`、`preservedRows`、`archiveOnlyTables`、`warnings`、`unmappedColumns` 和 fingerprint 全字段解析测试。Rust 定向 `21/21`、Dart 定向 `3/3` 通过。
- 架构/R1-12 `emulator-5556` Android smoke：debug 重构 APK 已安装到 `com.legado.legado_flutter`；基于原版 Room v99 schema 生成的临时非空等价 fixture（七张核心表各 1 行，user_version/identity hash 一致）完成 import/verify 两阶段。新增设备端断言覆盖书籍字段、`bookUrl -> sourceUrl`、`origin -> bookSourceUrl`、UTF-16 阅读位置语义、`readIteration`、章节 FNV-1a ID、重启读取、重复导入幂等和备份恢复；两阶段均通过。该证据不替代真实原版非空数据库。
- 架构/R1-12 Android smoke 门禁补强：导入阶段新增 fingerprint 非空及 `books`、`sources`、`chapters` 正行数断言，空库或无核心映射行不会再被登记为真实非空迁移通过；未改变导入、持久化、重复导入幂等和备份恢复行为。
- 架构/R1-12 当前状态复核：R1 已重新打开。Kotlin Room v99 → Rust v17 当前只确认核心七表业务映射与 23 个 Room 实体表全量原始归档；本批新增 v99 版本/identity hash 门禁、备份保护、正冲突、归档恢复、JSON 恢复事务性、既有数据回滚、非核心 fingerprint 稳定性、缺失实体表结构、实体 table-only、非法 UTF-8 无损和源库文件字节级只读边界测试，Room 定向 `21/21`、Rust 全量 `249`、release、`flutter analyze --no-pub` 和 Flutter 全量 `908`（`3` 项既有条件跳过）通过。缺失实体表或 view 冒充实体会在读取行前拒绝，非法 UTF-8 不进行 lossy 替换且不会产生目标写入。当前七张核心表为空，`book_groups` 有 7 行，`keyboardAssists` 有 14 行；`readRecord` 仍仅 warning，非核心表仍 archive-only。`emulator-5556` 只安装原版包，未安装重构 APK，真实非空迁移验收无法执行；不把 23 张表写成全部 Rust v17 业务迁移，也不把 R1/R2/R6 历史实现记录写成当前阶段退出。R1-12 复核完成前不推进新的 R2-R6 实现。
- R1-12 schema 形状审计：只读对照原版 `99.json` 与仓库 `original_legado.db`，23/23 个实体表的列集合均一致，无缺列或额外列；唯一 view 为 `book_sources_part`。当前七张核心表均为空，`book_groups` 有 7 行，`keyboardAssists` 有 14 行；该结果仅证明 schema 形状和当前样本数据分布，不构成真实非空核心数据迁移证据。
- 架构/R1-12 结构与备份边界补强：`readRecord.lastRead` 纳入最低结构门禁，仍保留 `deviceId/bookName/readTime/lastRead` 原始快照，不写入 Rust v17 业务统计表；导入前备份写入失败时清理临时路径且不触碰预存在路径。Room 定向 `21/21`、Rust 全量 `248`、release、架构扫描和 `git diff --check` 通过。`readRecord` 的设备维度、书名聚合和 `lastRead` 最大值语义仍需产品目标模型后再迁移。
- 架构/R1-12 归档无损补强：现有 23 表 archive-only 归档/导出/恢复回归新增 BLOB 字节数组断言，验证合法 SQLite BLOB 经 `rawSnapshotJson` 往返保持一致；非法 UTF-8 仍明确拒绝。真实非空 Room 数据库迁移证据仍未关闭。
- 架构/R1-12 并行回归补强：`readRecord` 四字段原始快照/导出/恢复与不写入 `reading_records` 回归通过；重复 fingerprint 导入验证不写新备份且不改变既有数据库/备份；成功导入和非法 UTF-8 失败均验证源库文件字节与大小不变。Room 定向 `21/21`、数据库定向 `23/23`、Rust 全量 `249`、release、架构扫描和 `git diff --check` 通过。`emulator-5556` 在线但只安装原版 `io.legado.app.releaseS`（`3.26.071309`），未安装重构包，真实非空迁移验收仍无法执行。
- 架构/浏览器宿主错误边界与 WebView 生命周期：`serve_source_browser_host`、`probe_source_browser_host` 统一返回 `AppError`，取消映射 `Cancelled`，不支持平台映射 `Unsupported`，宿主停止/锁失败/线程失败保留原文并映射 `Unknown`；浏览器宿主 abort/clear 后不留下 stale sender，重启后使用新宿主。`AppWebViewPage` 在 dispose 后不再派发新的 Cookie 回调，同时保留完成验证时等待 Cookie 同步、抓取 DOM、返回 finalUrl/body 的成功路径。验证：Rust `browser_host` 定向 `7/7`、Dart 浏览器宿主/WebView 定向 `8/8`、Rust 全量 `234`、Flutter 串行全量 `908` 通过，另有 `3` 项既有条件跳过；release 构建、`flutter analyze --no-pub`、架构扫描和 `git diff --check` 通过。本批不改变正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、WebDAV、平台验收或阶段退出条件。
- 架构/重复公开 FRB 入口收敛：将 `search/explore/toc/debug/validate` 子模块实现降为 `pub(crate)` 并标记 `frb(ignore)`，保留根 `api/mod.rs` wrapper 作为唯一公开 FRB 契约；生成绑定移除子模块重复 Dart/Rust wire 导出，并删除陈旧子模块 Dart wrapper，不改变根 API 参数、返回值、`AppError` 分类、正文、目录顺序、分页、章节身份或 UTF-16 阅读位置。验证：`cargo fmt -p legado_engine`、Rust 全量 `228`、release 构建、`flutter analyze --no-pub`、Flutter 全量 `903` 通过且 `3` 项既有条件跳过，架构扫描和 `git diff --check` 通过。本批不覆盖浏览器宿主、WebDAV、平台验收或阶段退出条件。
- 架构/正文处理 FFI 错误边界：`process_content_for_reading` 统一返回 `AppError::Parse`，保留成功输出、替换规则、段落缩进、标题合并和重新分段行为；FRB codec 已同步为结构化错误，新增 Rust 与 Dart mock 契约测试覆盖成功转发和 Parse 原文保留。Rust 定向 `2/2`、Dart 定向 `2/2`、Rust 全量 `228`、Flutter 全量 `903` 通过，另有 `3` 项既有条件跳过；release 构建、`flutter analyze --no-pub`、架构扫描和 `git diff --check` 通过。本批不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则，也不覆盖浏览器宿主、重复公开 FRB 子模块入口、WebDAV、平台验收或阶段退出条件。
- 架构/登录头预热 FFI 错误边界：`seed_login_header` 统一返回 `AppError`，保留 source URL/header trim、空值忽略、缓存写入和无 dirty 更新行为；最终 FRB 只保留三处最小 codec/API 差异。Rust 定向 `3/3`、Rust 全量 `226`、Flutter 定向 `2/2`、Flutter 全量 `901` 通过，另有 `3` 项既有条件跳过；release 构建、analyze、架构扫描和 `git diff --check` 通过。生成器的 Windows 文件映射锁警告未纳入无关全量漂移，浏览器宿主和其它公开字符串错误入口仍未完成。
- 架构/JavaScript 执行 FFI 错误边界：`eval_js` 统一返回 `AppError::JsExecution`，保留脚本成功结果、错误原文、纯 QuickJS 5 秒 interrupt 和 `script/jsLib` 256 KiB 输入限制；FRB 已重新生成。Rust 定向 `2/2`、Rust 全量 `226`、Flutter 定向 `2/2`、Flutter 全量 `899` 通过，另有 `3` 项既有条件跳过；release 构建、analyze、架构扫描和 `git diff --check` 通过。`java.ajax`、`getStrResponse`、WebView 宿主阻塞、浏览器宿主和其它公开字符串错误入口仍未完成。
- 架构/本地书籍与 RSS 公开 FFI 错误边界：`parse_epub`、`parse_remote_archive_book_files` 使用 `AppError::Parse`，`get_rss_articles`、`get_rss_content` 使用 `AppError::Network` 或 `AppError::Parse`；保留成功行为、错误原文、解析/大小/路径安全/文件筛选、排序/分页/文章字段/正文解析和既有限制。FRB 已重新生成，Dart 适配层提取 `AppError.field0`，避免错误文本变为 Freezed `toString()`。Rust RSS 定向 `4/4`、Rust 全量 `224`、Flutter 适配器定向 `10/10`、Flutter 全量 `897` 通过，另有 `3` 项既有条件跳过；release 构建、analyze、架构扫描和 `git diff --check` 通过。浏览器宿主、QuickJS 宿主阻塞、其它公开字符串错误和阶段退出条件仍未完成。
- 架构/公开 FFI 错误边界：将 `get_book_info`、`query_dict_rule`、笔记和书签入口迁移到 Rust `AppError`，保留详情/字典成功结果、数据库 CRUD、Markdown、排序、UTF-16 位置和错误原文；目录/校验内部使用 `AppError::into_legacy` 保持旧错误文本过渡。FRB 已重新生成；Rust 全量 `218`、Flutter 全量 `894` 通过，`3` 项既有条件跳过，`flutter analyze --no-pub`、架构扫描和 `git diff --check` 通过。RSS、EPUB、浏览器宿主及其它公开 `Result<T, String>` 入口仍未迁移，本批不新增 R1-12、R2 或 R6 阶段退出声明。
- 架构/QuickJS 与数据库初始化边界：统一 Rust QuickJS 脚本入口的 Runtime，增加 5 秒纯 QuickJS 执行 interrupt 和 `script/jsLib` 单项 256 KiB 输入上限；在 `rust/` 工作目录执行 `cargo test -p legado_engine rule::js_engine::tests -- --nocapture` 为 `29/29` 通过。该 interrupt 不覆盖 `java.ajax`、`getStrResponse` 或 WebView 宿主阻塞，完整宿主端到端超时仍未完成。
- 架构/数据库初始化契约：`init(app_dir)` 固定使用 `app_dir/legado.db`，拒绝空路径和文件路径，同目录幂等、异目录拒绝，初始化锁覆盖首次并发调用，schema 初始化使用事务且失败不发布；FRB 已重新生成，`LegadoDbBridge` 已切换到应用数据目录入口。Rust 数据库定向 `19/19`、Rust 全量 `208` 通过，`flutter test --no-pub test/services/backup_service_test.dart` 为 `10/10` 通过，Flutter 全量 `894` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构扫描、`cargo fmt -p legado_engine` 和 `git diff --check` 均通过。本批不新增 R1-12、R2 或 R6 阶段退出声明。
- 架构/网络错误边界扩展：将裸 `http_fetch`、网络配置、Cookie 和 HTTP trace FFI 入口统一为 Rust `AppError`，保留请求参数、Cookie 域规则、trace 和错误原文语义；Rust API 定向 `57/57`、全量 `202` 通过，Windows FRB HTTP 集成 `2/2`，Flutter 全量 `894` 通过、`3` 项既有条件跳过，analyze/架构边界/diff 检查通过，并重新生成 FRB。QuickJS 超时、统一初始化、书架生产 Riverpod 和其它公开字符串错误入口仍未完成。
- 架构/网络 FFI 错误边界：将公开的文本抓取、应用 HTTP 文本请求和应用二进制请求迁移到 Rust `AppError`，保留原请求与错误文本语义；新增 `Validation`、`Parse`、`Network` 分类回归，Rust 网络定向 `9/9`、全量 `199` 通过，Windows FRB HTTP 集成 `2/2`，Flutter 全量 `894` 通过、`3` 项既有条件跳过，analyze 通过，并同步重新生成 FRB。其它网络配置/Cookie、裸 HTTP、RSS、JS、笔记和书签入口仍按后续批次迁移。
- 架构/模型与状态样板：在已有 `SearchResultItem` Freezed 镜像基础上，补充 `BookReadConfig`、`BookGroup`、`Chapter` 的 Freezed 定义与兼容映射；新增 `BookshelfNotifier`，覆盖初始、加载、成功、失败、刷新保留旧数据、并发旧结果丢弃和不可变列表，定向 `8` 项通过。Book/BookSource 仍未全部迁移。
- 架构/FFI 追溯：`debug_search`、`debug_toc` 和 23 个数据库入口已接入 Rust `AppError`，FRB 生成链已恢复并验证；Rust 全量 `192` 项通过，Flutter 串行全量 `894` 项通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构扫描和 `git diff --check` 均通过。运行时曾由过期 debug DLL 暴露 FRB 错误标签不匹配，重建 `rust/target/debug/legado_engine.dll` 后定向/全量恢复通过；生成器的 SDK `3.11.0`/analyzer `3.9.0` 版本提示为非阻塞警告，其它公开 FFI `Result<T, String>` 仍按计划继续迁移。
- 架构/组合根：生产组合根通过 ProviderScope 注入真实 `RealCoreApi`，复用现有 Book/BookSource Repository 与书源端口；书架页面仍保留 `BookProvider` 单一事实源，未提前切换到 `BookshelfNotifier`，避免刷新、删除和分组命令出现双状态。
- 架构/统一错误边界：将 `validate_source` FFI 入口迁移到 Rust `AppError`，保留书源校验返回字段和失败语义；同步重新生成 FRB 绑定并更新错误断言。验证：Rust `186` 通过，Flutter 全量 `879` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构扫描和 `git diff --check` 通过。
- 架构/并行推进：主线将 `explore`、书籍详情、目录、正文和下一章正文 FFI 入口迁移到 Rust `AppError`，同步更新 FRB 生成绑定和既有错误断言；子线新增 `flutter_riverpod` CoreApi Notifier/Provider 样板及 3 项测试，另一子线新增 Rust/Flutter/架构边界 CI。验证：Rust `186` 通过，Flutter 全量 `879` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构扫描和 `git diff --check` 通过。
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

- R2 历史阶段记录：曾完成 `java.startBrowserAwait` 可见 WebView 宿主实现并记录对应验证结果。该历史记录不作为当前 R2 最终退出判定；后台 `java.webView*`、文件/压缩及其它第三方宿主 API 仍保留在兼容性 backlog，且 R1-12 复核完成前不得推进新的 R2 实现。

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

- R1 历史阶段记录：曾完成领域模型归属收尾。`BookProgress` 迁入纯 domain，带时钟的 `fromBook` 创建移入 application factory，WebDAV JSON 字段、UTF-16 章内位置和冲突比较不变；登录行 UI DTO 迁入 application，书源校验结果迁入 domain，默认校验词策略迁入 application，旧 `lib/models` 路径仅保留兼容导出。合并定向回归 `46/46`，Flutter 串行全量 `578` 通过（`3` 项按既有条件跳过），Rust `legado_engine` 全量通过，Android Room v99 两阶段 Driver smoke 曾通过；当前 R1 因 R1-12 重新打开，不据此宣称最终退出。

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
- R1-12 历史阶段记录：曾记录 Kotlin Room v99 → Rust v17 的只读探针、核心映射、23 表稳定快照、archive-only 保存、事务/备份/回滚/幂等和 FRB/Dart 入口；该记录不等于 23 张表全部完成 Rust v17 业务迁移。当时的复核点只确认核心七表业务映射 + 23 表全量原始归档；`readRecord` 仍仅 warning，非核心表仍 archive-only，真实非空 `original_legado.db` 证据仍缺失。最新 owner gate 以本节顶部 2026-08-02 R1-12 补强记录为准。
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
2026-08-05 Phase 4/R6 书架整理 SourceController 显式注入收口：`BookshelfArrangePage` 移除页面内旧 `SourceProvider` 依赖，生产组合根继续提供共享 scope，测试宿主显式注入 controller；保留源标签刷新、分组、删除、排序和选择状态。定向 `18/18`；`flutter analyze --no-pub`、架构边界、Flutter 全量 `1280`（`3` 项既有条件跳过）通过；待完成 `git diff --check` 后创建中文本地提交，不自动 push。

2026-08-05 Phase 4/R6 书架整理 SourceController 边界：`BookshelfArrangePage` 移除页面内直接依赖旧 `SourceProvider`，增加可选 `SourceController` 显式注入；生产环境继续使用组合根共享 scope，测试宿主显式注入 controller。保留源标签刷新、分组、删除、排序和选择状态行为。定向 `18/18`；`flutter analyze --no-pub`、架构边界、Flutter 全量 `1280`（`3` 项既有条件跳过）通过；待完成 `git diff --check` 后创建中文本地提交，不自动 push。

2026-08-05 Phase 4/R6 探索页 SourceController 边界：`ExploreListPage` 移除页面内直接依赖旧 `SourceProvider` 和嵌套 Riverpod scope，统一由生产组合根/测试宿主提供共享 `SourceController`；保留当前书源、探索请求、结果映射和书架过滤行为。定向 `1/1`；`flutter analyze --no-pub`、架构边界、Flutter 全量 `1280`（`3` 项既有条件跳过）通过；待完成 `git diff --check` 后创建中文本地提交，不自动 push。

2026-08-05 Phase 4/R6 书架导入对话框 SourceController 边界：`AddBookUrlDialog` 与 `ImportBookshelfDialog` 移除页面内直接依赖旧 `SourceProvider` 和嵌套 Riverpod scope，统一由生产组合根/测试宿主提供共享 `SourceController`；保留源列表读取、网址导入、书单解析、进度和错误提示。定向 `4/4`；`flutter analyze --no-pub`、架构边界、Flutter 全量 `1280`（`3` 项既有条件跳过）通过；待完成 `git diff --check` 后创建中文本地提交，不自动 push。

2026-08-05 Phase 4/R6 目录持久化边界：新增 `TocPersistencePort`，`TocSheet` 的书籍状态读取、倒序目录章节保存和书籍状态保存改通过 application 端口；生产组合根继续复用同一 `BookRepository`，缓存元数据改从已注册 `ChapterContentCachePort` 读取，保留 `bookRepository` 显式兼容参数。目录定向 `15/15`；`flutter analyze --no-pub`、架构边界、Flutter 全量 `1280`（`3` 项既有条件跳过）通过；待完成 `git diff --check` 后创建中文本地提交，不自动 push。

2026-08-05 Phase 4/R6 书籍详情阅读启动与书源访问边界：`BookInfoPage` 的书源匹配改用既有 `ReaderSourceAccessPort`，阅读入口从 `BookshelfMembershipPort` 读取最新书架书籍，移除对 `BookProvider.books` 的直接读取；移除未使用的 `Consumer<BookProvider>` 展示包装，保留书源状态刷新和所有阅读/换源行为。详情定向 `10/10`；`flutter analyze --no-pub`、架构边界、Flutter 全量 `1280`（`3` 项既有条件跳过）通过；待完成 `git diff --check` 后创建中文本地提交，不自动 push。

2026-08-05 Phase 4/R6 书籍详情缓存下载边界：`BookInfoPage` 的“缓存全部”入口改用既有 `CacheBookDownloadPort`，生产组合根继续复用 `BookProvider` 的下载状态、目录加载、批量下载和取消事实源；保留同书取消、书源缺失、空目录提示、缓存过滤、并发参数和完成计数语义。书籍详情定向 `10/10`，`flutter analyze --no-pub`、架构边界、Flutter 全量 `1279`（`3` 项既有条件跳过）通过；待完成 `git diff --check` 后创建中文本地提交，不自动 push。
