# Legado Flutter 架构重构基线

> 2026-08-05 Phase 4/R6 配置页 AppConfig scope 边界：`ConfigPage` 不再创建局部 `appConfigProvider` override，直接消费组合根/父级默认的 `AppConfig.instance`；配置页子页面、AppConfig notifier、主题和其它设置行为保持不变。配置/主题相关测试 `10/10`，Flutter 全量 `1284`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-05 Phase 4/R6 全文搜索与 RSS 源编辑/管理页 controller scope 边界：`SearchContentPage`、`RssSourceEditPage`、`RssSourceManagePage` 不再在页面内读取旧 Provider 或创建嵌套 Riverpod scope；生产入口复用组合根父级 controller，独立宿主通过显式 controller 或父级 override 提供状态。全文搜索净化、RSS 编辑校验保存、源管理和导入行为保持不变；既有缓存端口测试宿主已补齐 ReplaceController 注入。受影响定向 `9/9`，Flutter 全量 `1284`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-05 Phase 4/R6 替换页、规则订阅与缓存页 controller scope 边界：`ReplacePage`、`RuleSubPage`、`CacheBookPage` 不再在页面内读取旧 Provider 或创建嵌套 Riverpod scope；生产入口复用组合根父级 controller，独立宿主通过显式 controller 或父级 override 提供状态。规则增删改/预览、订阅导入、缓存下载和书源查找行为保持不变。受影响定向 `15/15`，Flutter 全量 `1282`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-05 Phase 4/R6 RSS 收藏页 SourceController 边界：`RssFavoritesPage` 通过可选 `RssSourceController` 接入共享 application 状态；生产导航优先读取父级 Riverpod scope，独立宿主没有 `ProviderScope` 时回退到空 controller，避免页面重新依赖旧 `RssProvider`。收藏读取、取消收藏、书源匹配、图片请求策略和阅读跳转语义保持不变。定向 RSS 收藏/图片测试 `4/4`，Flutter 全量 `1280`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-04 Phase 4/R6 “我的”页缓存入口边界：`MyPage` 打开离线缓存时只读取组合根提供的 `ChapterContentCachePort`，不再依赖 `BookProvider.contentCache`；生产绑定与书架/启动阶段复用同一缓存实例，缺少端口的独立宿主仅显示不可用提示。定向 `3/3`、Flutter 全量 `1223`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-04 Phase 4/R6 书架展示状态边界：Style1/Style2 的 loading、重试和单本目录更新展示依赖可监听 application `BookshelfDisplayStatePort`，不再直接消费 `BookProvider`；infrastructure 适配器转发现有 Provider 的 `Listenable`、`isLoading`、`isBookShelfUpdating` 和 `loadBooks`，生产组合根使用 `ListenableProvider` 注册。书架业务状态仍由 `BookshelfNotifier` 快照提供，Provider 继续是过渡事实源。定向 `14/14`、Flutter 全量 `1223`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-04 Phase 4/R6 远程书籍书架导入边界：`RemoteBookPage` 不再直接依赖 `BookProvider`；`RemoteBookImportPort` 提供不可变本地书架快照和按路径导入回调，infrastructure 适配器复用现有 Provider 的 `books` 与 `importLocalBookFromPath`。WebDAV 列目录、筛选、选择、排序和请求失效仍由 `RemoteBookController` 负责；生产组合根接入真实适配器，独立宿主使用空实现。适配器/页面定向 `4/4`、Flutter 全量 `1223`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-04 Phase 4/R6 书架缓存入口边界：书架样式页打开缓存管理页时只读取组合根提供的 `ChapterContentCachePort`，不再从 `BookProvider` 取 `contentCache`；生产绑定与 Provider/启动阶段使用同一 `FileChapterContentCache` 实例，因此缓存统计、下载、清理和导出链路不变。未注册端口的独立宿主显示不可用提示，不创建第二份缓存事实源。定向 `19/19`、Flutter 全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；R6 尚未退出。

> 2026-08-04 Phase 4/R6 书架目录刷新边界：Style1/Style2 的目录刷新命令与运行状态依赖 application `BookshelfTocRefreshPort`，结果模型 `ShelfTocUpdateResult` 不再归属于 Provider 文件；infrastructure 适配器将端口接入现有 `BookProvider.refreshShelfToc`，保留其并发去重、源解析、`onlyUpdateRead`、逐本更新、章节元数据刷新和异常统计。未注册端口的独立宿主使用空实现，生产组合根始终注册真实适配器。定向 `14/14`、Flutter 全量 `1222`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过；缓存、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12 和暂停平台门禁不变，R6 尚未退出。

> **当前权威状态（2026-08-03）：** R1-12 已按 archive-only 产品边界完成：六张核心表映射后可直接使用，23 张 Room 实体表无损归档，JSON 备份、事务回滚和幂等导入通过；`.tmp/r1-device-room/original_legado.db` 已确认 Room v99、identity hash 与原版基线一致，非空行数为 `books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`，既有 `emulator-5556` all-phase smoke `1/1` 通过。不宣称 `readRecord` 统计语义或非核心表 Rust v17 业务化完成。历史段落中的“R1 重新打开/部分完成”保留为当时证据链，不覆盖本条当前判定。

> 2026-08-04 Phase 4/R6 书架整理删除边界：整理页从直接调用 Provider 改为依赖独立 application `BookshelfArrangeDeleteCommandPort`，infrastructure 适配器按原方法粒度委托 `BookProvider.removeBook/removeBooks`；页面成功后继续维护自己的筛选列表、选择和排序存储，因此端口刻意不返回 Provider 快照。Provider 兼容桥仍负责生命周期 controller、书架元数据、完整刷新、mutation version、`BookshelfChangeBus` 和通知；批量删除是逐本副作用、整批一次成功发布，任何中途失败均保留已完成副作用而不更新 Provider/页面成功状态。该边界不代表通用删除端口或 Provider/Riverpod 迁移完成，其他页面删除入口仍待独立处理。定向 `35/35`、Flutter 全量 `1220`（`3` 项既有条件跳过）、analyze、架构、格式和 diff 门禁通过；R6 尚未退出。

> 2026-08-04 Phase 4/R6 书架整理“移除分组”边界：页面不再直接逐本读取和调用 `BookProvider`，而是委托 application `BookshelfArrangeGroupCommandPort.clearBooksGroup`；infrastructure 兼容适配器仍在每个 ID 前读取最新 Provider 快照，按可空条件决定是否逐本清空。该设计刻意保留每本独立 mutation、完整刷新、`BookshelfChangeBus` revision、ChangeNotifier 通知和中途失败后的部分成功，不是事务式批量操作；空条件是无条件通配，非空条件是区分大小写的精确匹配。适配器仍是过渡桥，删除命令仍在 Provider 兼容路径，Provider/Riverpod 状态迁移和 R6 均未完成。定向 `37/37`、Flutter 全量 `1205`（`3` 项既有条件跳过）、analyze、架构边界、Dart 格式和 diff 门禁通过。

> 2026-08-04 Phase 4/R6 书架整理分组命令边界：迁移前整理页直接调用 `BookProvider.updateBookGroup/updateBooksGroup`；迁移后行内“分组”、批量“移入分组”和“加入分组”依赖 application `BookshelfArrangeGroupCommandPort`，组合根通过 infrastructure 兼容适配器委托现有 Provider，并返回不可变完整书架快照。该桥接保留 Provider 的 mutation version、`BookshelfChangeBus` 和通知，是过渡边界，不代表 Provider/Riverpod 状态迁移完成；条件式“移除分组”和删除仍保留原路径。受影响定向 `25/25`、Flutter 全量 `1196`（`3` 项既有条件跳过）、analyze、架构边界、Dart 格式和 diff 门禁通过；R6 尚未退出。

> 2026-08-04 Phase 4/R6 书籍基础信息字段级边界：Rust v17 新增只更新 `name/author/description` 的 SQL 与 FRB API，Dart 经 `RustDatabasePort`、`DatabaseHelper`、`BookRepository` 和 `BookMetadataController` 逐层委托。`BookProvider` 仍是书架事实源，写入成功后只将三字段合并到最新对象并发布快照；页面不再整书 upsert。契约固定封面、来源、readConfig、进度、章节索引、UTF-16 位置和旧导入字段不受影响。Rust 全量 `270/270`、Flutter 全量 `1188`（`3` 项既有条件跳过）通过；R6 尚未退出。

> 2026-08-03 Phase 4/R6 书架整理排序隔离：整理页的本地 `_books` 必须与 `BookProvider.books` 内部集合隔离；空保存顺序分支现由 `BookshelfArrangeOrderPolicy` 返回副本，拖动只改变页面局部顺序，不能绕过 Provider mutation version、变更总线或通知。策略/Widget 定向 `6/6`、Flutter 全量 `1177`（`3` 项既有条件跳过）通过。分组与删除仍通过 Provider 兼容命令，R6 尚未退出。

> 2026-08-03 Phase 4/R6 书籍封面写入边界：`BookMetadataController` 只依赖 `BookRepository.updateCover` 字段级接口；`BookProvider` 保留最新书架事实源、mutation version、变更总线和 ChangeNotifier 通知职责，成功后只替换目标书籍封面，失败不改内存或发布快照。`BookInfoPage` 不再直接写封面仓储，非书架和异常静默语义保持。定向 `12/12`、Flutter 全量 `1175`（`3` 项既有条件跳过）、`flutter analyze --no-pub` 和架构边界通过。整书基础信息保存仍是下一独立边界，不能用页面旧快照覆盖阅读进度、UTF-16 章内位置、来源或导入字段；R6 尚未退出。

> 2026-08-03 当前 owner 状态：R1-12 已按产品决策完成 Room v99 探针、六张核心业务表映射、`readRecord` archive-only 保存、23 表原始归档、事务/JSON 备份/回滚/幂等和真实非空证据。副本 `.tmp/r1-device-room/original_legado.db` 的计数为 `books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`，`emulator-5556` all-phase smoke `1/1` 通过。旧版数据必须可导入，已映射数据导入后直接可用，未业务化数据无损归档；备份保持 JSON，不增加文件级 SQLite 备份要求。

> 2026-08-03 Phase 4/R6 书架同步前置：`BookProvider.loadBooks` 使用 requestId 防止旧并发结果覆盖新列表；application 新增 `BookshelfChangePort`/`BookshelfChangeBus`，生产组合根把同一总线注入 Provider 和 `BookshelfNotifier`，Provider 成功书架写入后发布 revision，Notifier 触发既有 `refresh()`。定向 `16/16`、Flutter 全量 `1151`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界/脚本自测和 `git diff --check` 均通过。当前书架样式页仍以 `BookProvider` 为展示事实源，避免重复初始化；未扩展到 Reader、正文、目录、分页、章节身份、UTF-16 阅读位置或 R1-12。

> 2026-08-03 Phase 4/R6 书架只读状态与启动失败同步：`BookshelfStyle1Page`、`BookshelfStyle2Page` 的列表、分组、加载、错误、重试和空态改用共享 `BookshelfState`；目录刷新、更新中状态、缓存、删除和分组写入继续保留在 `BookProvider`。`BookshelfChangeBus` 增加失败快照事件，生产启动加载失败同步进入 `BookshelfNotifier.failure`，同时保留旧 `BookProvider.loadError` 和启动任务报告。书架相关定向 `39/39`、Flutter 全量 `1165`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 通过。该批不代表 `BookProvider` 写入/目录职责或 R6 全量迁移完成，也不改变 Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、R1-12、严格 UI 1:1、Web/WASM/PWA 或真实 Android TTS 门禁。

> 2026-08-03 Phase 4/R6 书架重试命令统一：Style1/Style2 错误态重试统一调用 `BookProvider.loadBooks()`，通过共享变更总线同步 `BookshelfNotifier`，同时观察 `BookProvider.isLoading` 保持重试 loading 语义。书架相关定向 `41/41`、Flutter 全量 `1167`（`3` 项既有条件跳过）通过；本批不代表目录/正文/缓存/Reader 或 R6 全量迁移完成，也不改变 R1-12、严格 UI 1:1、Web/WASM/PWA 或真实 Android TTS 门禁。

> 2026-08-03 Phase 4/R6 BookProvider 读取边界：`BookProvider.loadBooks` 通过可选注入的 `BookshelfController` 读取书架，默认构造仍使用同一 `BookRepository` 的 `RepositoryBookshelfPort`；controller 只承担读取，Provider 继续负责 loading、错误文本、通知、维护开关和全部写入动作。新增委托与错误传播回归 `2/2`，Flutter 全量 `1145`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界及脚本自测和 `git diff --check` 均通过；书架页面、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置及 R1-12 不在本批范围。

> 2026-08-03 Phase 4/R6 书架读取边界：`BookshelfNotifier` 的读取职责收口到 application `BookshelfController`，controller 只依赖 `BookshelfPort`；生产组合根以与 `RealCoreApi` 相同的 `BookRepository` 构造 `RepositoryBookshelfPort`，`CoreApiBookshelfPort` 仅作为兼容 fallback。Notifier 继续保留刷新旧值、requestId、异常堆栈和不可变列表契约，BookProvider 的其他状态、写入动作和书架页面不在本批范围。controller/Notifier/组合根定向 `21/21`、Flutter 全量 `1143`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 均通过；R6 尚未全量退出。

> 2026-08-03 Phase 4/R6 阅读进度写入边界：新增 `BookProgressController`，application 层只依赖 `BookRepository` 和领域 `Book`；`durChapterIndex` 非空且 `bookId == existingBook.id` 时执行整书 upsert，否则调用仓储局部 `updateProgress`。`BookProvider` 保留刷新书籍、章节元数据和通知职责，`pageIndex` 原样传递，异常不吞掉；身份不一致回归确保不会写入错误书籍。进度/迁移/同步定向 `34/34`、Flutter 全量 `1129`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 全部通过。该批不改变正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

> 2026-08-03 Phase 4/R6 书架章节元数据边界：新增 `BookshelfChapterMetaController`，application 层只依赖 `BookRepository` 和领域 `Book`；章节数量与当前章节标题索引按仓储列表顺序计算，变更时仅 upsert `totalChapterNum`/`durChapterIndex`，其他书籍字段完整保留。`BookProvider` 继续负责元数据缓存、书籍列表、后台异常隔离和通知；空章节、标题不匹配、异常传播和 UTF-16 页内位置契约不变。章节读取完成后重新取最新书籍快照，避免并发进度更新被旧元数据快照覆盖。定向 `29/29`、Flutter 全量 `1137`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界和 `git diff --check` 全部通过。该批不改变正文、目录顺序、分页、章节身份、第 3 条断行规则、R1-12 或暂停平台门禁。

> 2026-08-02 Phase 3 当前 owner 状态：Flutter `Book`/`BookSource`/`ReplaceRule`/阅读统计模型已改为 Freezed 领域模型，生成不可变值语义和 `copyWith`，同时保留旧版 JSON、`readConfig` 和嵌套书源规则兼容。Rust `BookDto`、`BookSourceDto` 均已提供 camelCase serde 投影；Rust `BookReadingStats.readingDays` 现已透传至 Dart。模型契约及书架/书源仓储、替换规则和统计链路定向回归通过，Rust 当前全量 `265/265`、Flutter 全量 `925`（`3` 项既有条件跳过）通过。Riverpod 生产页面和其余手写模型仍是后续批次。

> 2026-08-03 Phase 4/R6 书架分组写入边界：新增 `BookshelfBookGroupController`，将单本/批量分组写入、刷新和异常顺序收口到 application 层；`BookProvider` 保留旧兼容入口，组合根显式注入同一控制器。控制器/Provider 定向 `9/9`、书架相关定向 `12/12`、Flutter 全量 `1113`（`3` 项既有条件跳过）、`flutter analyze`、架构边界、Rust 全量 `268/268`、`cargo fmt -p legado_engine -- --check` 和 `git diff --check` 通过。未修改 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

> 2026-08-03 Phase 4/R6 书架书籍生命周期边界：新增 `BookshelfBookLifecycleController`，将新增/删除书籍的仓储写入和章节缓存清理顺序收口到 application 层；`BookProvider` 保留列表刷新、未读元数据、批量失败和通知职责，组合根显式注入 controller。生命周期/书架/缓存定向 `16/16`、Flutter 全量 `1115`（`3` 项既有外部网络条件跳过）、`flutter analyze`、架构边界和 `git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

> 2026-08-03 Phase 4/R6 书籍阅读元数据写入边界：新增 `BookRecordController`，将 `readIteration` 和模拟追读字段的 Book 复制、边界裁剪及仓储 upsert 收口到 application 层；`BookProvider` 保留当前书选择、列表刷新、通知和兼容返回值，组合根显式注入 controller。书籍记录/书架/缓存定向 `20/20`、Flutter 全量 `1117`（`3` 项既有外部网络条件跳过）、`flutter analyze`、架构边界和 `git diff --check` 通过；契约验证阅读位置不变。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、第 3 条断行规则、R1-12 或暂停平台门禁。

> 2026-08-02 Phase 3 Rust DTO 状态：Rust `BookSourceDto` 已提供与 Flutter `BookSource` 对齐的 camelCase serde 投影，`rawSourceJson` 完整保留，`rulePageNext` 回退顺序由测试固定。`BookDto` 已接入 `get_books_json()`，完整字段、默认值、`readConfig`、阅读位置和时间输出由定向测试固定；两者均未新增 FFI 入口，现有 `db_get_books()` 继续输出 `Vec<String>`。DTO 定向 `3/3`、Rust 全量 `265/265` 通过；生产 typed FFI 联调和其余手写模型仍未完成。

> 2026-08-03 Phase 4/R6 当前 owner 状态：SourceProvider 第三批已完成共享 application 状态层和 SourcesPage 状态订阅迁移。`SourceState` 使用 Freezed 并对列表、Map 及嵌套结果做防御性不可变快照；`SourceController` 统一承载书源 CRUD、分组、JSON/URL 导入、搜索、图片请求头和校验，并以请求序号阻止旧 load/search/validate 结果覆盖新状态，内置源初始化使用 single-flight。旧 `SourceProvider` 仅作为共享 controller 的 ChangeNotifier 兼容外观，`importSourcesFromFile` 的平台文件选择仍留在兼容入口；`SourcesPage` 通过局部 `ProviderScope` 读取 Riverpod 状态，选择/排序/分享和未迁移子页不变。controller/Notifier/Provider 兼容定向 `25/25`、source Feature/Widget `10/10`、Flutter 全量 `1066`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过。`SearchPage`、探索、书架/阅读器、启动任务和规则订阅仍使用兼容外观，R6 尚未全量退出。

> 2026-08-03 Phase 4/R6 当前 owner 状态：SourceProvider 第四批完成分组管理弹窗和书源市场子页面的共享状态接入。分组弹窗从当前旧 Provider 取得同一 controller 后覆盖局部 Riverpod scope，列表和 CRUD 通过 `SourceNotifier`；市场页的 tile 通过 Riverpod 状态判断已存在源，单个添加和全部导入均等待 controller 持久化完成。新增异步 Widget 测试验证全部导入在写入 release 前不提示、不返回，并修复局部 scope 外 `ProviderScope.containerOf` 的运行时错误。Source 管理相关定向 `38/38`、Flutter 全量 `1067`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过。SourceEditor、SourceDebug、RuleSub、启动任务和规则订阅适配器仍保留旧 Provider，R6 尚未全量退出。

> 2026-08-03 Phase 4/R6 当前 owner 状态：AppConfig 已新增 Freezed 状态、共享 Controller 和 Riverpod Notifier，`ConfigPage` 通过局部 scope 订阅既有 `AppConfig` 单例；`load()` 并发去重、乐观持久化、四个配置键和启动顺序保持不变。组合根已将现有 `SourceProvider.controller` 覆盖到 `sourceControllerProvider`，`BookInfoPage`、`BookmarkPage`、`ChangeSourcePage` 直接消费根级 SourceNotifier，旧 Provider 继续为未迁移消费者提供兼容外观。AppConfig 定向 `9/9`、Source 页面/组合根定向 `8/8`、Flutter 串行全量 `1100`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过。BookProvider/Reader 仍为高风险事实源边界，R6 尚未全量退出。

> 2026-08-03 Phase 4/R6 当前 owner 状态：第十二批完成 Riverpod provider 依赖声明与页面 scope 收口。六个 application Notifier 明确声明实际上游 provider，根级 `SourceProvider.controller`、RSS/替换/我的页面/配置和远程书籍 controller 覆盖不再触发 Riverpod 依赖断言；发现、搜索、书架样式、我的、RSS Tab 和书源相关页面不再重复创建已注入 controller 的局部 scope。Sources 管理、书源市场/编辑/调试和测试宿主保持既有行为与兼容入口。受影响定向 `19/19`、测试宿主补充 `2/2`、Flutter 全量 `1104`（`3` 项既有条件跳过）、analyze、架构边界和 diff 检查通过。BookProvider/Reader、正文/目录/分页、R1-12、原版 UI 基线及暂停平台门禁不变。

## 193. 2026-08-03：Riverpod 依赖声明与页面根级 scope 收口

- `SourceNotifier`、`RssNotifier`、`ReplaceNotifier`、`MyPageNotifier`、`AppConfigNotifier`、`RemoteBookNotifier` 对实际 `ref.watch` 上游 provider 补齐 `dependencies`，保持 Riverpod override 图与组合根一致，不改变 controller 或业务命令语义。
- 移除已由组合根提供共享 controller 的页面局部 scope；Sources 管理动作、书源市场/编辑/调试和旧 Provider 兼容外观继续保留。直接构造 `BookshelfPage` 的旧测试宿主改为提供真实 controller override，未削弱空态、页面样式或主壳断言。
- 未修改 `legado-main/`、Rust、正文算法、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则或 R1-12 数据库迁移边界；R6、Web/WASM/PWA 和真实 Android TTS 仍未退出。

验证记录：受影响页面/管理定向 `19/19`、补充测试宿主 `2/2`、Flutter 串行全量 `1104`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 均通过。

## 194. 2026-08-03：R1-12 真实非空 Room 副本证据补录

- 纳入只读副本 `.tmp/r1-device-room/original_legado.db`，确认 Room v99、identity hash 与原版基线一致；非空行数为 `books=1`、`book_sources=1`、`chapters=876`、`readRecord=1`、`detailedReadRecord=2`。
- 既有 `emulator-5556` all-phase smoke 命令为 `flutter test --no-pub integration_test/r1_android_room_import_smoke_test.dart -d emulator-5556`，结果 `1/1` 通过，覆盖真实文件导入、章节 ID、持久化、重复导入、空备份路径和备份恢复。
- 本证据关闭真实非空 Room 数据库缺失子项；`readRecord` 仍为 archive-only，统计语义未声明，非核心 Room 表仍不宣称已完成 Rust v17 业务化。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

## 192. 2026-08-03：AppConfig 与 SourceController 根级状态边界

- AppConfig application 层新增 `AppConfigState`、`AppConfigController` 和 `AppConfigNotifier`，只将 `ConfigPage` 的四项配置状态接入 Riverpod；旧 `AppConfig` 单例继续负责 SharedPreferencesRuntime、`load()` single-flight、持久化和启动兼容语义。
- `AppCompositionRoot.withCoreApi` 在已有 ProviderScope 中绑定 `SourceProvider.controller`，三个书籍页面删除局部 Source scope；测试宿主显式提供同一 controller。`BookProvider` 继续负责书籍、章节、阅读、目录、换源落库和入库，未创建第二份书籍事实源。
- 只读审查确认 `BookProvider`、Reader、正文/目录和媒体链路属于高风险边界；下一批可独立处理 SourcesPage 管理动作或 Source scope 清理，不把这些边界与正文、章节身份、UTF-16 阅读位置或 R1-12 混迁。

验证记录：AppConfig 定向 `9/9`、Source 页面/组合根定向 `8/8`、Flutter 串行全量 `1100`（`3` 项既有条件跳过）；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。该批不代表 BookProvider 生产状态、Source 全链路、R6 全量或 R1-12/平台门禁退出。

## 191. 2026-08-03：书源分组与市场子页面共享 Riverpod 状态

- `source_group_manage_dialog.dart` 通过当前 `SourceProvider.controller` 建立局部 `ProviderScope`，分组列表订阅 `SourceNotifier`，添加、重命名和删除保留原中文文案、空名删除语义和主题布局。
- `source_market_page.dart` 通过局部 scope 共享同一 controller，市场 tile 使用 Riverpod 源列表判断存在状态，单个添加和“全部导入”等待持久化完成；新增异步 Widget 测试固定写入未完成前不得提示/返回的契约。
- 首轮测试捕获 `_importAll` 从 scope 外 context 调 `ProviderScope.containerOf` 的运行时错误，改为在 scope 内 Consumer 取得 Notifier 后显式传递；未修改 `legado-main/`、正文、目录、分页、章节身份、UTF-16 位置、第 3 条断行规则、Room 导入或暂停平台门禁。SourceEditor、SourceDebug、RuleSub 及规则订阅适配器保留兼容外观。

验证记录：Source 管理相关定向 `38/38`、`flutter test --no-pub --concurrency=1 --reporter compact` 为 `1067` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。该批不代表 Source 全链路或 R6 阶段退出。

## 190. 2026-08-03：SourceProvider 共享状态与 SourcesPage 首条 Riverpod 迁移

- 新增 `SourceState`、`SourceController` 和 `SourceNotifier`，将书源加载、CRUD、分组、JSON/URL 导入、搜索、图片请求头和校验状态统一放入 application 层；请求序号保护 load/search/validate 竞态，内置书源初始化使用 single-flight，状态对外暴露不可变列表、Map 和嵌套搜索结果。
- `SourceProvider` 改为共享 controller 的 ChangeNotifier 兼容外观，保留构造参数、公开方法、静态 JSON 提取入口和平台文件导入；`SourcesPage` 以 `SourceProvider.controller` 覆盖局部 Riverpod ProviderScope，业务状态从 `SourceNotifier` 订阅。未迁移的搜索、探索、书架/阅读器、启动任务、规则订阅和平台文件选择继续走兼容边界。
- 修复两个兼容契约：无活动加载时取消请求不产生额外空状态通知；校验持久化失败时保留成功的内存校验结果并返回既有 `null` 结果。未修改 `legado-main/`、Room 导入、正文、目录、分页、章节身份、UTF-16 位置或第 3 条断行规则。

验证记录：Source controller/Notifier/Provider 兼容定向 `25/25`、source Feature/Widget 定向 `10/10`、`flutter test --no-pub --concurrency=1 --reporter compact` 为 `1066` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。该批不代表 Source 全链路或 R6 阶段退出。

## 188. 2026-08-03：ReplaceProvider 首条生产 Riverpod 状态迁移

- 新增 application 层 `ReplaceState` 和 `ReplaceRulesController`，将规则 CRUD、内置规则初始化、按 pattern 去重、正文处理和预览统一放在共享控制器；规则列表通过 Freezed 状态保持不可变。
- 新增 Riverpod `ReplaceNotifier`，`ReplacePage` 在局部 `ProviderScope` 中读取 Notifier；旧 `ReplaceProvider` 保留 ChangeNotifier 兼容 API，并与页面共享同一控制器，避免迁移期间出现双份规则状态。
- 未迁移 `BookProvider`、`RssProvider`、`SourceProvider`，未改变 `legado-main/`、Room 导入、正文算法、目录顺序、分页、章节身份、UTF-16 位置或第 3 条断行规则。

验证记录：替换控制器/Notifier/Provider 定向 `5/5`、Flutter 串行全量 `1057`（`3` 项既有条件跳过）、`flutter analyze --no-pub`、架构边界检查和 `git diff --check` 通过。Riverpod 生产页面并未全量迁移，R6 阶段退出条件不因本批改变。

## 189. 2026-08-03：RSS 源管理首条生产 Riverpod 状态迁移

- 新增 application 层 `RssState` 与 `RssSourceController`，承载 RSS 源加载、持久化、导入、删除、启用、置顶、分组筛选和管理排序；Freezed 状态对外暴露不可变源列表。
- 新增 `RssNotifier`，`RssSourceManagePage` 通过局部 `ProviderScope` 使用 Riverpod 状态；旧 `RssProvider` 与 Notifier 共享控制器，`RssTabPage`、启动任务和订阅适配器继续使用兼容外观。
- 未修改 `legado-main/`、RSS 文章正文处理、Room 导入、正文算法、目录顺序、分页、章节身份、UTF-16 位置或第 3 条断行规则。

验证记录：RSS 控制器/Notifier/Provider/页面定向 `9/9`、Flutter 串行全量 `1060`（`3` 项既有条件跳过）通过；`flutter analyze --no-pub`、架构边界和 `git diff --check` 在最终源码与文档复核后执行。

## 187. 2026-08-02：R1-12 Room 快照与导入并发一致性复核

- Room v99 源库 probe、schema 和逐表读取统一在单一 SQLite 只读事务中完成，避免并发写入造成跨提交混合快照。
- fingerprint 去重检查移入 `BEGIN IMMEDIATE`，与目标业务写入、raw archive 写入共用互斥事务；导入前备份使用唯一 `create_new` 临时文件、`sync_all` 和不覆盖 hard-link 提交，避免并发覆盖和 TOCTOU。

验证记录：Room 定向 26/26、数据库定向 28/28、Rust 全量 259/259、cargo fmt -p legado_engine 通过。所有 Android 操作统一使用 emulator-5556；真实非空 Room 源库证据仍未完成，R1-12 继续复核中。

## 186. 2026-08-02：R1-12 跨层报告与 Android smoke 契约复核

- 主机侧测试固定 Rust serde 报告的 13 个字段、基础类型和 `sourceRoomIdentityHash`/`backupPath` nullable 分支，并保留未知字段向前兼容。
- Android smoke 增加 application → FRB → generated API 的重复导入 `backupPath=null` 断言，继续验证目标书籍与 `legacyRoomImports` 归档数量不增加；真实设备测试未因缺少 Room 源库而伪造通过。

验证记录：Flutter 导入报告定向 13/13、Flutter 全量 918（3 项既有条件跳过）、flutter analyze --no-pub 通过；真实 Android smoke 因原版 release 包数据库目录无权限读取未执行，R1-12 继续复核中。

## 185. 2026-08-02：R1-12 Dart 导入端口可空备份路径复核

- Dart `LegacyRoomImportPort`、`LegacyRoomImportUseCase` 和 FRB adapter 与 Rust `Option<String>` 对齐；重复导入可传入 `backupPath=null`，首次导入的缺少备份路径仍由 Rust 拒绝。
- 新增 application 测试覆盖 null 路径转发和下游拒绝，避免应用层错误收窄 Rust 已实现的重复导入语义。

验证记录：Flutter 导入报告定向 12/12、Flutter 全量 917（3 项既有条件跳过）、flutter analyze --no-pub 通过。本批不改变真实非空 Room 数据缺失、readRecord 产品统计语义和 R1-12 其它未决边界。

## 184. 2026-08-02：R1-12 幂等与 archive-only 覆盖补强

- 完全相同的 detailedReadRecord 会话在新的 Room snapshot fingerprint 下不重复写入；冲突统计继续只覆盖已有五类业务主键，不把 readRecord、readingRecords、detailedReadRecords 误报为冲突。
- 导入报告明确 readRecord 的原始计数、archive-only 表归属、四个未映射列和 aggregate warning；非核心 archive-only fixture 为每张归档表补充代表性非空行，并验证 snapshot、备份 JSON 和恢复后的 raw snapshot 行数。

验证记录：cargo fmt -p legado_engine、Room 定向 25/25、Rust 全量 256/256、release 构建、Flutter 导入报告 10/10、Flutter 全量 916（3 项既有条件跳过）、flutter analyze --no-pub、架构边界扫描和 git diff --check 通过。emulator-5556 当前在线，但原版 io.legado.app.releaseS 为不可调试 release 包，数据库目录无权限读取；外部 backup.zip 仅含配置，不含 Room 数据库，Android smoke 与真实非空 original_legado.db 证据仍未完成，R1-12 不退出。

边界结论：本批只修正可由现有架构确定的幂等和证据缺口。Rust v17 现有阅读记录 CRUD、统计和导出能力已完成；legacy Room `readRecord` 仍只做 archive-only 保存和报告计数，不写入 Rust v17 阅读统计业务表，其产品统计语义尚未决定；本批也不决定非核心表 Rust v17 业务 port 或文件级 SQLite 备份目标。

## 183. 2026-08-02：R1-12 报告失败契约与回滚证据复核

- `LegacyRoomImportReport` 对 Rust 输出的必需字段执行严格缺失/类型校验，损坏报告不再静默归零；`sourceRoomIdentityHash`、`backupPath` 缺失仍兼容，未知字段仍向前兼容。
- Android smoke 的重复导入路径断言 `backupWritten=false`、请求的重复备份文件不创建，且目标书籍数和 `legacyRoomImports` 归档数不增加；设备不可用时不宣称 smoke 通过。
- Rust 失败回滚测试解析导入前 JSON 备份，确认原有书籍、原有归档 fingerprint 及 raw snapshot 内容保留。

验证记录：报告定向 `10/10`、Rust Room `24/24`、Rust 全量 `255/255`、Flutter 全量 `912`（`3` 项既有 Flutter 条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：严格报告解析只覆盖当前唯一 FRB Rust 报告来源；真实原版非空数据库、阅读统计产品语义、非核心表 Rust v17 业务 port 和文件级 SQLite 备份目标仍未关闭，R1-12 继续复核中。

## 182. 2026-08-02：R1-12 导入报告与事务边界复核

- Dart `LegacyRoomImportReport` 补齐 `sourceRoomIdentityHash`、`backupPath`，旧报告 JSON 缺少字段时保持兼容；测试按 Rust 实际输出键 `sources`、`detailedReadRecords`、`replaceRules` 校验，重复导入明确 `backupWritten=false`。
- Android smoke 增加 Room v99 23 张实体表精确集合、逐表行数和 archive-only 集合断言；本批设备不可用，未宣称设备 smoke 通过。
- Rust 增加未 checkpoint WAL/SHM 源库主文件及侧文件字节不变回归、`replace=true` 成功替换和导入前备份内容回归；详细阅读记录短会话过滤与 raw snapshot 保留继续由测试固定。

验证记录：Flutter 报告定向 `6/6`、Rust Room `24/24`、数据库 `26/26`、Rust 全量 `255/255`、Flutter 全量 `912`（`3` 项既有 Flutter 条件跳过）、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：Android smoke 因 `adb devices -l` 为空、`emulator-5556` 被拒绝而未执行；真实原版非空 Room 数据库、`readRecord`/详细阅读记录产品语义、非核心表 Rust v17 业务 port 和文件级 SQLite 备份目标仍未关闭，R1-12 继续复核中。

## 181. 2026-08-02：R1-12 阅读记录与替换规则归档边界复核

- owner 工作树完成本批迁移门禁复核：Rust Room 定向 `23/23`、数据库定向 `24/24`、Rust 全量 `252/252`、Flutter 全量 `912` 通过，另有 `3` 项既有 Flutter 条件跳过；`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。
- `readRecord` 明确归入 archive-only，原始行数纳入导入报告计数，原始字段保留在 `raw_snapshot_json`，当前不写入 Rust v17 阅读统计业务表；warning 继续用于提示该表尚未完成业务化映射。
- `detailedReadRecord` 的原始行和 Room 自增 `id` 在 `raw_snapshot_json` 中保留；当前业务映射按书名聚合为 sessions，聚合后的 session 不保留 Room 自增 `id`。
- `replace_rules.sortOrder`、`scope`、`group` 仅通过 archive-only 原始快照保存，不进入当前 Rust v17 替换规则业务模型。
- 上述分类确保字段可恢复且不擅自扩大领域模型，但不代表相关产品语义已经最终确定。真实原版非空数据库、`readRecord` 统计模型、非核心表业务 port 和文件级 SQLite 备份目标仍未关闭；R1-12 继续复核中。

## 179. 2026-08-02：R1-12 Room 迁移证据与字段分类复核

- Rust Room 七张核心表新增逐字段 golden fixture，覆盖书籍、书源规则、章节、书签、`readRecord`、详细阅读记录和替换规则；Flutter 导入报告补充计数、保留行、归档表、告警、未映射列、指纹和重复导入幂等断言。
- 修正 `books.originName` 的报告分类：当前只进入 `rawSnapshotJson`，不进入 Rust v17 业务映射，因此明确登记为 `unmappedColumns`，不擅自扩展领域模型。
- 验证记录：Rust Room `21/21`、Flutter Room `5/5`、Rust 全量 `249/249`、Flutter 串行全量 `911` 通过，`3` 项既有 Flutter 条件跳过；`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：当前设备 `emulator-5556` 不可连接，真实原版非空 Room v99 数据库证据仍缺失；`readRecord` 统计语义、详细阅读记录聚合、非核心表业务 port 和文件级 SQLite 备份仍未形成产品契约，R1-12 继续复核中，不推进新的 R2-R6 实现。

补充验证：Flutter 导入报告对重复导入空集合和未知 JSON 字段向前兼容的定向测试为 `6/6`，未改变迁移生产逻辑。

## 180. 2026-08-02：Room 书源规则与目标表落库边界

- `upsert_source_json` 对嵌套 `ruleSearch`、`ruleBookInfo`、`ruleToc`、`ruleContent` 增加扁平业务列回退，扁平字段存在时保持其优先级；`rulePageNext` 按扁平字段、目录分页、正文分页顺序选择。
- Rust 测试覆盖 Room 规则映射到目标业务列的实际查询，以及 books/book_sources/chapters 的实际落库；章节 `wordCount` 明确只在 `legacy_room_imports.raw_snapshot_json` 保留，不宣称进入 Rust v17 章节模型。
- 验证记录：Rust Room `22/22`、数据库 `24/24`、Rust 全量 `251/251`、Flutter 全量 `912` 通过，`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：本批不扩展章节、替换规则或书籍附加字段模型；真实原版非空 Room 数据库、`readRecord`/详细阅读记录语义、非核心表业务 port 和文件级 SQLite 备份仍未形成关闭条件。

## 178. 2026-08-01：浏览器宿主错误边界与 WebView 生命周期

- `serve_source_browser_host`、`probe_source_browser_host` 从公开 `Result<_, String>` 迁移为 `Result<_, AppError>`；取消映射 `Cancelled`，平台不支持映射 `Unsupported`，宿主停止、锁失败和线程失败映射 `Unknown`，均保留原错误文本。
- `browser_host` 在服务 abort/clear 时只清理当前 sender，避免 stale sender 阻塞后续 `startBrowserAwait`；测试宿主覆盖成功、取消、停止和重启。
- `AppWebViewPage` 在 dispose 后不再派发新的 Cookie 回调；完成验证成功路径仍等待 Cookie 同步、抓取 `document.documentElement.outerHTML` 并返回 finalUrl/body。

验证记录：Rust `browser_host` 定向 `7/7`、Dart 浏览器宿主/WebView 定向 `8/8`、Rust 全量 `234`、Flutter 串行全量 `908` 通过，`3` 项既有 Flutter 条件跳过；release 构建、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：本批不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则，不覆盖 WebDAV、平台验收或阶段退出条件。

## 177. 2026-08-01：重复公开 FRB 子模块入口收敛

- `search/explore/toc/debug/validate` 子模块函数降为 `pub(crate)` 并标记 `frb(ignore)`，根 `api/mod.rs` wrapper 保持唯一公开 FRB API。
- FRB 生成层删除子模块重复 Dart wrapper、`.io` 导入和 Rust wire 分支；根 `search/explore/get_toc/debug_search/debug_toc/validate_source` 的参数、返回值和 `AppError` 分类不变。

验证记录：`cargo fmt -p legado_engine`、`cargo test -p legado_engine api -- --nocapture` 为 `72/72` 通过，release 构建、`flutter analyze --no-pub`、Flutter 全量 `903` 通过且 `3` 项既有条件跳过，架构边界扫描和 `git diff --check` 通过。

边界结论：本批只收敛生成公开面，不覆盖浏览器宿主、WebDAV、平台验收或阶段退出，不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

## 176. 2026-08-01：`process_content_for_reading` 公开 FFI 错误边界

- `process_content_for_reading` 从 `Result<String, String>` 改为 `Result<String, AppError>`，底层正文处理错误映射为 `AppError::Parse`；成功输出、替换规则、段落缩进、标题合并和重新分段行为保持不变。
- FRB 对应错误 codec 已同步为 `AppError`，Rust 增加 `2` 项定向契约，Dart 增加 `2` 项 mock 生成 API 契约；没有向页面或领域层扩散生成类型。

验证记录：Rust `process_content_for_reading` 定向 `2/2`、Dart FRB mock 定向 `2/2`、Rust 全量 `228`、Flutter 全量 `903` 通过，`3` 项既有 Flutter 条件跳过；release 构建、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：本批不覆盖浏览器宿主、重复公开 FRB 子模块入口、其它公开 `Result<T, String>` 或平台验收，不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

## 175. 2026-08-01：`seed_login_header` 公开 FFI 错误边界

- `seed_login_header` 从 `Result<(), String>` 改为 `Result<(), AppError>`；source URL/header trim、空值忽略、登录头缓存写入和无 dirty 更新行为保持不变。
- FRB 对应 codec 与 Rust wrapper 已同步，Rust 增加 `3` 项定向测试，Dart 增加 `2` 项生成 API 错误测试；没有向页面或领域层扩散生成类型。

验证记录：Rust 全量 `226`、Flutter 全量 `901` 通过，`3` 项既有 Flutter 条件跳过；release 构建、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。生成器在 Windows rustfmt 阶段遇到文件映射锁警告，产生的无关全量漂移已排除，source-owned diff 仅保留三处 FRB/API 变更。

边界结论：本批不覆盖浏览器宿主、WebView 生命周期、其它公开 `Result<T, String>` 或平台验收，不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

## 174. 2026-08-01：`eval_js` 公开 FFI 错误边界

- `eval_js` 从 `Result<String, String>` 改为 `Result<String, AppError>`，脚本异常映射为 `AppError::JsExecution`；成功结果、错误原文、纯 QuickJS 5 秒 interrupt 和 256 KiB 输入上限保持不变。
- FRB 生成绑定已同步，Rust 增加成功/错误契约测试，Dart 增加结构化错误变体测试；没有向页面或领域层扩散生成类型。

验证记录：Rust `eval_js` 定向 `2/2`、Dart FRB 定向 `2/2`、Rust 全量 `226`、Flutter 全量 `899` 通过，`3` 项既有 Flutter 条件跳过；release 构建、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：本批不覆盖宿主级 QuickJS 阻塞/取消、浏览器宿主、WebView 生命周期或其它公开 `Result<T, String>` 入口，不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

## 173. 2026-08-01：公开 FFI 错误边界扩展：本地 EPUB/远程 ZIP 与 RSS

- Rust 公开 `parse_epub`、`parse_remote_archive_book_files` 失败结果统一为 `AppError::Parse`；`get_rss_articles`、`get_rss_content` 统一为 `AppError::Network` 或 `AppError::Parse`。具体解析和分类仍归 Rust engine，FRB 生成文件只作为绑定产物，不向页面扩散。
- FRB 适配层提取 `AppError.field0` 并通过 `RssPortException`、`RemoteArchiveParserException` 保留原错误文本；非 Rust 异常继续原路径传播。新增 RSS 分类边界、AppError 原文和 ZIP 适配器回归测试。
- 未改变 EPUB/ZIP 解析、输入大小、路径安全、文件筛选和成功结果；未改变 RSS 排序、分页、文章字段、正文解析和请求参数，也未修改正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证记录：`cargo fmt -p legado_engine`、Rust RSS 定向 `4/4`、Rust 全量 `224`、Flutter 适配器定向 `10/10`、Flutter 全量 `897` 通过，`3` 项既有 Flutter 条件跳过；release DLL 构建、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。

边界结论：本批只收敛公开错误契约，没有迁移 RSS/本地书籍的 application/UI 用例；浏览器宿主、QuickJS 宿主阻塞、其它公开 `Result<T, String>`、Dart 全链路错误展示和 R1-12/R2/R3/R6 阶段退出仍按计划排队。

状态：R0-R5 本地门禁已完成；R6 功能域迁移及 P0-1 崩溃防护与启动恢复已完成，下一项为 P0-2 存储初始化安全；发布前正式/主流 WebDAV 和其余目标平台验收待执行
日期：2026-07-29
依据：当前工作区代码、`docs/REFACTOR_PLAN.md`、根目录 `legado-main/`

## 1. 目的

本文记录重构开始前的真实工程边界、入口和依赖问题。它不是目标架构的设计稿，也不把目录名称当作模块边界；后续每个重构阶段都必须更新“迁移前/迁移后”和对应测试证据。

原版目录边界：根目录 `legado-main/` 是只读的原版核对基线，用于行为、数据结构、UI
和错误语义对照；它不是主源码目录，不参与本工程的 Flutter/Rust/Gradle/CI 构建，任何
原版差异必须在当前工程中通过契约、集成测试或文档记录处理。

## 2. 当前工程形态

### Flutter 侧

| 当前位置 | 实际职责 | 主要问题 |
|---|---|---|
| `lib/pages/` | 页面、交互、部分业务编排 | 页面存在直接依赖 bridge、Rust API 和数据库的入口 |
| `lib/providers/` | Provider 状态、目录/书架/书源编排 | Provider 同时承担用例、持久化和远程请求协调 |
| `lib/services/` | 网络、缓存、同步、偏好、备份、书源服务 | “Service”既可能是领域服务，也可能是基础设施适配器，边界不统一 |
| `lib/models/`、`lib/model/` | 书籍、章节、阅读会话和配置模型 | `model` 与 `models` 并存，领域模型和展示/配置模型未清晰分离 |
| `lib/database/`、`lib/bridge/` | Rust 数据库与引擎调用 | bridge 既是平台适配，又承载业务 DTO 转换和状态同步 |
| `lib/src/rust/` | FRB 生成代码和 Rust API 类型 | 生成层被业务代码直接引用，替换 FRB 或测试困难 |
| `lib/help/`、`lib/utils/` | 正文、缓存、解析和通用工具 | 领域逻辑、基础设施逻辑和纯函数混放 |
| `lib/pages/reader/`、`lib/widgets/` | 阅读器分页、富文本、图片和手势 | 阅读会话、排版输入、Flutter 渲染和平台能力耦合在页面/Widget 链路 |

### Rust 侧

| 当前位置 | 实际职责 | 主要问题 |
|---|---|---|
| `src/api/` | FRB 出口、书源用例、数据库、WebDAV 和本地书解析 | API 出口和业务/基础设施实现混在同一命名空间 |
| `src/rule/` | CSS/XPath/JSONPath/Legado DSL/JS/正则 | 核心规则能力相对集中，是可优先稳定的核心域 |
| `src/http/` | HTTP、Cookie、登录头、代理、限速、SSRF | 基础设施边界清晰，但由 api 直接编排 |
| `src/db/` | SQLite schema、迁移、实体读写和 JSON 映射 | 数据库 schema、存储模型和对外 DTO 仍有混合 |
| `src/lib.rs` | FRB 注册、公共 DTO、初始化、API 转发 | 根模块承载过多公共类型和入口函数 |
| `src/frb_generated.rs` | FRB 生成代码 | 必须保持生成文件隔离，不作为业务层依赖目标 |
| `legado-webdav/` | WebDAV 客户端 | 可作为基础设施 crate，但同步冲突编排仍在 engine/Flutter 多处存在 |

## 3. 当前关键入口和数据流

### 应用启动

```text
main.dart
  -> EngineConfig / AppConfig
  -> LegadoEngineBridge.tryInit()
  -> LegadoDbBridge.init()
  -> NetworkPrefs.restoreToEngine()
  -> WebApiService.restoreIfEnabled()
  -> BookProvider.loadBooks()
  -> BookProvider.downloadAllBookProgress()
  -> MultiProvider -> LegadoApp
```

问题：应用入口直接知道引擎初始化、数据库初始化、网络配置、Web API、书架加载和同步顺序。目标是迁移为 `AppBootstrap` 用例，由 infrastructure 提供适配器，UI 只接收完成后的应用状态。

### 在线目录

```text
BookInfoPage / TocSheet
  -> BookProvider / BookSourceService
  -> LegadoEngineBridge
  -> generated FRB API
  -> Rust api::get_toc / api::get_book_info
  -> http + rule + db/cache
```

当前已确认的结构性风险：`BookSourceService._fetchChaptersOnce` 会先调用 `getBookInfo` 再取目录；目录 UI、字数元数据、书签和当前章定位也由同一页面链路触发。它们属于 R4 的重构对象，但在 R0 不直接修改行为。

### 阅读正文

```text
ReaderPage
  -> ReadBook / BookProvider
  -> BookSourceService / CacheService
  -> Rust get_content or local chapter cache
  -> ContentProcessor / ReaderMarkup
  -> ReaderPaginator / ReaderSelectableText
```

第 3 条行为约束要求正文字符范围、中文断行、分页和章节边界不可因结构迁移改变，因此 R3 必须先建立旧链路与新链路的快照契约，再迁移调用者。

## 4. 重构目标边界

```text
features        页面和交互，只依赖 application/domain
application     用例、任务、状态转换和错误呈现策略
domain          纯模型、值对象、Repository/Port 接口
infrastructure  Rust/FRB、数据库、HTTP、文件缓存、WebDAV、平台适配
engine          Rust 规则、网络和数据库核心实现
generated       FRB 生成文件，只能被 infrastructure 适配层引用
```

依赖方向固定为：

```text
features -> application -> domain
infrastructure -> domain
application -> domain ports
Rust engine -> Rust domain/core
FRB generated <- infrastructure adapter only
```

禁止方向：页面 -> `lib/src/rust`、页面 -> SQL/文件路径、domain -> Flutter/FRB、Rust 核心 -> Flutter UI、Provider -> 多个具体基础设施实现。

## 5. 当前领域模型与数据所有权

| 对象 | 当前定义 | 当前持久化/修改入口 | 重构后所有权 |
|---|---|---|---|
| `Book` | `lib/models/book.dart` | `DatabaseHelper`、`BookDao`、`BookProvider`，部分页面直接更新 | `domain/book`；由 `BookRepository` 持久化 |
| `Chapter` | `lib/models/chapter.dart` | `DatabaseHelper`、`BookDao`、`BookSourceService`、`TocSheet` | `domain/chapter`；目录 Repository 负责身份和 index |
| `BookSource` | `lib/models/book_source.dart` | `SourceDao`、`SourceProvider`、`BookSourceService`、导入页面 | `domain/source`；解析/序列化与存储映射分离 |
| 阅读进度 | `Book` 字段 + `BookProgress` + `ReadBook` | `BookProvider`、`ReadBook`、进度同步服务、Rust DB | `domain/reading`；本地/远端由不同 Repository 实现 |
| 书签/想法 | Rust `BookmarkDto`/`NoteDto` + Flutter service/page | `BookmarkService`、`NoteService`、同步服务、页面/Widget | `domain/annotation`；同步策略不进入 Widget |
| 章节正文缓存 | `Chapter.content`、文件缓存、Rust `chapters.content` | `BookHelp`、`CacheService`、`DatabaseHelper`、`ReadBook` | `domain/content` 接口；文件/SQLite 是 infrastructure |
| 阅读配置 | `services/*prefs.dart`、`models/read_style_config.dart` | SharedPreferences、ReaderPage、配置页 | `domain/reader_config`；平台存储由 adapter 实现 |
| 书源规则执行结果 | FRB generated DTO + `LegadoEngineBridge` Map/Flutter model | `LegadoEngineBridge`、各页面/Service | Rust engine DTO + Flutter application mapper，禁止页面直接拿 generated DTO |

当前最重要的所有权冲突是：`Book`/`Chapter` 同时被当作 UI 状态、数据库行、网络结果和缓存对象；重构时不能简单移动文件，必须先定义不可变领域字段和持久化映射。

## 6. 数据库访问调用清单

当前数据库入口集中在 Rust SQLite，但调用边界已泄漏到多个 Flutter 层：

| 调用者 | 直接依赖 | 当前用途 | R1 迁移目标 |
|---|---|---|---|
| `lib/main.dart` | `LegadoDbBridge.init` | 启动初始化数据库 | `AppBootstrap` 注入 `DatabasePort` |
| `lib/database/database_helper.dart` | FRB `api/db.dart` | 书籍、章节、书源、进度、缓存和配置 CRUD | `infrastructure/rust_database_repository` |
| `lib/database/dao/book_dao.dart` | `DatabaseHelper` | 书籍/章节 DAO 薄封装 | 领域 `BookRepository`/`ChapterRepository` 的具体实现 |
| `lib/database/dao/source_dao.dart` | `DatabaseHelper` | 书源 CRUD | `BookSourceRepository` 的具体实现 |
| `lib/providers/book_provider.dart` | `DatabaseHelper`、`BookDao`、Service | 书架、目录刷新、阅读进度和章节缓存编排 | `BookShelfUseCases`，Provider 只订阅状态 |
| `lib/model/read_book.dart` | `DatabaseHelper` | 阅读会话中直接读写书籍/章节 | `ReadingSession` + `ReadingRepository` |
| `lib/pages/book/book_info_page.dart` | `DatabaseHelper` | 详情页直接保存书籍/章节 | 通过 `BookDetailsUseCases` |
| `lib/pages/main/main_shell.dart` | `DatabaseHelper` | 页面层读取书架统计/数据 | 通过应用查询用例 |
| `lib/pages/book/bookmark_page.dart`、`toc_sheet.dart` | Rust DTO/Service/数据库间接链路 | 书签和目录元数据 | 通过 `BookmarkQuery`/`TocQuery` |
| `lib/services/*` | 多个 FRB API 和 Bridge | 备份、笔记、同步、阅读记录、WebDAV | 各自 infrastructure adapter + application use case |

R1 的第一项代码迁移应从 `DatabaseHelper` 的接口化开始，但必须先补齐字段映射和旧数据库迁移测试；不能先把文件移动到 `domain/` 造成“看起来分层、实际仍直连数据库”。

## 7. 迁移顺序

1. R0：保留当前实现，建立入口、所有权、依赖和行为基线。
2. R1：先统一领域模型和 Repository 接口，再迁移数据库调用；不先移动页面。
3. R2：以书源用例为第一个跨 Rust/Flutter 适配边界，集中 FRB 依赖。
4. R3：迁移阅读会话和正文/缓存链路，使用第 3 条逐页契约保护断行分页。
5. R4：迁移目录 Repository、顺序持久化、可见行元数据和列表渲染；执行兼容性子计划 2A/2B。
6. R5：迁移同步、备份和 WebDAV 冲突编排。
7. R6：最后按功能域收拢页面、Provider 和平台实现，避免 UI 移动反复返工。

## 8. R0 退出门禁

- [x] 已扫描 Flutter、Rust、FRB、数据库、服务和页面的实际目录。
- [x] 已记录启动、目录、正文三条主要链路。
- [x] 已确认重复模型/混合职责/生成层泄漏/页面直连基础设施等问题。
- [x] 已定义目标依赖方向和禁止依赖方向。
- [x] 为 R1 建立领域模型字段与数据所有权表。
- [x] 为 R1 建立当前数据库访问调用清单；迁移测试仍待 R1 建立。
- [x] 运行并记录 R0 全量测试基线：Rust `114` 个库测试及非 ignored 集成/文档测试通过；Flutter `383` 通过，3 个既有在线 smoke 跳过；`git diff --check` 通过。
- [x] 记录 `flutter analyze` 基线：命令退出码为 1，共 47 条既有诊断（4 warning、43 info）；本轮只修改文档，未新增 Dart 诊断。

因此，R0 的架构盘点和可重复测试基线已完成；`flutter analyze` 的 47 条既有诊断作为已知基线保留，不因本轮文档变更扩大。下一步进入 R1 的第一个最小边界：书籍/章节 Repository 接口化；迁移测试通过前不移动其他领域模型或页面。

## 9. R1 第一边界迁移记录：书籍/章节 Repository

日期：2026-07-25

实现：

- 新增 `lib/domain/repositories/book_repository.dart`，定义书籍、章节、进度和章节缓存所需的领域存储端口。
- `lib/database/dao/book_dao.dart` 保留为 Rust SQLite 的具体适配器，并实现 `BookRepository`；没有移动数据库实现或改变字段映射。
- `BookProvider` 的内部字段改为 `BookRepository`，所有书籍/章节存储调用改走接口；`dao:` 构造参数暂时保留，作为迁移期间的兼容注入入口。
- 新增 `test/domain/book_repository_contract_test.dart`，验证 SQLite 适配器满足领域端口。

行为验证：

- Provider 定向测试：`6/6` 通过，覆盖并发目录加载、旧源结果隔离、目录刷新进度迁移和章节缓存一致性。
- Rust 全量：`114` 通过；首次并行重跑曾因测试进程继承失效 `127.0.0.1:1080` 代理导致本地 fixture 失败，清除测试进程代理变量后重跑通过；未修改测试或业务代理逻辑。
- Flutter 全量：`384` 通过，3 个既有在线 smoke 跳过。
- 相关 Dart 静态检查：无新增诊断；全仓 `flutter analyze` 仍为既有 `47` 条诊断。
- `dart format --set-exit-if-changed` 和 `git diff --check`：通过。

边界结论：本步只完成 Provider 到 Repository 的依赖反转，数据库、ReadBook、页面直连和其他模型尚未迁移；下一步仍属于 R1，先建立数据库字段映射/迁移契约，再决定是否迁移 `DatabaseHelper`。

## 10. R1 第二边界迁移记录：数据库记录映射与旧 schema 契约

日期：2026-07-25

实现：

- 新增 `lib/infrastructure/database/database_record_codec.dart`，集中 `Book`/`Chapter` 与 Rust SQLite JSON 记录之间的编码、解码和章节缓存清除标记。
- `DatabaseHelper` 的书籍和章节读写改用 `DatabaseRecordCodec`；书源、替换规则和其他业务暂不迁移，保持本边界单一。
- Rust 数据库新增 `legacy_v7_schema_migrates_to_current_without_losing_book_rows`，验证旧 v7 表升级到当前 v15 后保留书籍数据，并补齐代表性迁移列。

验收：

- 数据库编解码定向测试：`3/3` 通过。
- Rust 迁移定向测试：`1/1` 通过。
- Rust 全量：`115` 通过；3 个需网络的 ignored 测试保持跳过。
- Flutter 全量：`387` 通过，3 个既有在线 smoke 跳过。
- 相关 Dart 静态检查：无诊断；全仓 `flutter analyze` 仍为既有 `47` 条诊断。
- `dart format --set-exit-if-changed`、`git diff --check`：通过。

边界结论：数据库字段映射已从 `DatabaseHelper` 中集中，但 `DatabaseHelper` 仍直接依赖 FRB 生成 API；下一步 R1-3 才处理 `RustDatabasePort`/FRB 适配边界，不在本步继续迁移其他数据对象。

## 11. R1 第三边界迁移记录：RustDatabasePort 与 FRB 适配隔离

日期：2026-07-25

实现：

- 新增 `lib/infrastructure/database/rust_database_port.dart`，定义数据库基础设施端口。
- 新增 `lib/infrastructure/database/frb_rust_database_port.dart`，集中实现 `LegadoDbBridge` ready 检查和全部 FRB `api/db.dart` 调用。
- `DatabaseHelper` 改为依赖 `RustDatabasePort`；生产默认使用 `FrbRustDatabasePort`，测试可通过 `DatabaseHelper.forPort` 注入 fake。
- `DatabaseHelper` 已不再直接导入 `legado_db_bridge.dart` 或 `src/rust/api/db.dart`。
- 新增 `test/infrastructure/rust_database_port_test.dart`，验证数据库管理器可以在不加载 FRB 数据库 API 的情况下使用端口。

验收：

- R1-3 定向测试：`5/5` 通过（含前两项数据库契约回归）。
- Rust 全量：`115` 通过；3 个需网络的 ignored 测试保持跳过。
- Flutter 全量：`388` 通过，3 个既有在线 smoke 跳过。
- 相关 Dart 静态检查：无诊断；全仓 `flutter analyze` 仍为既有 `47` 条诊断。
- `dart format --set-exit-if-changed`、`git diff --check`：通过。

边界结论：FRB 数据库调用已从 `DatabaseHelper` 隔离，但页面、`ReadBook`、Provider 和其他 Service 仍可直接构造 `DatabaseHelper`；下一步 R1-4 迁移这些调用到应用/领域 Repository，先处理 `BookProvider` 之外的书籍读写入口。

## 12. R1-4a：ReadBook 阅读会话 Repository 注入

日期：2026-07-25

实现：

- `BookRepository` 增加章节正文读取契约 `getChapterContent`，由 `BookDao` 转发到现有数据库适配器。
- `ReadBook` 移除对 `DatabaseHelper` 的直接依赖，改为通过 `BookRepository` 读取数据库正文，并通过同一接口写入章节和正文。
- `BookProvider` 将自身已有的 `_repository` 注入 `ReadBook`，不再为阅读会话单独构造 `DatabaseHelper`。
- 数据库正文回落测试改为注入 `BookDao`，验证真实存储适配器仍满足阅读会话契约。

行为验证：

- R1-4a 定向测试：`10/10` 通过，覆盖 DB 正文回落、占位正文网络重试、旧会话结果隔离、预加载令牌隔离和 Provider 目录/进度回归。
- 正文读取顺序保持：文件缓存 -> 数据库正文 -> 网络；未改变正文处理、缓存跳过和失败占位语义。
- `dart format`、`git diff --check`：通过。

边界结论：`ReadBook` 已不再直接构造或依赖 `DatabaseHelper`；页面和其他 Service 的直接数据库调用仍保留，下一步只迁移其中一个调用者，完成后再复验全量门禁。

## 13. R1-4b：LocalBookService Repository 注入

日期：2026-07-25

实现：

- `LocalBookService` 移除 `DatabaseHelper` 依赖，改为要求注入 `BookRepository`。
- `BookProvider` 将自身的 Repository 传入默认创建的 `LocalBookService`；自定义 `localService` 的测试注入入口保留。
- 本地 TXT 导入测试增加 Repository 记录适配器，验证书籍和章节落库都经过领域端口。

行为验证：

- R1-4b 定向测试：`13/13` 通过，覆盖 TXT 导入、Provider 目录并发/缓存一致性/进度迁移，以及 ReadBook 数据库回落。
- Flutter 全量：`389` 通过，3 个既有在线 smoke 跳过。
- 本步未修改 Rust；上一边界 Rust 全量 `115` 通过，3 个网络 ignored 测试保持跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。

边界结论：本地书籍导入已通过领域 Repository 持久化；剩余直接构造 `DatabaseHelper` 的调用者为页面、`main_shell` 和 `ReplaceProvider`，下一步继续逐个迁移。

## 14. R1-4c：ReplaceProvider 替换规则 Repository 注入

日期：2026-07-25

实现：

- 新增 `lib/domain/repositories/replace_rule_repository.dart`，定义替换规则查询、写入、更新、启停、删除和清空端口。
- 新增 `ReplaceRuleDao`，把现有 `DatabaseHelper` 替换规则 CRUD 收敛到具体 DAO 适配器。
- `ReplaceProvider` 改为依赖 `ReplaceRuleRepository`，保留默认 DAO 和测试注入入口；默认规则初始化、ContentProcessor 同步和预设去重逻辑不变。
- 新增 Provider Repository 契约测试，覆盖默认规则初始化和规则增删改、启停流程。

行为验证：

- R1-4c 定向测试：`12/12` 通过。
- Flutter 全量：`390` 通过，3 个既有在线 smoke 跳过。
- 本步未修改 Rust；上一边界 Rust 全量 `115` 通过，3 个网络 ignored 测试保持跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。

边界结论：替换规则 Provider 已不再直接构造 `DatabaseHelper`；剩余直接数据库调用集中在书籍详情页、`MainShell` 和其他页面/服务边界，下一步继续逐个迁移。

## 15. R1-4d：BookInfoPage 书籍 Repository 注入

日期：2026-07-25

实现：

- `BookProvider` 暴露领域级 `BookRepository` 查询入口，保持具体 DAO 不向页面泄漏。
- `BookInfoPage` 的封面更新和编辑书籍保存改为通过 `BookProvider.repository` 写入，不再直接构造 `DatabaseHelper`。
- 页面构造签名和现有路由保持不变，目录加载、书源请求和阅读位置逻辑未修改。

行为验证：

- 详情页相关定向回归：`10/10` 通过，包含 MainShell、Provider 目录/进度和 Repository 契约测试。
- Flutter 全量：`390` 通过，3 个既有在线 smoke 跳过。
- 本步未修改 Rust；上一边界 Rust 全量 `115` 通过，3 个网络 ignored 测试保持跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。

边界结论：`BookInfoPage` 已不再直接依赖数据库实现；剩余直接数据库调用集中在 `MainShell`、其他页面和服务边界，下一步继续逐个迁移。

## 16. R1-4e：MainShell 书源 Repository 注入

日期：2026-07-25

实现：

- 新增 `BookSourceRepository` 领域端口，定义书源查询、写入、更新、启停和删除契约。
- `SourceDao` 实现该端口，继续作为现有 SQLite/Rust 适配器。
- `SourceProvider` 暴露领域级书源 Repository，`MainShell` 的内置书源检查和初始化改为通过该端口完成，不再直接构造 `DatabaseHelper`。
- 书源 Provider 的完整 CRUD、搜索和校验链路未在本步改动。

行为验证：

- MainShell/书源定向测试：`10/10` 通过，包含启动框架、书源导入和书源 Repository 契约。
- Flutter 全量：`391` 通过，3 个既有在线 smoke 跳过。
- 本步未修改 Rust；上一边界 Rust 全量 `115` 通过，3 个网络 ignored 测试保持跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。

边界结论：`MainShell` 已不再直接依赖数据库管理器；剩余直接数据库调用集中在 SourceProvider、其他页面和服务边界，下一步继续逐个迁移。

## 17. R1-4f：SourceProvider 书源 Repository 注入

日期：2026-07-25

实现：

- `SourceProvider` 增加 `BookSourceRepository` 注入入口，内部所有书源加载、写入、更新、启停、删除和启用书源查询均通过接口调用。
- 默认实现仍为 `SourceDao`，生产行为和旧构造方式保持兼容。
- 新增 SourceProvider Repository 测试，验证加载和新增书源使用注入适配器。
- 搜索、书源校验、分组、导入和书源顺序算法未改变。

行为验证：

- SourceProvider/MainShell 定向测试：`11/11` 通过。
- Flutter 全量：`392` 通过，3 个既有在线 smoke 跳过。
- 本步未修改 Rust；上一边界 Rust 全量 `115` 通过，3 个网络 ignored 测试保持跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。

边界结论：书源 Provider 已不再依赖具体 DAO 类型进行业务操作；剩余直接数据库调用集中在其他页面和服务边界，下一步继续逐个迁移。

## 18. R1-5：AppBootstrap 启动编排

日期：2026-07-25

实现：

- 新增 `lib/application/app_bootstrap.dart`，集中编排 `EngineConfig`、应用配置、Rust/数据库初始化、网络/Web API 配置、书架初始加载和主题加载。
- `main.dart` 只负责 Flutter binding、Provider 组装和 `runApp`；不再直接编排基础设施启动顺序。
- 保留 `loadStartupBookProgress` 的导出兼容入口，启动同步失败仍只记录并降级为未应用进度，不阻塞首屏。
- 本步未改变 Provider 注册、书源初始化、目录顺序、阅读位置或正文处理行为。

行为验证：

- 启动/Widget 定向测试：`8/8` 通过。
- Flutter 全量：`392` 通过，3 个既有在线 smoke 跳过。
- 本步未修改 Rust；上一边界 Rust 全量 `115` 通过，3 个网络 ignored 测试保持跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。

边界结论：应用入口已将启动基础设施编排移入 application 层；R1 的主要数据库调用边界已完成，下一步进入 R2/R3 的书源用例与阅读会话进一步收敛。

## 19. R2-1：书源搜索入口端口化

日期：2026-07-25

实现：

- 新增 `BookSourceSearchPort`，定义搜索入口所需的最小 Rust 引擎契约。
- 新增 `FrbBookSourceSearchPort`，集中把搜索调用转发到现有 `LegadoEngineBridge`，并保留 Rust 未加载错误语义。
- `BookSourceService.search` 改为依赖可注入搜索端口；详情、目录、正文和发现入口暂留在原链路，控制本步行为范围。
- 新增搜索端口注入测试，确认 Service 不需要直接加载 FRB 即可测试搜索编排。

行为验证：

- R2-1 书源链路定向测试：`16/16` 通过，包含 Rust 搜索→详情→目录→正文和离线 JS fixture 回归。
- Flutter 全量：`393` 通过，3 个既有在线 smoke 跳过。
- 本步未修改 Rust；Rust 全量基线 `115` 通过，3 个网络 ignored 测试保持跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。

边界结论：搜索入口已隔离到 infrastructure 适配器；下一步逐个迁移书源详情、目录和正文入口，保持目录顺序与正文处理行为不变。

## 20. R2-2：书源详情入口端口化

日期：2026-07-25

实现：

- 新增 `BookSourceBookInfoPort`，定义书源详情入口所需的最小 Rust 引擎契约。
- 新增 `FrbBookSourceBookInfoPort`，集中把详情调用转发到现有 `LegadoEngineBridge`，并保留 Rust 未加载错误语义。
- `BookSourceService.getBookInfo` 改为依赖可注入详情端口；搜索、目录、正文和发现入口未在本步改变。
- 新增详情端口注入测试，验证详情请求的书源、URL 和返回字段由 Service 原样编排。

行为验证：

- R2-2 定向测试：`14` 个通过，包含详情端口契约、R2-1 搜索端口和 Rust 搜索→详情→目录→正文链路；`1` 个既有在线 smoke 跳过。
- Flutter 全量：`394` 通过，3 个既有在线 smoke 跳过。
- Rust workspace：`115` 通过，3 个网络测试 ignored。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步新增文件和修改没有新增诊断。

边界结论：书源搜索和详情入口已隔离到 infrastructure 适配器；目录加载顺序、章节 index、正文内容、中文断行和分页行为本步未修改。下一步继续逐个迁移目录入口，并在迁移中保持原 App 的断行规则。

## 21. R2-3：书源目录入口端口化

日期：2026-07-25

实现：

- 新增 `BookSourceTocPort`，定义目录请求所需的最小 Rust 引擎契约。
- 新增 `FrbBookSourceTocPort`，集中把目录调用转发到现有 `LegadoEngineBridge`，并保留 Rust 未加载错误语义。
- `BookSourceService.getChapters` 改为通过注入的目录端口获取章节；详情预热、`tocUrl` 重定位、同书源请求去重和源站繁忙重试编排保持不变。
- 新增目录端口契约测试，验证传入书籍、`tocUrl` 重定位、章节顺序和 0-based `index` 均保持原行为。

行为验证：

- R2-3 定向测试：`25` 个通过，包含目录/详情/搜索端口和 Rust 搜索→详情→目录→正文链路；`1` 个既有在线 smoke 跳过。
- Flutter 全量：`395` 通过，3 个既有在线 smoke 跳过。
- Rust workspace 串行测试：核心 crate `115` 通过，其余已执行 workspace 测试通过；现有网络/人工场景保持 ignored。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步新增文件和修改没有新增诊断。
- 并行 Rust 全量曾出现 1 个既有目录 fixture 因共享全局网络代理配置而失败；该用例单独 `1/1` 通过，使用 `--test-threads=1` 的 workspace 全量通过。未修改测试断言。

边界结论：书源搜索、详情和目录入口已隔离到 infrastructure 适配器；目录返回顺序、章节身份和 `index` 未被重排，正文内容、中文断行和分页行为本步未修改。下一步继续迁移书源正文入口。

## 22. R2-4：书源正文入口端口化

日期：2026-07-25

实现：

- 新增 `BookSourceContentPort`，定义书源正文请求所需的最小 Rust 引擎契约。
- 新增 `FrbBookSourceContentPort`，集中把正文调用转发到现有 `LegadoEngineBridge`，并保留 Rust 未加载错误语义。
- `BookSourceService.getChapterContent` 改为通过可注入正文端口获取文本；日志、异常重新抛出和调用参数保持不变。
- 新增正文端口契约测试，验证书源、章节 URL 和包含 `CRLF/LF` 的正文文本均原样传递，不在 Service 层引入换行、清洗或分页逻辑。

行为验证：

- R2-4 定向测试：`26` 个通过，包含正文/目录/详情/搜索端口、离线 JSON/JS 正文和 Rust 搜索→详情→目录→正文链路；`1` 个既有在线 smoke 跳过。
- Flutter 全量：`396` 通过，3 个既有在线 smoke 跳过。
- Rust workspace 串行测试：核心 crate `115` 通过，其余已执行 workspace 测试通过；现有网络/人工场景保持 ignored。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步新增文件和修改没有新增诊断。

边界结论：书源搜索、详情、目录和正文入口已隔离到 infrastructure 适配器；正文文本、中文断行、分页输入和错误传播本步未改变。下一步继续迁移发现入口或进入阅读会话边界，仍按固定顺序逐项推进。

## 23. R2-5：书源发现入口端口化

日期：2026-07-25

实现：

- 新增 `BookSourceExplorePort`，定义发现请求所需的最小 Rust 引擎契约。
- 新增 `FrbBookSourceExplorePort`，集中把发现调用转发到现有 `LegadoEngineBridge`，并保留 Rust 未加载错误语义。
- `BookSourceService.explore` 改为通过可注入发现端口转发书源、发现 URL 和页码；发现分类解析和页面分页逻辑未改变。
- 新增发现端口契约测试，验证页码、请求参数和结果列表由 Service 原样编排。
- 书源搜索、详情、目录、正文和发现五个 Rust 入口完成第一轮端口化后，移除 Service 中已无调用点的旧 Rust 前置检查和桥接依赖。

行为验证：

- R2-5 定向测试：`13` 个通过，`1` 个既有在线 smoke 跳过；发现端口、既有四个入口端口和 Rust 搜索→详情→目录→正文链路均通过。
- Flutter 全量：`397` 通过，3 个既有在线 smoke 跳过。
- Rust workspace 串行测试：核心 crate `115` 通过，其余已执行 workspace 测试通过；现有网络/人工场景保持 ignored。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步最终代码没有新增诊断；中途发现的 `_requireRust` 未使用诊断已删除。

边界结论：书源搜索、详情、目录、正文和发现入口已隔离到 infrastructure 适配器；正文内容、目录顺序、中文断行、分页输入和现有错误语义未改变。下一步进入书源校验用例或阅读会话边界，继续按固定顺序逐项重构。

## 24. R2-6：书源校验入口端口化

日期：2026-07-25

实现：

- 新增 `BookSourceValidationPort` 和纯 Dart `BookSourceValidationSnapshot`，隔离 FRB 生成的 `SourceValidation` 类型。
- 新增 `FrbBookSourceValidationPort`，集中把校验调用转发到现有 `LegadoEngineBridge`，并保留 Rust 可用性和错误语义。
- `SourceProvider.validateSource` 改为通过注入校验端口获取结果；关键词选择、超时、阶段进度、校验偏好裁剪、结果持久化、响应时间回写和 UI 状态更新未改变。
- 新增 SourceProvider 校验端口契约测试，验证书源、关键词、结果字段和错误列表均按原流程传递。

行为验证：

- R2-6 定向测试：`9` 个通过，3 个既有在线 smoke 跳过；校验端口、SourceProvider Repository、结果持久化和 Rust 调试链路通过。
- Flutter 全量：`398` 通过，3 个既有在线 smoke 跳过。
- Rust workspace 串行测试：核心 crate `115` 通过，其余已执行 workspace 测试通过；现有网络/人工场景保持 ignored。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步最终代码没有新增诊断。

边界结论：书源搜索、详情、目录、正文、发现和校验入口已隔离到 infrastructure 适配器；校验步骤顺序、超时、状态更新、错误列表和阅读相关断行/分页行为未改变。下一步进入阅读会话或其他 Rust 业务入口，继续按固定顺序逐项重构。

## 25. R2-7：书源调试入口端口化

日期：2026-07-25

实现：

- 新增 `BookSourceDebugPort`、`BookSourceDebugSnapshot`、`BookSourceDebugStep` 和 `BookSourceDebugItem`，把调试搜索、调试目录和 URL 请求定义为纯 Dart 领域边界。
- 新增 `FrbBookSourceDebugPort`，集中把调试入口转发到现有 `LegadoEngineBridge`，并在适配层将 FRB `DebugResult` 映射为领域快照；Rust 不可用时保留原错误语义。
- `SourceDebugPage` 改为依赖可注入调试端口；搜索、章节调试、URL 测试的请求顺序、参数、加载状态和错误日志保持原行为。
- `SourceDebugPanel` 和 `formatDebugLog` 改为消费纯 Dart 快照，页面展示层不再直接导入 FRB 生成的 `DebugResult`/`DebugItem`。
- 新增调试端口契约测试，并保留原日志字段、规则步骤、结果上限和响应预览格式；未引入正文清洗、中文断行、分页或目录排序逻辑。

行为验证：

- R2-7 定向测试：`3` 个通过，包含调试端口可替换契约、Rust 不可用错误语义和日志格式化回归。
- Flutter 全量：`400` 个通过，`3` 个既有在线 smoke 跳过。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步没有新增诊断；命令仍因既有诊断返回非零。

边界结论：书源搜索、详情、目录、正文、发现、校验和调试入口均已隔离到 infrastructure 适配器；调试请求和日志展示不再把 FRB 类型扩散到页面，原 App 的目录顺序、章节 `index`、正文内容、中文断行和分页行为未改变。下一步进入 R3 阅读会话、正文处理与缓存链路。

## 25.1 R1-6：SourceDebugPage FRB Feature 边界复验

日期：2026-07-27

范围：

- 原版只读核对文件：`legado-main/app/src/main/java/io/legado/app/ui/book/source/debug/BookSourceDebugActivity.kt`、`BookSourceDebugModel.kt` 与 `model/Debug.kt`。
- 当前工程将 `BookSourceDebugPort` 的 FRB 实现创建责任收敛到 `lib/main.dart` 根组合层；`lib/features/sources/source_debug_page.dart` 只接收领域端口，不再导入或构造 `FrbBookSourceDebugPort`。
- 新增 `test/features/sources/source_debug_page_test.dart`，以 fake port 验证搜索调用参数、引擎不可用时不发起调用、调试失败时保留错误日志。

不做事项与已知缺口：

- Kotlin 原版为统一调试工作流，支持五种输入路径、增量状态和取消；当前 Rust 仅有独立的 `debug_search` 与 `debug_toc`，没有统一会话事件流或取消 API。本单元不改变 Rust API，也不把当前三标签 Flutter 页面误记为与原版统一流程等价。
- `SourceDebugPage` 的 `dart:io` 同步日志保存仍是独立的平台文件操作迁移项。
- 未触及目录排序、章节身份、正文内容、中文断行、分页或阅读位置。

验证：

- `flutter test --no-pub test/features/sources/source_debug_page_test.dart test/infrastructure/engine/frb_book_source_debug_port_test.dart test/services/source_debug_formatter_test.dart`：`6` 通过。
- `flutter analyze --no-pub lib/main.dart lib/features/sources/source_debug_page.dart test/features/sources/source_debug_page_test.dart`：`No issues found`。
- 静态边界脚本由 `21` 项降至 `19` 项；其非零退出码仍代表未迁移 backlog，不能作为本单元失败或 R6 退出结论。

边界结论：本单元仅消除了 Feature 对 FRB adapter 的两处直接依赖，端口的组装仍限于受控应用启动组合层。原版统一调试会话能力保留为后续 Rust R2 迁移条件。

## 25.2 R1-7：TocSheet 数据与缓存依赖边界复验

日期：2026-07-27

范围：

- 原版只读核对文件：`legado-main/app/src/main/java/io/legado/app/ui/book/toc/TocViewModel.kt`。其中 `reverseToc` 先翻转已保存章节并连续重写 `index`，再保存书籍的 `reverseToc`。
- `lib/features/book/toc_sheet.dart` 不再导入 `BookDao` 或 `FileChapterContentCache`，也不在 Feature 内构造它们；`TocSheet.show` 从可用的 `BookProvider` 取得 `BookRepository` 和 `ChapterContentCachePort`，直接构造的离线预览保持可用但不猜测基础设施实现。
- `lib/providers/book_provider.dart` 公开既有缓存端口的只读 getter，未修改缓存文件布局、缓存命中、网络加载或目录首帧策略。

不做事项：

- 不改目录默认顺序、`reverseToc`、章节身份、0-based `index`、缓存字数计算、正文、中文断行、分页或阅读位置。
- 不迁移 `BookProvider` 自身的 DAO/缓存默认组装；该 Provider 越界项留在后续 R1/R3 调用者迁移单元。

验证：

- `dart format --output=none --set-exit-if-changed lib/providers/book_provider.dart lib/features/book/toc_sheet.dart`：通过。
- `flutter analyze --no-pub lib/providers/book_provider.dart lib/features/book/toc_sheet.dart test/pages/book/toc_order_test.dart`：`No issues found`。
- `flutter test --no-pub test/pages/book/toc_order_test.dart`：`5` 通过，覆盖原顺序、界面翻转、持久化翻转与连续重编号、远端目录 0-based 归一化、`reverseToc` 序列化。测试 fixture 会记录 SharedPreferences/Rust 未初始化的既有正文回退日志，但不影响目录契约断言，未将其视为集成通过。

边界结论：目录 Feature 不再直接控制 DAO 或文件缓存适配器；原版目录翻转和索引顺序保持由既有契约覆盖。

## 25.3 R1-8：ReplaceProvider Repository 组合边界复验

日期：2026-07-27

范围：

- 原版只读核对文件：`legado-main/app/src/main/java/io/legado/app/data/dao/ReplaceRuleDao.kt`。其规则查询保持 `sortOrder` 顺序，插入、更新、删除和启停均是持久化行为。
- `lib/providers/replace_provider.dart` 改为要求 `ReplaceRuleRepository`，不再导入或默认构造 `ReplaceRuleDao`。
- `lib/main.dart` 根组合层创建 `ReplaceRuleDao` 并传入 Provider；默认规则首次初始化、载入 `ReplaceService` 和 `ContentProcessor` 的顺序不变。

不做事项：

- 不改规则匹配、替换执行、内容净化、正文字符、中文断行、分页、目录或 Rust API。
- 不迁移 `ContentProcessor` 与 `ReplaceService` 的 Dart 规则执行；它们仍是 R3 的 Rust 唯一事实来源迁移项。

验证：

- `dart format --output=none --set-exit-if-changed lib/providers/replace_provider.dart lib/main.dart test/widget/main_shell_test.dart`：通过。
- `flutter analyze --no-pub lib/main.dart lib/providers/replace_provider.dart test/providers/replace_provider_repository_test.dart test/widget/main_shell_test.dart`：`No issues found`。
- `flutter test --no-pub test/providers/replace_provider_repository_test.dart test/widget/main_shell_test.dart`：`3` 通过，覆盖替换规则 Repository CRUD 与 MainShell 入口；测试加载 Rust 引擎成功。
- `git diff --check`：通过。

边界结论：Provider 只依赖领域仓储；DAO 实例仅在受控根组合层创建。原版规则排序和 CRUD 语义由既有契约测试保持。

## 25.4 R1-9：BookProvider 数据与缓存组合边界复验

日期：2026-07-27

范围：

- 原版只读核对文件：`legado-main/app/src/main/java/io/legado/app/data/dao/BookDao.kt`。书籍和章节的读取、替换插入、删除与进度更新属于持久化层；书架页面状态不拥有数据库实现。
- Rust 现状：`rust/legado_engine/src/api/db.rs` 与 `rust/legado_engine/src/db/mod.rs` 已提供书籍、章节存取；本单元不改变其 schema、FRB API 或事务。
- `lib/providers/book_provider.dart` 改为要求 `BookRepository` 和 `ChapterContentCachePort`，不再导入或默认构造 `BookDao`、`FileChapterContentCache`。
- `lib/application/app_bootstrap.dart` 是受控启动组合点，显式创建既有 DAO/cache adapter；`ReadBook.instance.configure` 的 source service、repository、正文处理与缓存注入顺序不变。
- 所有测试构造点显式传入既有 adapter 或 fake，覆盖 Android 阅读器集成测试的编译入口。

不做事项：

- 不改 Rust 书籍/章节 schema、DAO 查询语义、目录合并、章节 `index`、缓存文件布局、缓存生命周期、正文内容、中文断行、分页或阅读位置。
- 不迁移 `BookSourceService` 的 Dart 网络责任；该项仍按 R2 的 Rust 网络迁移处理。

验证：

- `flutter analyze --no-pub`（AppBootstrap、BookProvider、所有更新的 unit/widget/integration 测试文件）：`No issues found`。
- 定向串行回归覆盖目录顺序与翻转、书架排列、BookProvider 并发目录/自动换源/缓存一致性/缓存端口/进度迁移/tocUrl、书架空态和 MainShell：`22` 通过。
- `flutter test --no-pub --concurrency=1`：`519` 通过、`3` 个既有在线 smoke 跳过。
- `dart format --output=none --set-exit-if-changed` 与 `git diff --check`：通过。
- 静态边界检查由 `13` 降至 `9` 项；未归零的退出码继续表示分阶段 backlog，不是本单元失败。

边界结论：BookProvider 仅编排领域仓储和缓存端口；生产依赖只在启动组合层创建。原版书架数据职责、目录/缓存/阅读行为保持不变。

## 25.5 R1-10：SourceProvider Repository 组合边界复验

日期：2026-07-27

范围：

- 原版只读核对文件：`legado-main/app/src/main/java/io/legado/app/data/dao/BookSourceDao.kt`。书源按 `customOrder` 排序，启用状态、分组查询和批量写入属于存储层。
- Rust 现状：`rust/legado_engine/src/db/mod.rs` 保留书源表的插入、更新、删除与查询；`api/validate.rs` 是独立的 R2 校验能力。本单元不修改 Rust、schema、校验或 FRB。
- `lib/providers/source_provider.dart` 改为要求 `BookSourceRepository`，不再导入或默认构造 `SourceDao`；内置书源空库导入、分组同步和失败传播顺序不变。
- `lib/main.dart` 根组合层显式创建既有 `SourceDao`。校验 port 的 FRB 默认组装保留，作为 R2 的单独迁移项。

不做事项：

- 不改书源排序、启用状态、分组标签、内置源内容、导入/导出、网络请求、规则解析、校验结果、正文断行或分页。
- 不移动 `FrbBookSourceValidationPort`；它是 R2 引擎适配器边界，不能借 R1 DAO 清理提前改变。

验证：

- `flutter analyze --no-pub`（main、SourceProvider、所有更新的 unit/widget/integration 测试文件）：`No issues found`。
- 定向串行回归覆盖图片 header、书源 repository CRUD、空库内置源导入、非空库跳过、启动失败传播、校验 fake、书架排列与 MainShell：`11` 通过。
- `flutter test --no-pub --concurrency=1`：`519` 通过、`3` 个既有在线 smoke 跳过。
- `dart format --output=none --set-exit-if-changed` 与 `git diff --check`：通过。
- 静态边界检查由 `9` 降至 `7` 项；其中 SourceProvider 剩余的两项 FRB validation 违规明确登记为 R2，而非 R1 遗漏。

边界结论：SourceProvider 的存储依赖已收敛到领域仓储和根组合层；原版书源持久化语义与内置源启动策略保持不变。

## 25.6 R1-11：SourceProvider 校验 FRB 组合边界复验

日期：2026-07-27

范围：

- `lib/providers/source_provider.dart` 改为要求 `BookSourceValidationPort`，不再导入或构造 `FrbBookSourceValidationPort`。
- `lib/main.dart` 根组合层创建 `FrbBookSourceValidationPort` 并注入 SourceProvider；校验快照、未初始化状态、超时和错误展示逻辑未改。
- 原版只读核对路径：`legado-main/app/src/main/java/io/legado/app/data/dao/BookSourceDao.kt` 负责书源持久化；规则校验并非由页面持有数据库/FRB 实现。

验证：

- `flutter analyze --no-pub`：`No issues found`。
- 定向书源/主壳回归：`11` 通过；校验测试继续以 fake port 验证请求与快照映射。
- `flutter test --no-pub --concurrency=1`：`519` 通过、`3` 个既有在线 smoke 跳过。
- `cargo test --workspace`：Rust 核心 `117` 通过；既有网络 e2e 保持 ignored，编译输出保留现有 FRB macro warning。
- `dart format --output=none --set-exit-if-changed` 与 `git diff --check`：通过。
- 静态边界检查由 `7` 降至 `5` 项；剩余项为 R2 RSS Dart HTTP、R3 reader cache adapter、R4 remote WebDAV adapter 和备份文件 adapter。

边界结论：SourceProvider 只依赖领域仓储和校验 port，FRB 仅留在 infrastructure adapter 与根组合层。

## 25.7 R1 退出审计（当前工作树）

日期：2026-07-27

通过证据：

- 数据模型与 port：Book/Chapter codec、BookRepository、BookSourceRepository 和 Rust database port 契约通过。
- 旧 schema：Rust `db::tests::legacy_v7_schema_migrates_to_current_without_losing_book_rows` 证明本工程 Rust v7 schema 可升级至 v17、保留书籍行并可写入新增字段。
- 章节身份与位置：章节 URL 优先、标题回退、删章重置、0-based index 重排、页位置半开区间和 UTF-16 位置映射由 `chapter_progress_migrator`、BookProvider 和 reading position mapper 契约覆盖；定向集合 `26` 通过。
- 质量门禁：全仓 analyze 无诊断、串行 Flutter 全量 `519` 通过且 `3` 个既有在线 smoke 跳过、Rust workspace 通过。

范围限制：

- Kotlin 原版当前 Room schema 在 `legado-main/app/src/main/java/io/legado/app/data/AppDatabase.kt` 中为 v99；手写迁移链在 `DatabaseMigrations.kt` 覆盖 10→43，随后由 Room auto migration 覆盖 43→99。当前 Rust legacy fixture 是本工程 Rust v7 schema，不是 Kotlin Room 数据库文件。
- 2026-07-27 用户已确认必须支持原版 Kotlin Room 数据库迁移。因此“可读写旧数据库”仅对本工程 Rust 旧 schema 成立；不得宣称已经支持原版 Android 数据库文件迁移。
- 从已安装 Kotlin 原版直接迁移数据库需单独定义导入范围、表映射、冲突策略、备份/回滚与真实 Room fixture，不得把该工作混入 R2 网络迁移。

判定：R1 领域/FRB 边界在当前工程 schema 范围内技术退出就绪；但 R1 因 Kotlin Room v99 数据迁移门禁重新打开，完成 R1-12 前不得进入新的 R2 实现或宣称 R1 最终退出。

## 25.8 R1-12：Kotlin Room v99 初始探针记录（历史）

日期：2026-07-28

实现范围：

- `rust/legado_engine/src/db/room_import.rs` 提供只读 Room 探针、稳定快照和 Rust v17 映射，覆盖
  `books`、`book_sources`、`chapters`、`bookmarks`、`readRecord`、`detailedReadRecord`、
  `replace_rules` 七张核心表；探针读取 `user_version`、identity hash、表和列形状。
- 建立 Room → Rust 映射：`bookUrl` → `Book.id/sourceUrl`、`origin` → `bookSourceUrl`、
  `durChapterPos` → UTF-16 章内 `currentPageIndex`；书源规则 JSON 解析为嵌套对象并保留
  `rawSourceJson`；章节 ID 使用与 Flutter `Chapter.idFor` 一致的 UTF-16 FNV-1a；详细阅读记录按书籍
  聚合，`readRecord` 暂不猜测含义并登记 warning。
- 书签只在书名和作者唯一匹配时填写 `bookId`，冲突时留空并报警；Rust v17 新增
  `legacy_room_imports` 原始快照归档与 fingerprint，保留完整源行和未映射列。
- 导入包含导入前备份、单事务写入、失败回滚、重复 fingerprint 幂等，并返回导入计数、冲突、警告和
  未映射列。FRB 2.11.1 绑定、Dart application port/service 和备份页触发入口已接入。
- 本轮未修改正文、目录顺序、章节身份规则、分页输入、中文断行规则或 `legado-main/`。

验证：

- `cargo fmt -p legado_engine`：通过。
- `cargo test -p legado_engine db::room_import::tests -- --nocapture`：`9/9` 通过，覆盖探针、核心字段
  映射、阅读位置、书源规则、章节身份、详细阅读记录、书签歧义、备份/回滚和重复导入。
- `cargo test -p legado_engine`：`126` 个 Rust 测试通过；既有网络 ignored 测试保持原规则。
- `flutter analyze --no-pub`：通过，`No issues found!`；Dart/备份页定向测试 `6/6` 通过。
- `flutter test --no-pub --concurrency=1`：`521` 通过，3 个既有在线测试跳过。首次全量 release DLL
  content hash 过期，重建 release DLL 后重跑通过；没有修改测试断言。
- 对真实 `original_legado.db` 的只读探测得到 Room v99、identity hash
  `90980f1d0da029cf3254f354b227a2fe`；七张核心表均存在但当前均为 0 行。

限制与边界结论：

- 没有真实非空 Room 数据或非空等价 fixture 的逐字段迁移证据。
- 原版迁移范围内的非核心 Room 扩展表尚未纳入导入范围。
- 尚未在 Android 设备上验收真实文件导入、重启后继续写入以及再次备份/恢复。

因此，25.8 仅记录 2026-07-28 的初始探针状态；其后续结果由 25.9 的最终退出记录取代，
不能单独作为当前 R1-12 判定。

## 25.9 R1-12：Kotlin Room v99 数据库迁移门禁历史记录（当前状态已复核）

本节保留 2026-07-29 的阶段性实现与验证记录，不作为当前 R1-12 或 R1 最终退出判定。实现位于
`rust/legado_engine/src/db/room_import.rs`，原版 `legado-main/` 仍只读。

实现范围：

- 按原版 Room v99 schema 抽取全部 23 个实体表的稳定列和值；`book_sources_part` 是 schema 定义的只读 view，
  不作为独立实体迁移。
- 七张核心表映射到 Rust v17；章节 ID 保持 UTF-16 FNV-1a，`durChapterPos` 保持 UTF-16 章内位置语义，
  书源规则 JSON 解析为嵌套对象并保留原始字符串，书签身份冲突留空并报警。
- `legacy_room_imports` 保存全部实体表原始快照、列和值、fingerprint 和未映射字段；非核心表采用 archive-only
  保存，章节附加字段和替换规则 `group/scope` 等不会静默丢失。
- 导入前备份、单事务写入、失败回滚、重复 fingerprint 幂等、冲突统计、迁移报告、FRB 2.11.1、Dart
  application port/service 和备份页入口均已接入。

验证结果：

- `cargo fmt -p legado_engine`：通过。
- `cargo test -p legado_engine db::room_import::tests -- --nocapture`：`10/10` 通过。
- `cargo test -p legado_engine`：`127` 个 Rust 测试通过；既有网络 ignored 测试保持原规则。
- `flutter analyze --no-pub`：`No issues found!`；Dart/备份页定向测试 `6/6` 通过。
- `flutter test --no-pub --concurrency=1`：`521` 通过，3 个既有在线测试跳过。
- 真实 `original_legado.db`：Room v99，identity hash 为
  `90980f1d0da029cf3254f354b227a2fe`，23 个实体表存在；当前七张核心表均为空，`book_groups` 有 7 行，`keyboardAssists` 有 14 行；非空等价 fixture 已覆盖核心字段、
  阅读位置、规则 JSON、章节身份、详细记录、书签歧义和非核心原始行。
- Android `emulator-5556` 两阶段 Driver smoke 通过：真实文件导入及导入后写入；强制停止/新进程后读取、
  重复导入幂等、本地备份、清空和恢复。
  实际命令包含：
  `adb push original_legado.db /data/local/tmp/r1_original_legado.db`；
  `adb shell run-as com.legado.legado_flutter cp /data/local/tmp/r1_original_legado.db files/r1/original_legado.db`；
  `flutter drive --target=integration_test/r1_android_room_import_smoke_test.dart --driver=test_driver/integration_test.dart
  -d emulator-5556 --dart-define=R1_ROOM_PHASE=import --keep-app-running`；
  `adb shell am force-stop com.legado.legado_flutter`；
  再以 `R1_ROOM_PHASE=verify` 执行同一 Driver 命令。

历史结论：当时记录为 R1-12 数据库迁移门禁通过；该结论已被当前复核覆盖。非核心表产品业务 port、`readRecord`
映射和真实非空原版数据的补充采集仍未关闭；本轮没有推进新的 R2-R6 实现，也没有修改正文、目录、分页、章节身份或断行规则。

## 25.10 R1-12：历史复核快照（已被第184节覆盖）

> 本节保留较早 owner gate 的历史数字与临时 fixture 证据；当前状态以第184节、`docs/REFACTOR_PLAN.md` 顶部追溯和 `docs/DEVELOPMENT_PROCESS.md` 最新记录为准。

- R1 已重新打开，R1-12 当前只确认 Kotlin Room v99 → Rust v17 的核心七表业务映射与 23 个 Room 实体表全量原始归档，不能表述为 23 张表全部完成 Rust v17 业务迁移。
- 本批已补 v99 版本/identity hash 门禁、备份保护、正冲突、归档恢复、JSON 恢复事务性、既有数据回滚、非核心 fingerprint 稳定性、缺失实体表结构、实体 table-only、非法 UTF-8 无损和源库文件字节级只读边界测试；Room 定向 `21/21`、Rust 全量 `249`、release、Flutter analyze 和 Flutter 全量 `908`（`3` 项既有条件跳过）通过，但最终 R1-12 仍不据此标记为阶段退出。
- 只读 schema 形状审计：原版 `99.json` 与仓库 `original_legado.db` 的 23/23 个实体表列集合一致，无缺列/额外列；唯一 view 为 `book_sources_part`。当前七张核心表均为空，`book_groups` 有 7 行，`keyboardAssists` 有 14 行。该审计仅证明 schema 形状和当前样本数据分布，不替代真实非空核心数据迁移证据。
- 最新 owner 门禁补强：`readRecord.lastRead` 已纳入结构探针，四字段仍仅原始归档；导入前备份写入失败会清理临时路径且不删除预存在路径。Room 定向 `21/21`、Rust 全量 `249`、release、架构扫描和 `git diff --check` 通过。设备维度/书名聚合业务化和文件级 SQLite 备份仍未决。
- 归档无损回归新增合法 BLOB 字节数组经 snapshot、备份 JSON、恢复后的原始快照一致性断言，以及成功导入/非法 UTF-8 失败时源库主文件和 `-wal`/`-shm` 侧文件状态不变断言；`emulator-5556` 已安装 debug 重构 APK，临时非空等价 fixture 的 Android smoke 已通过，真实原版非空数据库仍未取得。
- 并行 owner 回归新增 `readRecord` 四字段原始快照/恢复和重复 fingerprint 导入备份 no-op 断言；Room `21/21`、数据库 `23/23`、Rust 全量 `249`、release、架构扫描和 `git diff --check` 通过。`emulator-5556` 上 debug 重构 APK 使用临时非空等价 fixture 完成 import/verify 两阶段，关键字段、章节身份、重启、幂等和备份恢复均通过；真实原版非空 Android 数据仍未取得。
- `readRecord` 仍仅登记 warning；非核心表仍为 archive-only；真实非空 `original_legado.db` 证据仍缺失。非核心业务 port、`readRecord` 映射和真实非空数据补充不在本轮擅自决定范围内。
- R1-12 复核完成前不推进新的 R2-R6 实现；R2/R6 的历史实现记录不替代当前阶段退出条件。

## 26. R3-1：阅读会话正文处理与章节文件缓存端口化

日期：2026-07-25

实现：

- 新增 `ChapterContentCachePort` 与 `FileChapterContentCache`，将章节文件正文的读取、保存和删除从 `ReadBook` 中的静态 `BookHelp` 调用隔离到 infrastructure 适配器；适配器复用原有文件路径、ID 清洗、空内容和异常处理语义。
- 新增 `ContentProcessingPort` 与 `ContentProcessorAdapter`，将正文清洗 API 及书源级替换规则映射隔离到 infrastructure；领域端口不依赖 `lib/help`。
- `ReadBook` 改为注入章节文件缓存端口和正文处理端口，同时保留旧 `processor: ContentProcessor` 参数作为兼容入口，默认适配器仍使用现有单例处理器。
- 缓存顺序保持为：内存 → 文件 → 数据库正文 → 网络 → 正文处理 → 原文文件缓存；预加载世代、旧请求失效、失败占位不缓存和数据库回落行为未改变。
- 新增缓存端口、正文处理适配器和 `ReadBook` 注入契约测试；未改 `ReaderPaginator`、中文断行、分页字符范围或目录排序。

行为验证：

- R3-1 定向测试：`14` 个通过，包含缓存端口 `5` 个、正文处理适配器 `3` 个、ReadBook 缓存注入 `2` 个及既有阅读会话/数据库回落 `4` 个。
- Flutter 全量：`410` 个通过，`3` 个既有在线 smoke 跳过。
- Rust workspace 串行测试：核心 crate `115` 个通过，其余 workspace 测试通过；既有网络/人工场景保持 ignored。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步最终没有新增诊断；中途发现的 R2-7 适配器多余 cast 已修正。

边界结论：阅读会话的正文处理和单章文件缓存已经可替换，数据库回落、正文内容、缓存命中语义、中文断行和分页输入未改变。下一步处理 `ReaderPage` 的单章原文缓存旁路和目录缓存元数据端口，仍不修改 R4 的目录顺序/首帧策略。

## 27. R3-2：阅读器与缓存管理调用者端口化

日期：2026-07-25

实现：

- `ReaderPage` 的原文编辑、重置重拉、缓存读取和缓存章节列表改为通过 `ReadBook`/`ChapterContentCachePort`，不再直接访问 `BookHelp`；`ContentEditDialog` 移除重复的静态文件写入，保存责任归还阅读会话。
- `TocSheet`、`SearchContentPage`、`BookProvider`、`CacheBookPage`、`BookCacheExportService` 和 `CacheService` 均支持注入缓存端口，默认适配器仍为 `FileChapterContentCache`。
- 缓存端口补齐章节列表、ID 规范化、字数统计、体积统计、清理全部/单书/无效目录和存在性查询；原 `BookHelp` 文件布局、UTF-8 字节统计、缓存标记和空内容语义保持不变。
- 下载筛选的章节 ID 规范化改为由调用者传入，消除 `download_helpers.dart` 的 `BookHelp` 依赖。
- 目录缓存字数改为首帧后按可见章节请求，减少整本缓存文件扫描；本步没有修改 `_reversed` 默认值、书源 `+/-` 规则、章节顺序、`index` 或分页器。

行为验证：

- R3-2 定向缓存/调用者测试：全部通过，覆盖端口实现、ReaderPage、目录/全文搜索、Provider、缓存管理和正文回归。
- Flutter 全量：`420` 个通过，`3` 个既有在线 smoke 跳过。
- Rust workspace 串行测试：核心 crate `115` 个通过，其余 workspace 测试通过；既有网络/人工场景保持 ignored。
- `dart format --output=none --set-exit-if-changed`、`git diff --check`：通过。
- `flutter analyze`：既有 `47` 条诊断，本步没有新增诊断。

边界结论：Flutter 侧除 infrastructure 适配器外已无直接 `BookHelp` 缓存调用；缓存链路可替换且正文原文、数据库回落、章节身份、中文断行和分页输入未改变。R4 仍需独立完成书籍级 `reverseToc`、连续 0-based `index`、持久化顺序和目录首帧性能契约。

## 28. R3-3：阅读位置映射与阅读记录端口化

日期：2026-07-25

实现：

- 新增纯 Dart `ReadingPositionMapper` 和 `ReadingPageRange`，统一页范围 `[start, end)` 与 Dart UTF-16 offset 的位置转换；分页仍由 Flutter `TextPainter` 负责，没有迁移或重写原 App 的中文断行和字符宽度算法。
- 新增 `ReadingRecordPort` 及 `FrbReadingRecordPort`，`ReadingRecordService` 的阅读记录写入和详细阅读会话记录改为通过可注入端口编排，FRB 生成类型保留在 infrastructure 适配层。
- `ReaderPage` 的分页目标改用位置 mapper；本地 `currentPageIndex` 继续保持页索引语义，云端 `durChapterPos` 修正为章内 UTF-16 字符位置，不再误当作页索引。
- `[newpage]` 仍作为布局间隙处理，不进入显示文本；图片占位 `U+FFFC` 和长 URL 布局副本的原文范围映射规则保持不变。
- 滚动模式的真实位置映射尚未完成，目前仍返回位置 `0`；本项也未处理 R4 的目录倒序、持久化顺序、章节 `index` 或目录首帧性能。

行为验证：

- R3-3 定向测试：`33` 个通过，覆盖位置 mapper、分页、快照、书签 hint、进度同步、书签同步和阅读记录集成。
- 阅读记录端口、tracker 和格式化定向测试：`10` 个通过。
- `flutter analyze`：仍为既有 `47` 条诊断，未发现新增诊断。
- Flutter 全量、Rust workspace 串行测试、`dart format --output=none --set-exit-if-changed` 和 `git diff --check`：R3-3 修改后尚未复跑，因此本边界暂不记录为全量门禁完成。

边界结论：阅读记录写入和云端阅读位置语义已隔离并完成全量回归；第 3 条断行规则继续由原有 `TextPainter` 分页链路保证。纯 Dart `ReadingScrollPositionMapper` 已作为独立基础设施建立并通过 6 个定向测试，但尚未接入 ReaderPage，因为原版 `TextChapter.getPageIndexByCharIndex` 使用已排版页面首行章内位置二分查找，滚动模式还依赖可视页首/底行，而不是简单线性比例。下一步补齐排版行范围映射和分页输入边界；R4 的目录顺序 2A 已完成，2B 性能继续独立验收。

## 29. R3-4：独立书签端口化与原版源码核对

日期：2026-07-25

实现：

- 新增纯 Dart `BookmarkSnapshot`、`BookmarkPort` 和 `FrbBookmarkPort`；`BookmarkService` 的列表、保存、删除、JSON 导入导出继续保持原有 DTO 外部兼容，FRB 访问集中到 infrastructure。
- 新增 `BookReadConfig`，将 `reverseToc` 放入 `Book.readConfig`，与原版 `Book.kt` 的 `ReadConfig.reverseToc` 结构一致；Rust 数据库 schema 增加 `readConfig` JSON 列并覆盖旧库迁移、重启读取和备份路径。
- `BookChapterList.kt` 对照结果：书源 `chapterList` 的 `-`/`+` 前缀处理、书籍级 `reverseToc`、去重和最终连续 `index` 必须分层执行；Flutter Provider 已在远端/本地目录展示与落库边界归一化 index。
- `TocViewModel.reverseToc` 对照结果：切换配置的同时反转持久化目录并重新编号；Flutter `TocSheet` 已在切换时同步反转章节记录、重写 index 并保存 `readConfig`。

行为验证：

- 书签端口定向测试：5 个通过。
- 目录顺序/持久化/首帧契约测试：6 个通过。
- Flutter 全量测试、Rust workspace 串行测试（核心库 116 个通过）、`flutter analyze`、格式检查和 `git diff --check` 均通过；在线 smoke 仍按既有规则跳过。

## 30. R6-1：Web API 设置页面端口化

日期：2026-07-26

实现：

- 新增纯 Dart `WebApiStatus` 和 `WebApiPort`，定义本地 Web API 状态查询、启动和停止边界。
- 新增 `FrbWebApiPort`，集中完成 FRB `WebApiStatus` 映射以及引擎/数据库可用性检查。
- `WebApiService` 改为依赖可替换端口，保留端口、Token、启停配置持久化和不可用时不调用底层的原有语义。
- `WebApiSettingsCard` 移除对桥接层和 FRB 状态类型的直接依赖，页面只消费领域状态和应用服务。
- 新增端口替换测试，覆盖启动持久化、停止持久化和不可用门禁。

行为验证：

- R6-1 定向测试：`7/7` 通过，包含 Web API 端口测试、偏好回归和备份配置页面回归。
- 修改文件定向 `flutter analyze`：无诊断。
- `git diff --check`：通过。
- 断行约束：本步只迁移 Web API 生命周期的依赖方向，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：Web API 设置页已不再直接依赖 FRB 生成状态或引擎/数据库桥接；FRB 仅保留在 `infrastructure/web_api` 适配器。下一步继续按页面直接依赖清单迁移一个 UI/服务边界，先从可替换端口建立再迁移调用者。

后续状态：本节记录的是 2026-07-26 当时边界。R5 checkpoint 已用 Dart IO adapter 和 application data port 替代 `FrbWebApiPort`，Rust 不再承载本地 HTTP Server 生命周期，详见第 119 节。

## 31. R6-2：阅读记录统计页面端口化

日期：2026-07-26

实现：

- 新增纯 Dart `ReadingStats`/`DailyReadingStat`，并扩展 `ReadingRecordPort` 覆盖统计查询、普通导出和详细记录导出。
- `FrbReadingRecordPort` 集中将 FRB 统计 DTO 映射为领域快照；`ReadingRecordService` 不再直接调用生成的统计/导出 API。
- `ReadRecordPage` 和阅读统计图表改为消费领域快照，保留原有范围切换、数值格式化、CSV/JSON 导出和空数据展示。
- 新增端口测试覆盖统计查询与两种导出，既有阅读记录服务和页面回归继续保留。

行为验证：

- R6-2 定向测试：`6/6` 通过。
- 修改文件定向 `flutter analyze`：无诊断。
- `git diff --check`：通过。
- 断行约束：本步只迁移阅读统计查询/导出和图表 DTO 依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：阅读记录页面及图表已不再直接依赖 FRB 统计类型；FRB 映射集中在 `infrastructure/engine/frb_reading_record_port.dart`。下一步继续迁移一个仍直接依赖生成 DTO 的页面边界。

## 32. R6-3：阅读小票统计端口化

日期：2026-07-26

实现：

- 新增纯 Dart `BookReadingStats` 和 `BookplatePort`，定义书籍阅读统计查询边界。
- 新增 `FrbBookplatePort`，集中映射生成的 `BookReadingStats`；`BookplateService` 支持端口替换并保留原有默认 FRB 实现。
- `BookplateOverlay` 和小票组装逻辑改用领域统计快照，评分、章节进度、时长、字数和完成日期语义不变。
- 新增端口替换测试，既有小票服务和 Widget 回归继续通过。

行为验证：

- R6-3 定向测试：`7/7` 通过。
- 修改文件定向 `flutter analyze`：无诊断。
- `git diff --check`：通过。
- 断行约束：本步只迁移阅读小票统计 DTO 依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：小票服务和展示组件已不再直接依赖生成的阅读统计类型；FRB 映射集中在 `infrastructure/engine/frb_bookplate_port.dart`。下一步继续迁移一个仍直接依赖生成 DTO 的页面或 Widget 边界。

## 33. R6-4：想法/笔记页面端口化

日期：2026-07-26

实现：

- 新增纯 Dart `NoteSnapshot` 与 `NotePort`，集中定义想法列表、保存、删除和 Markdown 导出边界。
- 新增 `FrbNotePort`，将 notes 表的 FRB DTO 映射限制在 infrastructure；`NoteService` 改为端口编排并保留不可用时的空值/空列表语义。
- 书签页、目录书签 Tab、想法编辑器和分享卡片改用领域 `NoteSnapshot`；书签编辑器和书签页展示改用领域 `BookmarkSnapshot`，同步服务的旧 JSON/FRB 兼容接口保留。
- 新增领域版旧书签前缀迁移入口，复用时间主键、书籍元数据、章节位置和重复迁移语义；旧 FRB 迁移入口保留给兼容调用者。
- 新增 `note_port_test.dart`，并迁移书签编辑器 fixture 到领域快照；所有原有字段断言保留。

行为验证：

- R6-4 定向测试：`9/9` 通过，覆盖 NotePort 全操作、旧书签迁移、书签页、书签编辑器和 Markdown 导出。
- 修改文件定向 `flutter analyze`：无诊断。
- `git diff --check`：通过。
- 断行约束：本步只迁移注释/书签 UI 的 DTO 和持久化端口，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：书签/想法 UI 已不再直接依赖 FRB `NoteDto`，FRB 仅保留在 `infrastructure/engine/frb_note_port.dart` 和既有同步兼容接口。下一步继续迁移一个仍直接依赖生成 DTO 的页面或 Widget 边界。

## 34. R6-5：RSS 服务端口化

日期：2026-07-26

实现：

- 新增纯 Dart `RssPort` 和 `RssArticlesResult`，定义 RSS 文章列表、分页 URL 和正文请求边界。
- 新增 `FrbRssPort`，集中完成 RSS 文章字段映射、来源默认值和 FRB 调用；`RssService` 改为端口编排。
- 保留原有行为：引擎不可用时文章请求抛出状态错误；无正文规则时直接返回文章已有正文/描述；文章来源、类型、空字段和 `nextUrl` 语义不变。
- `RssSortUrls` 的 JS 分类解析及缓存仍保持独立边界，未在本步混入。
- 新增端口替换测试，覆盖文章分页转发、正文转发和无规则正文回退。

行为验证：

- R6-5 定向测试：`3/3` 通过，包含 RSS 端口测试和 RSS 页面回归。
- 修改文件定向 `flutter analyze`：无诊断。
- `git diff --check`：通过。
- 断行约束：本步只迁移 RSS 请求与 DTO 映射依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：RSS 服务已不再直接依赖 FRB 生成文章类型，FRB 映射集中在 `infrastructure/engine/frb_rss_port.dart`。下一步继续处理 RSS 分类 JS 或其他剩余 Service 直连边界。

## 35. R6-6：RSS 分类 JS 端口化

日期：2026-07-26

实现：

- 新增纯 Dart `RssSortUrlJsPort`，定义 RSS `sortUrl` 脚本执行边界。
- 新增 `FrbRssSortUrlJsPort`，集中完成 `evalJs`、`jsLib` 和 `baseUrl` 传递；`RssSortUrls` 支持端口替换。
- 保留原有行为：`@js:`/`<js>` 提取大小写语义、`&&`/换行分类分隔、SharedPreferences 缓存、缓存清理和异常时回退到源 URL。
- 新增测试覆盖 JS 首次执行与缓存命中、普通分类 URL 跳过 JS、引擎不可用回退。

行为验证：

- R6-6 定向测试：`5/5` 通过，包含 RSS 分类端口、RSS 文章端口和 RSS 页面回归。
- 修改文件定向 `flutter analyze`：无诊断。
- `git diff --check`：通过。
- 断行约束：本步只迁移 RSS 分类脚本执行依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：RSS 服务及分类 JS 已不再直接依赖 FRB；相关绑定集中在 `infrastructure/engine` 适配器。下一步继续检查剩余 Service 层直连边界，Web/WASM/PWA 与 TTS 仍暂停。

## 36. R6-7：网络偏好引擎端口化

日期：2026-07-26

实现：

- 新增纯 Dart `NetworkEnginePort`，定义网络代理/DNS 配置下发所需的最小契约。
- 新增 `FrbNetworkEnginePort`，集中完成引擎可用性判断和 FRB `setNetworkConfig` 调用。
- `NetworkPrefs` 不再直接依赖引擎桥接或生成网络 API，支持测试端口替换；不可用时保持原有静默返回语义。
- 保留 SharedPreferences 键名、默认值、保存/加载和启动恢复行为，不改变网络请求参数内容。

行为验证：

- R6-7 定向测试：网络偏好原有回归和端口测试通过。
- 断行约束：本步只迁移网络配置适配依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：`NetworkPrefs` 已不再直接依赖 FRB；绑定集中在 `infrastructure/engine/frb_network_engine_port.dart`。缓存服务的引擎缓存清理仍是独立剩余边界，Web/WASM/PWA 与 TTS 仍暂停。

## 37. R6-8：书源调试日志格式化器领域化

日期：2026-07-26

实现：

- `formatDebugLog` 收紧为只接收领域 `BookSourceDebugSnapshot`，移除 Service 层对 FRB `DebugResult`、`RuleDebugStep` 和 `DebugItem` 的兼容转换。
- 调试页面原有 `BookSourceDebugPort` 链路和日志格式保持不变，FRB DTO 映射继续集中在 `FrbBookSourceDebugPort`。
- 测试 fixture 改用领域快照，保留请求、步骤、结果和响应预览的全部字段断言。

行为验证：

- R6-8 定向测试覆盖领域格式化器和 FRB 调试端口适配器回归。
- 断行约束：本步只迁移调试结果 DTO 的依赖方向，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：书源调试日志 Service 已不再直接依赖 FRB；调试结果映射集中在 `infrastructure/engine/frb_book_source_debug_port.dart`。剩余 Service 直连继续逐项处理，Web/WASM/PWA 与 TTS 仍暂停。

## 38. R6-9：缓存服务引擎清理端口化

日期：2026-07-26

实现：

- 扩展 `NetworkEnginePort` 的引擎缓存清理契约，由 `FrbNetworkEnginePort` 集中调用 FRB `clearEngineCache`。
- `CacheService` 改为注入网络引擎端口，移除对 `LegadoEngineBridge` 和生成网络 API 的直接依赖。
- 保留引擎不可用时不调用底层、仍输出清理完成日志的原有语义；文件缓存和备份清理流程不变。
- 新增缓存服务端口转发测试，验证引擎缓存清理不会绕过端口。

行为验证：

- R6-9 定向测试覆盖缓存统计、文件清理、备份清理、引擎清理端口转发和网络偏好回归。
- 断行约束：本步只迁移引擎缓存清理适配依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：`CacheService` 与 `NetworkPrefs` 的 FRB 网络依赖已集中在 `infrastructure/engine/frb_network_engine_port.dart`。剩余 Service 直连继续逐项处理，Web/WASM/PWA 与 TTS 仍暂停。

## 39. R6-10：登录 JS 执行端口化

日期：2026-07-26

实现：

- 新增纯 Dart `JsEvalPort`，定义登录 UI、`loginUrl` 和按钮脚本共用的裸 JS 执行契约。
- 新增 `FrbJsEvalPort`，集中完成引擎可用性判断和 FRB `evalJs` 参数转发。
- `SourceLoginService` 改为依赖可替换 JS 端口；登录脚本包装、宿主命令收集、JSON 解析和 Clipboard/浏览器回调逻辑均保持不变。
- 新增端口测试，验证脚本、JS 库和 base URL 原样传递，以及引擎不可用错误由端口边界保留。

行为验证：

- R6-10 定向测试覆盖 JS 端口转发、不可用错误和既有登录偏好回归。
- 断行约束：本步只迁移登录 JS 执行适配依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：`SourceLoginService` 已不再直接依赖 FRB 生成 API；登录 JS 绑定集中在 `infrastructure/engine/frb_js_eval_port.dart`。剩余 Service 直连继续逐项处理，Web/WASM/PWA 与 TTS 仍暂停。

## 40. R6-11：笔记文件导出领域化

日期：2026-07-26

实现：

- `NoteExportService.exportPerNoteFiles` 改为接收领域 `NoteSnapshot`，移除 Service 层对 FRB `NoteDto` 的直接依赖。
- 保留 Markdown 文件名非法字符替换、选中文本引用的逐行前缀、创建时间和书籍 ID 元数据格式。
- 生产导出对话框使用的 `NoteService.exportMarkdown` 链路不变；FRB Note DTO 映射仍集中在 `FrbNotePort`。
- 导出测试 fixture 改用领域快照，保留文件生成和正文内容断言。

行为验证：

- R6-11 定向测试覆盖逐笔 Markdown 文件导出和既有 NotePort 相关回归。
- 断行约束：本步只迁移笔记导出 DTO 依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：笔记文件导出 Service 已不再直接依赖 FRB `NoteDto`；剩余 FRB 兼容入口仅限同步/迁移等明确兼容边界，Web/WASM/PWA 与 TTS 仍暂停。

## 41. R6-12：本地书籍解析端口化

日期：2026-07-26

实现：

- 新增纯 Dart `LocalBookParserPort`、`LocalBookChapterSnapshot` 和 `LocalBookEpubSnapshot`，定义 TXT 分章与 EPUB 元数据/章节解析契约。
- 新增 `FrbLocalBookParserPort`，集中完成 `LegadoEngineBridge` 结果到领域快照的映射。
- `LocalBookService` 改为注入解析端口；Rust 不可用或解析失败时继续使用原有 TXT Dart 分章和 EPUB 占位书籍回退。
- 保留本地文件大小限制、书籍 ID、章节 ID、仓储写入顺序和章节正文内容，不触及阅读器断行/分页链路。

行为验证：

- R6-12 定向测试覆盖 TXT/EPUB 解析端口转发和本地导入限制回归。
- 断行约束：本步只迁移本地书籍解析适配依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：`LocalBookService` 已不再直接依赖 `LegadoEngineBridge`；本地书籍 Rust 绑定集中在 `infrastructure/engine/frb_local_book_parser_port.dart`。剩余 FRB 兼容入口继续按旧数据格式单独处理，Web/WASM/PWA 与 TTS 仍暂停。

## 42. R6-13：页面引擎状态端口化

日期：2026-07-26

实现：

- 新增纯 Dart `EngineStatusPort` 与 `EngineStatusService`，定义页面所需的引擎可用状态和版本查询。
- 新增 `FrbEngineStatusPort`，集中完成 FRB Bridge 状态读取和不可用时的空版本语义。
- `MyPage` 和 `OtherSettingsCard` 移除对 `LegadoEngineBridge` 的直接依赖，保留 Web API/缓存按钮的可用性、关于页版本展示和未就绪提示。
- `MyPage` 仍保留数据库就绪检查；备份编排继续通过 `BackupService`，本步不改变备份格式或 WebDAV 行为。

行为验证：

- R6-13 定向测试：引擎状态服务、`MyPage` 和 `OtherSettingsCard` 共 `4/4` 通过。
- 断行约束：本步只迁移页面引擎状态依赖，不修改正文原文、中文断行、分页输入、章节位置映射或阅读器 TTS 行为。

边界结论：两个页面已不再直接依赖引擎 Bridge；页面状态读取集中在 `services/engine_status_service.dart` 和 `infrastructure/engine/frb_engine_status_port.dart`。Web/WASM/PWA 与 TTS 仍暂停。

## 43. R6-14：SettingsBackup 存储端口化

日期：2026-07-26

实现：

- 新增 `SettingsStore` 端口和 `SharedPreferencesSettingsStore` 生产适配器。
- `SettingsBackup.collect/apply` 支持注入替代存储，默认 SharedPreferences 行为保持不变。
- 新增设置备份收集/恢复测试，覆盖字符串、整数和布尔值。

行为验证：

- 代码已完成，但 `flutter test test/services/settings_backup_test.dart` 首次运行在 Windows 沙箱启动阶段超时。
- 延长运行窗口的重试被终端审批服务以 `503 Service Unavailable` 拒绝，尚未取得通过或失败的测试结果。
- 因此本边界暂不标记为完成；不得用历史测试结果替代本次门禁。

边界结论：存储依赖方向已隔离，但必须在终端权限恢复后先重跑定向测试、`flutter analyze` 和格式检查，再进入下一个依赖该边界的任务。

## 44. R6-15：RSS 源管理文件传输端口化

日期：2026-07-26

实现：

- 新增 RSS 文件/剪贴板传输端口及平台适配器。
- `RssSourceManagePage` 移除对 `FilePicker`、`dart:io` 和 `Clipboard` 的直接依赖，改为注入传输端口。
- 保留原有 RSS 导入和复制行为；未修改阅读器、目录、分页或中文断行链路。

行为验证：

- `dart format`：通过。
- `flutter test test/pages/rss_source_manage_page_test.dart test/widget/rss_tab_test.dart`：`2/2` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

## 45. R5-1：WebDAV 设置 Repository 端口化

日期：2026-07-26

实现：

- `WebDavSetupService` 改为依赖 `WebDavRepository` 端口。
- FRB 具体实现下沉到 infrastructure 默认适配器，保留原有静态调用和回调兼容性。
- 保留 WebDAV 配置持久化、目录初始化顺序和错误传播语义。
- 测试使用 fake 只验证端口契约，没有替代真实 WebDAV 验收。

行为验证：

- `flutter test test/services/webdav_setup_service_test.dart`：`7/7` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。
- 未执行在线 WebDAV smoke；当前没有可用的真实 WebDAV 服务端点。

边界结论：WebDAV 设置编排已与 FRB 适配器隔离；真实服务端验收仍是 R5 外部门禁。

## 46. R5-2：阅读进度同步存储端口化

日期：2026-07-26

实现：

- 新增 `BookProgressSyncStore` 持久化端口和 SharedPreferences 适配器。
- `BookProgressSync` 支持注入存储实现；WebDAV、ETag/412 重试、冲突决策、章节位置和 `durChapterPos` 序列化语义保持不变。
- WebDAV 网络端口已存在，本步只迁移同步时间存储边界。

行为验证：

- `flutter test test/services/book_progress_sync_test.dart test/services/startup_book_progress_sync_test.dart`：相关同步用例通过；合并回归共 `23/23` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：同步时间持久化已可替换，进度位置、冲突和失败降级行为未改变。

## 47. R6-16：RSS 源编辑保存端口化

日期：2026-07-26

实现：

- `RssSourceEditPage` 新增可注入 `RssSourceEditPort`。
- 默认适配器仍使用现有 `RssProvider` 保存，UI 和原有保存行为保持不变。
- 本步没有修改 RSS 源管理页面、ReaderPage、目录、分页或中文断行链路。

行为验证：

- `flutter test test/pages/rss_source_edit_page_test.dart`：`1/1` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：RSS 源编辑页面的保存编排已与具体 Provider 隔离。

## 48. R5/R6 合并回归门禁

日期：2026-07-26

本轮 R5-1、R5-2、R6-14、R6-15 和 R6-16 合并后的验证：

- `flutter test`：`494` 个通过，`3` 个既有在线 smoke 跳过。
- `flutter analyze`：退出码 `1`，报告 `46` 条既有诊断；本轮涉及文件定向分析为 `No issues found`，没有新增诊断。
- 相关 16 个 Dart 文件：`dart format --output=none --set-exit-if-changed` 报告 `0 changed`。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。
- 真实 WebDAV 在线 smoke 仍未执行，原因是当前没有可用服务端点；端口契约测试不替代该外部验收。

## 49. R6-17：备份配置页面本地文件端口化

日期：2026-07-26

实现：

- `BackupConfigPage` 移除对 `dart:io File` 的直接依赖，改为注入本地备份文件端口。
- 新增本地备份条目模型、端口和生产文件系统适配器。
- 保留备份配置、导入导出和错误提示行为；`BackupService` 未在本步修改。

行为验证：

- `flutter test test/widget/backup_config_page_test.dart`：`4/4` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：备份配置页面的本地文件依赖已收敛到适配器，备份业务服务和 WebDAV 真实验收范围未扩大。

## 50. R6-18：捐赠页面剪贴板端口化

日期：2026-07-26

实现：

- `DonatePage` 移除对 Clipboard 的直接依赖，改为注入剪贴板端口。
- 保留复制内容、提示文本和 UI 行为不变。

行为验证：

- `flutter test test/widget/donate_page_test.dart`：`2/2` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：捐赠页面的平台剪贴板依赖已可替换，未触及阅读器或正文链路。

## 51. R6-19：书架排列页面偏好端口化

日期：2026-07-26

实现：

- `BookshelfArrangePage` 移除对 SharedPreferences 的直接依赖，改为注入排列偏好端口。
- 保留 `openBookInfoByClickTitle` 键名以及排序、分组、布局偏好持久化语义。

行为验证：

- `flutter test test/pages/bookshelf_arrange_page_test.dart`：`2/2` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：书架排列页面的偏好存储已可替换，现有键名和用户设置行为未改变。

## 52. R6-17 至 R6-19 合并回归门禁

日期：2026-07-26

- `flutter test`：`498` 个通过，`3` 个既有在线 smoke 跳过。
- 新增页面相关文件 `dart format --output=none --set-exit-if-changed`：`0 changed`。
- 新增页面相关文件 `flutter analyze`：`No issues found`。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

## 53. R6-20：BookGroupStore 偏好端口化

日期：2026-07-26

实现：

- 新增 `BookGroupPrefsPort` 和 SharedPreferences 适配器。
- `BookGroupStore` 移除对 SharedPreferences 的直接依赖，支持注入和重置端口。
- 保留 `book_groups_v1` 键名、JSON 格式、默认分组、空值、排序和异常传播行为。

行为验证：

- `flutter test test/services/book_group_store_test.dart`：`4/4` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：书架分组偏好存储已可替换，数据格式和用户可见行为未改变。

## 54. R6-21：CodeEditPrefs 偏好端口化

日期：2026-07-26

实现：

- 新增 `CodeEditPrefsStore` 和 SharedPreferences 适配器。
- `CodeEditPrefs` 移除对 SharedPreferences 的直接依赖，保留键名、默认值、日志上限和读写语义。
- SourceEditorPage 未在本步修改。

行为验证：

- `flutter test test/services/code_edit_prefs_test.dart test/widget/code_edit_page_test.dart`：相关回归通过，分别覆盖 `4/4` 和 `4/4`。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：代码编辑器偏好存储已可替换，编辑器页面行为未改变。

## 55. R6-22：日志/主题页面剪贴板端口化

日期：2026-07-26

实现：

- 新增通用 `ClipboardPort`。
- `AppLogPage` 和 `ThemeConfigPage` 的复制/粘贴操作统一通过端口执行。
- 保留日志复制、主题导入导出、提示文本和 UI 行为；未修改 DonatePage 的独立兼容端口。

行为验证：

- `flutter test test/pages/bookshelf/app_log_page_test.dart test/widget/theme_config_page_test.dart`：`8/8` 通过。
- `flutter analyze`（涉及文件）：`No issues found`。
- `dart format --set-exit-if-changed`：通过。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：日志和主题页面的平台剪贴板依赖已集中到通用端口，导入导出行为未改变。

## 56. R6-20 至 R6-22 合并回归门禁

日期：2026-07-26

- 合并定向回归：`19/19` 通过。
- `flutter test`：`509` 个通过，`3` 个既有在线 smoke 跳过。
- 新增相关 13 个 Dart 文件 `dart format --output=none --set-exit-if-changed`：`0 changed`。
- 新增相关文件 `flutter analyze`：`No issues found`。
- `git diff --check`：通过，仅有既有 LF/CRLF 警告。

边界结论：本轮三个页面/服务边界均完成端口化，未修改阅读器、目录、分页或断行链路。

## 57. 2026-07-27 当前门禁与 R5/R4 核查

本节是只读审计记录，不代表 R5 阶段已退出，也不替代真实 WebDAV 应用验收。

### 已实际执行并通过

- `cargo test --manifest-path rust/Cargo.toml`：退出 `0`；核心库 `117` 个测试通过，既有网络/人工场景按测试定义 ignored；编译输出包含既有 FRB 宏和 dead-code warnings。
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_js_compat.ps1`：退出 `0`；Rust `js_compatibility` `18/18`，Flutter JS 分析/集成 `4/4`；7565 在线探测按既有策略因 HTTP `400` 跳过。
- `flutter test` 最近全量结果：`509` 通过，`3` 个既有在线 smoke 跳过；全仓 `flutter analyze` 当前退出 `1`，`46` 条既有诊断；本轮涉及文件定向 analyze 无诊断。
- `flutter test integration_test/module2_android_toc_performance_test.dart -d emulator-5556`：通过。2000 章合成目录连续 index、首尾可见性、冷/热构建和滚动帧证据均输出；冷首帧 P50/P95 约 `48.8/415.1 ms`，热首帧约 `13.9/44.4 ms`，冷/热滚动均未出现 jank。
- `flutter test integration_test/module3_android_reader_page_snapshot_test.dart integration_test/module3_android_reader_page_multichapter_snapshot_test.dart -d emulator-5556`：`2/2` 通过；单章字符范围、`[newpage]` 隐藏、双章隔离、章节切换和 PNG 产物门禁通过。
- 本地 WebDAV Node 服务 `http://127.0.0.1:19080/`：认证、PUT `201`、GET `200`、ETag 存在、过期 `If-Match` `412`、MOVE `201`、移动后内容一致、DELETE `204` 均通过。该结果是协议层 smoke，不是 Flutter 应用端到端验收。

### 当前 R5 缺证据

- R5-A 已在雷电 `emulator-5556` 上完成：使用 `http://192.168.100.52:19080/`（雷电不可达标准模拟器地址 `10.0.2.2`）通过真实 FRB WebDAV 入口完成隔离目录初始化、书签上传/合并下载、阅读进度上传/读取，以及 `BackupConfigPage` 点击上传并在远端列出 ZIP 备份。
- 尚未用两个独立客户端/数据库对同一 WebDAV 文件执行 ETag 条件写入、412 重试、远端较新进度/书签合并和并发冲突结果核验。
- 尚未验证真实外部 WebDAV 服务的 TLS、代理、权限、服务器 ETag、MOVE/ZIP 往返差异；本地 Node 服务只能证明当前实现覆盖的协议基本动作。
- 因此 R5 只能称为“本地实现和协议 smoke 完成，应用/跨设备验收进行中”，不能标记阶段退出或发布。

## 60. 2026-07-27：R5-C 外部 WebDAV 验收夹具

实现范围：

- 新增 `integration_test/r5_external_webdav_smoke_test.dart`，通过 `dart-define`
  注入外部服务地址、账号、密码和可选代理；未提供外部地址时明确跳过。
- 验收夹具覆盖真实服务的认证目录访问、可选错误密码权限失败、服务端 ETag、旧
  ETag 条件写入 `412`、MOVE，以及 ZIP 备份字节上传/下载和恢复解析。
- 只新增验收入口和文档，不修改 `legado-main`、正文清洗、中文断行、分页、章节位置
  映射或生产同步冲突策略。

验收依据：

- 运行说明见 `docs/LOCAL_WEBDAV.md` 的 “External R5-C Gate”。
- 本地 WebDAV 可作为 R5 开发退出门禁；它不能替代发布前正式或主流 WebDAV 服务的真实验收证据。

当前状态：

- 代码夹具已建立；本地开发退出门禁已完成。正式或主流 WebDAV 发布前验收尚未执行，
  因此只能标记 R5 开发完成，不能标记发布验收完成。

## 61. 2026-07-27：R5 备份恢复与失败策略 Android smoke

实现范围：

- 新增 `integration_test/r5_android_webdav_backup_restore_failure_test.dart`，使用临时
  Rust 数据库写入已知书籍和书源，执行 WebDAV ZIP 上传、清空后恢复以及损坏/缺字段/404
  失败后的本地数据保护检查。
- 新增 `test/services/backup_failure_policy_test.dart`，覆盖 HTTP 401/403/404/405/501
  的用户可见失败策略，不修改生产错误映射。
- 本步不修改 ZIP 格式、同步冲突、正文内容、中文断行、分页或章节位置。

测试结果：

- `flutter analyze integration_test/r5_android_webdav_backup_restore_failure_test.dart
  test/services/backup_failure_policy_test.dart`：无诊断。
- `flutter test test/services/backup_service_test.dart test/services/backup_failure_policy_test.dart
  test/widget/backup_config_page_test.dart`：`17/17` 通过。
- `flutter test integration_test/r5_android_webdav_backup_restore_failure_test.dart
  -d emulator-5556 --dart-define=R5_WEBDAV_URL=http://192.168.100.52:19080/`：`1/1` 通过。
- R5-A、R5-B、本测试三项 Android 合并门禁均为 `1/1`；串行 Flutter 全量为 `512` 通过、
  `3` 个既有在线 smoke 跳过；Rust workspace 和 JS 兼容返回 `0`；`git diff --check` 通过。
- 真实外部 WebDAV 仍因缺少 URL、账号、密码和代理凭证待执行；该项是发布前门禁，不阻塞后续 R6 重构，但发布前必须补齐。

本地验收结果：

- `flutter test test/services/backup_service_test.dart test/services/backup_failure_policy_test.dart
  test/widget/backup_config_page_test.dart`：`17/17` 通过。
- `flutter test integration_test/r5_android_webdav_backup_restore_failure_test.dart
  -d emulator-5556 --dart-define=R5_WEBDAV_URL=http://192.168.100.52:19080/`：`1/1` 通过。
- 本地 smoke 使用临时 Rust 数据库验证书籍/书源 ZIP 上传、清空后恢复、损坏 ZIP、缺少
  `database` 字段和远端 404 失败时本地数据保持不变；该结果不替代真实外部 WebDAV 证据。

## 58. 2026-07-27：R5-A Android 应用 WebDAV smoke

实现范围：

- 新增 `integration_test/r5_android_webdav_application_smoke_test.dart`，只增加设备验收夹具，不改变生产同步、备份、书签或正文逻辑。
- 测试使用 `R5_WEBDAV_URL` `dart-define` 注入地址；标准 Android Emulator 可使用 `http://10.0.2.2:19080/`，当前雷电环境使用宿主机 `http://192.168.100.52:19080/`。
- 使用隔离 WebDAV 根目录和临时数据库，避免覆盖既有本地数据及其他测试文件。

行为证据：

- Rust 引擎在 Android 加载成功。
- `WebDavSetupService.initialize` 的真实 FRB 请求完成根目录、`bookProgress`、`books`、`background` 初始化。
- `BookmarkSyncService` 完成书签上传、远端读取和合并下载。
- `BookProgressSync` 完成阅读进度上传和读取。
- `BackupConfigPage` 在真实页面层级下点击“上传到 WebDAV”成功，远端列表可见生成的 ZIP 备份。

测试结果：

- `flutter test integration_test/r5_android_webdav_application_smoke_test.dart -d emulator-5556 --dart-define=R5_WEBDAV_URL=http://192.168.100.52:19080/`：`1/1` 通过；APK 构建和安装成功。
- R5 相关 Flutter 定向回归：`52/52` 通过。
- `cargo test --manifest-path rust/Cargo.toml`：`117` 通过，既有 ignored 场景保持 ignored。
- `scripts/run_js_compat.ps1`：Rust JS `18/18`、Flutter JS `4/4`，7565 可选在线探测因 HTTP `400` 跳过。
- `flutter analyze`（新增集成测试）：`No issues found`；`git diff --check` 通过。
- 并发普通 `flutter test` 曾有 7 个既有 7565 在线链路失败：搜索阶段出现 HTTP `400`/空结果并导致详情、目录、正文断言连锁失败；未修改测试。随后单独串行 7565 测试恢复 HTTP `200`，完整 `flutter test --concurrency=1` 通过，结果为 `509` 通过、`3` 个既有在线 smoke 跳过。

边界结论：R5-A 应用入口、R5-B 双客户端 ETag/412 冲突和本地备份恢复证据已补齐；R5 开发退出门禁满足。真实外部 WebDAV 的 TLS/代理/权限验收保留为发布前门禁。

## 59. 2026-07-27：R5-B 双客户端 ETag/412 冲突 smoke

实现范围：

- 新增 `integration_test/r5_android_webdav_cross_client_conflict_test.dart`，使用同一真实 WebDAV 服务器上的独立临时根目录模拟两个客户端状态。
- 客户端 A 和客户端 B 各自保存旧 ETag；A 先条件写入，B 使用旧 ETag 写入必须收到 `412`，随后 B 重读远端内容和新 ETag，再按现有合并/冲突策略写回。
- 书签验证 `time` 主键并集和远端写入结果；阅读进度验证 `SyncConflictPolicy.concurrentConflict/requireMerge` 以及新 ETag 写回。

测试结果：

- `flutter test integration_test/r5_android_webdav_cross_client_conflict_test.dart -d emulator-5556 --dart-define=R5_WEBDAV_URL=http://192.168.100.52:19080/`：`1/1` 通过，Android APK 构建/安装成功。
- `cargo test --manifest-path rust/Cargo.toml`：`117` 通过。
- `flutter test --concurrency=1`：`509` 通过，`3` 个既有在线 smoke 跳过。
- `scripts/run_js_compat.ps1`：Rust JS `18/18`、Flutter JS `4/4`；7565 可选在线探测按既有策略跳过。
- 新增冲突测试定向 `flutter analyze`：无诊断；`git diff --check`：通过。

边界结论：R5-B 本地真实服务器双客户端冲突证据已完成；真实外部 WebDAV 服务器的 TLS、代理、权限和服务端 ETag 差异保留为发布前门禁，不影响 R5 开发退出。

## 63. 2026-07-27：R6 book 功能域目录迁移

迁移范围：

- 将 `lib/pages/book/` 的 `BookInfoPage`、`BookmarkPage`、`ChangeCoverPage`、`ChangeSourcePage` 和 `TocSheet` 移至 `lib/features/book/`。
- 更新 bookshelf、reader、manga、search、explore 和 my 调用方的导入路径；`manga`、`obsidian` 等尚未迁移的功能继续保留在 `lib/pages/` 过渡目录，不扩大本步范围。
- 未改变书籍详情、目录顺序、书签身份、正文、断行、分页或章节位置行为。

测试结果：

- `flutter analyze lib/features/book test/pages/book/toc_order_test.dart test/widget/bookmark_page_test.dart test/widget/bookmark_editor_sheet_test.dart`：`No issues found`。
- `flutter test test/pages/book/toc_order_test.dart test/widget/bookmark_page_test.dart test/widget/bookmark_editor_sheet_test.dart`：`8/8` 通过。
- 全仓旧 `pages/book` 和旧相对 `../book` 导入扫描：无残留。
- 调用方联合 analyze 仍有 8 条既有 Radio 弃用诊断，位于 `lib/pages/my/my_page.dart` 和 `lib/pages/search/search_page.dart`；已登记到 R6 统一 analyze 批次，未 suppress、未修改测试。
- `git diff --check`：通过。

边界结论：`book` 功能域迁移完成，可以进入下一功能域；R6 阶段仍未退出。

## 64. 2026-07-27：R6 sources 功能域目录迁移

迁移范围：

- 将 `lib/pages/sources/` 的规则补全、书源调试、编辑、登录、市场和书源列表页面移至 `lib/features/sources/`。
- 更新 `app.dart`、`MyPage`、RSS 登录入口和规则补全测试的导入路径；代码编辑、二维码、搜索、发现和 WebView 页面仍保留在 `lib/pages/` 过渡目录，不扩大本步范围。
- 未改变书源数据、规则补全、登录、调试、市场和书源列表行为，也未改变正文、断行、分页或章节位置规则。

测试结果：

- `flutter analyze lib/features/sources test/pages/sources/rule_complete_test.dart`：生产代码路径和类型错误已清零；剩余 2 条既有诊断位于 `lib/features/sources/sources_page.dart`，分别为 `use_null_aware_elements` 和 `use_build_context_synchronously`。
- `flutter test test/pages/sources/rule_complete_test.dart`：`4/4` 通过。
- 迁移后相关旧 `pages/sources` 导入已清理；保留的过渡目录仅为本步明确未迁移的被依赖页面。
- `git diff --check`：通过。

边界结论：`sources` 功能域迁移完成，可以进入下一功能域；R6 阶段仍未退出。

## 65. 2026-07-27：R6 rss 功能域目录迁移

迁移范围：

- 将 `lib/pages/rss/` 的 RSS 标签页、文章、收藏、阅读、来源编辑、来源管理和来源列表组件移至 `lib/features/rss/`。
- 更新 `MainShell`、RSS 测试及过渡目录中 WebView、二维码、阅读记录和规则订阅页面的导入路径；这些被依赖页面仍保留在 `lib/pages/`，不扩大本步范围。
- 未改变 RSS 搜索、收藏、阅读、来源编辑/导入和来源登录行为，也未改变正文、断行、分页或章节位置规则。

测试结果：

- `flutter analyze lib/features/rss test/pages/rss_source_edit_page_test.dart test/pages/rss_source_manage_page_test.dart test/widget/rss_tab_test.dart`：`No issues found`。
- `flutter test test/pages/rss_source_edit_page_test.dart test/pages/rss_source_manage_page_test.dart test/widget/rss_tab_test.dart`：`3/3` 通过。
- 迁移后相关旧 `pages/rss` 导入已清理；RSS 组件目录已收敛到 `lib/features/rss`。
- `git diff --check`：通过。

边界结论：`rss` 功能域迁移完成，可以进入下一功能域；R6 阶段仍未退出。

## 66. 2026-07-27：R6 settings 功能域目录迁移

迁移范围：

- 将 `lib/pages/config/` 的备份、配置、主题、其他设置、Web API 设置和占位页面，以及 `lib/pages/settings/settings_page.dart` 移至 `lib/features/settings/`。
- 更新 `MyPage`、备份失败策略测试、设置 Widget 测试和 R5 Android 应用 smoke 的导入路径；不改变备份、WebDAV、主题、缓存、网络和引擎状态行为。
- 未改变正文、中文断行、分页或章节位置规则。

测试结果：

- `flutter analyze lib/features/settings test/services/backup_failure_policy_test.dart test/widget/backup_config_page_test.dart test/widget/other_settings_card_test.dart test/widget/theme_config_page_test.dart`：`No issues found`。
- `flutter test test/services/backup_failure_policy_test.dart test/widget/backup_config_page_test.dart test/widget/other_settings_card_test.dart test/widget/theme_config_page_test.dart test/widget/my_page_test.dart`：`17/17` 通过。
- `git diff --check`：通过。

边界结论：`settings` 功能域迁移完成，可以进入下一功能域；R6 阶段仍未退出。

## 67. 2026-07-27：R6 my 功能域目录迁移与 sync 边界核查

迁移范围：

- 将 `lib/pages/my/` 的我的页面、文件管理、阅读记录、阅读技巧和 WebDAV 配置对话框移至 `lib/features/my/`。
- 更新 `app.dart`、MainShell、RSS、settings、bookshelf 和 MyPage 测试调用方；AI、缓存、替换、字典、文本目录、Obsidian 等仍保留在 `lib/pages/` 过渡目录。
- 核查 `sync`：当前没有独立 `lib/pages/sync` UI；同步实现继续由 application 启动编排、domain 端口和 services 过渡服务承载，本步不创建空目录、不重排共享同步服务。
- 未改变状态服务、备份/WebDAV、阅读记录、正文、断行、分页或章节位置行为。

测试结果：

- `flutter analyze lib/features/my test/widget/my_page_test.dart test/widget/read_record_page_test.dart`：除 `MyPage` 原有 2 条 Radio 弃用诊断外无新增诊断；该 2 条进入统一 R6 analyze 批次。
- `flutter test test/widget/my_page_test.dart test/widget/read_record_page_test.dart`：`2/2` 通过。
- `flutter test --no-pub --concurrency=1`：`516` 通过，`3` 个既有在线 smoke 按既有条件跳过。
- `flutter analyze --no-pub`：无 error，保留 `46` 条既有 warning/info；未新增迁移诊断。
- 旧 `pages/my` 导入扫描：无残留；`git diff --check`：通过。

边界结论：`my` 功能域迁移完成，`sync` 无 UI 迁移项；R6 进入统一 analyze、平台构建和 UI 对照退出门禁准备阶段。

## 68. 2026-07-27：R6 机械 lint 清理批次

实现范围：

- 移除 `legado_db_bridge.dart` 未使用 import，使用等价 `contains` 替换 `indexOf != -1`，为 JSON 规则判断补齐花括号。
- 修正文档注释中的 HTML-like 文本、library doc comment 和 null-aware collection 元素。
- 删除 `ReaderSettings` 中未引用的私有主题排版方法；补充异步导入后的 `context.mounted` 保护。
- 未修改正文、中文断行、分页、章节位置、目录顺序或同步冲突行为。

测试结果：

- `flutter analyze lib/bridge/legado_db_bridge.dart lib/help/content_help.dart lib/models/book_source.dart lib/services/js_compat_analyzer.dart lib/services/source_group_tags.dart lib/widgets/legado_list_tile.dart`：`No issues found`。
- `flutter analyze lib/features/sources/sources_page.dart lib/features/reader/reader_settings.dart test/integration/js_compatibility_test.dart`：`No issues found`。
- `flutter test --no-pub test/pages/sources/rule_complete_test.dart test/services/read_book_config_prefs_test.dart test/services/reader_font_loader_test.dart`：`14/14` 通过。
- 组合命令包含 JS 测试时断言 `16/16` 已通过，但进程收尾超过工具 120 秒；全量回归和拆分本地测试均未受影响。
- 全仓 `flutter analyze --no-pub`：无 error，剩余 `33` 条既有诊断，主要为 RadioGroup 弃用和 flutter_tts 子包 lints 配置缺失。
- `git diff --check`：通过。

边界结论：机械 lint 批次完成，可以进入 RadioGroup/生命周期批次；R6 阶段仍未退出。

## 69. 2026-07-27：R6 RadioGroup 迁移批次

实现范围：

- 将 `BookshelfConfigDialog` 的视图、排序和书名三个独立选择组迁移到 `RadioGroup<int>`。
- 将 `MyPage` 主题模式和 `ReaderPage` 翻页动画选择迁移到 `RadioGroup<int>`；子项仅保留 `value`，选中值和回调语义保持不变。
- 未修改阅读正文、中文断行、分页、章节位置、目录顺序或同步冲突策略。

测试结果：

- `flutter analyze lib/features/bookshelf/bookshelf_config_dialog.dart lib/features/my/my_page.dart test/widget/main_shell_test.dart test/widget/my_page_test.dart`：`No issues found`。
- `flutter test --no-pub test/widget/main_shell_test.dart test/widget/my_page_test.dart test/widget_test.dart`：`4/4` 通过。
- `flutter analyze lib/features/reader/reader_page.dart`：`No issues found`。
- `flutter test --no-pub test/pages/reader/turn test/pages/reader_markup_test.dart test/pages/reader_paginator_test.dart`：`41/41` 通过。
- 全仓 `flutter analyze --no-pub`：无 error，剩余 `23` 条诊断，集中在 cache、manga、obsidian、search 和 flutter_tts 子包配置。
- `git diff --check`：通过。

边界结论：bookshelf、my、reader 的 RadioGroup 迁移完成，可以继续处理过渡页面中的剩余 Radio 组；R6 阶段仍未退出。

## 70. 2026-07-27：R6 analyze 门禁清零

实现范围：

- 将 `download_choice_dialog.dart`、`search_page.dart`、`manga_reader_page.dart` 和 `obsidian_export_dialog.dart` 的 Radio 选择迁移到 `RadioGroup`，保持下载范围、搜索范围、页脚方向和 Obsidian 导出方式的状态语义。
- 将 vendored `packages/flutter_tts/analysis_options.yaml` 改为自身 strict analyzer 配置，移除无法在独立子包上下文解析的 lint include；未修改 TTS 运行代码，也未执行真实 Android TTS 验收。
- 未修改正文、中文断行、分页、章节位置、目录顺序、同步冲突或 ZIP 格式。

测试结果：

- `flutter analyze --no-pub`：`No issues found`。
- cache 单元回归：`9/9` 通过；search、manga、obsidian 文件 analyze：无诊断。
- `flutter test --no-pub --concurrency=1`：`516` 通过，`3` 个既有在线 smoke 按既有条件跳过。
- `git diff --check`：通过。

边界结论：R6 analyze 诊断门禁完成；剩余退出条件为平台构建矩阵、UI 对照记录、过渡页面边界收敛和发布前正式/主流 WebDAV 真实验收。

## 71. 2026-07-27：R6 Android/Windows 本机平台构建矩阵

测试结果：

- `flutter build apk --debug`：通过，产物 `build/app/outputs/flutter-apk/app-debug.apk`。
- `flutter build windows --debug`：通过，产物 `build/windows/x64/runner/Debug/legado_flutter.exe`。
- `D:\leidian\LDPlayer9\adb.exe devices -l`：`emulator-5556` 为 `device`。
- `adb -s emulator-5556 install -r build/app/outputs/flutter-apk/app-debug.apk`：`Success`。
- `adb -s emulator-5556 shell monkey -p com.legado.legado_flutter 1`：启动事件成功；`dumpsys activity` 确认 `MainActivity` 在前台任务。

平台边界：

- iOS/macOS 需要 macOS/Xcode，本机 Windows 不执行。
- Linux 暂不作为本机门禁，需 GTK/toolchain 环境后执行。
- Web/WASM/PWA 和真实 Android TTS 继续按计划暂停，不标记为完成。
- 本步未改变正文、断行、分页、章节位置或 WebDAV 外部验收结论。

边界结论：Android/Windows 本机构建与安装启动门禁完成；R6 仍需 UI 对照记录、过渡页面收敛和发布前正式/主流 WebDAV 真实验收。

## 72. 2026-07-27：R6 Android UI 对照初测

- 新增 [`UI_COMPARISON_RECORD.md`](./UI_COMPARISON_RECORD.md)，记录原版 `io.legado.app.debug` 与重构版
  `com.legado.legado_flutter` 在 `emulator-5556`、`720x1280`、DPI `320`、DPR `2` 下的书架首屏采集。
- 已实际采集原版已有书籍、重构版首次启动隐私协议和重构版同意协议后的空书架截图；由于数据、主题和启动状态不一致，当前只登记结构差异和证据缺口，不标记像素验收通过。
- 原版源码仍以根目录 `legado-main/` 为只读核对基线，本步未修改；截图保存在用户临时目录，不进入仓库。

边界结论：UI 对照采集链路已验证，最终同数据/同主题对照仍待补齐；R6 阶段尚未退出。

## 73. 2026-07-27：R6 Android 我的页面 UI 对照

- 在 `emulator-5556` 上分别启动原版和重构版，点击同一底部“我的”入口采集截图。
- 两端页面层级、快捷入口区域、设置列表和底部四 Tab 结构基本一致。
- 已记录棕色/蓝色主题差异、品牌图标差异、快捷入口图标语义差异、`Web 服务` 文本空格差异和设置项集合差异。
- 该结果只证明对照采集和差异分类可执行，不代表 UI 1:1 通过；原版和重构版仍需统一主题、资源和目标版本功能集合后复验。

## 74. 2026-07-27：R6 Android 书源管理 UI 对照

- 原版和重构版均在 `emulator-5556` 进入书源管理页面；重构版首次进入的帮助弹窗已单独采集并关闭后复采。
- 两端工具栏、书源列表和底部批量操作结构相近，但当前书源数量不同，且主题色、排序/分组图标、书源名称截断、列表行密度和按钮布局存在差异。
- 结果已写入 `UI_COMPARISON_RECORD.md`，当前仅作为差异证据，未标记 UI 1:1 通过。

## 62. 2026-07-27：R6 UI 数据库/桥接状态直连清理

实现范围：

- `MainShell` 移除 `DatabaseHelper()`，空库内置书源初始化改由 `SourceProvider` 的
  Repository 用例负责；新增空库、非空库和 Repository 失败测试。
- 新增 `DatabaseStatusPort`、`FrbDatabaseStatusPort` 和 `DatabaseStatusService`；
  `BackupConfigPage`、`MyPage` 改为依赖状态服务，FRB/Bridge 读取集中到基础设施适配器。
- 未修改正文、中文断行、分页、章节位置或 TTS。

测试结果：

- SourceProvider/MainShell 定向测试：`6/6` 通过。
- 数据库/引擎状态、备份页、我的页定向测试：`9/9` 通过。
- 相关新端口、Provider 和 MainShell 定向 analyze：无诊断；`MyPage` 仍有原有 2 条
  `RadioGroup` 弃用提示，转入 R6 analyze 批次。
- 页面源码检索未发现 `DatabaseHelper()`、`LegadoDbBridge` 或 `LegadoEngineBridge` 直接调用。

### 并行边界约束

- R5 应用端到端验证、跨设备冲突验证和文档证据整理可以并行，但必须使用独立数据目录/客户端状态，不能共享会改变结果的远端文件。
- 任何修改 `BackupService`、`BookProgressSync`、`BookmarkSyncService`、`WebDavRepository` 或 WebDAV 配置入口的任务都必须串行执行，并在修改后重跑 R5 全套门禁。
- R4/R3 当前没有新的实现任务；目录或阅读器代码只有在新证据暴露回归时才能重新开启，并必须重新执行 2A/2B 或模块 3 第 3 条断行/分页门禁。

## 75. 2026-07-27：R0 重基线与静态边界检查

实现范围：

- 新增 `R0_REBASELINE.md`，固定当前原版基线、历史资料定位、Flutter 残留业务清单、工件分类和
  R0-R6 重新判定。
- 新增 `scripts/check_architecture_boundaries.ps1`，扫描 `lib/features`、`lib/widgets` 和
  `lib/providers` 中的 Bridge、FRB、DAO、生成 Rust API、Dio 和业务 HTTP 客户端直接依赖。
- `legado-main/`、原版数据库和本地探针加入忽略规则；本步没有删除、移动、暂存或提交既有工作树内容。
- 文档索引、开发流程和兼容性计划统一将 `legado-main/` 作为活跃只读基线，历史 UI/Phase 资料不再
  定义当前重构执行顺序。
- 未修改的 `UI_REPLICATION_PLAN.md` 已移动到 `docs/archive/`；含既有未提交内容的
  `docs/superpowers/` 与 `.superpowers/sdd` 只登记为原位归档候选，尚未物理移动。
- 新增 `R0_WORKTREE_GROUPS.md`，将当前大工作树拆分为 R0、R1、R3、R4-R5、R6、生成/供应商和
  文档追溯候选组；本步不暂存、不提交、不推送，也不宣称历史改动已经重新验证。

测试结果：

- `scripts/check_architecture_boundaries.ps1`：可执行，退出 `1` 并列出 `21` 项现存架构违规；结果作为
  R1-R6 迁移 backlog，不标记为通过。
- `flutter analyze --no-pub`：`No issues found`。
- `git diff --check`：通过；仅有现有文件的 LF/CRLF 警告。

边界结论：R0 已建立当前残留业务和静态越界的可重复证据，基线退出就绪，等待确认进入 R1。历史
资料中含既有未提交内容的部分仅登记为原位归档候选；现有工作树的可追溯提交拆分与 `21` 项违规的
逐项迁移属于后续 R1-R6 最小迁移单元，不阻塞 R0 基线退出。

## 76. 2026-07-29：R6 RemoteBookPage WebDAV 端口边界

迁移范围：

- `RemoteBookPage` 移除 `FrbWebDavRepository` 的直接导入和默认构造，改为读取根组合层提供的
  `WebDavRepository`；测试仍可通过 widget 注入 fake。
- `main.dart` 负责创建 `FrbWebDavRepository`，页面继续保留 WebDAV 配置、目录浏览、下载和本地导入行为。
- 未修改远程路径、排序、书籍导入、正文、断行、分页、章节位置或 TTS 行为。

测试结果：

- `flutter analyze lib/features/bookshelf/remote_book_page.dart lib/main.dart test/features/bookshelf/remote_book_page_test.dart`：`No issues found`。
- `flutter test --no-pub test/features/bookshelf/remote_book_page_test.dart`：`1/1` 通过，覆盖注入端口的初始目录加载。
- `scripts/check_architecture_boundaries.ps1`：剩余 `4` 项违规；本步移除 `RemoteBookPage` 的 WebDAV adapter 违规。

边界结论：书架远程书籍页面已收敛到领域端口；下一步处理 Reader 搜索页的章节缓存 adapter 直接依赖。

## 77. 2026-07-29：R6 SearchContentPage 章节缓存端口边界

迁移范围：

- `SearchContentPage` 移除 `FileChapterContentCache` 的直接导入和默认构造，构造函数及 `open` 入口改为要求
  `ChapterContentCachePort`。
- `ReaderPage` 从已有 `BookProvider.contentCache` 显式传入缓存端口；现有全文搜索 fake 测试同步补齐依赖。
- 未修改当前章/缓存章/联网搜索范围、替换规则、结果顺序、正文内容、断行、分页或章节位置行为。

测试结果：

- `flutter analyze lib/features/reader/search_content_page.dart lib/features/reader/reader_page.dart test/pages/cache_port_pages_test.dart`：`No issues found`。
- `flutter test --no-pub test/pages/cache_port_pages_test.dart`：`3/3` 通过。
- `scripts/check_architecture_boundaries.ps1`：剩余 `3` 项违规；本步移除 `SearchContentPage` 的章节缓存 adapter 违规。

边界结论：Reader 全文搜索已收敛到章节缓存端口；下一步处理 `BackupConfigPage` 的 Room 导入服务和本地文件 adapter 直接依赖。

## 78. 2026-07-29：R6 BackupConfigPage 依赖组装边界

迁移范围：

- `BackupConfigPage` 移除 application service 和本地文件 adapter 的直接导入；`BackupService`、`BackupLocalFilePort`
  与 `LegacyRoomImportUseCase` 均从根组合层读取，测试继续支持显式 fake 注入。
- 新增 domain 层 `LegacyRoomImportUseCase` 与 `LegacyRoomImportReport`，application 的具体
  `LegacyRoomImportService` 实现该用例；Room JSON 报告解析仍集中在 application/domain 契约，不进入页面。
- 未修改本地备份列表、文件恢复、WebDAV 备份、Room 导入确认/备份/回滚提示或其他阅读行为。

测试结果：

- `flutter analyze lib/features/settings/backup_config_page.dart lib/main.dart lib/application/database/legacy_room_import_service.dart lib/domain/ports/legacy_room_import_use_case.dart lib/domain/remote/legacy_room_import_report.dart test/widget/backup_config_page_test.dart`：`No issues found`。
- `flutter test --no-pub test/application/database/legacy_room_import_service_test.dart test/widget/backup_config_page_test.dart`：`7/7` 通过。
- `scripts/check_architecture_boundaries.ps1`：剩余 `1` 项违规；本步移除备份页的两项直接依赖。

边界结论：备份设置页已收敛到 application/domain 端口；剩余静态边界问题为 `RssProvider` 的业务 HTTP client，下一步处理其网络端口化。

## 79. 2026-07-29：R6 RssProvider 网络端口边界

迁移范围：

- 新增 `RssSourceImportPort` 与 `IoRssSourceImportPort`，将 RSS URL 抓取、手动重定向、每跳 SSRF 校验、30 秒超时和 10 MiB 上限移出 `RssProvider`。
- `main.dart` 根组合层注入 IO adapter；`RssProvider` 只保留 JSON 解析、持久化和导入状态，并支持 fake/不可用端口测试。
- 未修改 RSS JSON 字段映射、去重/覆盖、SharedPreferences 键名或文章正文、断行、分页和 TTS 行为。

测试结果：

- `flutter analyze lib/providers/rss_provider.dart lib/domain/ports/rss_source_import_port.dart lib/infrastructure/network/io_rss_source_import_port.dart lib/main.dart test/providers/rss_source_import_port_test.dart`：`No issues found`。
- `flutter test --no-pub test/providers/rss_source_import_port_test.dart test/widget/rss_tab_test.dart test/pages/rss_source_manage_page_test.dart`：`4/4` 通过。
- `scripts/check_architecture_boundaries.ps1`：`Architecture boundary check passed`，静态违规由 `1` 条降为 `0` 条。

边界结论：当前 `lib/features`、`lib/widgets` 和 `lib/providers` 静态边界检查已通过；R6 剩余工作转为同状态 UI 对照、过渡目录收敛和发布前外部 WebDAV 验收。

## 80. 2026-07-29：R6 RuleSub 管理页功能域收敛

迁移范围：

- 将 `lib/pages/rule_sub/rule_sub_page.dart` 迁移至 `lib/features/sources/rule_sub_page.dart`，并更新 `MainShell` 与 RSS 页面入口。
- 保持 RuleSub 导入、自动更新、静默更新、本地分组和确认缓存行为；未修改 RuleSub 服务、订阅 JSON 或原版基线。
- 本步未新增测试文件，复用既有规则订阅定向回归。

测试结果：

- 代理定向 `flutter analyze --no-pub`：无诊断。
- 规则订阅定向回归：`11/11` 通过。
- 旧 `pages/rule_sub` 路径引用扫描：无残留。

边界结论：RuleSub 管理页已进入 `features/sources` 功能域；R6 仍需继续收敛其他过渡页面和完成 UI/发布验收。

## 81. 2026-07-29：R6 AudioPlayPage 功能域收敛

迁移范围：

- 将 `lib/pages/audio/audio_play_page.dart` 迁移至 `lib/features/reader/audio_play_page.dart`，并更新 `ReaderPage` 入口。
- 迁移前后页面内容保持一致，保留 TTS 播放、章节切换、播放模式和 UI 语义；未实现原版 Android 后台 `AudioPlayService`。
- 本步未新增测试文件，复用既有 TTS 播放模式回归。

测试结果：

- 代理定向 `flutter analyze --no-pub`：无诊断。
- TTS 播放模式定向回归：`5/5` 通过。
- 旧 `pages/audio` 路径引用扫描：无残留。

边界结论：音频播放 UI 已进入 `features/reader` 功能域；真实 Android TTS、后台音频服务和媒体会话仍按暂停项处理。

## 82. 2026-07-29：R6 Explore 功能域收敛

迁移范围：

- 将 `lib/pages/explore/` 的 `ExploreListPage`、`ExploreTabPage` 和 `explore_utils.dart` 迁移至 `lib/features/explore/`。
- 更新 MainShell、SourcesPage 和 Explore 测试导入；保持发现分类、书源校验、搜索列表和启用状态行为不变。
- 涉及 Flutter app，无 Rust crate；未修改原版基线或正文/目录/分页契约。

测试结果：

- 定向 `flutter analyze --no-pub`：无诊断。
- Explore 定向测试：`2/2` 通过。
- 旧 `pages/explore` 路径引用扫描：无残留。

边界结论：Explore 页面已进入 `features/explore` 功能域；R6 仍需继续收敛剩余过渡页面和完成 UI/发布验收。

## 83. 2026-07-29：R6 CodeEdit 功能域与偏好服务边界

迁移范围：

- 将 `lib/pages/code_edit/` 六个文件迁移至 `lib/features/code_edit/`，更新书源编辑器和规则完整页面入口。
- 将 `CodeEditPrefs` 移至 `lib/services/code_edit_prefs.dart`，由服务层持有 SharedPreferences adapter；功能域只依赖服务和领域端口。
- 保持格式化、高亮、主题、键盘工具栏、偏好键、会话日志和保存结果语义不变；涉及 Flutter app，无 Rust crate。

测试结果：

- 定向 `flutter analyze --no-pub`：无诊断。
- CodeEdit/SourceEditor 定向测试：`17/17` 通过（CodeEdit 13、规则完整 4）；与 Explore 合计本批 `19/19`。
- 架构边界检查：`Architecture boundary check passed`。
- 旧 `pages/code_edit` 路径引用扫描：无残留。

边界结论：CodeEdit UI 已进入 `features/code_edit`，偏好持久化归入服务边界；R6 仍需继续收敛剩余过渡页面和完成 UI/发布验收。

## 84. 2026-07-29：R6 Cache 功能域与缓存端口边界

迁移范围：

- 将 `lib/pages/cache/` 的缓存管理、下载选择和下载辅助迁移至 `lib/features/cache/`，更新书架、我的页面和 Reader 入口。
- `CacheBookPage` 改为由生产调用方显式传入 `BookProvider.contentCache`，功能域不再直接导入 `FileChapterContentCache`；缓存统计、清理、导出和下载行为保持不变。
- 涉及 Flutter app，无 Rust crate；未修改正文、目录、分页或章节身份。

测试结果：

- 定向 `flutter analyze --no-pub`：无诊断。
- Cache/设置相关定向复核：`19/19` 通过。
- 架构边界检查：`Architecture boundary check passed`。
- 旧 `pages/cache` 路径引用扫描：无残留。

边界结论：Cache 页面已进入 `features/cache`，文件缓存实现保留在 infrastructure；R6 仍需继续收敛剩余过渡页面和完成 UI/发布验收。

## 85. 2026-07-29：HTTP TTS 缓存清理入口

实现范围：

- 在 `OtherSettingsCard` 的缓存管理区域增加“清理 HTTP TTS 缓存”操作，调用已有 `TtsService.clearHttpTtsCache()`。
- 清理成功或失败均显示明确提示；不改变 HTTP TTS 请求、缓存键、播放链路或真实 Android TTS 行为。
- 新增 1 个设置 Widget 测试用例，涉及 Flutter app，无 Rust crate。

测试结果：

- 定向 `flutter analyze --no-pub`：无诊断。
- 设置页定向测试：`2/2` 通过。
- Flutter 全量：`540` 通过，3 个既有条件测试跳过。

边界结论：HTTP TTS 文件缓存现在有设置页清理入口；真实 Android TTS/后台音频服务仍按暂停项处理。

## 86. 2026-07-29：R6 Search 功能域收敛

迁移范围：

- 将 `lib/pages/search/search_page.dart` 迁移至 `lib/features/search/search_page.dart`，并更新应用、书架、发现、书源编辑和书源管理入口。
- 保持搜索范围、精准搜索、搜索历史、结果分组和跳转书籍详情行为不变；未修改搜索端口、书源请求、结果顺序或正文/目录契约。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- 相关入口 `flutter analyze --no-pub`：无诊断。
- 搜索端口与搜索偏好定向测试：`3/3` 通过。
- 旧 `pages/search` 路径引用扫描：无残留。

边界结论：Search 页面已进入 `features/search` 功能域；R6 仍需继续收敛字典、替换、TXT 目录和漫画等过渡页面，并完成 UI/发布验收。

## 87. 2026-07-29：R6 DictRule 功能域收敛

迁移范围：

- 将 `lib/pages/dict/dict_rule_page.dart` 迁移至 `lib/features/my/dict_rule_page.dart`，更新“我的”页入口。
- 保持字典规则的加载、启用、编辑、删除、导入导出和规则测试行为不变；未修改字典查询、网络请求或阅读正文行为。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- 相关入口 `flutter analyze --no-pub`：无诊断。
- 字典规则服务与查询面板定向测试：`10/10` 通过。
- 旧 `pages/dict` 路径引用扫描：无残留。

边界结论：DictRule 页面已进入 `features/my` 功能域；R6 仍需继续收敛替换、TXT 目录和漫画等过渡页面，并完成 UI/发布验收。

## 88. 2026-07-29：R6 TXT 目录规则功能域收敛

迁移范围：

- 将 `lib/pages/txt_toc/txt_toc_rule_page.dart` 迁移至 `lib/features/my/txt_toc_rule_page.dart`，更新“我的”页入口。
- 保持 TXT 目录规则的加载、启用、编辑、删除和导入导出行为不变；未修改 TXT 目录解析、章节顺序、章节身份或阅读位置行为。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- 相关入口 `flutter analyze --no-pub`：无诊断。
- TXT 目录规则偏好定向测试：`3/3` 通过。
- 旧 `pages/txt_toc` 路径引用扫描：无残留。

边界结论：TXT 目录规则页面已进入 `features/my` 功能域；R6 仍需继续收敛替换和漫画等过渡页面，并完成 UI/发布验收。

## 89. 2026-07-29：R6 替换净化功能域收敛

迁移范围：

- 将 `lib/pages/replace/replace_page.dart` 迁移至 `lib/features/my/replace_page.dart`，更新“我的”页入口。
- 保持替换规则的列表、编辑、导入预设、启用/删除、恢复默认和实时预览行为不变；未修改替换规则 Repository、正文处理或阅读分页行为。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- 相关入口 `flutter analyze --no-pub`：无诊断。
- 替换 Provider、服务和预览面板定向测试：`9/9` 通过。
- 旧 `pages/replace` 路径引用扫描：无残留。

边界结论：Replace 页面已进入 `features/my` 功能域；R6 仍需处理漫画阅读页并完成 UI/发布验收。

## 90. 2026-07-29：R6 漫画阅读功能域收敛

迁移范围：

- 将 `lib/pages/manga/manga_reader_page.dart` 迁移至 `lib/features/reader/manga_reader_page.dart`，更新书籍详情页和 Reader 入口。
- 保持漫画图片提取、相对 URL 解析、章节切换、页码、方向、自动翻页和阅读位置行为不变；未修改正文内容、目录顺序、章节身份或分页契约。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- Reader、书籍详情和漫画相关 `flutter analyze --no-pub`：无诊断。
- 漫画图像提取、阅读位置、滚动位置、缓存端口和标记处理定向测试：`24/24` 通过。
- 旧 `pages/manga` 路径引用扫描：无残留。

边界结论：漫画阅读页面已进入 `features/reader` 功能域；R6 过渡页面目录已完成本轮收敛，仍需执行全量门禁并完成 UI/发布验收。

## 91. 2026-07-29：R6 Donate 功能域收敛

迁移范围：

- 将 `lib/pages/about/donate_page.dart` 迁移至 `lib/features/my/donate_page.dart`，更新“我的”页入口和 Donate Widget 测试导入。
- 保持捐赠渠道展示、二维码 URL、剪贴板复制和提示语行为不变；未修改外部服务、网络请求或阅读行为。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- 相关 `flutter analyze --no-pub`：无诊断。
- Donate 页面 Widget 测试：`2/2` 通过。
- 旧 `pages/about` 路径引用扫描：无残留。

边界结论：Donate 页面已进入 `features/my` 功能域；R6 仍需处理启动页及跨功能共享页面，并完成 UI/发布验收。

## 92. 2026-07-29：R6 Welcome 启动功能域收敛

迁移范围：

- 将 `lib/pages/welcome/welcome_page.dart` 迁移至 `lib/features/main/welcome_page.dart`，更新 App 启动入口和 Welcome Widget 测试导入。
- 保持启动闪屏时长、首帧后计时、完成回调、隐私键和品牌展示行为不变；未修改 MainShell、隐私流程或阅读行为。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- App 与启动页 `flutter analyze --no-pub`：无诊断。
- Welcome 页面 Widget 测试：`5/5` 通过。
- 旧 `pages/welcome` 路径引用扫描：无残留。

边界结论：Welcome 页面已进入 `features/main` 功能域；R6 仍需处理跨功能共享页面，并完成 UI/发布验收。

## 93. 2026-07-29：R6 二维码导入功能域收敛

迁移范围：

- 将 `lib/pages/qrcode/qrcode_capture_page.dart` 迁移至 `lib/features/sources/qrcode_capture_page.dart`，更新书源和 RSS 入口及 Widget 测试导入。
- 保持相机扫码、图库识别、桌面端回退、结果校验和页面返回值行为不变；未修改书源导入、RSS 导入或平台权限语义。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- 书源、RSS 和二维码相关 `flutter analyze --no-pub`：无诊断。
- 二维码页面 Widget 测试：`2/2` 通过。
- 旧 `pages/qrcode` 路径引用扫描：无残留。

边界结论：二维码页面已进入 `features/sources` 功能域；R6 仍需处理通用 WebView、AI、Obsidian 等共享页面，并完成 UI/发布验收。

## 94. 2026-07-29：R6 AI 配置功能域收敛

迁移范围：

- 将 `lib/pages/ai/ai_config_dialog.dart` 迁移至 `lib/features/ai/ai_config_dialog.dart`，更新“我的”页和 Reader AI 聊天入口。
- 保持 AI 配置加载、保存、模型获取、工具开关和头像/人设字段行为不变；未调用真实外部 AI 服务，也未改变 Reader 正文或章节行为。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- AI 配置、我的页和 Reader AI 聊天 `flutter analyze --no-pub`：无诊断。
- MainShell 集成回归：`2/2` 通过。
- 旧 `pages/ai` 路径引用扫描：无残留。

边界结论：AI 配置页面已进入 `features/ai` 功能域；真实 AI 外部服务继续按范围外处理，R6 仍需处理通用 WebView、Obsidian 等共享页面，并完成 UI/发布验收。

## 95. 2026-07-29：R6 Obsidian 导出功能域收敛

迁移范围：

- 将 `lib/pages/obsidian/obsidian_export_dialog.dart` 迁移至 `lib/features/obsidian/obsidian_export_dialog.dart`，更新书签页和“我的”页入口。
- 保持本地文件导出、Obsidian API 配置、连接测试、章节选择和导出结果提示行为不变；未修改书签身份、阅读位置或外部 WebDAV 行为。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- Obsidian 对话框、书签页和“我的”页 `flutter analyze --no-pub`：无诊断。
- 书签相关 Widget 测试：`3/3` 通过。
- 旧 `pages/obsidian` 路径引用扫描：无残留。

边界结论：Obsidian 导出对话框已进入 `features/obsidian` 功能域；外部 Obsidian/WebDAV 服务继续按既有范围处理，R6 仍需处理通用 WebView 并完成 UI/发布验收。

## 96. 2026-07-29：R6 通用 WebView 功能域收敛

迁移范围：

- 将 `lib/pages/common/app_webview_page.dart` 迁移至 `lib/features/common/app_webview_page.dart`，更新 RSS 阅读和书源登录入口。
- 保持内嵌 WebView、HTML 加载、外链回退、平台支持判断和登录/RSS 页面返回行为不变；未改变网络请求、Cookie 或书源登录语义。
- 涉及 Flutter app，无 Rust crate；未修改原版基线。

测试结果：

- RSS 阅读、书源登录和共享页面 `flutter analyze --no-pub`：无诊断。
- RSS 编辑/管理、书源登录端口和 RSS Tab 定向测试：`6/6` 通过。
- 旧 `pages/common` 路径引用扫描：无残留。

边界结论：通用 WebView 页面已进入 `features/common` 功能域；R6 过渡页面目录收敛完成，仍需执行本批最终门禁并完成 UI/发布验收。

## 97. 2026-07-29：R6 AI/Obsidian 网络边界修复

修复范围：

- 将 AI 配置的模型列表/测试请求移至 `AiConfigHttpService`，将 Obsidian 连通性/REST 导出移至 `ObsidianApiService`；`features` 页面不再直接导入 Dio 或创建业务 HTTP 客户端。
- 保持原有 URL 拼接、请求头、HTTP 方法、超时、状态码提示和错误文本行为；未扩大真实 AI、Obsidian 或 WebDAV 服务范围。
- 新增服务层适配器，未修改 Rust crate、原版基线、正文、目录、分页或章节身份。

测试结果：

- 相关服务、AI/Obsidian 页面和调用方 `flutter analyze --no-pub`：无诊断。
- 架构边界检查：`Architecture boundary check passed`，AI/Obsidian 原有 `10` 条违规已清零。
- 相关集成回归：`5/5` 通过；Flutter 全量：`540` 通过，3 个既有条件测试跳过。

边界结论：AI、Obsidian 和通用 WebView 页面均已满足当前静态功能域边界；真实外部服务仍按暂停/范围外条件处理。

## 98. 2026-07-29：R1 默认适配器与组合根收敛

迁移范围：

- 将 FRB、DAO、文件缓存、WebDAV 和 SharedPreferences 的实例化集中到
  `lib/bootstrap/app_composition_root.dart`；`AppBootstrap` 改为显式依赖编排。
- 书源、缓存、备份、进度同步、书签同步和静态状态服务移除默认具体 adapter；RuleSub 文本抓取
  必须显式传入 `PublicTextFetchPort`。
- 生产页面从 Provider 或构造参数消费同一服务实例；测试使用 fake/内存 port，不恢复生产默认值。

验证结果：

- `flutter analyze --no-pub`：无诊断。
- R1 组合联合定向测试：`73/73`；RuleSub/书源网络：`12/12`；`yckceo` 三源 smoke：`4/4`。
- `flutter test --no-pub --concurrency=1`：`563` 通过、`3` 项按既有条件跳过。
- 架构检查：核心层具体基础设施违规从 `78` 降为 `0`；剩余 Feature 偏好/服务依赖 `146` 条进入后续阶段。
- `git diff --check`：通过，仅有工作树 LF/CRLF 提示。

边界结论：R1 默认适配器和组合根边界已收敛；领域模型归属仍按独立批次迁移，R1 尚未最终退出。

## 99. 2026-07-29：全局能力与启动可靠性审计

审计范围：对照原版 legado-main/app/src/main/java/io/legado/app/App.kt 及其全局帮助类，检查当前 Flutter lib/main.dart、lib/bootstrap/app_composition_root.dart、lib/application/app_bootstrap.dart、lib/services/app_log.dart 和平台工程入口。

原版已注册或启动的全局能力：

- CrashHandler：注册 Thread.UncaughtExceptionHandler，保存崩溃日志和 appCrash 标记，下次启动由 MainActivity 提示打开日志。
- AppLog、LifecycleHelp、AppFreezeMonitor、DispatchersMonitor：分别提供运行诊断、Activity/Service 生命周期、应用冻结和调度器超时观测。
- DefaultData.upVersion：按版本门禁导入默认 HTTP TTS、TXT 目录规则、RSS 书源和字典规则。
- App.onCreate 后台维护：过期章节缓存、搜索书籍、无效规则/书籍缓存、备份缓存清理，书源排序修复，简繁转换预热，阅读进度同步。
- 平台/网络初始化：通知通道、Cronet 预下载、低版本 Android GMS TLS provider、Rhino 初始化和 WebView 绘制配置。

Flutter 对照结果：

| 能力 | 当前状态 | 证据/缺口 |
|---|---|---|
| 全局崩溃捕获与上次崩溃提示 | 未迁移 | main.dart 无 runZonedGuarded、FlutterError.onError、PlatformDispatcher.instance.onError 或启动崩溃标记 |
| 运行日志 | 部分覆盖 | AppLog 有 100 条 SharedPreferences 环形日志，但不是全局异常入口，也未统一设备/版本/启动阶段诊断字段 |
| 存储未初始化安全 | 部分覆盖 | AppConfig 有内存默认值；多个服务/端口未配置时仍抛 StateError，没有统一的初始化状态协议 |
| 启动编排 | 部分覆盖 | AppBootstrap 已隔离 WebDAV/同步失败；默认数据升级、缓存/搜索清理和启动维护任务未统一编排 |
| 生命周期协调 | 局部覆盖 | MyPage 自己实现 WidgetsBindingObserver；没有 application 级生命周期协调器 |
| 卡顿/调度监控 | 未发现等价实现 | 未发现全局 FrameTiming、isolate/任务超时或应用冻结监控 |
| 默认数据版本升级 | 部分覆盖 | 字典/TXT 规则等有偏好/内置数据服务，但未发现等价的集中版本门禁和启动升级任务 |
| 启动缓存/搜索清理 | 部分覆盖 | 有 clearInvalid 和手动缓存清理；未发现等价的启动过期清理全局任务 |
| 书源排序修复 | 未发现启动等价实现 | 页面内有局部排序，但未发现原版 SourceHelp.adjustSortNumber 的启动修复边界 |
| 简繁转换 | 功能覆盖，启动预热缺失 | Reader 内按配置转换正文；未发现原版启动阶段的转换引擎预热 |
| 通知通道/后台任务 | 未发现等价实现 | 当前 Flutter 依赖和平台入口未发现原版下载、朗读、Web 服务通知通道或统一后台任务注册 |
| Cronet/GMS TLS/WebView 设置 | 部分或平台差异 | Rust HTTP 已承担主要网络链路；未发现 Cronet 预下载、GMS provider 和全局 WebView 绘制配置的 Flutter 等价项，需按目标平台登记差异 |

处理结论：这些能力不属于普通页面功能，应作为 docs/REFACTOR_PLAN.md 的“横切基础设施：全局能力与启动可靠性”执行。P0 优先补齐崩溃防护、存储初始化安全和启动任务隔离；P1 再补生命周期、卡顿/调度监控、诊断模型和平台启动能力盘点。未完成前不得将 R6 发布验收描述为全局启动行为兼容。

## 100. 2026-07-29：R1 阅读配置与叶子领域模型归属

迁移范围：

- 架构脚本新增 `domain/model/models` 纯度规则和独立 fixture 测试，`bootstrap` 仅按目录授权为组合根。
- `ReadBook` 改依赖最小 `ReaderContentSourcePort`，不再导入 `BookSourceService`。
- 阅读样式、主题排版、字重和点击区迁入 `domain/reader_config`；Flutter `Color` 映射、中文标签和
  `ReaderSettings` 映射保留在 application/Feature。
- 书架分组、字典、替换、规则订阅、TXT 目录规则和 RSS 文章迁入纯 domain；旧 `lib/models` 只保留
  export。中文展示和时间戳 ID 创建移入 application policy，JSON 字段、默认值和相等性保持不变。

验证结果：

- 架构脚本 fixture 测试通过；真实检查的 domain/models 纯度违规从 `2` 降为 `0`。
- 阅读配置、分页、ReadBook、模型、持久化、RSS、替换正文和页面联合回归 `90/90`。
- `flutter analyze --no-pub`：无诊断；`git diff --check`：通过，仅有 LF/CRLF 提示。

边界结论：阅读配置和低耦合模型归属已收敛；Book/Chapter、BookSource/RssSource 和阅读进度仍按 R1 顺序迁移。

## 101. 2026-07-29：R1 Book/Chapter 核心领域模型归属

- `Book`、`BookReadConfig` 和 `Chapter` 迁入 `lib/domain/book`，旧 `lib/models` 路径仅保留 export。
- 阅读轮次中文文案移入 application policy；数据库序列化继续统一由 `DatabaseRecordCodec` 负责。
- 保持 `readConfig.reverseToc` 旧顶层兼容、模拟追读范围、章节 URL 身份、UTF-16 FNV-1a、
  URL-less 本地 ID、目录合并和下载正文元数据语义。

验证结果：核心仓储、codec、旧 schema、章节身份、目录合并/顺序和阅读位置联合回归 `29/29`；
`flutter analyze --no-pub` 无诊断；`git diff --check` 通过，仅有 LF/CRLF 提示。

边界结论：Book/Chapter 核心契约归属完成；BookSource/RssSource 与阅读进度模型仍待迁移，R1 尚未退出。

## 102. 2026-07-29：R1 BookSource/RssSource 领域模型归属

- `BookSource` 和 `RssSource` 迁入纯 domain，旧 `lib/models` 路径仅保留 export。
- 为保持既有静态 API 和无损往返，本批保留实体中的纯 Dart JSON 能力；没有把 domain 反向依赖到 infrastructure。
- 嵌套/扁平规则优先级、`rawSourceJson`、未知字段、header 对象/字符串、登录字段、jsLib、
  concurrentRate、RSS raw 和 engine JSON 语义不变。

验证结果：关键源模型、仓储、五组书源端口、导入、RuleSub、RSS 端口/排序/编辑回归 `30/30`；
完整批次另含 JS 兼容 `2/2`，可选在线检查按既定逻辑因 HTTP 400 跳过；全仓 analyze 无诊断。

边界结论：书源与 RSS 源模型归属完成；阅读进度模型是 R1 模型归属的最后一批。

## 103. 2026-07-29：R1 阅读进度与模型归属历史记录（当前状态已复核）

迁移范围：

- `BookProgress` 迁入 `lib/domain/reader`；WebDAV JSON 字段、进度前后比较和 `durChapterPos` 的
  UTF-16 章内位置语义保持不变。
- 原 `BookProgress.fromBook` 的系统时钟读取移入 application factory，并支持注入时钟；Reader 的
  两个上传入口改用该工厂。
- `LoginRowUi` 作为 UI/application DTO 迁入 `lib/application/source_login`；书源校验结果迁入
  `lib/domain/source`，默认校验关键词迁入 application policy。
- `lib/models` 已全面复核，现有文件均只保留兼容 export；`lib/model/read_book.dart` 是阅读会话对象，
  不作为持久化领域实体迁移。

验证结果：

- 合并定向回归 `46/46`；`flutter analyze --no-pub` 无诊断；架构脚本 fixture 测试通过。
- `flutter test --no-pub --concurrency=1`：`578` 通过、`3` 项按既有条件跳过。
- `cargo test -p legado_engine`：命令退出 `0`，核心单测 `127/127`，其余集成与文档测试通过，
  `1` 项既有测试 ignored。
- Android `emulator-5556` 重新执行 Room v99 两阶段 Driver smoke：import 与强停后的 verify 均
  `1/1` 通过，覆盖重启读取、重复导入幂等、本地备份、清空与恢复。
- 真实架构扫描仍报告既有 `146` 条后续 backlog：Feature 直接 SharedPreferences `14` 条、Feature
  直接业务 service `132` 条；domain/model 纯度与核心具体基础设施违规均为 `0`。
- `git diff --check` 在提交前最终执行；未修改 `legado-main/`、正文、目录、分页、章节身份或断行规则。

历史边界结论：本节记录当时对领域模型、数据访问、默认适配器和组合根的阶段判断；当前 R1 因 Kotlin Room
v99 → Rust v17 迁移门禁重新打开，不能据本节宣称 R1 最终退出。`146` 条 Feature backlog 和全局启动可靠性
P0/P1 任务继续保留，不得描述为已完成或以白名单消除。

## 104. 2026-07-29：R2 RSS 订阅源统一文本网络端口

- 删除 `IoRssSourceImportPort` 的 Dart `HttpClient`、手写重定向和响应读取实现。
- 新增 application 级 `PublicTextRssSourceImportPort`，组合既有 `PublicTextFetchPort`；根组合层复用同一
  `FrbPublicTextFetchPort`，实际请求继续由 Rust HTTP 执行。
- 保留 URL trim、Dart 侧私有地址前置拒绝和 `RssSourceImportPort` 的可空失败契约；Rust 侧继续执行
  TLS、逐跳重定向 SSRF、超时和响应大小限制。

验证结果：RSS adapter/provider/管理页回归 `6/6`；`flutter analyze --no-pub` 无诊断；架构脚本
fixture 测试通过。真实扫描仍为既有 `146` 条：Feature SharedPreferences `14`、Feature 业务 service
`132`，domain/model 与核心具体基础设施违规为 `0`。

边界结论：RSS URL 文本导入已进入统一 Rust HTTP 边界；R2 继续审计并迁移其它文本/JSON 与二进制
网络入口，本批未修改正文、目录、分页、章节身份、阅读位置或断行规则。

## 105. 2026-07-29：R2 主题 URL 统一文本网络端口

- `ThemeImportService` 删除 Dio 实例和具体网络配置，`fetchFromUrl` 改为显式接收
  `PublicTextFetchPort`；主题页面从根组合层 Provider 取得同一 Rust 文本端口。
- 保留主题 JSON 解析、预设/模式/颜色应用和空响应错误文本；新增 URL trim、网络错误透传和私有地址
  前置拒绝契约。

验证结果：主题服务与页面回归 `16/16`；`flutter analyze --no-pub` 无诊断；架构脚本 fixture 通过；
真实扫描仍为既有 `146` 条后续 backlog。

边界结论：主题公开文本已进入统一 Rust HTTP 边界；R2 下一批处理需要完整 AnalyzeUrl/JS 语义的
字典请求，不复用只能表达简单 GET 文本的接口来削弱规则行为。

## 106. 2026-07-29：R2 字典 AnalyzeUrl 与规则执行边界

- 新增 `DictRuleQueryPort`、application `DictRuleTester` 和 `FrbDictRuleQueryPort`；管理页与阅读器查词
  面板从根组合层取得端口，不再调用静态 Dio 测试器或返回“JS 尚未支持”占位。
- Rust 新增 `query_dict_rule`，复用统一 HTTP client 和通用 AnalyzeUrl 解析；`RequestConfig` 保留
  method/body/charset/headers，修正 `data:` URL 与 `,{jsonOptions}` 的分隔解析。
- showRule 复用现有 HTML、JSON、SourceRule 和 QuickJS 能力；补齐 Rhino `org.jsoup` 别名和
  Jsoup Elements 的 `text/html` 聚合方法。
- FRB 绑定使用仓库固定 `2.11.1` 重新生成，release DLL 重建后通过 hash 与真实调用验证。

验证结果：

- Rust 字典 fixture `5/5`，覆盖中文 GET key、POST headers/body、`data:`、HTML/JS、`@js` URL、
  Jsoup、空参数和私网拒绝。
- `cargo test -p legado_engine`：核心单测 `132/132`，其余集成与文档测试通过，`1` 项既有 ignored。
- FRB/Dart 字典、面板和组合回归 `14/14`；Flutter 串行全量 `587` 通过、`3` 项既有条件跳过；
  `flutter analyze --no-pub` 无诊断。
- 架构脚本 fixture 通过；真实 backlog `146 → 145`，Feature 业务 service `132 → 131`，
  SharedPreferences 仍为 `14`。

边界结论：字典网络与基础 AnalyzeUrl/showRule 已进入 Rust 端口，Dart Dio 和占位结果已移除；内置
百度汉语等规则使用的 `JavaImporter/JsonPath` 高级 Rhino API 尚未完成兼容，必须继续以 fixture
推进，不能据本批结果宣称所有内置字典规则已通过。R2 仍未退出。

## 107. 2026-07-29：R2 字典 Rhino 与 JsonPath 高级兼容

- Rust JS host 新增 `java.base64Encode`、`java.hexDecodeToString` 和内部 JSONPath 读取桥，复用既有
  `json_util::resolve_path`，没有另建一套路径解析语义。
- JS 标准库补齐 Rhino `JavaImporter`、Jayway `JsonPath`、`Configuration.builder()` 和
  `Option.SUPPRESS_EXCEPTIONS`；导入成员同时暴露给全局作用域，以适配原版 `with(aly)` 脚本。
- 字典执行入口只剥离 QuickJS 不支持的 `with(...)` 包装，保留其中脚本主体；新增管线 fixture 覆盖
  `data:` Base64 URL、十六进制解码、JavaImporter 和 JsonPath 的连续执行。

验证结果：

- `cargo test -p legado_engine`：核心单测 `135/135`，其余离线与集成测试通过；既有网络/人工场景
  按原条件 ignored。
- `cargo build -p legado_engine --release`：通过；真实 release DLL 经 FRB 加载，字典 port、偏好和
  查词面板联合回归 `12/12`。
- `scripts/run_js_compat.ps1`：Rust JS `18/18`、Flutter JS `4/4` 通过；可选在线 7565 因既有
  HTTP 400 条件跳过。
- `flutter analyze --no-pub` 与架构脚本 fixture 通过；真实架构审计按设计以非零退出并保持 `145`
  项存量：SharedPreferences `14`、Feature 业务 service `131`，没有新增或白名单化。
- `git diff --check` 通过，仅有 LF/CRLF 提示；未修改 `legado-main/`、正文、目录、分页、章节身份、
  阅读位置或断行规则。

边界结论：百度汉语等规则依赖的 JavaImporter/JsonPath 主链路已由离线 fixture 覆盖，但不能据此宣称
全部内置字典规则通过。Jsoup DOM 修改 API（包括 `remove`、`before`、`after`、`replaceWith`、
Element 构造/追加、属性和文本 setter、Elements 可迭代）仍待后续 fixture 驱动实现，R2 尚未退出。

## 108. 2026-07-29：R2 内置字典离线 fixture 与 Jsoup DOM 兼容

- 对照只读原版 `assets/defaultData/dictRules.json`，直接从 Flutter `DictRulePrefs.defaultRules` 读取
  当前五条内置规则，只将远程输入替换为 `data:` fixture；没有复制或简化 showRule。
- Jsoup shim 新增带父子关系的可变 DOM、逗号和 `:has` 选择器、Elements 迭代，以及 `remove`、
  `before`、`after`、`replaceWith`、Element 构造、append、attr/text setter 等原规则 API。
- Jayway shim 兼容原规则的递归路径、通配单命中列表语义及 `[*]field` 写法；百度普通释义和成语
  两个分支均以原始路径执行。
- 依据原版 `AnalyzeByJSoup.getResultLast("all") = elements.outerHtml()`，将 Rust Legado DSL 的
  `@all` 从错误的纯文本语义修正为 outer HTML，并以完整标签断言替换旧错误预期。

验证结果：

- `cargo test -p legado_engine`：核心单测 `141/141`，其余离线与集成测试通过；既有网络/人工场景
  按原条件 ignored。
- `cargo build -p legado_engine --release`：通过；release DLL 经真实 FRB 加载，海词英文/中文、
  有道、哔哩、百度普通释义和成语分支 fixture `7/7` 通过。
- `scripts/run_js_compat.ps1`：Rust JS `18/18`、Flutter JS `4/4` 通过；可选在线 7565 因既有
  HTTP 400 条件跳过。
- `flutter test --no-pub --concurrency=1`：`592` 通过、`3` 项既有条件跳过；
  `flutter analyze --no-pub` 无诊断。
- 架构脚本 fixture 通过；真实扫描仍为 `145` 项存量：SharedPreferences `14`、Feature 业务 service
  `131`，没有新增或白名单化。

边界结论：当前内置字典规则的离线网络输入、AnalyzeUrl/showRule、主要 Rhino/JsonPath 与 DOM 修改
链路均已覆盖；本批不宣称外部站点长期在线或所有第三方自定义规则均兼容。R2 下一批按顺序迁移
AI/Obsidian JSON 网络入口，Obsidian localhost 策略必须与仅允许公网的文本端口分离。

## 109. 2026-07-29：R2 AI/Obsidian 应用 HTTP 请求边界

- 新增 `ApplicationHttpRequestPort` 与 `FrbApplicationHttpRequestPort`，由根组合层提供；AI 配置和
  Obsidian 页面不再构造 Dio，服务保留原有 URL、headers、JSON/Markdown body 和返回文案契约。
- Rust 新增通用应用 HTTP 请求入口，支持 GET/POST/PUT、原始 body、包含限流等待的总超时及非 2xx
  状态码/正文；响应按流读取并严格限制为 8 MiB，固定 FRB `2.11.1` 重新生成绑定。
- AI 固定 `publicOnly`：初始 URL、每跳重定向、IPv4/IPv6 字面量及 DNS 解析结果均执行 SSRF 防护，
  直连时由过滤 DNS resolver 固定校验后的地址；Obsidian 固定 `localNetwork`：保留 localhost/LAN，
  并仍限制为 HTTP/HTTPS。两种策略均使用默认 TLS 校验和最多 5 次重定向。
- AI 模型列表恢复迁移前 Dio 对非 2xx 的失败语义；模型可用性测试和 Obsidian 继续按原行为读取
  状态码，Obsidian 导出错误继续包含服务端正文。

验证结果：

- `cargo test -p legado_engine api::network::tests -- --nocapture`：`4/4` 通过；应用 HTTP 策略回归
  `6/6`，覆盖 IPv6/DNS 私网拒绝、逐跳策略、恰好 5 跳成功/第 6 跳拒绝和限流等待超时。
- `cargo build -p legado_engine --release` 通过；`cargo test -p legado_engine` 核心单测 `152/152`，
  其余集成与文档测试无失败。
- AI/Obsidian Flutter 服务契约和 Windows release DLL 真实 FRB 本地往返 `9/9`；
  `flutter test --no-pub --concurrency=1`：`601` 通过、`3` 项既有条件跳过；
  `flutter analyze --no-pub` 无诊断。
- 架构脚本 fixture 通过；真实扫描按设计以非零退出并保持 `145` 项存量：SharedPreferences `14`、
  Feature 业务 service `131`，没有新增、削弱或白名单化。

边界结论：AI/Obsidian JSON 网络请求已进入 application port 和 Rust HTTP 边界，公网与本地网络策略
保持显式分离。本批未修改 `legado-main/`、正文、目录、分页、章节身份、阅读位置或断行规则；R2
继续按顺序审计和迁移二进制网络入口，尚未最终退出。

## 110. 2026-07-29：R2 统一二进制 HTTP 基础端口

- 新增 `ApplicationBinaryHttpRequestPort` 与 `FrbApplicationBinaryHttpRequestPort`，根组合层提供单一
  infrastructure adapter；业务层可取得状态码、Content-Type 和原始响应字节。
- Rust 二进制请求复用文本应用请求的 HTTP/HTTPS、默认 TLS、public/local 网络策略、逐跳重定向、
  DNS/IP SSRF、主机限流和总超时，不另建第二套网络安全语义。
- 调用者可传正数作为流式响应硬上限；`0` 表示保留旧二进制调用者的无上限行为。文本入口继续固定
  8 MiB 并在同一字节核心之上执行 UTF-8 解码。
- 固定 FRB `2.11.1` 重新生成 Dart/Rust 绑定；本批只建立端口，不提前修改 HTTP TTS、阅读样式 ZIP、
  正文图片缓存或页面图片展示行为。

验证结果：

- Rust 网络 API `5/5`、应用网络策略 `6/6`；`cargo test -p legado_engine` 核心 `153/153`，其余
  集成与文档测试无失败。
- `cargo build -p legado_engine --release` 通过；Windows release DLL 的文本与二进制真实 FRB 本地
  往返 `2/2`，验证非 2xx、Content-Type 和非 UTF-8 字节保持。
- `flutter analyze --no-pub` 无诊断；`flutter test --no-pub --concurrency=1`：`602` 通过、
  `3` 项既有条件跳过。

边界结论：统一二进制传输能力已就绪，但生产 Dio 二进制入口和 `Image.network/NetworkImage` 仍存在；
R2 下一批先迁移正文图片缓存、阅读样式 ZIP 与 HTTP TTS，前一批全绿后再处理页面远程图片直连。

## 111. 2026-07-29：R2 Dio 二进制调用者迁移

- `ReaderImageCache.createDefault` 删除 Dio，改由根组合层二进制 port 下载；保留 URL+headers 缓存键、
  书源/登录 headers、内存/磁盘缓存、并发去重和失败返回空结果，并增加 32 MiB 流式响应上限。
- `ReadStyleZipService` 删除 Dio，通过构造参数取得二进制 port；URL 导入保留 trim、GET、30 秒和
  localhost/LAN。新增 64 MiB 下载上限、32 MiB 解压单文件、128 MiB 解压总量，以及绝对路径和
  `..` 路径穿越拒绝；readConfig、字体和背景落盘语义不变。
- `HttpTtsClient` 删除 Dio，保留 GET/POST、原始 UTF-8 body、headers、非 2xx 失败、文本/JSON 错误、
  Content-Type 正则和 16 MiB 上限，使用 `localNetwork` 保留本地 TTS 端点。`TtsService` 仅增加根组合
  层端口配置，系统 TTS、播放器、句子推进和真实 Android TTS 暂停条件不变。

验证结果：

- HTTP TTS、正文图片缓存和阅读样式 ZIP 定向回归 `28/28`；`flutter analyze --no-pub` 无诊断。
- `flutter test --no-pub --concurrency=1`：`611` 通过、`3` 项既有条件跳过。
- `git grep` 已确认生产代码和测试代码中的 `package:dio` import 均为 `0`；依赖声明待页面远程图片
  批次完成后统一清理。

边界结论：三个业务二进制 Dio 入口已收敛到 Rust/FRB port；页面中的 `Image.network/NetworkImage`
仍绕过该边界。R2 下一批按前一批全绿原则迁移书源/漫画/封面，再迁移 RSS/字典远程图片。

## 112. 2026-07-29：R2 页面远程图片统一二进制端口

- 新增 `RemoteBinaryImage`，通过根组合层提供的 `ApplicationBinaryHttpRequestPort` 下载原始图片字节；
  单响应限制 32 MiB，内存 LRU 限制 64 MiB/128 项，相同 URL、headers 和网络策略的并发请求合并。
- 书源、漫画、封面、RSS 和正文图片使用 `localNetwork`，保留 localhost/LAN；漫画图片继续使用
  `SourceProvider.imageHeadersForBook` 提供的书源 headers，并通过同一组件预取。
- 字典 Markdown/HTML 图片固定使用 `publicOnly`；端口缺失、请求失败或解码失败时只渲染调用者既有
  占位，不再回退 `Image.network/NetworkImage` 绕过统一网络策略。
- 本批未修改 `legado-main/`、正文、目录、分页、章节身份、阅读位置或第 3 条断行规则。

验证结果：

- 远程图片、RSS、字典、封面、正文图片边界定向回归 `18/18` 通过。
- `flutter analyze --no-pub` 无诊断；`flutter test --no-pub --concurrency=1`：`618` 通过、
  `3` 项既有条件跳过。
- 源码扫描确认生产 `Image.network/NetworkImage` 为 `0`，生产与测试 `package:dio` import 为 `0`；
  `pubspec.yaml` 和 lockfile 中的 Dio 依赖声明留到下一批独立移除。

边界结论：页面图片展示已进入统一 Rust/FRB 二进制网络边界。R2 尚需移除 Dio 依赖声明、核查
WebView Cookie 边界并执行阶段退出门禁，当前不提前宣称退出。

## 113. 2026-07-29：R2 Dio 依赖清理

- 从 `pubspec.yaml` 删除已无调用者的 Dio 直接依赖；`flutter pub get` 同步移除 lockfile 中的 `dio`
  与传递依赖 `dio_web_adapter`，没有升级其余依赖版本。
- 源码扫描确认生产/测试 `package:dio` import、pubspec 声明和 lockfile 条目均为 `0`。

验证结果：

- `flutter pub get` 成功；`flutter analyze --no-pub` 无诊断。
- `flutter test --no-pub --concurrency=1`：`618` 通过、`3` 项既有条件跳过。

边界结论：Dart/Flutter Dio 依赖已完整移除。R2 下一批处理书源登录 WebView Cookie 到 Rust 网络会话的
同步闭环；普通 RSS WebView 不共享书源 Cookie，`java.startBrowserAwait` 真实宿主另列后续独立批次。

## 114. 2026-07-29：R2 书源登录 WebView Cookie 基础闭环

- 对照只读原版 `WebViewLoginFragment`、`CookieStore`、`AnalyzeUrl` 和 `HttpHelper`：登录 WebView
  初始请求只携带 source header 与覆盖其上的 login header，不额外注入 Rust 持久 Cookie；页面开始和
  完成时按当前 URL 读取 WebView Cookie，但写入 `bookSourceUrl` 对应的书源 Cookie 桶。
- 新增 `SourceLoginCookiePort`、`SourceLoginCookieService` 与 FRB adapter。Flutter 持久化扁平 Cookie
  串并立即整串写入 Rust；每次书源引擎调用前恢复该 source key Cookie，空串表示清除。
- Rust 新增 `set_source_cookie`/`clear_source_cookie`，使用 Public Suffix 将 source key 归一化为
  eTLD+1，IP 保持独立；跨子域共享、跨实际请求域按 source key 读取，整串设置删除旧键，登录 header
  的非 JSON Cookie 继续按原版合并。持久 Cookie 先合并、HTTP 会话 Cookie 后合并，同名时会话值覆盖。
- 删除登录 header 时同时删除持久/Rust Cookie；源编辑页“清除 Cookie”改为只清目标 source key，
  不再调用全局 Cookie/JS cache 清理。普通 RSS/通用 WebView 未接入该回调，不共享书源 Cookie。
- unsupported Windows/Linux WebView 回退改为确认平台支持后再创建 Cookie manager，避免桌面占位页断言。

验证结果：

- Rust source Cookie `7/7`、network API `5/5`；`cargo test -p legado_engine` 核心 `160/160`，
  其余集成与文档测试无失败。
- 固定 `flutter_rust_bridge_codegen 2.11.1` 重新生成绑定并重建 release DLL；set/clear 真实 FRB 往返通过。
- Flutter Cookie/登录/WebView 定向 `20/20`；`flutter analyze --no-pub` 无诊断；
  `flutter test --no-pub --concurrency=1`：`625` 通过、`3` 项既有条件跳过。

边界结论：手动 WebView 登录后的 Cookie 已能持久进入 Rust，并由搜索、详情、目录和正文复用。原版
定域清除还会尝试让平台 WebView Cookie 过期，当前插件缺少等价定域删除入口；此外
`enabledCookieJar` 的二次覆盖优先级和 `java.startBrowserAwait` 真实宿主仍需独立完成，R2 不退出。

## 115. 2026-07-29：R2 enabledCookieJar 与 Cookie 优先级

- 请求 Cookie 按原版两阶段组装：先以 source key/eTLD+1 持久 Cookie 为低优先级，随后由 source
  header、login header 和 AnalyzeUrl URL option 依次覆盖；URL option 的 method/body/charset/headers
  现在均进入搜索请求，不再丢失 headers。
- `enabledCookieJar=true` 时，发送前按实际请求 URL/eTLD+1 再合并一次 CookieJar，同名键覆盖临时
  Cookie，未冲突的 source/URL option Cookie 保留；为 `false` 时不执行第二次覆盖。
- 仅在 `enabledCookieJar=true` 时接收并保存书源响应的 `Set-Cookie`；普通非书源 HTTP 路径保持原有
  Cookie 行为。loginCheckJs、java.ajax 和 GE-UA 重试复用同一策略。

验证结果：

- Cookie 优先级、开关两态、跨实际请求域与响应保存定向 `4/4` 通过。
- `cargo test -p legado_engine` 核心 `162/162`，其余集成与文档测试无失败；release DLL 重建通过。
- `flutter analyze --no-pub` 无诊断；`flutter test --no-pub --concurrency=1`：`625` 通过、
  `3` 项既有条件跳过。

边界结论：`enabledCookieJar` 与实际代码优先级已对齐，搜索 URL option headers 已恢复。R2 剩余
Cookie 项仅为平台 WebView 的定域过期；规则宿主仍需实现 `java.startBrowserAwait` 真实 WebView。

## 116. 2026-07-29：R2 平台 WebView Cookie 定域清除

- 新增 `SourceLoginWebCookiePort` 与 MethodChannel adapter；组合根只在 Android/iOS/macOS 调用
  `legado_flutter/source_login_cookies.clearForSource`，Windows/Linux/Web 保持无操作。
- Rust 新增只读 `source_cookie_domain`，复用同一 Public Suffix 规则返回 eTLD+1，避免 Dart、Kotlin
  和 Swift 各自近似域名；固定 FRB `2.11.1` 重新生成绑定。
- Android 从 source URL 与 eTLD+1 读取 Cookie 名，逐个对 host-only 和 Domain Cookie 写入
  `Max-Age=0`/过去 Expires 并 flush；iOS/macOS 从默认 WK CookieStore 中只删除 domain 等于 source
  host 或 eTLD+1 的 Cookie。三端均未调用全局 Cookie 清空。
- 持久偏好和 Rust CookieJar 始终完成定域清除；平台 Cookie 过期失败仅记录，不恢复已删除登录态，
  对齐原版平台清除的尽力而为行为。普通 RSS/通用 WebView 不进入该端口。

验证结果：

- Rust network 定向 `6/6`；`cargo test -p legado_engine` 核心 `163/163`，其余集成与文档测试无失败。
- release DLL 的 domain/set/clear 真实 FRB 往返与 Flutter Cookie 定向 `5/5` 通过。
- `flutter analyze --no-pub` 无诊断；`flutter test --no-pub --concurrency=1`：`625` 通过、
  `3` 项既有条件跳过。
- `flutter build apk --debug --no-pub` 通过，包含 armv7、arm64、x86_64 Rust 引擎；iOS/macOS 因
  当前 Windows 环境无 Xcode，仅完成 Swift API 与无全局清除静态校验，不登记为平台构建通过。

边界结论：书源 Cookie 捕获、持久化、请求优先级、响应保存和定域清除均已闭环。R2 剩余实现项为
规则宿主 `java.startBrowserAwait` 的真实 WebView 能力及其退出门禁。

## 117. 2026-07-29：R2 `java.startBrowserAwait` 可见 WebView 宿主历史记录（当前状态已复核）

- 对照只读原版 `JsExtensions.kt`、`SourceVerificationHelp.kt`、`WebViewActivity.kt` 和
  `WebViewModel.kt`：实现 2/3/4 参数重载、默认 `refetchAfterSuccess=true`、按 UTF-16 计算的
  64 KiB URL 门禁、URL/HTML 两种加载、用户完成后 Cookie 保存、DOM 或重新抓取结果及最终 URL。
- Rust 新增长期 FRB Dart callback 服务。QuickJS 整段 `loginCheckJs` 在 `spawn_blocking` 专用线程
  执行；同步 `startBrowserAwait` 通过通道等待 Dart 主 isolate 导航，返回后继续同一个 JS context，
  不重跑脚本、不丢局部变量，也不占用 Tokio 异步工作线程。并发验证请求由宿主循环串行处理。
- Flutter 新增纯 Dart `SourceVerificationBrowserPort`、Navigator 实现和 infrastructure FRB adapter；
  根组合层持有 `navigatorKey` 并注入 Cookie capture，Feature 不直接依赖业务 service 或生成绑定。
  `AppWebViewPage` 增加完成动作，完成前等待当前 URL Cookie 队列，再返回最终 URL 与
  `document.documentElement.outerHTML`；返回键取消和宿主异常通过 FRB 错误返回，Rust 保留原响应。
- AnalyzeUrl URL option headers 继续覆盖 source/login headers；重新抓取使用已同步的 Rust CookieJar，
  并保留重定向后的最终 URL。RSS loginCheck 最小上下文补齐 `sourceUrl/sourceName/header`。
- 固定 `flutter_rust_bridge_codegen 2.11.1` 生成绑定；真实 Dart callback → Rust 后台探针 → Dart
  response → Rust Future 往返 `1/1` 通过，release DLL 重建通过。

验证结果：

- `startBrowserAwait` 参数/继续执行/UTF-16/重定向定向 `2/2`，宿主通道 `1/1`；JS compatibility
  `18/18`、模块 1 离线 fixture `4/4`。
- `cargo test -p legado_engine`：核心 `166/166`，其余集成与文档测试无失败。
- Flutter 宿主定向 `5/5`；`flutter test --no-pub --concurrency=1`：`629` 通过、`3` 项既有条件
  跳过；`flutter analyze --no-pub` 无诊断。
- `flutter build apk --debug --no-pub` 通过，包含 armv7、arm64、x86_64 Rust 引擎。当前 Windows
  环境无 Xcode，iOS/macOS 未登记为构建通过。
- 架构扫描按设计以非零退出并保持既有 `146` 条 backlog：SharedPreferences `14`、Feature
  业务 service `132`；核心层、domain/model 和展示层直连基础设施均为 `0`，本批无新增违规。

历史边界结论：本节记录当时对 R2 统一书源入口、网络/TLS、Cookie、规则 fixture、JS 兼容、错误恢复、FRB
适配和可见 WebView 宿主的阶段判断；当前不据本节宣称 R2 最终退出。后台 `java.webView*`、文件/压缩及其它
第三方宿主 API 继续保留在兼容性 backlog；且 R1-12 复核完成前不得推进新的 R2 实现。

## 118. 2026-07-29：R3 阅读正文、缓存与远端 ZIP 最终退出

- `ReaderPage` 保存当前页起始 UTF-16 章内位置，不再把页序号写入 `durChapterPos`；迁移与同步继续使用同一位置语义。
- Rust 新增正文处理事实源，覆盖全局普通/正则替换、书源级替换、标题去重、trim、缩进、重新分段和多行正则；生产阅读、全文搜索、替换 Provider 与预览均通过同一 `ContentProcessingPort`。
- 正文下一页规则支持多值：单 URL 串行跟随并终止循环，多 URL 并发抓取后按规则顺序合并；下一页等于下一章 URL 时停止，超过 100 个串行页面显式失败。
- 文件缓存、坏缓存删除、空正文、预加载去重、孤儿目录清理和文件/DB 状态修复保持既有布局与失败语义。
- Rust 接管远端书籍 ZIP 解码、TXT/EPUB 识别、安全相对路径、50MB 输入/解压总量、损坏包和空包错误；Flutter domain port/FRB adapter 只接收安全相对路径与字节，Service 负责平台文件落盘。
- 固定 FRB `2.11.1` 重新生成；正文内部函数只保留 crate 内可见实现，根 API 是唯一 FRB 出口，并删除 codegen 不会自动清理的陈旧 `api/content.dart` 生成文件。

验证结果：

- Rust ZIP 定向 `9/9`；Rust workspace 核心 `185/185`，其余非 ignored 集成、`legado_webdav` 和文档测试无失败。
- Flutter ZIP 端口/服务/页面 `6/6`，正文与 ZIP 真实 Windows release DLL/FRB `5/5`。
- 桌面分页、中文/URL 断行、硬分页、媒体、UTF-16 选区、快照、PNG、字体行高门禁 `59/59`；Android 真实 ReaderPage 单章/双章、固定快照和 SVG 像素门禁 `4/4`。
- `flutter test --no-pub --concurrency=1` 最终 `641` 通过、`3` 项既有条件跳过；首次全量的一项瞬时失败在随后两次完整全量中均未复现。
- `flutter analyze --no-pub` 无诊断；`flutter build apk --debug --no-pub` 通过，包含 armv7、arm64、x86_64 Rust 引擎；`git diff --check` 通过。
- 架构扫描仍按设计报告既有 `146` 条 backlog：SharedPreferences `14`、Feature 业务 service `132`；无新增违规。`legado-main/` 保持只读。

边界结论：R3 的正文处理契约、缓存生命周期、章节切换和第 3 条断行/分页退出条件均已满足。分页与中文断行继续属于 Flutter 展示层，远端 ZIP 解析属于 Rust；备份 ZIP、阅读样式 ZIP 和 WebDAV 发布验收仍按各自 R2/R5 边界处理，不在本批交叉迁移。

## 119. 2026-07-29：R4 复核与 R5 本地 Web API 归属迁移

- R3 最终退出后只读复核目录顺序、章节 `index/identity`、目录分页和可见行元数据，未发现回归，R4 不重开。
- 新增纯 Dart `WebApiDataPort`，application 层的 Repository 实现组合 `BookRepository`、`BookSourceRepository` 和 `ReadingRecordPort`；Dart IO adapter 只负责 loopback 监听、路由、Token 认证、响应与运行状态。
- 根组合层复用同一数据库 DAO/Repository/阅读记录端口。Rust 保留数据库和业务能力，不再负责 HTTP Server 生命周期。
- 删除 Rust `web_server`、FRB `start/stop/status` API 与 DTO、`FrbWebApiPort` 和旧 Rust listener 集成测试；`axum` 仅作为正文测试 fixture 的 dev-dependency 保留。
- 保持 `GET/HEAD /api/health`、books、chapters、sources、records，`POST /api/books` 和 `DELETE /api/books/:id` 的认证、状态码、Allow、空响应及 JSON 错误语义；未知路由不提前认证。
- Rust HTTP 主机并发闸按主机和有效端口隔离，避免同主机不同本地服务及并行 fixture 互相占用并发额度；目录多分页并发断言未修改。

验证结果：

- Web API application/infrastructure/service 定向 `11/11`，Dart IO 协议与真实临时 Rust 数据库 HTTP 集成合并 `6/6`。
- Rust workspace 核心 `184/184`，其余集成、`legado_webdav` 和文档测试无失败；目录并发与端口隔离定向测试通过。
- `flutter test --no-pub --concurrency=1` 最终 `648` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断。
- Android debug APK 和 Windows debug 应用构建通过。
- 架构扫描按设计报告既有 `146` 条 backlog：SharedPreferences `14`、Feature 业务 service `132`；无新增类别。`legado-main/` 保持只读。

边界结论：R5 本地 Web API 归属迁移完成，监听和协议属于 Dart IO，业务查询经 application port 进入 Repository/Rust 数据能力。正式或主流 WebDAV 发布验收仍需外部服务或凭证，继续按暂停条件登记，不宣称发布验收完成。

## 120. 2026-07-29：R6/P0-1 全局崩溃防护与启动恢复

- 对照只读原版 `App.kt`、`CrashHandler.kt` 和 `MainActivity.notifyAppCrash()`：原版在 Application 最早安装 handler，写入崩溃日志/标记，并在隐私流程后提示一次。`legado-main/` 未修改。
- 新增纯 Dart `CrashReport`、`CrashReportStore` 和 `CrashLogService`；报告保存时间、捕获来源、启动阶段、错误/堆栈、平台、应用版本和 Rust 引擎版本。字段有长度上限，截断不拆分 UTF-16 代理对。
- SharedPreferences adapter 只保存最近一条报告和独立待提示标记；确认提示只清标记、保留最新报告，损坏 JSON、读取/写入或元数据失败均返回安全空值/失败状态，不依赖 Rust DB、WebDAV 或完整 UI。
- `main` 在同一 `runZonedGuarded` 内初始化 Flutter binding、安装 `FlutterError.onError` 和 `PlatformDispatcher.onError`，保留并调用既有 handler；组合根和 `AppBootstrap` 只上报启动阶段，不改变初始化顺序。
- MainShell 严格先完成原版隐私流程，再确认待提示标记并显示崩溃提示；用户可暂不查看或打开完整崩溃日志。Feature 只依赖纯领域报告与回调，没有新增 Feature → service 违规。
- Rust WebDAV 代理测试改用显式 `NetworkConfig` 构造客户端，不再短暂改写全局 HTTP 客户端，消除与目录/正文 localhost fixture 的并行污染；代理映射和客户端构造断言保持不变。

验证结果：

- 崩溃 service/store/global handler/平台元数据/提示/MainShell 顺序定向 `13/13`；启动 WebDAV、进度同步、AppLog、MainShell 和 Welcome 回归 `15/15`。
- `flutter test --no-pub --concurrency=1`：`659` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断。
- Rust WebDAV 代理定向 `2/2`、目录/正文 HTTP fixture `6/6`；Rust workspace 核心 `184/184`，其余集成、WebDAV 和文档测试无失败。
- Android debug APK 与 Windows debug 应用构建通过；Windows debug 进程隐藏冷启动 5 秒保持运行，Android APK 安装到 `emulator-5556` 后 `MainActivity` 启动成功且 5 秒后进程仍存活。
- 架构扫描保持既有 `146` 条：SharedPreferences `14`、Feature 业务 service `132`；无新增类别，`legado-main/` 保持只读。

边界结论：P0-1 已满足当前计划的捕获、持久化、启动阶段、一次性提示、日志查看和失败降级要求。下一固定任务为 P0-2 存储初始化安全；`MainShell` 隐私偏好迁移和 `AppLog` 统一分别留给 P0-2/P1-3，不混入本 checkpoint。

## 121. 2026-07-30：R6/P0-2 存储初始化安全

- 新增 `SharedPreferencesRuntime`，统一记录 `uninitialized`、`initializing`、`ready` 和 `failed` 状态；并发调用共享同一初始化 Future，失败返回 null、保留错误并允许后续显式重试。启动关键的书架分组、阅读进度同步、代码编辑器和崩溃报告 adapter 在存储不可用时返回空值、默认值或 `false` 写入结果。
- `AppConfig`、主题、书架布局、WebDAV、隐私提示、AppLog 和数据路径均通过该运行时读取；初始化失败时保留内存默认值或当前内存状态，写入不抛出未捕获异常。MainShell 仍严格先执行隐私流程，再处理崩溃提示。
- `LegadoDbBridge` 增加数据库初始化状态、并发初始化合并和失败记录。数据库初始化失败不再从组合根向首屏冒泡；数据库业务调用仍由 `requireReady` 返回带失败原因的 `StateError`，不伪造数据库可用状态。文件缓存 `hasCachedContent` 在路径创建/文件系统异常时返回 `false`。
- 测试使用新增运行时 reset 隔离 `SharedPreferences.setMockInitialValues`，避免全量串行测试之间复用旧缓存；未放宽或删除业务断言。`legado-main/` 未修改，本批未改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- SharedPreferences 状态、并发竞态、失败重试和三个启动 adapter 定向 `4/4`；AppConfig、主题、书架、网络、文件缓存、MainShell、崩溃存储和备份回归 `43/43`。
- `flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1`：`663` 通过、`3` 项既有条件跳过。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，其余集成、`legado_webdav` 和文档测试无失败。
- 架构扫描为 `144` 条 backlog（本批从 `146` 降至 `144`，未新增或白名单化）；`legado-main/` 保持只读。

边界结论：P0-2 已满足当前计划的存储初始化失败降级、并发初始化安全、数据库失败可识别和文件缓存安全探测要求。下一固定任务为 P0-3 启动任务隔离；偏好业务全面 port 化和统一诊断模型仍分别属于后续 backlog/P1-3，不在本批扩大范围。

## 122. 2026-07-30：R6/P0-3 启动任务隔离

- 新增 `StartupTaskRunner`，统一记录启动后台任务的 `running/succeeded/failed/skipped`、attempt、起止时间、错误和堆栈；同一任务运行中合并 Future，成功后同进程不重复执行，失败任务允许后续重试，默认 30 秒超时。
- `AppBootstrap` 不再把网络恢复、Web API 恢复、WebDAV 初始化、书架加载、缓存维护和阅读进度同步串联到首屏组装链路。首屏依赖组装和主题加载完成后即返回应用状态，后台任务通过 runner 独立执行和上报。
- `BookProvider.loadBooks` 新增 `runMaintenance` 参数；启动路径只加载书架数据，文件缓存孤儿目录清理和章节元数据刷新移入独立 `bookshelf.maintenance` 任务，避免维护操作阻塞首屏。
- `MainShell` 保留 AppConfig 与书架布局偏好的同步读取，以维持默认首页和底栏显隐；RSS 源、替换规则、内置书源补齐、书源加载和规则订阅自动更新改为 runner 管理的后台任务。规则订阅仍保留原版约 1 秒延迟语义。
- `legado-main/` 未修改；本批未改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 启动任务 runner、启动 WebDAV、阅读进度同步、书架缓存维护、MainShell 和 Welcome 定向 `22/22`。
- `flutter analyze --no-pub`：`No issues found`。
- 架构扫描保持 `144` 条既有 backlog：Feature 直接 SharedPreferences `12`、Feature 业务 service `132`，无新增类别。
- `flutter test --no-pub --concurrency=1`：`667` 通过、`3` 项既有条件跳过。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，其余集成、`legado_webdav` 和文档测试无失败。

边界结论：P0-3 已满足启动任务独立超时、失败隔离、结果可观测、不阻塞首屏、不重复执行和失败可重试要求。下一固定任务为 P1-1 全局生命周期边界；默认数据版本门禁与更细粒度业务 port 化仍按后续独立任务推进，不在本批扩大范围。

## 123. 2026-07-30：R6/P1-1 全局生命周期边界

- 新增 application 级 `AppLifecycleCoordinator`，记录 `resumed/inactive/hidden/paused/detached` phase、恢复次数和当前是否前台，作为页面订阅的唯一生命周期状态入口。
- 新增 infrastructure 级 `FlutterLifecycleObserver`，将 Flutter `AppLifecycleState` 映射到 application phase；组合根统一创建并启动 observer，Provider dispose 时注销，页面不再直接注册同类全局回调。
- `MyPage` 移除 `WidgetsBindingObserver` mixin 和 `WidgetsBinding.instance.addObserver/removeObserver`，仅在 coordinator 的 `resumeCount` 增加且状态为 resumed 时刷新 Web 服务开关/地址，保留原版“回到前台刷新状态”的行为。
- `MainShell` 和 MyPage 测试宿主补齐生命周期 coordinator 注入，避免页面依赖隐藏全局状态；本批未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。`legado-main/` 保持只读。

验证结果：

- 生命周期 coordinator、MyPage 和 MainShell 定向回归 `5/5`。
- `flutter analyze --no-pub`：`No issues found`。
- 架构扫描保持 `144` 条既有 backlog：Feature 直接 SharedPreferences `12`、Feature 业务 service `132`，无新增类别。
- `flutter test --no-pub --concurrency=1`：`668` 通过、`3` 项既有条件跳过。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，其余集成、`legado_webdav` 和文档测试无失败。

边界结论：P1-1 已满足当前计划的 application 生命周期协调、平台 observer 收口、页面订阅状态和前台恢复刷新要求。下一固定任务为 P1-2 卡顿与调度监控；更完整的通知/后台服务/TLS/WebView 启动能力继续按 P1-4 独立盘点，不在本批扩大范围。

## 124. 2026-07-30：R6/P1-2 卡顿与调度监控

- 对照只读原版 `AppFreezeMonitor.kt` 与 `DispatchersMonitor.kt`：原版仅在 `recordLog` 开启时运行，冻结采样每 3 秒检查额外延迟，Dispatcher 5 秒未响应写运行日志。本批未修改 `legado-main/`。
- 新增 application 级 `AppDiagnosticsMonitor`，定义慢帧、应用冻结、调度超时、启动任务超时和启动任务失败诊断事件；默认 `AppDiagnosticsConfig.enabled=false`，关闭时不发事件、不写日志。
- 新增 infrastructure 级 `FlutterFrameDiagnosticsObserver`，仅在诊断开关开启时注册 `SchedulerBinding.addTimingsCallback` 和主 isolate 冻结计时器；Provider dispose 时移除帧回调并取消计时器，避免默认启动成本。
- 新增 `DiagnosticsPrefs`，通过 SharedPreferencesRuntime 读取/保存诊断监控开关；默认关闭，存储不可用时安全返回 false。
- 组合根创建 diagnostics monitor，以 AppLog 作为 sink；启动任务失败/超时通过 monitor 写入诊断日志，CrashLogService 仍只记录未处理异常、Flutter/平台错误和启动阶段，不把普通慢帧、冻结或后台任务失败误记为崩溃。
- 本批未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 诊断 monitor、诊断偏好和启动任务回归定向 `8/8`。
- `flutter analyze --no-pub`：`No issues found`。
- 架构扫描保持 `144` 条既有 backlog：Feature 直接 SharedPreferences `12`、Feature 业务 service `132`，无新增类别。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`672` 通过、`3` 项既有条件跳过。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，其余集成、`legado_webdav` 和文档测试无失败。

边界结论：P1-2 已满足当前计划的可开关帧耗时、主 isolate 冻结采样、后台任务超时诊断、AppLog 接入和非崩溃边界要求。下一固定任务为 P1-3 全局日志与诊断信息；通知/后台服务/TLS/WebView 启动能力继续留给 P1-4 逐项盘点。

## 125. 2026-07-30：R6/P1-3 全局日志与诊断信息

- 新增纯 domain `DiagnosticRecord`、`DiagnosticSeverity` 和 `DiagnosticRuntimeInfo`，统一运行日志、诊断日志和崩溃展示格式；行文本包含时间、级别、分类、来源、平台、应用版本、Rust 引擎版本和可控元数据。
- 统一敏感信息脱敏和 UTF-16 安全截断，覆盖 `token/access_token/password/passwd/secret/cookie` 与 `Authorization: Bearer ...`；错误、堆栈、元数据、单行长度、内存条数和持久化总字节均有上限。
- `AppLog` 保留最新在前、清理和复制导出语义，底层改为 `DiagnosticRecord` 格式；组合根加载真实平台/应用/Rust 引擎版本后配置运行日志元数据，并把启动阶段同步写入 AppLog。
- `CrashLogService` 写入前复用同一脱敏/截断策略；`CrashReport.displayText` 复用统一诊断模型，但 SharedPreferences 崩溃报告 store 的“最新报告”和“一次性待提示标记”边界保持不变。
- P1-2 诊断事件继续 `isCrash=false`，写入 AppLog 但不写入 CrashLogService；普通慢帧、冻结采样和后台任务失败不会被误记为崩溃。
- 本批未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。`legado-main/` 保持只读。

验证结果：

- 诊断 record、AppLog、CrashLogService、AppDiagnosticsMonitor、AppLogPage 和 CrashRecoveryPrompt 定向 `16/16`。
- `flutter analyze --no-pub`：`No issues found`。
- 架构扫描保持 `144` 条既有 backlog：Feature 直接 SharedPreferences `12`、Feature 业务 service `132`，无新增类别。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`678` 通过、`3` 项既有条件跳过。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，其余集成、`legado_webdav` 和文档测试无失败。

边界结论：P1-3 已满足当前计划的全局日志格式、敏感信息限制、运行/崩溃/手动导出复用诊断模型和清理边界要求。下一固定任务为 P1-4 平台启动能力盘点。

## 126. 2026-07-30：R6/P1-4 平台启动能力盘点

- 对照只读原版 `App.kt`、`AppFreezeMonitor`、`DispatchersMonitor` 和通知创建逻辑，登记原版 Application 启动期间的通知通道、WebView 绘制设置、Cronet 预下载、GMS TLS provider、简繁转换预热、缓存清理和阅读记录同步行为。
- 通知通道：原版创建下载、朗读、Web 服务三类 Android notification channel；当前 Flutter/Android 没有对应 channel 或通知插件/前台服务。真实 Android TTS、后台音频和通知服务按暂停/范围外条件登记，不宣称等价完成。
- 后台任务/服务：当前 Flutter 已有启动任务 runner 和阅读进度同步，但没有原版 Android 前台服务/后台音频生命周期；后台能力继续单独受目标平台和产品需求约束。
- WebView 绘制：当前使用 `webview_flutter` 作为页面宿主，没有原版 `WebView.enableSlowWholeDocumentDraw()` 全局调用；未发现当前产品流程需要该分享卡片截图差异，登记为 Android 平台差异，待明确需求后补平台 adapter 和 smoke。
- 网络/TLS：原版 Android Q 以下可选插入 GMS Conscrypt，且预下载 Cronet；当前主网络请求已由 Rust HTTP 统一承接 TLS、重定向、SSRF、限流和超时，不重复引入 Cronet 或 GMS provider。GMS/Cronet 属于实现差异，不影响当前 Rust 网络契约。
- 简繁转换：当前阅读器保留局部 `ChineseConvert`/阅读配置转换；没有原版全局词典预热等价入口，登记为功能边界差异，不在本轮启动阶段改变正文转换行为。
- 启动清理/同步：P0-3 已将书架缓存维护和阅读进度同步纳入可观测后台任务；原版其他数据升级/清理行为继续按各自数据与服务边界追踪，不在本平台盘点中扩大迁移。
- 本批为只读能力审计，没有修改业务代码或 `legado-main/`，未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 复用 P1-3 最终门禁：Flutter 串行全量 `678` 通过、`3` 项既有条件跳过；Rust workspace `184/184`；`flutter analyze --no-pub` 无诊断；架构扫描保持 `144` 条既有 backlog。
- `git diff --check` 在本批文档修改后通过。

边界结论：P1-4 平台启动能力盘点完成。Rust 网络能力已覆盖，不重复引入 Cronet/GMS TLS；通知、后台音频、WebView 全量绘制和全局简繁预热明确登记为平台差异/暂停项。下一阶段进入应用用例依赖、受控 UI/目标平台和发布门禁。

## 127. 2026-07-30：R6 应用用例依赖：AppLog 页面边界

- 新增 application `AppLogPort`，只暴露 `DiagnosticRecord` 列表、加载、清理和导出文本；新增 infrastructure `AppLogPortAdapter`，复用既有 AppLog 静态持久化，不改变存储 key、条数、字节上限或脱敏规则。
- `AppLogPage` 和 `AppLogDialog` 改为从 Provider 读取端口，页面不再直接 import `services/app_log.dart`；复制、清空、最新在前、级别颜色和空状态保持不变。
- 组合根注册 `AppLogPort` adapter；测试宿主显式注入 adapter，未放宽既有 UI/日志断言。`legado-main/` 未修改，本轮不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- AppLog 页面与日志服务定向 `4/4`。
- `flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`678` 通过、`3` 项既有条件跳过。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，其余集成、`legado_webdav` 和文档测试无失败。
- 架构扫描从 `144` 降至 `142` 条：Feature 直接 SharedPreferences `12`、Feature 业务 service `130`；无新增类别。
- `git diff --check` 通过。

边界结论：AppLog 页面这一条 application 用例依赖边界已完成；剩余 Feature service 依赖继续按单边界、单用例迁移，不以旧违规作为永久例外。

## 128. 2026-07-30：R6 应用用例依赖：AppLog 写入边界

- `AppLogPort` 扩展 `i/w/e` 写入契约，`AppLogPortAdapter` 继续转发到既有静态 `AppLog`，不改变日志持久化 key、条数、字节上限、脱敏和最新在前语义。
- `AddBookUrlDialog`、`BookshelfMenuActions`、`ImportBookshelfDialog` 和 `RemoteBookPage` 通过 Provider 读取 `AppLogPort`；异步流程在等待前捕获端口，避免跨 async gap 使用 `BuildContext`。
- `BookmarkService` 与 `NoteService` 移除 `services/app_log.dart` 直接依赖，由组合根注入同一 `AppLogPort`；未配置端口时错误日志安全跳过，原有静态书签/笔记业务 API、返回值和异常降级不变。
- 远程书籍页面测试宿主补齐显式日志端口注入，未放宽或删除既有断言。`legado-main/` 未修改，本批未改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- AppLog/远程书籍定向 `5/5`；书签/笔记服务定向及集成回归 `7/7`。
- `flutter analyze --no-pub`：`No issues found`；Flutter 串行全量 `678` 通过、`3` 项既有条件跳过。
- `cargo test --manifest-path rust/Cargo.toml`：workspace 全量通过，Rust 核心 `184/184`；现有 FRB 宏和未使用代码 warning 未新增为失败。
- 架构扫描为 `138` 条 backlog：Feature 直接 SharedPreferences `12`、Feature 业务 service `126`；无新增类别。
- `git diff --check`：通过。

边界结论：AppLog 写入已从书架 Feature、书签服务和笔记服务收口到 application port 与组合根；剩余 Feature 偏好/业务服务依赖继续按单边界、单用例迁移。

## 129. 2026-07-30：R6 三线并行收口 Feature 偏好边界

- 书架线新增 `BookshelfDisplayPrefsPort` 与 `SharedPreferencesBookshelfDisplayPrefs`，迁移 `shelf_show_grouped`、`shelf_pinned_ids`；排序、置顶集合和书架 UI 行为保持不变。
- 下载线新增 `DownloadChoicePrefsPort` 与 `SharedPreferencesDownloadChoicePrefs`，迁移 `download_choice_concurrency`、`download_choice_next_n`；保留默认值、`1..8`/`1..9999` clamp、加载状态和确认保存语义。
- RSS 线新增 `RssReadStatePort` 与 `SharedPreferencesRssReadStateAdapter`，迁移 `rss_read_<Uri.encodeComponent(sourceUrl)>`；保留已读链接集合、重复链接去重、异步生命周期和文章列表行为。
- 三类 adapter 均通过 `SharedPreferencesRuntime` 获取存储，组合根统一注册 application port；三个 Feature 不再直接 import 或调用 `SharedPreferences`。本批由主 agent 与两个子 agent 使用不重叠写入范围并行完成，未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 三条线定向回归 `8/8`；`flutter analyze --no-pub`：`No issues found`。
- Flutter 串行全量 `686` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过。
- 架构扫描为 `128` 条 backlog：Feature 直接 SharedPreferences `2`、Feature 业务 service `126`；无新增类别。
- `git diff --check`：通过。

边界结论：本批完成三类独立 Feature 偏好端口化，架构 backlog 从 `138` 降至 `128`；剩余两条 SharedPreferences 违规集中在 `SourceEditorPage`，后续继续单独迁移。

## 130. 2026-07-30：R6 第二轮 Feature 端口边界

- `SourceEditorPage` 新增 `SourceVariablePort` 与 `SharedPreferencesSourceVariableAdapter`，迁移 `source_variable:<bookSourceUrl>` 读写；保留保存前书源提交、变量注释、对话框和成功提示语义，存储不可用时安全返回空值/失败结果。
- `SearchPage` 新增 `SearchHistoryPort`，通过 `SharedPreferencesSearchHistoryAdapter` 复用既有搜索历史持久化规则；Feature 不再直接 import `services/search_history.dart`，保留 trim、去重、最多 20 条、删除和清空行为。
- `AppLogPage` 与 `AppLogDialog` 新增 `ReaderFontPort`，通过 `ReaderFontPortAdapter` 复用既有系统字体和 CJK fallback 顺序；日志读取、复制、清空和展示行为不变，测试宿主显式注入展示端口。
- 组合根统一注册三类 port；本轮原计划由主 agent 加两个子 agent 三线推进，两个子 agent 部分请求受服务端 `429` 限流影响，主 agent 接管未完成线。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 源变量 adapter、搜索历史 port 和 AppLog 页面定向 `7/7`；`flutter analyze --no-pub`：`No issues found`。
- Flutter 串行全量 `690` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过。
- 架构扫描为 `123` 条 backlog：Feature 直接 SharedPreferences `0`、Feature 业务 service `123`；无新增类别。
- `git diff --check`：通过。

边界结论：Feature 直接 SharedPreferences 访问已归零，搜索历史、源变量和 ReaderFont 展示能力均完成第一层 application/infrastructure 边界收口；剩余工作集中在 Feature 业务 service 依赖。

## 131. 2026-07-30：R6 第三轮 ReaderFont Feature 边界

- `BookshelfOverflowMenu`、`RssSourceManagePage` 和 `RssSourceTile` 移除对 `services/reader_font_loader.dart` 的直接依赖，统一通过已有 application `ReaderFontPort` 获取平台字体和 CJK fallback。
- 菜单保留既有 action 顺序/文案；RSS 源管理页和 tile 保留字体族、fallback 顺序与原有 UI 行为。测试宿主补齐 fake port，未放宽既有菜单、导入和远程图片断言。
- 本批由两个子 agent 分别处理书架和 RSS 文件，主 agent 负责共享端口审查、组合根集成和全量门禁；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- ReaderFont/书架菜单/RSS 页面定向 `4/4`；`flutter analyze --no-pub`：`No issues found`。
- Flutter 串行全量 `694` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过。
- 架构扫描为 `120` 条 backlog：Feature 业务 service `120`，无 SharedPreferences 类别新增或残留。
- `git diff --check`：通过。

边界结论：ReaderFont 展示能力已从当前命中的书架/RSS Feature 调用点收口到 application port；剩余 backlog 全部是 Feature 业务 service 依赖，继续按独立用例迁移。

## 132. 2026-07-30：R6 第四轮 Donate/CodeEdit 业务能力边界

- `DonatePage` 新增 application `DonateClipboardPort` 和 infrastructure `PlatformDonateClipboard`；旧 `services/donate_clipboard_port.dart` 保留兼容导出，构造注入和 Provider 注入均可用，复制提示与外链行为不变。
- `CodeEditPage` 新增 application `CodeEditPrefsPort` 和 infrastructure `SharedPreferencesCodeEditPrefs`，覆盖偏好加载、主题/字号/换行/补全设置、会话日志追加/读取/清空；复用既有 store 和键名，页面不再直接 import `services/code_edit_prefs.dart`。
- 组合根统一注册两类端口；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- Donate/CodeEdit 定向 `13/13`；`flutter analyze --no-pub`：`No issues found`。
- Flutter 串行全量 `698` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过。
- 架构扫描为 `118` 条 backlog：Feature 业务 service `118`，无 SharedPreferences 直接访问类别残留。
- `git diff --check`：通过。

边界结论：剪贴板和代码编辑器偏好已完成第一层 application/infrastructure 收口，剩余工作继续处理更复杂的 Feature 业务 service 依赖。

## 133. 2026-07-30：R6 文件管理、剪贴板与书源调试边界

- `FileManagePage` 从 `services/app_paths.dart` 的静态数据根目录调用迁移到 application `AppPathsPort`；`AppPathsPortAdapter` 只在 infrastructure 层转发既有 `AppPaths.dataRoot()`，自定义数据目录创建和文件列表行为保持不变。
- `AppLogPage`、`AddBookUrlDialog` 和 `ImportBookshelfDialog` 移除 Flutter Clipboard 直接访问，统一依赖 application `ClipboardPort`；`PlatformClipboard` 在组合根提供真实平台实现，复制/粘贴、trim、空文本和日志提示语义保持不变。旧 `services/clipboard_port.dart` 仅保留兼容导出。
- `SourceDebugPage` 不再直接依赖调试日志格式化 service，改用 application `SourceDebugFormatterPort`；`SourceDebugFormatterAdapter` 复用既有格式化输出，搜索/目录调试请求、结果上限、错误日志和展示格式保持不变。
- 补齐独立 widget 测试宿主此前缺失的 `BookshelfDisplayPrefsPort`、`ReaderFontPort` 和 `RssReadStatePort` 注入；这些改动只修复组合边界，不放宽已有 UI 断言。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- AppPaths、AppLog、SourceDebug、剪贴板和格式化器定向 `10/10`；测试宿主回归 `2/2` 与 `6/6`。
- `dart format --output=none --set-exit-if-changed`：通过；`flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`699` 通过、`3` 项既有条件跳过；全量过程中未放宽断言，修复的失败均为测试宿主缺少已存在的 application port 注入。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过；保留既有 FRB cfg/linker/dead-code warnings。
- 架构扫描为 `115` 条既有 Feature→service backlog，无新增类别；`git diff --check`：通过。

边界结论：本批完成 AppPaths、平台剪贴板和 SourceDebugFormatter 的 application/infrastructure 组合边界，并将两处书架导入剪贴板调用纳入统一端口；剩余 Feature→service backlog 继续按单边界、单用例迁移，不登记为永久例外。

## 134. 2026-07-30：R6 RSS Tab 与主题 Clipboard 边界

- `RssTabPage` 移除 `services/reader_font_loader.dart` 直接依赖，改由 Provider 注入既有 `ReaderFontPort`；搜索栏字体族和 CJK fallback 顺序保持不变，RSS 导航和订阅源展示不变。
- `ThemeConfigPage` 移除 `services/clipboard_port.dart` 直接依赖，改由 Provider 注入 application `ClipboardPort`；主题 JSON 导出、从剪贴板粘贴、导入应用和提示语义保持不变，测试宿主显式提供 fake/平台 adapter。
- 这两个调用者未修改正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则或 `legado-main/`。

验证结果：

- RSS Tab 和主题配置定向 `8/8`；`dart format --output=none --set-exit-if-changed`：通过；涉及文件 analyze：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`699` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过。
- `flutter analyze --no-pub`：`No issues found`；架构扫描由 `115` 降至 `113` 条 Feature→service backlog；`git diff --check`：通过。

边界结论：本批完成 RSS Tab ReaderFont 和主题设置 Clipboard 的 application port 调用者迁移，剩余 Feature→service backlog 继续按独立用例推进。

## 135. 2026-07-30：R6 源管理与备份路径边界

- `SourcesPage` 移除 `services/reader_font_loader.dart` 直接依赖，改由 Provider 注入既有 `ReaderFontPort`；源列表的字体族、CJK fallback、搜索、排序和交互行为保持不变。
- `BackupConfigPage` 移除 `services/app_paths.dart` 直接依赖，改由 Provider 注入 `AppPathsPort`；端口补充与既有 `AppPaths.backupsDir()` 对应的 `backupsDir()` 能力，保留本地备份列表、导入导出路径、WebDAV 配置和失败提示语义。
- 测试宿主补齐 `ReaderFontPort` 与 `AppPathsPort`，未放宽源管理、MainShell、备份失败策略和恢复安全断言；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- AppPaths、BackupConfig、Sources、MyPage 和 MainShell 定向 `11/11`；`dart format --output=none --set-exit-if-changed`：通过；涉及文件 analyze：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`699` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过。
- `flutter analyze --no-pub`：`No issues found`；架构扫描由 `113` 降至 `111` 条 Feature→service backlog；`git diff --check`：通过。

边界结论：本批完成源管理字体能力与备份路径能力的 application/infrastructure 调用者迁移，剩余 Feature→service backlog 继续按独立用例推进。

## 136. 2026-07-30：R6 阅读记录与 Web API 剪贴板边界

- `ReadRecordPage` 移除 Flutter Clipboard 直接访问，改由 Provider 注入 application `ClipboardPort`；阅读统计导出文本、格式选择、复制提示和 Rust 不可用回退行为保持不变。
- `WebApiSettingsCard` 移除 Flutter Clipboard 直接访问，改由 Provider 注入 application `ClipboardPort`；复制的 `/api/books` URL、Token 提示和 Web API 设置行为保持不变。
- 测试宿主补齐 fake `ClipboardPort`，未放宽已有断言；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 阅读记录和 Web API 设置定向 `2/2`；`dart format --output=none --set-exit-if-changed`：通过；涉及文件 analyze：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`700` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过。
- `flutter analyze --no-pub`：`No issues found`；架构扫描保持 `111` 条 Feature→service backlog（本批消除的是直接 Flutter Clipboard 访问，不计入该 service-import 数字）；`git diff --check`：通过。

边界结论：本批完成两个 UI 剪贴板调用者的 application port 迁移，剩余 Feature→service backlog 继续按独立用例推进。

## 137. 2026-07-30：R6 四个页面剪贴板边界

- `SourceEditorPage` 通过 `ClipboardPort` 处理源 JSON 复制/粘贴；`DictRulePage` 通过端口复制规则摘要；`TxtTocRulePage` 通过端口复制正则；`ContentEditDialog` 通过端口复制清洗后的标题与正文。原有文本、提示、保存和编辑行为保持不变。
- 新增定向测试覆盖源 JSON 双向操作、字典规则复制、TXT 目录规则复制和正文复制；测试 fake 仅替代平台剪贴板，不替换业务断言。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 四页面定向 `5/5`；`dart format --output=none --set-exit-if-changed`：通过；涉及文件 analyze：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：最终 `705` 通过、`3` 项既有条件跳过；中间一次出现 `1` 个未复现的时序失败，随后完整重跑通过，未修改或跳过任何断言。
- `cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 全量通过；`flutter analyze --no-pub`：`No issues found`；架构扫描保持 `111` 条 Feature→service backlog；`git diff --check`：通过。

边界结论：本批完成四个页面的 application ClipboardPort 调用者迁移，剩余 Feature→service backlog 继续按独立用例推进。

## 138. 2026-07-30：R6 规则与阅读偏好端口边界

- `DictRulePage`、`TxtTocRulePage` 移除对规则偏好 service 的直接依赖，改由 application `DictRulePrefsPort`、`TxtTocRulePrefsPort` 读写；SharedPreferences adapter 保留既有 JSON 键名、默认规则、排序、重置和编辑行为。
- `ClickActionPanel` 与 `ReaderPage` 通过 `ClickActionPrefsPort` 读写九宫格、菜单兜底和首次提示标记；`SearchContentPage` 通过 `SearchContentPrefsPort` 读写替换开关、正则开关和搜索范围；Reader、模拟追读对话框及 `ShelfUnread` 通过 `SimulatedReadingPrefsPort` 复用既有 Book 字段优先和旧 SharedPreferences 迁移语义。
- 新增端口、SharedPreferences adapter 和定向测试；测试 fake 只替代持久化/平台边界，不替代规则、搜索、阅读和未读计算断言。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 规则页、点击区域、搜索偏好、模拟阅读和缓存页面定向测试通过；点击区域补齐 ReaderPage 读取/首次提示后定向回归仍通过。
- `dart format --output=none --set-exit-if-changed`：涉及文件通过；`flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`714` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml`：Rust 核心 `184/184`，workspace 通过。
- 架构扫描由 `110` 降至 `104` 条既有 Feature→service backlog；`git diff --check`：通过。剩余 service 依赖未加入白名单，继续按单用例推进。

边界结论：本批完成规则偏好、点击区域、正文搜索和模拟阅读的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，未推进暂停中的真实 Android TTS、Web/WASM/PWA 或其他发布门禁。

## 139. 2026-07-30：R6 阅读样式偏好端口边界

- `ReaderPage` 和 `ReaderSettingsPanel` 移除 `ReadStylePrefs` 直接依赖，改由 application `ReadStylePrefsPort` 和 SharedPreferences adapter 读写共享布局、主题槽、主题覆盖、主题排版和清理操作；保留既有 SharedPreferences 键名、paper 默认主题、非法主题忽略和损坏 JSON 返回空值语义。
- 组合根注册真实 adapter；新增 adapter 定向测试，既有 `ReadStylePrefs` service 测试继续覆盖键值 round-trip 和覆盖清理。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 阅读样式 adapter 与既有 service/阅读配置定向 `6/6`；`dart format --output=none --set-exit-if-changed`：涉及文件通过；涉及文件 `flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`715` 通过、`3` 项既有条件跳过；Rust workspace 复用本阶段已通过的 `cargo test --manifest-path rust/Cargo.toml`，核心 `184/184`。
- 架构扫描保持 `102` 条既有 Feature→service backlog；`git diff --check`：通过。剩余 service 依赖未加入白名单，继续按单用例推进。

边界结论：本批完成阅读样式持久化调用者的 application/infrastructure 迁移，保留旧 service 作为兼容实现入口，不改变阅读内容和布局行为。

## 140. 2026-07-30：R6 阅读图片缓存端口边界

- 新增 application `ReaderImageCachePort` 与懒初始化 infrastructure adapter；`ReaderPage` 不再创建或持有 `ReaderImageCache` service，`ReaderMarkup`、`ReaderSelectableText` 和 `ReaderInlineImage` 统一使用端口类型。缓存目录探测与下载能力仍在首次图片访问时初始化，不阻塞首屏。
- adapter 继续复用既有 Rust 二进制 HTTP、本地文件缓存、请求头参与缓存键、位图/SVG 尺寸解析和失败返回 null 语义；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 图片缓存、ReaderMarkup、真实媒体/正文 pipeline、内联 SVG 和 ReaderSelectableText 定向 `22/22`；`dart format --output=none --set-exit-if-changed`：涉及文件通过；涉及文件 `flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：`715` 通过、`3` 项既有条件跳过；Rust workspace 复用本阶段已通过的 `cargo test --manifest-path rust/Cargo.toml`，核心 `184/184`。
- 架构扫描由 `102` 降至 `100` 条既有 Feature→service backlog；`git diff --check`：通过。剩余 service 依赖未加入白名单，继续按单用例推进。

边界结论：本批完成阅读图片技术能力的 application/infrastructure 调用者迁移，保留旧 service 作为底层实现入口，不改变正文渲染和图片失败占位行为。

## 141. 2026-07-30：R6 Web API 配置偏好端口边界

- `WebApiSettingsCard`、`MyPage` 移除 `WebApiPrefs` 直接依赖，改由 application `WebApiPrefsPort` 和 SharedPreferences adapter 读写 enabled、port、token；`WebApiConfig` 移至 application 并由旧 service 兼容导出，保留既有键名和默认端口。
- `WebApiService` 继续负责 Web API port 的配置、启动、停止、状态和 Token 生成，未改变本地 HTTP 协议、认证或失败策略。测试宿主补齐 Web API fake port；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- Web API 偏好、Web API port、设置卡片和 MyPage 定向 `7/7`；首轮全量发现 3 个 MainShell 测试宿主缺少新 Provider，补齐依赖后复跑通过，未放宽任何断言。
- `dart format --output=none --set-exit-if-changed`：涉及文件通过；涉及文件 `flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1 --reporter compact`：最终 `715` 通过、`3` 项既有条件跳过；Rust workspace 复用本阶段已通过的 `cargo test --manifest-path rust/Cargo.toml`，核心 `184/184`。
- 架构扫描由 `100` 降至 `98` 条既有 Feature→service backlog；`git diff --check`：通过。剩余 service 依赖未加入白名单，继续按单用例推进。

边界结论：本批完成 Web API 配置持久化调用者的 application/infrastructure 迁移，保留旧 service 作为兼容实现入口，不改变 Web API 运行行为。

## 142. 2026-07-30：R6 TocSheet 笔记读取端口边界

- `TocSheet` 移除对 `services/note_service.dart` 的直接依赖，改由可选 application `NotePort` 查询书签；组合根注入 `FrbNotePort`。端口未配置或不可用时返回空列表，保留“书签”笔记前缀筛选和目录首帧行为。
- 目录顺序、缓存端口页面和目录性能定向测试 `8/8`；`dart format --output=none --set-exit-if-changed` 与涉及文件 `flutter analyze --no-pub` 通过。
- Flutter 串行全量 `715` 通过、`3` 项既有条件跳过；`cargo test --manifest-path rust/Cargo.toml` workspace 通过，核心 `184/184`；架构扫描由 `98` 降至 `97` 条既有 Feature→service backlog；`git diff --check` 通过。

边界结论：本批完成 TocSheet 笔记读取的 application/infrastructure 调用者迁移，保留旧 service 作为底层实现入口，不改变目录顺序、分页、章节身份、阅读位置或正文断行行为。

## 143. 2026-07-30：R6 BookInfoPage 书源搜索端口边界

- `BookInfoPage` 移除对 `services/book_source_service.dart` 的直接依赖，封面补全改由已有 `BookSourceSearchPort` 查询；组合根向页面 Provider 暴露与 `BookSourceService` 共用的 `FrbBookSourceSearchPort` 实例。
- 保留精确书名优先、包含书名回退、书架封面回写和搜索异常静默降级语义；未修改正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- 书源搜索、BookProvider 自动选源和目录顺序定向 `8/8`；涉及文件格式与 `flutter analyze --no-pub` 通过；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过；架构扫描由 `97` 降至 `96` 条 Feature→service backlog；`git diff --check` 通过。

边界结论：本批完成 BookInfoPage 书源搜索的 application/infrastructure 调用者迁移，保留 `BookSourceService` 供其他尚未迁移调用者使用，不改变封面补全行为。

## 144. 2026-07-30：R6 BookInfoPage 漫画类型语义边界

- 新增纯 domain `BookSourceTypeSemantics` 扩展，集中保留原 `MangaPrefs.isImageSourceType` 对 `2`、`image`、`漫画`、`图片` 的兼容判定；`BookInfoPage` 移除对 `services/manga_prefs.dart` 的直接依赖。
- 书源模型、书源搜索、BookProvider 自动选源和目录顺序定向 `12/12`；涉及文件格式与 `flutter analyze --no-pub` 通过；Flutter 串行全量 `715` 通过、`3` 项既有条件跳过；架构扫描由 `96` 降至 `95` 条 Feature→service backlog；`git diff --check` 通过。

边界结论：本批只迁移纯书源类型判断，不迁移漫画阅读偏好存储；漫画阅读器其余偏好仍由 `MangaPrefs` 负责，产品行为和偏好键名不变。

## 145. 2026-07-30：R6 四 agent Feature 端口并行收口

- `ExploreListPage` 移除 `BookSourceService` 直接依赖，使用 `BookSourceExplorePort` 和 application `mapBookSourceResults`；`SourceMarketPage` 移除 service 和 data 层直接读取，使用 `SourceMarketPort`、内置资源 infrastructure adapter 与 `SourceMarketMapper`。
- `ReadRecordPage` 改用可选 `ReadingRecordPort`，保留统计字段、导出格式和引擎不可用回退；`BgTextConfigPanel` 改用 `ReadStyleZipPort`，由 adapter 复用既有 ZIP 服务；`ReaderSettings` 的系统字体预览改用已有 `ReaderFontPort`，自定义字体扫描/解析仍保留 `ReaderFontLoader`。
- 主 agent 负责组合根注入和集成，四个子 agent 使用不重叠写入范围并行完成；未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 子线定向测试分别通过：SourceMarket `9/9`、ReadRecord `8/8`、ReadStyleZip `12/12` 加 Reader 回归 `19/19`、ReaderFont `8/8`；主线合并定向 `28/28`，SourceMarket Provider 集成 `3/3`。
- `dart format`、涉及文件 `flutter analyze`、`git diff --check` 通过；Flutter 串行全量 `721` 通过、`3` 项既有条件跳过；Rust 未改动，沿用核心 `184/184` 结果。
- 架构扫描由 `95` 降至 `91` 条既有 Feature→service backlog；ReaderSettings 的自定义字体能力尚未完全端口化，未伪装为零依赖。

边界结论：本批完成五个独立 Feature 调用者的第一层 application/infrastructure 收口，保留旧 service 作为兼容实现入口，后续继续按单边界推进剩余 `91` 条 backlog。

## 146. 2026-07-30：R6 四 agent 偏好与缓存端口并行收口

- `ReaderSettings` 完成 `ReaderFontPort` 扩展，覆盖自定义字体扫描、路径判断、显示名、serif/mono 解析、加载和目录访问；`ReaderFontPortAdapter` 继续复用 `ReaderFontLoader` 原有行为。
- `ReplacePage` 改用 `ReplacePresetPort` 和应用层预置模型；`ConfigPage` 改用 `BookshelfConfigPrefsPort`，保留 `bookGroupStyle` 键名、默认值、迁移和用户确认后保存；`CacheBookPage` 改用 `BookCacheExportPort`，adapter 复用既有缓存导出服务。
- 组合根注册四类端口；6 个使用 ReaderFontPort 的既有测试 fake 改为共享测试基类，以适配新增接口成员，未改变业务断言。

验证结果：

- ReaderFont adapter `5/5`、原有字体回归 `9/9`；Replace adapter `2/2`、替换服务/预览 `8/8`；Config adapter `4/4`；Cache adapter `2/2`、缓存回归 `5/5`；接口 fake 修复后受影响 widget 定向 `11/11`。
- 首轮 Flutter 全量仅因测试 fake 缺少新增接口成员编译失败；补齐后 `flutter test --no-pub --concurrency=1 --reporter compact`：`732` 通过、`3` 项既有条件跳过。`dart format`、涉及文件 `flutter analyze`、`git diff --check` 通过；Rust 未改动，沿用核心 `184/184` 结果。
- 架构扫描由 `91` 降至 `87` 条既有 Feature→service backlog；未修改 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

边界结论：本批完成四个独立 Feature 调用者的第一层 application/infrastructure 收口；ReaderFont 的自定义字体能力已进入端口，剩余 Feature backlog 继续按单边界推进。

## 147. 2026-07-31：R6 RSS、主题与二维码端口边界

- `RssReadPage` 改用 `RssPort`，`RssFavoritesPage` 改用 `RssStarPrefsPort`；`ThemeConfigPage` 改用 `ThemeImportPort`；`QrCodeCapturePage` 改用 `QrCodePort`。组合根注册共享端口，adapter 继续复用既有 RSS、主题导入和二维码服务，保留正文回退、收藏顺序、主题 JSON/URL 校验、图库解码失败和桌面无相机回退行为。
- 为端口扩展补齐 RSS 收藏图片测试宿主的依赖注入，并为 Android SVG 图片像素集成测试增加 `ReaderImageCachePort` 薄适配器；所有既有断言保持不变。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- RSS、主题和二维码受影响定向测试最终 `19/19`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact` 为 `739` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `87` 降至 `83` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。

边界结论：本批完成 RSS 阅读/收藏、主题导入和二维码图片解码的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `83` 条 Feature 依赖继续按单边界推进。

## 148. 2026-07-31：R6 RSS 文章列表收藏写入端口

- `RssArticlesPage` 移除对 `services/rss_star_prefs.dart` 的直接依赖，改由 `RssStarPrefsPort` 读取当前源收藏状态并执行 toggle；端口 adapter 继续复用既有 `RssStarPrefs`，保留 SharedPreferences 键名、文章字段、收藏顺序、返回状态和提示文案。
- 测试宿主显式注入收藏端口，新增 toggle 的收藏/取消收藏和字段保留回归；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- RSS 收藏 adapter、RSS 服务和 RSS 页面/图片定向 `10/10`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`740` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `83` 降至 `82` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。

边界结论：本批完成 RSS 文章列表收藏写入的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `82` 条 Feature 依赖继续按单边界推进。

## 149. 2026-07-31：R6 SourceEditor 二维码能力端口

- `QrCodePort` 扩展为完整二维码能力端口，包含 PNG 编码和图片解码；`SourceEditorPage` 移除对 `services/qr_code_service.dart` 的直接依赖，二维码分享通过 application port 获取 PNG，adapter 继续复用既有服务。
- 保留二维码导入、分享图片/字符串、内容过长回退和错误提示行为；SourceEditor 测试宿主显式注入端口并新增编码后解码回归。未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 二维码 adapter、二维码服务、扫码页和 SourceEditor 定向 `8/8`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`741` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `82` 降至 `81` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。

边界结论：本批完成 SourceEditor 二维码能力的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `81` 条 Feature 依赖继续按单边界推进。

## 150. 2026-07-31：R6 SourceEditor 代码编辑偏好端口

- `SourceEditorPage` 移除对 `services/code_edit_prefs.dart` 的直接依赖，改用已有 `CodeEditPrefsPort` 读取自动补全、保存自动补全开关和管理会话日志；组合根既有 SharedPreferences adapter 不变，登录 Cookie 等其他 service 依赖保持原边界。
- 保留代码编辑偏好键名、默认值、日志上限、清理行为和提示文案；测试宿主通过 fake store 组装 application adapter，未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- SourceEditor、CodeEdit 偏好 service/application adapter、CodeEdit 页面和 SharedPreferences 运行时定向 `15/15`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`741` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `81` 降至 `80` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。

边界结论：本批完成 SourceEditor 代码编辑偏好与会话日志的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `80` 条 Feature 依赖继续按单边界推进。

## 151. 2026-07-31：R6 SourceEditor 登录 Cookie 清理端口

- 新增 application `SourceLoginCookieClearPort` 与 infrastructure adapter；`SourceEditorPage` 移除对 `services/source_login_cookie_service.dart` 的直接依赖，清理动作继续由既有 service 协调 SharedPreferences Cookie 桶、Rust CookieJar 和 WebView Cookie。
- 保留清理顺序、Cookie 域名处理、失败提示和清理后会话日志行为；领域 `SourceLoginCookiePort` 仍只负责 Rust CookieJar，不混入持久化/WebView 语义。新增 adapter 回归验证 Cookie 桶清理，未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- Cookie 清理 adapter、既有 SourceLoginCookieService 和 SourceEditor 定向 `6/6`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`742` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `80` 降至 `79` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。

边界结论：本批完成 SourceEditor 登录 Cookie 清理的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `79` 条 Feature 依赖继续按单边界推进。

## 152. 2026-07-31：R6 四 agent AI、书签、书架与漫画偏好并行收口

- 四条不重叠子线完成：`AiConfigDialog` 改用 AI 配置偏好/HTTP port；`BookmarkPage` 改用书签页面 port，集中处理书签迁移、笔记读取、JSON 导入导出和同步；`BookshelfArrangePage` 改用排列偏好与分组目录 port；`MangaReaderPage` 改用 `MangaPrefsPort` 读取和保存漫画偏好。组合根注册共享 adapter，书架页面去除默认 infrastructure adapter，改从 Provider 获取 application port。
- 保留 AI 配置/记忆、书签迁移/同步/导入导出、书架分组与排序、漫画偏好键名/默认值/互斥和阅读行为；未修改 `legado-main/`、Rust、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：

- 子线定向证据：AI `9/9`、书签 `25`、书架端口/服务 `8/8`、漫画 `11`；owner 合并定向 `16/16`。
- Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`755` 通过、`3` 项既有条件跳过；`dart format`、`flutter analyze --no-pub`（`No issues found`）和 `git diff --check` 通过。
- 架构扫描由 `79` 降至 `69` 条既有 Feature→service backlog；剩余依赖未加入白名单，继续按单边界推进。

边界结论：本批完成四个独立 Feature 的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `69` 条 Feature 依赖继续按单边界推进。

## 153. 2026-07-31：R6 书架展示、MainShell 与 MyPage 端口边界

- `BookshelfPage`、`BookshelfStyle1Page`、`BookshelfStyle2Page` 和书架展示组件改用 `BookshelfDisplayPort`；`BookshelfConfigDialog` 改用 `BookshelfConfigDialogPort`。SharedPreferences adapter 继续复用既有书架配置、手动顺序和排序行为。
- `MainShell` 改用 `MainShellStartupPort`，由组合根在 `SourceProvider`、`ReplaceProvider`、`RssProvider` 之后注入，保持启动任务隔离、规则订阅导入、书架更新角标和默认首页语义。`MyPage` 改用 `MyPagePort`，封装 Web API 状态/启停、本地备份和引擎/数据库就绪状态；测试宿主显式补齐端口 fake。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；剩余 Feature→service 依赖未加入白名单。

验证结果：

- 受影响定向 `20/20`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`769` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `69` 降至 `57` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。
- 首轮全量曾因 L4 已落地而 MainShell 测试宿主尚未注册 `MyPagePort` 出现 ProviderNotFound；补齐 fake 后定向和最终全量通过，未放宽断言。Rust 未改动，本批不重复运行 Rust 测试。

边界结论：本批完成书架展示/配置、MainShell 启动和 MyPage 的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `57` 条 Feature 依赖继续按单边界推进。

## 154. 2026-07-31：R6 书架书单与 RemoteBook 端口边界

- 书架菜单与导入对话框改用 `BookshelfListPort`，由 adapter 继续复用既有书单 JSON/URL/文件解析、导出和剪贴板相关实现。
- `RemoteBookPage` 改用 `RemoteArchiveImportPort`、`RemoteBookSortPort` 和 `WebDavPrefsPort`；组合根注册四类 adapter，远程 ZIP 导入 adapter 复用已有 `RemoteArchiveImportService`。保留远程 ZIP/TXT/EPUB 导入、目录优先排序、WebDAV 配置和错误提示行为。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；剩余 Feature→service 依赖未加入白名单。

验证结果：

- 受影响定向 `25/25`，其中 RemoteArchive/Sort 既有回归 `5/5`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`779` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `57` 降至 `52` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。
- Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。

边界结论：本批完成书架书单和 RemoteBook 的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `52` 条 Feature 依赖继续按单边界推进。

## 155. 2026-07-31：R6 书架样式与 WebDAV 配置端口边界

- 两种书架样式移除 `BookGroupStore`、`LocalBookService` 直接依赖，改用 `BookGroupStorePort` 和 `BookshelfLocalBookPort`；本地导入 adapter 包装 `BookProvider` 的既有导入回调，并保留原异常提示映射。
- `WebDavConfigDialog` 移除 `WebDavPrefs`、`WebDavSetupService`、`WebDavRepository` 直接依赖，改用 `WebDavConfigDialogPort`；读取契约复用 `WebDavPrefsPort`，保存和连接初始化由 infrastructure adapter 负责。
- 组合根完成两个新增能力的 Provider 注册；测试宿主补齐端口 fake。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；剩余 Feature→service 依赖未加入白名单。

验证结果：

- 定向组合回归 `34/34`，`test/widget_test.dart` `1/1`，MainShell/书架展示宿主回归 `4/4`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`788` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub`：`No issues found`；架构扫描保持 `46` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。
- 首轮全量因 4 个测试宿主缺少 `BookGroupStorePort` 而失败，补齐 fake 后最终全量通过，未放宽断言。Rust 未改动，本批不重复运行 Rust 测试。

边界结论：本批完成书架样式分组/本地导入和 WebDAV 配置的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `46` 条 Feature 依赖继续按单边界推进。

## 156. 2026-07-31：R6 Obsidian 与 Reader AI Chat 端口边界

- `ObsidianExportDialog` 移除四个 Obsidian/笔记 service 直接依赖，改用 `ObsidianExportPort`；adapter 组合既有 `NotePort` 和 `ApplicationHttpRequestPort`，保留配置、Markdown、本地文件、REST API、连接测试和错误行为。
- `AiChatPage` 移除 `AiConfigPrefs` 直接依赖，复用已有 `AiConfigPrefsPort`，与 AI 配置/记忆弹窗共享偏好端口；保留默认值、请求前置校验、消息状态和提示语义。
- 组合根注册 `ObsidianExportPort`；未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；剩余 Feature→service 依赖未加入白名单。

验证结果：

- D1/D2 定向 `8/8`；Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`796` 通过、`3` 项既有条件跳过。
- `dart format` 通过；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `46` 降至 `41` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。
- Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。

边界结论：本批完成 Obsidian 导出和 Reader AI Chat 的 application/infrastructure 调用者迁移，保留旧 service 作为兼容实现入口，剩余 `41` 条 Feature 依赖继续按单边界推进。

## 157. 2026-07-31：R6 Web API、TTS、其它设置与备份配置端口边界

- `WebApiSettingsCard` 改用 `WebApiSettingsPort`，由 adapter 保留既有 Web API 启停、状态和 API URL 语义；`AudioPlayPage` 与 `TtsPanel` 共用 `TtsPort`，adapter 映射既有系统/HTTP TTS、stub、句子控制、播放模式、定时和 HTTP TTS 配置行为。
- `OtherSettingsCard` 改用 `OtherSettingsPort`，统一封装网络代理/DNS、数据目录、引擎就绪状态和 HTTP TTS 缓存清理；`BackupConfigPage` 改用 WebDAV 偏好端口和备份状态端口，保留 BackupService、文件端口、Room 导入和 WebDAV 业务流程。
- 组合根注册新增 adapter；受影响测试宿主显式注入 fake，未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；剩余 Feature→service 依赖未加入白名单。

验证结果：

- 端口/页面组合定向 `24/24`，新增 TTS adapter 契约测试覆盖状态、播放模式、句子绑定和定位。
- Flutter 串行全量 `flutter test --no-pub --concurrency=1 --reporter compact`：`798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `41` 降至 `30` 条既有 Feature→service backlog；`git diff --check` 在文档更新后复核。
- 全仓 analyze 首次因命令时限退出 `124`，在延长时限后通过；期间发现并修复 Web API 异步 `BuildContext` 诊断，未放宽断言。Rust 未改动，本批不重复运行 Rust 测试。

边界结论：本批完成 Web API 设置、AudioPlay/TTS、其它设置和备份配置的 application/infrastructure 调用者迁移，旧 service 继续作为兼容实现入口，剩余 `30` 条 Feature 依赖继续按单边界推进。Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 仍按暂停门禁执行。

## 158. 2026-07-31：R6 OtherSettings 缓存管理端口边界

- `OtherSettingsCard` 移除 `CacheService` 直接依赖，改用 `CacheManagementPort` 读取缓存统计并执行书籍缓存、引擎缓存、备份和全量清理；adapter 复用既有 `CacheService`，保持统计格式、清理范围和错误降级语义。
- 组合根注册缓存管理 adapter，测试宿主改为注入端口；未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则，剩余 Feature→service 依赖未加入白名单。

验证结果：受影响定向 `2/2`；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `30` 降至 `29` 条既有 Feature→service backlog。上一批 Flutter 串行全量 `798` 通过、`3` 项既有条件跳过，本小批不重复运行全量；Rust 未改动。

边界结论：本小批完成 OtherSettings 缓存管理的 application/infrastructure 调用者迁移，剩余 `29` 条 Feature 依赖继续按单边界推进。

## 159. 2026-07-31：R6 BackupConfig 操作端口边界

- `BackupConfigPage` 移除 `BackupService` 直接依赖，改用 `BackupConfigOperationsPort` 执行本地备份、WebDAV 上传/恢复/删除/重命名和本地恢复；adapter 复用既有 `BackupService`，Room 导入仍通过独立用例端口。
- R5 Android smoke 测试宿主补齐操作端口、WebDAV 偏好端口和备份状态端口；未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则，剩余 Feature→service 依赖未加入白名单。

验证结果：备份页定向 `4/4`；目标文件 analyze、全仓 `flutter analyze --no-pub` 和格式检查通过；架构扫描由 `29` 降至 `28` 条既有 Feature→service backlog。本批未执行 Android 真机 smoke，Rust 未改动。

边界结论：本小批完成 BackupConfig 的 application/infrastructure 操作调用者迁移，剩余 `28` 条 Feature 依赖继续按单边界推进。

## 160. 2026-07-31：R6 RSS 文章与 Reader 阅读记录端口边界

- `RssArticlesPage` 移除 `RssService` 直接依赖，改用已由组合根注册的 `RssPort`，保留文章分页、刷新、错误回退和文章字段行为。
- `ReaderPage` 移除 `ReadingRecordService` 静态写入依赖，改用 `ReadingRecordPort`；`ReadingSessionTracker`、`DetailedReadingSessionTracker` 和相关纯模型迁移到 application 文件，旧 service 通过 export 保留测试和历史调用兼容。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；剩余 Feature→service 依赖未加入白名单。

验证结果：RSS/Reader 定向组合 `17/17`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `28` 降至 `26` 条既有 Feature→service backlog；格式门禁通过，Rust 未改动。

边界结论：本批完成 RSS 文章获取和 Reader 阅读记录的 application/infrastructure 调用者迁移，剩余 `26` 条 Feature 依赖继续按单边界推进。

## 161. 2026-07-31：R6 ReaderPage TTS 端口边界

- 扩展 `TtsPort` 覆盖选区朗读、连续朗读回调、句子位置、选区模式和播放模式能力；`ReaderPage` 移除 `TtsService` 直接依赖，使用组合根注册的 TTS adapter。
- 保留系统/HTTP TTS、stub、选区朗读、连续朗读、章节切换、句子定位和正文位置语义；未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：TTS/Reader 定向 `29/29`；Flutter 串行全量 `798` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `26` 降至 `25` 条既有 Feature→service backlog；格式门禁通过，Rust 未改动。

边界结论：本批完成 ReaderPage TTS 的 application/infrastructure 调用者迁移，真实 Android TTS 仍按暂停门禁，剩余 `25` 条 Feature 依赖继续按单边界推进。

## 162. 2026-07-31：R6 RSS 分类、源管理与 Reader 书籍偏好端口边界

- `RssArticlesPage` 的分类 URL 解析/缓存清理改用 `RssSortUrlsPort`；`RssSourceManagePage` 的文件/剪贴板传输改用 `RssSourceTransferPort`；`ReaderPage` 的 `BookReaderPrefs` 改用 `BookReaderPrefsPort`。
- 组合根统一注册三个 infrastructure adapter；owner 验收移除 agent fallback 的 Feature→infrastructure 直接构造，保留 RSS 分类刷新、源导入导出、阅读动画/重新分段和原有兼容 export 语义。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则；剩余 Feature→service 依赖未加入白名单。

验证结果：三条线定向 `8/8`；Flutter 串行全量 `802` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`：`No issues found`；架构扫描由 `25` 降至 `22` 条既有 Feature→service backlog；格式和 `git diff --check` 通过，Rust 未改动。

边界结论：本批完成 RSS 分类、RSS 源管理传输和 Reader 书籍阅读偏好的 application/infrastructure 调用者迁移，剩余 `22` 条 Feature 依赖继续按单边界推进。

## 163. 2026-07-31：R6 Widget 边界并行收口

- W1 将书架分组编辑、管理和选择对话框迁移到 `BookGroupManagementPort`；W2 将书签编辑、书票和笔记编辑迁移到 annotation application ports；W3 将源校验偏好、字典查询和替换预览 helper 迁移到 source-rule application ports；所有 adapter 复用既有 service/FRB 语义，组合根已完成 Provider 接入。
- W4 只读审查确认 Widget/Feature 侧无直接 service import；剩余直接依赖集中在 `BookProvider`、`ReplaceProvider`、`RssProvider` 和 `SourceProvider`，未在本批扩大 Provider 写集。
- W4-W0 将 `legado_bottom_nav.dart` 的字体与 CJK fallback 读取迁移到既有 `ReaderFontPort`，不新增端口、不修改组合根。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：W1 `11/11`、W2 `10/10`、W3 `14/14`、W4-W0 `4/4`，owner 组合回归 `33/33`；Flutter 串行全量 `829` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构脚本和 `git diff --check` 通过。`read_book_async_test.dart` teardown 增加预加载完成等待，修复 Windows 临时目录文件锁竞态，不改变断言或阅读行为。

边界结论：本批完成 Widget/Feature 到 application/infrastructure 的直接依赖收口；Provider 依赖继续作为下一批单边界 backlog，真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续按暂停门禁执行。

## 164. 2026-07-31：R6 Provider 边界并行收口

- P0 将 `ReplaceProvider` 的内置规则初始化/重置改为 `ReplacePresetPort.builtInRules()`；端口 adapter 仍委托原 `ReplaceService`，只返回四条启动规则，完整预置库导入语义不变。
- P1 将纯 `ChapterProgressMigrator` 策略移到 `lib/application/book/`，旧 service 保留兼容导出；章节 URL/标题匹配、阅读位置裁剪和迁移边界不变。
- P2 将 `SourceProvider` 的登录头读取/解析和源校验偏好改为既有 `SourceLoginPagePort`、`CheckSourcePrefsPort`；组合根提供真实 adapter，Provider 只保留 application fallback。
- P3 新增 `RssSourceStorePort` 和 SharedPreferences adapter，`RssProvider` 不再直接依赖 SharedPreferences；保留 `legado_rss_sources` 键、源 URL 去重、排序和空数据行为。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。扩展静态扫描不再发现 Feature/Widget/Provider 对 infrastructure、SharedPreferences 或 Dio 的直接引用；Provider 的剩余 service 依赖仍按下一批风险拆分，不加入白名单。

验证结果：P0 `4/4`、P1 `8/8`、P2 `24/24`、P3 `10/10`，owner 组合 `42/42`；Flutter 串行全量 `838` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构脚本和 `git diff --check` 通过。真实 Android TTS、Web/WASM/PWA 和正式/主流 WebDAV 继续按暂停门禁执行。

边界结论：本批完成 Replace/Book/Source/RSS Provider 的四个低风险应用边界，Provider 剩余 BookSource 聚合、SourceGroup/Validation、批量同步等高风险 service 依赖继续保持未迁移状态。

## 165. 2026-07-31：R6 SourceProvider 源分组边界与 Provider 高风险契约审查

- `SourceProvider` 的分组目录加载/合并/增删改和标签拆分、去重、追加、移除、重命名改用 application `SourceGroupCatalogPort`；infrastructure adapter 继续委托既有 `SourceGroupCatalog` 与 `SourceGroupTags`，保持 SharedPreferences 键、排序和中英文逗号语义。
- 组合根注册并注入真实 adapter；Provider 默认 fallback 只包含 application 内存标签规则，不直接引用 infrastructure。
- 三条只读审查确认：validation store 保持 `source_validation_v1` 与损坏数据空映射；BookSource/LocalBook 聚合不能绕过目录/正文与 TXT/EPUB fallback；批量进度同步必须在 apply 成功后才推进 sync time。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：owner 定向 `13/13`；Flutter 串行全量 `842` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构脚本通过；扩展扫描剩余五处明确 Provider→service 依赖；`git diff --check` 通过，仅有既有 LF/CRLF 提示。

边界结论：源分组边界已集成到 owner checkout；validation store、BookSource/LocalBook 聚合和批量进度同步仍按审查结果进入后续独立批次，审查结果本身不构成运行时迁移完成声明。

## 166. 2026-08-01：R6 Provider 四项高风险边界收口

- `SourceProvider` 接入 `SourceValidationStorePort` 与 `SourceManagementBookSourcePort`；校验缓存仍保持 `source_validation_v1`、URL 键和损坏数据空映射，书源导入/搜索/结果映射仍由现有 `BookSourceService` 执行。
- `BookProvider` 的批量 WebDAV 进度改用 `BatchBookProgressSyncPort`，本地文件/路径导入改用 `LocalBookImportPort`；组合根 adapter 保留 `lastModified`、remote-ahead、apply 成功后更新时间戳、50MB、编码、TXT/EPUB fallback 和 Repository 写入语义。
- 书架本地导入 adapter 同时接受 application 与 legacy 导入异常，避免迁移期间旧测试宿主或兼容 callback 改变用户可见错误消息。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。扩展 Provider 扫描由五处降至一处，剩余为 `BookProvider -> BookSourceService` 的高风险聚合边界。

验证结果：四条 owner 定向分别 `20/20`、`20/20`、`26/26`、`32/32`；Flutter 串行全量 `864` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构脚本通过；`git diff --check` 通过，仅有既有 LF/CRLF 提示。

边界结论：Batch 6 四项 Provider application/infrastructure 边界已集成并通过全量门禁；下一批只处理 BookProvider 的 BookSource 聚合拆分，不扩大到正文算法、Reader 内容或 Rust 数据库迁移。

## 167. 2026-08-01：R6 BookProvider 书源聚合边界收口

- 新增 `BookProviderSourcePort` 与 `BookProviderSourcePortAdapter`，覆盖 BookProvider 实际使用的详情、搜索、结果映射、目录、普通正文和分页正文能力；adapter 仅委托现有 `BookSourceService`，不重写源站忙碌重试、TOC URL 补全、映射、分页回退或正文失败语义。
- `BookProvider`、`AppBootstrap` 和组合根改用 application port；`ReadBook` 继续接收同时满足 `ReaderContentSourcePort` 与 `PaginatedReaderContentSourcePort` 的门面。`Provider<BookSourceService>`、SourceProvider、规则订阅、主壳启动和内容重取链路保持原 concrete service 注入。
- 未修改 `legado-main/`、Rust、正文算法、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：facade focused `2/2`；owner BookProvider/ReadBook/BookSourceService 定向 `41/41`；Flutter 串行全量 `866` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构脚本通过；Provider service 扩展扫描为零；`git diff --check` 通过，仅有既有 LF/CRLF 提示。

边界结论：R6 Provider 直接 service backlog 已清零。本批只完成调用边界，不宣称 Web/WASM/PWA、真实 Android TTS、正式/主流 WebDAV 或 Rust 数据库迁移门禁完成。

## 168. 2026-08-01：R6 MainShell 隐私协议持久化边界

- 新增 `PrivacyConsentPort` 与 `SharedPreferencesPrivacyConsentPortAdapter`；adapter 复用 `SharedPreferencesRuntime`，保持 `legado_privacy_accepted`、缺失/初始化失败返回未同意、保存失败安全降级，并允许 runtime 后续重试。
- `MainShell` 移除 `SharedPreferencesRuntime` 直接依赖，隐私读取仍在初始化后的 post-frame prompt 中执行；不改变不可点击遮罩、拒绝退出、同意关闭、mounted 检查或崩溃恢复提示顺序。
- 组合根注册独立 privacy port；三个 MainShell 测试宿主补充 fake，未并入 `MainShellStartupPort`，未修改 `WelcomePage`、Reader 内容或 Rust。

验证结果：privacy/runtime/MainShell/Welcome 定向 `14/14`；Flutter 串行全量 `869` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构脚本通过；Feature/Widget/Provider 扩展扫描清零；`git diff --check` 通过，仅有既有 LF/CRLF 提示。

边界结论：MainShell 隐私持久化已完成 application/infrastructure 隔离；本批不宣称 Web/WASM/PWA、真实 Android TTS、正式/主流 WebDAV 或 Rust 数据库迁移完成。

## 169. 2026-08-01：R6 Batch 9 `<js>` 兼容证据审查

- 四条只读审查线复核 Rust JS 执行器、原版 Kotlin 宿主变量与规则 schema、Flutter/FRB 桥接以及测试脚本。现有离线 Rust JS `18/18`、Flutter JS `4/4` 通过；7565 在线探测返回 HTTP 400，按既有测试契约作为可选路径跳过，不能作为在线链路验收证据。
- 测试脚本修复为从 PATH 查找 Cargo/Flutter，Rust 固定 `--locked --offline`，Flutter 固定 `--no-pub`，工具缺失直接失败；`docs/JS_COMPAT.md` 的 Rust 统计更新为 `18` 项，并明确离线门禁与在线探测边界。
- 原版对照发现 `@js:`/`@JS:` 路由应大小写不敏感，形成最小可复现缺口；普通 JS 宿主变量、完整 `java.*` API、真实 Dart→FRB→Rust 链路、对象返回值转换和完整书源 schema 仍需调用上下文或更大范围设计，暂不以默认占位值关闭。
- 当前最小实现线仅修改 Rust `BookSource` 的 JS 判定及回归测试；不得修改 `legado-main/`、正文/目录/分页/章节身份/UTF-16 阅读位置或 Web/WASM/PWA/真实 Android TTS 暂停范围。

验证记录：`cargo fmt -p legado_engine`、BookSource 定向 `8/8`、`cargo test -p legado_engine` `186/186`、`powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_js_compat.ps1`（Rust `18/18`、Flutter `4/4`）、Flutter 全量 `869` 通过且 `3` 项既有条件跳过、`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 均通过。7565 在线探测 HTTP 400 按既有可选契约跳过；Rust 既有 FRB/dead_code 警告保留，未因本批扩大范围。

## 170. 2026-08-01：R6 Batch 10 Flutter JS 入口契约收口

- `SourceLoginService.extractScript`、`isJsUrl` 对 `@js:` 采用 ASCII 大小写不敏感判定，并统一识别 `<js>`/`<Js>`；登录表单脚本提取和 URL 分类不改变已有返回值或端口调用语义。
- `JsCompatAnalyzer` 对 `@js:` 统计、规则字段归类和 `<js>` 标签计数复用大小写不敏感正则；内置 7565/7497 统计保持原断言，新增混合大小写 fixture。
- 未修改 `legado-main/`、Rust 引擎、正文/目录/分页/章节身份/UTF-16 阅读位置，也未将完整宿主 API、执行超时/取消、真实 Dart→FRB→Rust 链路、在线书源或对象返回值语义宣称为已完成。

验证记录：Batch 10 owner 定向 `11/11`；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式检查和 `git diff --check` 通过。JS 兼容脚本上一轮已验证 Rust `18/18`、Flutter `4/4`，在线 7565 HTTP 400 按既有可选契约跳过。

## 171. 2026-08-01：R6 Batch 11/12 登录头与 HTTP trace 收尾

- `LegadoEngineBridge` 的搜索、发现、详情、目录、正文和 `validateSource` 均把登录头同步移入 `finally`，并在同步后 drain 对应 HTTP trace；失败路径也能处理 Rust 已写入的 dirty 登录头，原始业务异常不被收尾操作替换。
- `validateSource` 新增 `validateSource` trace 收尾；未扩大到 `debugSearch`、`debugToc`、`httpFetch`，这三个入口由后续独立批次处理，避免把统一调试链路和主请求链路混写。
- 未处理登录头队列先 drain 后持久化的失败重试/ack、空登录头删除、Rust `loginCheckJs` 错误响应重试和校验偏好实际短路；这些均已登记为后续兼容性风险。

验证记录：引擎/source debug owner 定向 `2` 个可运行测试通过、`2` 个在线 smoke 按既有开关跳过；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。未修改 `legado-main/`、正文/目录/分页/章节身份/UTF-16 阅读位置。

## 172. 2026-08-01：R6 Batch 13 调试与裸 HTTP bridge 收尾

- `debugSearch`、`debugToc` 增加 `finally` 收尾，顺序为同步登录头后 drain trace；`httpFetch` 无论 source 是否存在都 drain trace，传入 source 时执行防御性登录头同步。
- 保持调试/HTTP 参数、返回值、错误传播和既有 Rust API 不变；未处理登录头持久化 ack/重试、空值删除、真实异常 fixture 和 Rust `loginCheckJs` 错误响应语义。

验证记录：owner 定向 `4/4`，含引擎、source debug 和本地 HTTP port；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。未修改 `legado-main/`、Rust、正文/目录/分页/章节身份/UTF-16 阅读位置。

## 173. 2026-08-03：R6 Provider 书源三页面迁移

- `SourceEditorPage`、`SourceDebugPage` 和 `RuleSubPage` 通过局部 Riverpod `ProviderScope` 复用既有共享控制器；页面状态读取与写入收敛到 `SourceNotifier`、`RssNotifier` 和 `ReplaceNotifier`，未创建第二份业务状态。
- 保存书源、执行一键校验、导入规则订阅三类动作分别通过对应 Notifier/Controller 完成；保留书源编辑六个 Tab、调试搜索/目录/URL 测试参数和日志、规则订阅 JSON/自动更新/编辑删除重排及原版可观察行为。
- 新增三页面回归测试，未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：三页面定向 `19/19`；Flutter 串行全量 `1071` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；`scripts/check_architecture_boundaries.ps1` 通过；`git diff --check` 通过，仅有既有 Windows LF/CRLF 提示。

边界结论：本批完成书源编辑、调试和规则订阅页面的 Riverpod 调用边界；其他 Provider 消费者继续按后续批次收敛，不宣称 R1-12、Web/WASM/PWA 或真实 Android TTS 门禁变化。

## 174. 2026-08-03：R6 Provider RSS、搜索探索与书籍换源页面迁移

- `RssTabPage`、`RssFavoritesPage`、`SearchPage`、`ExploreTabPage`、`ExploreListPage`、`BookInfoPage` 和 `ChangeSourcePage` 通过局部 Riverpod `ProviderScope` 复用既有共享 `RssSourceController` 或 `SourceController`；`BookProvider` 仍只负责书籍、章节、阅读和缓存职责。
- RSS 源筛选/收藏、书源搜索/探索、详情源显示和换源搜索改用对应 Notifier/Controller 状态，保留原版 JSON、搜索范围、分组、收藏、换源和 UI 行为；未注入旧版 `RssProvider` 的图片测试宿主使用空 application controller fallback，不改变生产组合根。
- 新增并保留页面回归测试，未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：受影响定向 `11/11`；Flutter 串行全量 `1078` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；`scripts/check_architecture_boundaries.ps1` 通过；`git diff --check` 通过，仅有既有 Windows LF/CRLF 提示。

边界结论：本批完成 RSS、搜索/探索和书籍详情/换源页面的 Provider 消费边界；BookProvider 生产状态迁移及其他服务消费者继续按后续批次收敛，不宣称 R1-12、Web/WASM/PWA 或真实 Android TTS 门禁变化。

## 175. 2026-08-03：R6 Provider 书签、RSS 源编辑与书架 URL 导入迁移

- `BookmarkPage`、`RssSourceEditPage` 和 `AddBookUrlDialog` 通过局部 Riverpod `ProviderScope` 复用既有 `SourceController` 或 `RssSourceController`；书源查找、RSS 源保存和 URL 导入前选择使用对应 Notifier/Controller，不创建第二份业务状态。
- `BookProvider` 继续负责书签关联的书籍/阅读边界及 URL 导入、入库职责；保留书签、RSS 源 JSON/登录/启用/排序、URL 导入和原版 UI 行为。
- 新增页面回归测试，未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：受影响定向 `8/8`；Flutter 串行全量 `1080` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；`scripts/check_architecture_boundaries.ps1` 通过；`git diff --check` 通过，仅有既有 Windows LF/CRLF 提示。

边界结论：本批完成书签、RSS 源编辑和书架 URL 导入页面的 Provider 消费边界；BookProvider 生产状态迁移及其他服务消费者继续按后续批次收敛，不宣称 R1-12、Web/WASM/PWA 或真实 Android TTS 门禁变化。

## 176. 2026-08-03：R6 Provider 缓存、书架整理与书单导入迁移

- `CacheBookPage`、`BookshelfArrangePage` 和 `ImportBookshelfDialog` 通过局部 Riverpod `ProviderScope` 复用共享 `SourceController`；书源查找、书源显示和书单导入前选择不再从页面动作直接读取 `SourceProvider` 的兼容状态。
- `BookProvider` 继续负责书籍、缓存、导入、排序和持久化，未扩大本批写集；测试宿主显式补齐 `SourceProvider`、书架列表、公共文本获取和日志端口，保留原有导入与文件选择回归。
- 未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。真实 Android TTS、Web/WASM/PWA、R1-12 和其他暂停门禁保持原边界。

验证结果：受影响定向 `7/7`；Flutter 串行全量 `1083` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构边界脚本和 `git diff --check` 通过。

边界结论：本批完成缓存页、书架整理和书架书单导入页面的 Provider 消费边界；`BookProvider` 生产状态及剩余页面消费者继续作为后续独立批次，不据此宣称 Riverpod 全量迁移完成。

## 177. 2026-08-03：R6 Provider 搜索内容与书架样式迁移

- `SearchContentPage` 通过局部 Riverpod `ProviderScope` 复用共享 `ReplaceController`；替换规则加载和正文净化改由 `ReplaceNotifier` 提供入口，搜索结果、取消、缓存、滚动和异步代数继续保留页面本地状态。
- `BookshelfStyle1Page`、`BookshelfStyle2Page` 通过局部 Riverpod `ProviderScope` 复用共享 `SourceController`；目录刷新和 source resolver 改用 `SourceNotifier`，`BookProvider` 仍是书籍、分组、排序、目录刷新和持久化的唯一兼容事实源。
- RemoteBook 本批只完成只读边界审查，确认远程页面状态可独立建模，但本地文件导入和书架入库仍保留在 `BookProvider`；未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

验证结果：受影响定向 `8/8`；Flutter 串行全量 `1086` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 无诊断；架构边界脚本和 `git diff --check` 通过。

边界结论：本批完成搜索内容页与两种书架样式的 Provider 消费边界；RemoteBook 状态 Controller、`BookProvider` 生产状态迁移及正文阅读会话继续作为后续独立批次，不据此宣称 Riverpod 全量迁移完成。

## 178. 2026-08-03：R6 BookProvider 书架书籍生命周期写入边界

- 新增 `BookshelfBookLifecycleController`，负责书籍新增和删除时的 `BookRepository` 写入、`ChapterContentCachePort.clearBook` 清理及其固定顺序。
- `BookProvider` 继续负责书架列表刷新、`_shelfChapterMeta` 清理、批量删除的逐项失败语义和通知；组合根显式注入 controller，旧构造调用保留默认兼容组装。
- 生命周期/书架/缓存定向 `16/16`，Flutter 全量 `1115` 通过、`3` 项既有外部网络条件跳过；`flutter analyze`、架构边界和 `git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

边界结论：本批仅收口 `BookProvider` 的新增/删除写入副作用，不迁移 Provider 状态、不改变书籍导入、阅读进度、目录刷新、换源和正文链路；R6、真实 Android TTS、Web/WASM/PWA、正式/主流 WebDAV 仍按各自门禁推进。

## 179. 2026-08-03：R6 BookProvider 阅读元数据写入边界

- 新增 `BookRecordController`，负责 `readIteration` 和模拟追读字段的 Book 复制、`startChapter`/`dailyChapters` 兼容裁剪及 `BookRepository` upsert。
- `BookProvider` 继续负责当前书选择、列表刷新、通知和模拟追读的兼容返回值；测试固定 `durChapterIndex`、`currentPageIndex`、当前章节标题和其他阅读字段不被本批写入改变。
- 书籍记录/书架/缓存定向 `20/20`，Flutter 全量 `1117` 通过、`3` 项既有外部网络条件跳过；`flutter analyze`、架构边界和 `git diff --check` 通过。未修改 `legado-main/`、Rust、正文、目录顺序、分页、章节身份或第 3 条断行规则。

边界结论：本批只收口两类书籍阅读元数据写入，不迁移 `BookProvider` 状态，不改变章节索引、页内 UTF-16 位置、正文内容、书籍导入、目录刷新或换源链路；R6 及暂停平台门禁保持原状态。

## 180. 2026-08-03：R6 书架快照同步前置收口

- `BookshelfChangePort`/`BookshelfChangeBus` 由 revision 信号扩展为携带不可变完整 `List<Book>` 快照，并保存总线最新快照；生产组合根将同一总线注入 `BookProvider` 与 `BookshelfNotifier`，避免 Provider 和 Notifier 各自维护第二份书架事实源。
- `BookProvider` 在 `loadBooks` 成功或书架写入成功并重新读取完整列表后发布快照；写入失败不发布。`loadBooks` 的 requestId 失效保护保证旧并发结果不能覆盖新列表。`BookshelfNotifier` 直接应用外部快照，并在创建时从总线最新快照初始化，不重复读取数据库；其已有加载/刷新失败保留旧列表和 requestId 语义不变。
- 本批未替换 `BookshelfStyle1Page`、`BookshelfStyle2Page` 的 `BookProvider` 只读消费，也未改变网络目录刷新按钮的语义；页面迁移必须另行验证，不能将 `BookshelfNotifier.refresh()` 当作目录刷新替代。

验证结果：书架同步相关七个测试文件定向 `25/25`，命令为 `flutter test --no-pub --enable-experiment=dot-shorthands test/application/bookshelf/bookshelf_change_port_test.dart test/application/bookshelf_notifier_test.dart test/providers/book_provider_bookshelf_change_test.dart test/providers/book_provider_load_request_test.dart test/providers/book_provider_bookshelf_controller_test.dart test/providers/book_provider_group_update_test.dart test/providers/book_provider_chapter_meta_controller_test.dart`；Flutter 全量 `flutter test --no-pub --enable-experiment=dot-shorthands` 为 `1153` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过，仅保留既有 Windows LF/CRLF 提示。

边界结论：本批只完成书架快照同步前置契约和并发保护，不宣称 BookshelfStyle1/Style2 UI 只读状态迁移完成，不改变 `legado-main/`、Reader、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12、Web/WASM/PWA、真实 Android TTS 或其他暂停门禁。

## 181. 2026-08-04：R6 书架整理页快照读取边界

- 新增 `BookshelfArrangeSnapshotPort` 与 infrastructure 适配器，`BookshelfArrangePage` 的初始化、分组过滤、排序和“导出全部书源”只依赖 application 同步快照端口；不再直接读取 `BookProvider.books`。
- 生产组合根以 `BookshelfArrangeSnapshotPortAdapter` 复用现有 Provider 最新完整快照；空测试宿主保留空实现，需验证页面数据的宿主显式注入快照，避免引入第二份书架事实源或新的异步时序。
- 本批不迁移整理页写入命令，不改变分组/删除的局部列表与排序持久化语义、完整书架导出、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12、`legado-main/` 或暂停平台门禁。

验证结果：快照适配器与整理页联合定向 `19/19`；Flutter 全量 `1221` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成 `BookshelfArrangePage` 的三处只读 Provider 依赖收口，不宣称 `BookProvider` 写入/目录职责迁移完成或 R6 退出。

## 182. 2026-08-04：R6 书架菜单导出快照边界

- `BookshelfMenuActions._exportList` 复用 `BookshelfArrangeSnapshotPort` 读取完整书架，不再直接依赖 `BookProvider`；`BookshelfListPort`、AppLog 和空书架/成功/失败提示行为保持不变。
- 本批只收口导出入口的只读依赖，不迁移添加网址、书单导入、书架写入或 RemoteBook 生命周期，不改变 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：菜单导出及书架读取联合定向 `23/23`；Flutter 全量 `1222` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成一个书架只读导出调用点的 Provider 依赖收口，不宣称 `BookProvider` 写入职责迁移或 R6 退出。

## 183. 2026-08-04：R6 Style1/Style2 单本书架命令边界

- `BookshelfStyle1Page` 的行内分组改用 `BookshelfArrangeGroupCommandPort`；Style1/Style2 的单本移除改用 `BookshelfArrangeDeleteCommandPort`，组合根复用现有 Provider 回调适配器。
- 目录刷新、缓存读取、书架列表展示、重试和状态兼容仍由现有职责承载；本批不迁移批量命令、URL/书单/远程入库，不改变 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：Style1/Style2 相关定向 `15/15`；Flutter 全量 `1222` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。

边界结论：本批只完成两种书架样式的单本分组/删除命令接入，不宣称 `BookProvider` 目录、缓存或状态职责迁移完成，也不宣称 R6 退出。

## 184. 2026-08-04：R6 添加网址入库端口边界

- 新增 `BookshelfUrlImportPort` 及 infrastructure 适配器，`AddBookUrlDialog` 通过端口调用 URL 入库，不再直接依赖 `BookProvider`；生产组合根复用现有 `addBooksByUrls` 实现。
- 书源来源仍由共享 `SourceController` 提供，逐 URL 进度、成功/失败计数、日志和错误提示保持不变；本批不迁移书单导入、目录刷新、缓存、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：添加网址定向 `2/2`；Flutter 全量 `1222` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成 URL 入库页面的单一 application 写入入口，不宣称书单导入或 `BookProvider` 其他书架职责迁移完成，也不宣称 R6 退出。

## 185. 2026-08-04：R6 书单条目入库端口边界

- 新增 `BookshelfBooklistImportPort` 及 infrastructure 适配器，`ImportBookshelfDialog` 将解析后的 `BookshelfListEntry` 交给 application 端口；生产组合根复用现有 `importBookshelfEntries` 实现。
- JSON/URL 解析继续由 `BookshelfListPort` 承担，书源仍来自共享 `SourceController`，进度、added/skipped/failed 结果、日志和错误提示保持不变；本批不迁移添加网址、目录刷新、缓存、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：书单入库定向 `2/2`；Flutter 全量 `1222` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成书单解析后入库的单一 application 写入入口，不宣称 `BookProvider` 其他书架职责迁移完成或 R6 退出。

## 186. 2026-08-04：R6 发现页书架成员读取边界

- 新增只读可监听 `BookshelfMembershipPort` 和 `BookshelfMembershipPortAdapter`；`ExploreListPage` 的书架成员过滤通过端口快照执行，并用 `ListenableBuilder` 响应书架变化，不再直接依赖 `BookProvider`。
- 生产组合根以 `ListenableProvider` 适配现有 `BookProvider` 的 `Listenable` 和 `books` 快照；适配器返回不可变列表，未引入第二份书架事实源。书源探索、名称/来源 URL 匹配、空态和刷新行为保持不变。

验证结果：发现页与成员端口定向 `2/2`；Flutter 全量 `1224` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。

边界结论：本批完成发现页书架只读成员依赖收口，不宣称 `BookProvider` 写入/目录职责迁移完成或 R6 退出；不改变 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

## 187. 2026-08-04：R6 换源页写入端口边界

- 新增 `BookSourceChangePort` 和 `BookSourceChangePortAdapter`；`ChangeSourcePage` 通过端口完成换源及目录刷新，不再直接依赖 `BookProvider`。组合根将现有 Provider 的 `changeSource` 与 `loadChapters` 回调接入端口，独立宿主缺失能力时使用明确空实现。
- 页面仍先解析目标书源，再执行换源，随后以 `forceRefresh: true` 强制刷新目录；成功返回更新书籍，异常保持原错误状态和 SnackBar 提示。本批未合并自动换源或其他 Reader/目录调用点。

验证结果：换源页与适配器定向 `2/2`；Flutter 全量 `1225` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。

边界结论：本批完成换源页写入调用点收口，不宣称 `BookProvider` 其他书籍/目录职责迁移完成或 R6 退出；不改变 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

## 188. 2026-08-04：R6 主框架书架更新角标边界

- `MainShell` 不再直接消费 `BookProvider.shelfUpdateActiveCount`；`BookshelfDisplayStatePort` 增加 `shelfUpdateActiveCount` 只读状态，主框架用 `ListenableBuilder` 监听端口，生产组合根由 `BookshelfDisplayStatePortAdapter` 转发现有 Provider 数值和通知。
- 角标仍只在 `BookshelfLayout.showWaitUpCount` 开启时显示，端口缺失时使用空实现并回退 0；书架列表、写入、目录刷新和其他页面职责未迁移或改变。

验证结果：主框架/书架样式/展示状态适配器定向 `18/18`；Flutter 全量 `1226` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。

边界结论：本批完成主框架一个书架只读角标调用点收口，不宣称 `BookProvider` 其他职责迁移完成或 R6 退出；不改变 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

## 189. 2026-08-04：R6 书签页阅读跳转边界

- 新增 `BookmarkReaderPort` 和 `BookmarkReaderPortAdapter`；`BookmarkPage` 通过端口查找书籍、读取当前目录、加载书源目录和回退读取本地目录，不再直接依赖 `BookProvider`。书签数据加载改用既有 `BookshelfMembershipPort` 的不可变书架快照。
- 书源匹配仍由共享 `SourceController` 完成；书架缺书提示、目录加载异常后的本地回退、章节索引/标题回退、`chapterPos`/`pageIndex` 传递和 Reader 导航保持不变。缺少端口的独立宿主使用明确空实现。

验证结果：书签页与适配器全量 Flutter `1227` 通过、`3` 项既有条件跳过；测试类型注解修正后书签定向 `4/4`、`flutter analyze --no-pub`、架构边界、本批文件格式和 `git diff --check` 通过。

边界结论：本批完成书签页书架/目录只读与加载调用点收口，不宣称 Reader 其他页面或 `BookProvider` 其他职责迁移完成或 R6 退出；不改变 `legado-main/`、正文、目录、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

## 190. 2026-08-04：R6 有声页正文读取端口边界

- 新增 `ReaderChapterContentPort` 和 `ReaderChapterContentPortAdapter`；`AudioPlayPage` 通过端口读取章节缓存正文，不再直接依赖 `BookProvider` 或 `SourceProvider`。生产组合根以回调适配器复用现有书源匹配、`loadChapterContentCached` 和 `未找到匹配的书源` 失败文案；独立宿主缺少能力时使用明确空实现。
- 保留初始正文优先级、缓存命中、正文处理、TTS 播放、章节切换、异常传播和正文位置语义；本批不改变 `legado-main/`、目录、分页、章节身份、UTF-16 位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：适配器定向 `1/1`；Flutter 全量 `1228` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。

边界结论：本批完成有声页一个正文读取调用点收口，不宣称 Reader 其他页面、`BookProvider` 其他职责迁移完成或 R6 退出。

## 191. 2026-08-04：R6 阅读器与书籍目录读取端口边界

- 漫画阅读页新增 `MangaChapterContentPort`；组合根适配器继续调用原 `BookProvider.loadChapterContent`，保留非缓存正文读取、书源缺失异常、正文图片提取和图片请求头行为。普通 `ReaderPage` 的正文搜索改用已注册的 `ReaderChapterContentPort` 与 `ChapterContentCachePort`，保留书源缺失转 `null`、搜索缓存和导航参数。
- `BookInfoPage` 新增 `BookInfoChapterPort`，目录缓存读取、目录加载、强制刷新、目录打开、摘要和阅读定位统一通过端口；组合根复用 Provider 的当前目录、加载状态和刷新状态。移除 Feature 对 infrastructure 适配器的直接导入，未改变书源匹配、失败提示、封面/进度/写入等未迁移职责。
- 本批不改变 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：漫画、阅读器、书籍详情和三个适配器联合定向 `14/14`；Flutter 串行全量 `1232` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成三个页面调用点的 application 端口收口，不宣称 Reader/BookProvider 其他职责迁移完成或 R6 退出。

## 192. 2026-08-04：R6 阅读器、书籍详情和缓存页只读端口边界

- `ReaderPage` 新增 `ReaderImageHeadersPort`，图片尺寸读取通过端口获取请求头；组合根在 `SourceProvider` 注册后延迟创建适配器，保留请求世代、空源、失败和图片尺寸状态语义。其他 Reader 书源/书籍职责本批不迁移。
- `BookInfoPage` 的 `findShelfBook` 只读查询改用既有 `BookshelfMembershipPort` 快照，保留 sourceUrl 优先、书名+作者回退匹配；不迁移书架写入、目录、进度和 Provider 状态职责。
- `CacheBookPage` 新增 `CacheBookShelfPort`，书架快照、本地章节计数和导出所需本地章节读取通过端口完成；组合根复用现有 `BookProvider`，保留缓存统计、下载/取消、排序、导出和 UI 行为。端口对书架列表提供不可变快照。
- 本批不改变 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：阅读器图片请求头、书籍详情、缓存页及适配器联合定向 `13/13`；Flutter 串行全量 `1236` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成三个页面只读调用点收口，不宣称 Reader/BookProvider/SourceProvider 其他职责迁移完成或 R6 退出。

## 193. 2026-08-05：R6 漫画阅读进度写入端口边界

- 新增 `MangaProgressPort` 和 `MangaProgressPortAdapter`；漫画阅读页 `_persistProgress` 通过端口写入书籍进度，不再直接依赖 `BookProvider.updateProgress`。组合根复用同一 Provider 回调，保留进度比例、章节标题、`pageIndex`、`durChapterIndex`、异常传播和原页面时序。
- 本批仅迁移进度写入职责，不改变 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：漫画进度适配器和页面端口定向 `7/7`；Flutter 串行全量 `1239` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。

边界结论：本批完成漫画页一个进度写入调用点收口，不宣称漫画页其他 Provider/SourceProvider 职责迁移完成或 R6 退出。

## 194. 2026-08-05：R6 漫画换源目录读取端口边界

- 新增 `MangaChapterListPort` 和 `MangaChapterListPortAdapter`；漫画阅读页 `_openChangeSource` 通过 application 端口获取换源后的当前目录，不再直接依赖 `BookProvider.currentChapters`。组合根复用同一 Provider 快照并返回不可变列表，保留空目录提示、索引裁剪、换源后替换导航和原页面时序。
- 本批仅迁移换源后的目录读取职责，不改变 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：漫画目录适配器和页面端口定向 `5/5`；Flutter 串行全量 `1241` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成漫画换源目录一个读取调用点收口，不宣称漫画页其他 Provider/SourceProvider 职责迁移完成或 R6 退出。

## 195. 2026-08-05：R6 缓存下载与阅读器书源展示端口边界

- `CacheBookDownloadPort` 提供不可变目录快照、下载状态、章节下载和取消命令；缓存页通过端口渲染进度和执行命令，生产组合根委托既有 `BookProvider`，缺少端口的独立宿主才保留旧回调 fallback。
- `ReaderSourcePresentationPort` 保留书源名优先、`bookSourceUrl` 再 `sourceUrl` 的 host 回退、空值和不可解析 URL 原样展示；`MangaSourcePresentationPort` 保留旧菜单的未匹配“书源”回退。两个适配器均复用 `SourceProvider.findSourceForBook`，未产生第二份书源事实源。
- 本批不改变 `legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：缓存下载、漫画与普通阅读器书源展示联合定向 `21/21`；Flutter 串行全量 `1254` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成三个独立调用面的 application 端口收口，不宣称 CacheBookPage、ReaderPage、MangaReaderPage 的其他 Provider/SourceProvider 职责迁移完成或 R6 退出。

## 196. 2026-08-05：R6 书架未读角标元数据边界

- 新增可监听只读 ShelfUnreadMetaPort 和 ShelfUnreadMetaPortAdapter；ShelfUnreadBadge 通过 application 端口读取章节数量与当前阅读索引，不再直接依赖 BookProvider。生产组合根继续委托同一 Provider 的章节元数据事实源，未创建第二份状态。
- 保留未读计算、更新文案、999+ 截断、主题色、显示条件和元数据变化后的重建行为；本批不改变 legado-main、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：端口与角标 Widget 定向 5/5；flutter analyze --no-pub、scripts/check_architecture_boundaries.ps1 和 git diff --check 通过；R6 尚未退出。

边界结论：本批完成书架未读角标一个只读调用点的 application 端口收口，不宣称 BookProvider 其他书架职责迁移完成或 R6 退出。

## 197. 2026-08-05：R6 书籍详情元数据写入边界

- 新增 BookMetadataPort 和 BookMetadataPortAdapter；BookInfoPage 的封面自动补全、书名/作者/简介字段写入通过 application 端口完成，不再直接调用 BookProvider 的对应写入方法。生产组合根继续复用 BookProvider 的最新书架快照、通知和异常语义。
- 保留字段裁剪、空书名回退、非书架不落库、封面写入失败静默降级和已有 UI 行为；本批不改变 legado-main、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：元数据端口与书籍详情定向 9/9；Flutter 全量 1264 通过、3 项既有条件跳过；flutter analyze --no-pub、scripts/check_architecture_boundaries.ps1 和 git diff --check 通过；R6 尚未退出。

边界结论：本批完成书籍详情两个基础元数据写入调用面的 application 端口收口，不宣称 BookInfoPage 其他 Provider 职责迁移完成或 R6 退出。

## 198. 2026-08-05：R6 书籍详情阅读状态写入边界

- 新增 `BookReadStatusPort` 和 `BookReadStatusPortAdapter`；`BookInfoPage._setReadIteration` 通过 application 端口写入读完/N 刷轮次，生产组合根继续复用 `BookProvider.updateReadIteration`，独立宿主可显式注入端口或使用回调实现。
- 保留阅读状态选项、书架内落库条件、Provider 异常传播和原有 UI 行为；本批不迁移书架增删、分组、阅读启动、目录或进度职责，不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：端口转发和书籍详情交互定向 `9/9`；Flutter 全量 `1266` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成书籍详情一个阅读状态写入调用点的 application 端口收口，不宣称 BookInfoPage 其他 Provider 职责迁移完成或 R6 退出。

## 199. 2026-08-05：R6 书籍详情分组命令边界

- `BookInfoPage` 的单本分组写入改用已存在的 `BookshelfArrangeGroupCommandPort`；生产组合根继续复用 `BookshelfArrangeGroupCommandPortAdapter` 与 `BookProvider`，独立宿主缺少能力时使用明确空实现。分组列表读取仍通过 `BookshelfMembershipPort`，未创建第二份书架事实源。
- 保留加入书架前置、分组输入裁剪、取消、页面局部状态更新和原有 UI 行为；本批不迁移书架增删、阅读启动、目录、进度职责，不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：分组适配器与书籍详情定向联合 `15/15`；Flutter 全量 `1266` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成书籍详情一个单本分组写入调用点的 application 端口收口，不宣称 BookInfoPage 其他 Provider 职责迁移完成或 R6 退出。

## 200. 2026-08-05：R6 书籍详情书架生命周期边界

- 新增 `BookshelfBookLifecyclePort` 和 `BookshelfBookLifecyclePortAdapter`；`BookInfoPage` 的加入书架、加入后的当前目录保存和移除书架均通过 application 端口执行。生产组合根继续复用现有 `BookProvider.addBook`、`persistCurrentTocFor`、`removeBook`，因此保留书架快照、章节元数据、变更总线和通知语义。
- 保留加入顺序、移除行为、成功提示、失败传播和“去阅读”入口；阅读启动、目录刷新、书源匹配和其他 Provider 职责本批不迁移，不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：书架生命周期适配器和书籍详情回归定向 `9/9`；Flutter 全量 `1267` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成书籍详情三个书架生命周期调用面的 application 端口收口，不宣称 BookInfoPage 其他 Provider 职责迁移完成或 R6 退出。

## 201. 2026-08-05：R6 普通阅读器进度写入边界

- 新增 `ReaderProgressPort` 和 `ReaderProgressPortAdapter`；`ReaderPage._saveProgress` 通过 application 端口写入章节进度，生产组合根继续复用 `BookProvider.updateProgress`，未创建第二份阅读进度事实源。
- 保留进度比例、章节标题、`pageIndex`、`durChapterIndex`、异步写入时序和异常行为；本批不迁移正文、目录、换源、缓存、模拟追读或云端同步职责，不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：阅读进度适配器和 Reader 端口宿主定向 `5/5`；Flutter 全量 `1268` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成普通阅读器一个进度写入调用点的 application 端口收口，不宣称 ReaderPage 其他 Provider 职责迁移完成或 R6 退出。

## 202. 2026-08-05：R6 普通阅读器目录刷新边界

- 新增 `ReaderChapterRefreshPort` 和 `ReaderChapterRefreshPortAdapter`；`ReaderPage._updateToc` 的强制目录刷新通过 application 端口获取不可变章节快照，生产组合根继续复用 `BookProvider.loadChapters`，未创建第二份目录事实源。
- 保留当前章节 ID/标题定位、空目录提示、成功提示、异常文案和替换导航行为；本批不迁移普通目录读取、换源、正文、缓存或阅读进度职责，不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：目录刷新适配器和 Reader 端口宿主定向 `5/5`；Flutter 全量 `1269` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1`、Dart 格式和 `git diff --check` 通过。

边界结论：本批完成普通阅读器一个目录刷新调用点的 application 端口收口，不宣称 ReaderPage 其他 Provider 职责迁移完成或 R6 退出。

## 203. 2026-08-05：R6 普通阅读器模拟追读边界

- 新增 `ReaderSimulatedReadingPort` 和 `ReaderSimulatedReadingPortAdapter`；`ReaderPage` 的模拟追读书籍查询、旧书字段迁移写入和对话框保存写入均通过 application 端口完成，生产组合根继续复用 `BookProvider.findBookById/updateSimulatedReading`。
- 保留 `SimulatedReadingPrefsPort` 配置存储、旧书字段迁移顺序、日期/章节/每日章节参数裁剪、可读章节限制和原有 UI 行为；本批不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：模拟追读适配器与 Reader 端口宿主定向 `6/6`；Flutter 全量 `1271` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。

边界结论：本批完成普通阅读器模拟追读一个读写调用面的 application 端口收口，不宣称 ReaderPage 其他 Provider 职责迁移完成或 R6 退出。

## 204. 2026-08-05：R6 普通阅读器离线缓存边界

- `ReaderPage._openOfflineCache` 的下载状态读取、同书取消、目录加载和批量章节下载改用已有 `CacheBookDownloadPort`；页面通过端口读取不可变下载状态，生产组合根继续复用 `BookProvider` 的下载回调与通知，不创建第二份下载状态事实源。
- 保留书源缺失、其他书籍正在缓存、空目录、缓存章节过滤、选择对话框、并发参数、完成计数和原有提示语义；本批不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：Reader 端口宿主与缓存下载适配器定向 `7/7`；Flutter 全量 `1272` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。

边界结论：本批完成普通阅读器离线缓存一个下载调用面的 application 端口复用，不宣称 ReaderPage 其他 Provider/SourceProvider 职责迁移完成或 R6 退出。

## 205. 2026-08-05：R6 普通阅读器目录快照边界

- 新增 `ReaderChapterListPort` 和 `ReaderChapterListPortAdapter`；普通阅读器目录面板、手动换源后的目录导航、自动换源后的目录导航通过 application 端口读取不可变当前目录快照，组合根继续复用 `BookProvider.currentChapters`。
- 换源与自动换源命令本身仍由既有 Provider 负责；保留目录面板秒开、当前书籍匹配、空目录提示、当前索引裁剪和换源后替换导航语义。本批不改变 `legado-main`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：Reader 目录适配器与端口宿主定向 `8/8`；Flutter 全量 `1274` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。

边界结论：本批完成普通阅读器三个当前目录只读调用面的 application 端口收口，不宣称 ReaderPage 其他 Provider/SourceProvider 职责迁移完成或 R6 退出。

## 206. 2026-08-05：R6 Reader 外部访问边界

- 新增 `ReaderSourceAccessPort` 和 `ReaderSourceAccessPortAdapter`；普通阅读器的书源匹配、可用书源不可变快照和自动换源命令通过 application 端口接入，组合根分别复用 `SourceProvider` 与 `BookProvider` 的现有事实源/算法。
- `ReaderChapterListPort` 改为 `currentChaptersFor(Book)`，适配器先按首章 `bookId` 校验再返回不可变快照；缓存章节 ID 读取和清洗改用已注册的 `ChapterContentCachePort`。保留书源顺序、自动换源并发默认值、目录顺序和章节身份，不改变 `legado-main`、正文、分页、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：Reader 源访问、目录校验、缓存端口与页面宿主定向 `10/10`；Flutter 全量 `1276` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。

边界结论：本批完成普通阅读器书源/目录/缓存外部访问的 application 端口收口，不宣称 ReaderPage 自动换源内部算法或其他 Provider 职责迁移完成或 R6 退出。

## 207. 2026-08-05：R6 普通阅读器正文读取边界

- `ReaderPage._loadContent` 的缓存正文读取改用已注册的 `ReaderChapterContentPort`；新增 `ReaderChapterCacheStatusPort` 和适配器承载成功正文后的 `markChapterDownloaded`，组合根继续复用 `BookProvider.loadChapterContentCached/markChapterDownloaded`。
- 保留书源缺失文案、`ReadBook` 章节缓存失效、正文处理、请求世代、分页、图片加载、章节身份和失败语义；本批不改变 `legado-main`、目录顺序、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁。

验证结果：Reader 正文端口、缓存状态适配器与页面宿主定向 `11/11`；Flutter 全量 `1278` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、`scripts/check_architecture_boundaries.ps1` 和 `git diff --check` 通过。

边界结论：本批完成普通阅读器正文读取和缓存状态更新两个外部调用面的 application 端口收口，不宣称 `ReadBook` 内存缓存/编辑职责或 ReaderPage 其他 Provider 职责迁移完成或 R6 退出。
## 208. 2026-08-05：R6 书籍详情缓存下载边界

- `BookInfoPage` 的“缓存全部”入口改用既有 `CacheBookDownloadPort`，页面不再直接读取 `BookProvider` 的下载状态或调用批量下载、取消；生产组合根继续复用同一 `BookProvider` 事实源。
- 目录加载、书源缺失、空目录提示、缓存过滤、并发参数、同书取消和完成计数语义保持不变；独立宿主未注入端口时使用回调适配器，不创建第二份下载状态。
- 新增详情页显式端口注入回归，定向 `10/10`；`flutter analyze --no-pub`、架构边界和 Flutter 全量 `1279`（`3` 项既有条件跳过）通过。
- 本批未修改 Rust、`legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
## 209. 2026-08-05：R6 书籍详情阅读启动与书源访问边界

- `BookInfoPage` 的书源匹配改用既有 `ReaderSourceAccessPort`，生产组合根继续复用 `SourceProvider` 书源事实源和 `BookProvider` 自动换源能力，独立宿主可显式注入该端口。
- 阅读入口的最新书籍读取改用 `BookshelfMembershipPort`，移除页面对 `BookProvider.books` 的直接读取；移除未使用的 `Consumer<BookProvider>` 展示包装，书源状态仍通过共享 `SourceState` 驱动名称刷新。
- 保留书架匹配优先级、章节定位、普通/漫画阅读分流、书源回退和原 UI 行为。新增书源端口显式注入回归，详情定向 `10/10`；`flutter analyze --no-pub`、架构边界和 Flutter 全量 `1280`（`3` 项既有条件跳过）通过。
- 本批未修改 Rust、`legado-main/`、正文、目录顺序、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
## 210. 2026-08-05：R6 目录持久化边界

- 新增 `TocPersistencePort`；`TocSheet` 的书籍状态读取、倒序目录章节保存和书籍状态保存通过 application 端口完成，生产组合根以 `TocPersistencePortCallbacks` 复用同一 `BookRepository`。
- 目录缓存字数/缓存状态读取改从已注册的 `ChapterContentCachePort` 获取；保留 `bookRepository` 显式参数作为旧宿主兼容路径，以及目录顺序、倒序、0-based index 重写和异常降级行为。
- 目录页与书籍详情定向 `15/15`；`flutter analyze --no-pub`、架构边界和 Flutter 全量 `1280`（`3` 项既有条件跳过）通过。
- 本批未修改 Rust、`legado-main/`、正文、目录顺序语义、分页、章节身份、UTF-16 阅读位置、第 3 条断行规则、R1-12 或暂停平台门禁；R6 尚未退出。
## 211. 2026-08-05：R6 书架导入对话框 SourceController 边界

- `AddBookUrlDialog` 与 `ImportBookshelfDialog` 移除页面内对旧 `SourceProvider` 的直接依赖和嵌套 Riverpod scope；生产组合根已经提供共享 `SourceController`，测试宿主显式设置同一 `sourceControllerProvider` override。
- 保留源列表读取、网址导入、书单解析、进度更新、错误记录和原有 UI 行为；不改变书源顺序、正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- 对话框定向 `4/4`；`flutter analyze --no-pub`、架构边界和 Flutter 全量 `1280`（`3` 项既有条件跳过）通过。
- 本批未修改 Rust、`legado-main/`、R1-12 或暂停平台门禁；R6 尚未退出。
## 212. 2026-08-05：R6 探索页 SourceController 边界

- `ExploreListPage` 移除页面内对旧 `SourceProvider` 的直接依赖和嵌套 Riverpod scope；生产组合根已提供共享 `SourceController`，测试宿主显式设置同一 `sourceControllerProvider` override。
- 保留当前书源读取、探索请求、结果映射、书架成员过滤、分页和原有 UI 行为；本批未改变正文、目录、分页语义、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- 探索页定向 `1/1`；`flutter analyze --no-pub`、架构边界和 Flutter 全量 `1280`（`3` 项既有条件跳过）通过。
- 本批未修改 Rust、`legado-main/`、R1-12 或暂停平台门禁；R6 尚未退出。
## 214. 2026-08-05：R6 书架整理 SourceController 显式注入收口

- `BookshelfArrangePage` 移除页面内旧 `SourceProvider` 依赖，增加可选 `SourceController` 显式注入；生产组合根继续消费共享 `sourceControllerProvider`，测试宿主显式提供 controller。
- 保留源标签刷新、分组命令、删除命令、排序、选择状态和原有 UI 行为；本批未改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- 书架整理定向 `18/18`；`flutter analyze --no-pub`、架构边界和 Flutter 全量 `1280`（`3` 项既有条件跳过）通过。
- 本批未修改 Rust、`legado-main/`、R1-12 或暂停平台门禁；R6 尚未退出。

## 213. 2026-08-05：R6 书架整理 SourceController 边界

- `BookshelfArrangePage` 移除页面内对旧 `SourceProvider` 的直接依赖，增加可选 `SourceController` 显式注入；生产环境不创建新 scope，继续消费组合根共享 `sourceControllerProvider`，独立测试宿主可显式提供 controller。
- 保留源标签刷新、分组命令、删除命令、排序、选择状态和原有 UI 行为；本批未改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。
- 书架整理定向 `18/18`；`flutter analyze --no-pub`、架构边界和 Flutter 全量 `1280`（`3` 项既有条件跳过）通过。
- 本批未修改 Rust、`legado-main/`、R1-12 或暂停平台门禁；R6 尚未退出。
