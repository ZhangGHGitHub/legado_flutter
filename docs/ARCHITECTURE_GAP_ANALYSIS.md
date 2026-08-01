# 统一设计与当前实现差距

日期：2026-08-01
依据：[统一设计](./LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md)、当前代码、`REFACTOR_PLAN.md`、`DEVELOPMENT_PROCESS.md`。

## 结论

当前工程已经满足 Rust + Flutter 的主要分层方向，但尚未满足统一设计稿的严格技术要求。以下缺口必须按 `REFACTOR_PLAN.md` 的收敛顺序逐项关闭。

| 设计要求 | 当前证据 | 状态 | 后续门禁 |
|---|---|---|---|
| UI 不直连基础设施 | 架构边界脚本通过；Feature/Widget/Provider 直接基础设施扫描为 0 | 基本符合 | 增加 Notifier 和业务编排检查 |
| Riverpod/Notifier | 已加入 `flutter_riverpod`；CoreApi 有首个 Notifier 样板，`BookshelfNotifier` 已覆盖加载、失败、刷新和并发旧结果丢弃；业务页面仍使用 Provider | 部分完成 | 逐模块迁移并保持 Widget 回归 |
| freezed 镜像模型 | `SearchResultItem`、`BookReadConfig`、`BookGroup`、`Chapter` 已引入 Freezed 定义和兼容映射，生成链已通过；Book/BookSource 仍未全部迁移 | 部分完成 | 继续扩展 Book/BookSource，并保持旧 JSON 契约 |
| CoreApi + Mock/Real | 书架/搜索 CoreApi、MockCoreApi、RealCoreApi 和契约测试已建立；生产组合根通过 ProviderScope 注入 RealCoreApi | 基本完成首批 | 先补书架命令契约，再迁移页面单一事实源 |
| 统一 AppError | 根 `api/mod.rs` 的 `search/explore/get_book_info/get_toc/get_content/get_content_with_next_chapter/validate_source/debug_search/debug_toc`、`query_dict_rule`、笔记/书签入口、23 个 `db_*` 入口、HTTP 文本/二进制入口、`http_fetch`、网络配置/Cookie/trace、RSS 文章/正文、EPUB、远程 ZIP、`eval_js`、`seed_login_header` 和 `process_content_for_reading` 入口已改为 Rust `AppError`；子模块重复 FRB 导出已收敛，浏览器宿主和其它公开 FFI 仍有 `Result<T, String>` | 部分完成 | 继续迁移其它公开 FFI 错误和 Dart 统一映射 |
| QuickJS 5 秒超时 | 已接入统一 QuickJS Runtime interrupt，纯脚本执行预算为 5 秒；脚本和 `jsLib` 输入上限均为 256 KiB；定向测试 29/29、Rust 全量 208 项通过。`java.ajax`、`getStrResponse` 和 WebView 宿主同步阻塞不受本批 interrupt 中断 | 部分完成 | 单独补齐宿主调用超时、取消和资源上限边界，不宣称本批已覆盖宿主阻塞 |
| 统一 `init(app_dir)` | `init(app_dir)` 固定使用 `app_dir/legado.db`，schema 初始化在单事务中执行，失败不发布；同目录幂等且首次并发调用受初始化锁保护。FRB 已重新生成，生产 `LegadoDbBridge` 传入应用数据目录；数据库定向 19/19、备份桥接 10/10、Flutter 全量 894 项通过且有 3 项既有跳过 | 基本完成首批 | 继续补齐历史 schema 异常版本覆盖并保持旧入口兼容过渡；不宣称 R1-12/R2/R6 阶段退出 |
| 编码探测 | Rust 使用 `encoding_rs`；本地 TXT 仍有 Dart GBK fallback | 部分完成 | GBK/GB18030 fixture 和 Rust 唯一事实源 |
| Rust `core/ffi_bridge` 目录 | 实际为 `rust/legado_engine` | 部分符合 | 先按逻辑边界隔离，目录迁移需独立决策 |
| 模块映射和 API 清单 | 本批新增 `MODULE_MIGRATION_MAPPING.md` | 已建立初版 | 对照原版逐项补全 |
| CI | 已新增 Rust/Flutter/架构边界 push/PR workflow；Apple workflow 保留 | 部分完成 | GitHub runner 首次真实执行并补平台矩阵 |
| 多平台完整验收 | Android/Windows 有证据；Web/WASM/PWA 等暂停 | 未完成 | 依平台条件逐项验收 |

## 不得改变的行为契约

架构迁移不得改变正文内容、目录顺序、章节身份、分页、UTF-16 阅读位置和原版第 3 条断行规则。每次迁移必须先有定向回归，再运行对应全量门禁。

## 当前范围

本报告只固化差距和执行顺序；CoreApi 首批、Riverpod 样板、CI 门禁、书源主链、数据库入口、HTTP 文本/二进制入口以及 RSS/EPUB/远程 ZIP 的公开 `AppError` 边界已完成，下一批继续迁移其它公开 FFI 错误和 Dart 统一映射，不改变 Provider 页面事实源或正文行为。

## 2026-08-01 公开 FFI 错误边界扩展

- `parse_epub`、`parse_remote_archive_book_files` 的公开失败结果改为 `AppError::Parse`；EPUB/ZIP 的成功解析、输入大小、路径安全、文件筛选和错误原文保持不变。
- `get_rss_articles`、`get_rss_content` 的公开失败结果改为 `AppError::Network` 或 `AppError::Parse`；请求前缀决定网络分类，解析文本即使包含 `network` 仍分类为 `Parse`，成功文章字段、排序、分页和正文解析保持不变。
- FRB 生成文件仍属于绑定产物，Rust/FRB 具体实现留在 infrastructure 边界；`AppError.field0` 在 FRB 适配层转换为领域端口异常，避免 Freezed `toString()` 改写用户可见错误文本。
- 验证：Rust RSS 定向 `4/4`、Rust 全量 `224`、Flutter 适配器定向 `10/10`、Flutter 全量 `897` 通过，`3` 项既有条件跳过；release 构建、`flutter analyze --no-pub`、架构扫描和 `git diff --check` 通过。
- 本批没有迁移 RSS/本地书籍的 application/UI 用例，也不覆盖浏览器宿主、QuickJS 宿主阻塞、Dart 全链路错误展示和其它公开 `Result<T, String>` 入口；不构成 R1-12、R2、R3 或 R6 阶段退出证据。

## 2026-08-01 `eval_js` 错误边界扩展

- `eval_js` 的公开失败结果统一为 `AppError::JsExecution`，成功字符串、错误原文和 QuickJS 纯执行 5 秒 interrupt、256 KiB 输入上限保持不变。
- Rust `eval_js` 定向 `2/2`、Dart FRB 定向 `2/2`、Rust 全量 `226`、Flutter 全量 `899` 通过，`3` 项既有条件跳过；release 构建、analyze、架构扫描和 diff 检查通过。
- `java.ajax`、`getStrResponse`、WebView 宿主阻塞、取消/资源回收、浏览器宿主和其它公开 `Result<T, String>` 仍是后续边界；本条不改变统一设计的“部分完成”状态。

## 2026-08-01 `seed_login_header` 错误边界扩展

- `seed_login_header` 的公开失败结果统一为 `AppError`；缓存 key/header 清理、空值忽略和无 dirty 更新行为保持不变。
- Rust 定向 `3/3`、Dart FRB 定向 `2/2`、Rust 全量 `226`、Flutter 全量 `901` 通过，`3` 项既有条件跳过；release 构建、analyze、架构扫描和 diff 检查通过。
- 生成器 Windows 文件映射锁导致的全量生成漂移不属于 source-owned 变更；最终只保留三处最小 FRB codec/API 差异，统一错误边界仍为“部分完成”。

## 2026-08-01 `process_content_for_reading` 错误边界扩展

- `process_content_for_reading` 的公开失败结果统一为 `AppError::Parse`；成功正文输出、替换规则、缩进、标题合并和重新分段行为保持不变。
- Rust 定向 `2/2`、Dart FRB mock 契约 `2/2`、Rust 全量 `228`、Flutter 全量 `903` 通过，`3` 项既有条件跳过；release 构建、`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 通过。
+ 本批只收敛公开错误契约，不覆盖浏览器宿主、WebView 生命周期、重复公开 FRB 子模块入口、WebDAV、平台验收、阶段退出或其它公开 `Result<T, String>`；不改变正文、目录、分页、章节身份、UTF-16 阅读位置或第 3 条断行规则。

## 2026-08-01 追溯补充

- 本批实际收敛了 `SearchResultItem`、`BookReadConfig`、`BookGroup` 的 Freezed 模型入口，以及 `BookshelfNotifier` 的首个书架状态编排样板；`BookshelfNotifier` 定向测试为 `8` 项通过。
- Rust 侧新增 `debug_search`、`debug_toc` 的 `AppError` 边界；FRB 生成链已恢复并验证。`cargo test -p legado_engine` 为 `190` 项通过，Flutter 串行全量为 `887` 项通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。
- 生成器仍提示 SDK `3.11.0` 高于 analyzer `3.9.0`，当前为非阻塞警告；其它公开 FFI `Result<T, String>`、Book/Chapter/BookSource 完整镜像和业务页面 Riverpod 迁移继续按既定 Phase 推进。本补充不改变正文/目录/分页/章节身份/UTF-16 阅读位置契约。
- 本批继续完成 `Chapter` Freezed 镜像、23 个数据库 FFI 入口的 `AppError::Database` 边界，以及组合根的真实 `RealCoreApi` ProviderScope 注入；Chapter 定向 `6` 项、组合根定向 `4` 项通过。
- 本批验证：Rust `192` 项通过；Flutter 定向联调 `18` 项通过，串行全量 `894` 项通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。运行时回归曾发现 debug DLL 过期导致的 FRB 错误标签不匹配，按源码重建 `rust/target/debug/legado_engine.dll` 后定向和全量均恢复通过。
- `BookSource` 仍因嵌套规则/raw JSON 无损语义保留手写模型；书架页面仍使用 `BookProvider`，暂不与 `BookshelfNotifier` 并行作为第二事实源。其它公开 FFI `Result<T, String>`、Book/BookSource 完整镜像和业务页面 Riverpod 迁移继续按既定 Phase 推进。
- 网络边界批次将 `fetch_public_text`、应用 HTTP 文本请求和二进制请求迁移为 `AppError`，Rust 定向 `9/9` 通过；FRB 绑定已同步生成。其余网络配置、Cookie、裸 HTTP、RSS、JS、笔记和书签入口仍按后续低风险批次推进。
- 网络边界批次最终验证：Rust 全量 `199` 项、Windows FRB HTTP 集成 `2/2`、Flutter 串行全量 `894` 项通过，`3` 项既有条件跳过；`flutter analyze --no-pub` 通过。该结果不改变 QuickJS 超时、初始化、编码、Book/BookSource Freezed 和生产书架 Riverpod 等未完成差距。
- 网络扩展批次将裸 `http_fetch`、网络配置、Cookie 和 HTTP trace 入口统一为 `AppError`；Rust API 定向 `57/57`、全量 `202` 通过，Windows FRB HTTP 集成 `2/2`，Flutter 串行全量 `894` 通过、`3` 项既有条件跳过；analyze、架构边界和 diff 检查通过。其余书源、RSS、JS、笔记和书签入口仍未迁移。
- QuickJS 与数据库初始化批次验证：QuickJS Runtime interrupt 纯脚本预算 `5` 秒、脚本和 `jsLib` 输入上限 `256 KiB`，定向 `29/29`、Rust 全量 `208` 通过；`java.ajax`、`getStrResponse` 和 WebView 宿主同步阻塞仍不在本批 interrupt 覆盖范围。`init(app_dir)` 使用 `app_dir/legado.db`，事务初始化失败不发布，同目录幂等并覆盖首次并发调用锁；数据库定向 `19/19`、备份桥接 `10/10`、Flutter 全量 `894` 通过且 `3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。FRB 已重新生成并接入生产 `LegadoDbBridge`；本条不表示 R1-12/R2/R6 阶段退出，也不表示已覆盖全部宿主超时、编码或剩余 `AppError` 差距。
- 公开 FFI 错误边界批次验证：`get_book_info`、`query_dict_rule`、笔记和书签入口改用 `AppError`，保留详情/字典成功结果、数据库 CRUD、Markdown、排序、UTF-16 位置和错误原文；FRB 已重新生成。Rust 全量 `218` 项、Flutter 全量 `894` 项通过，`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。RSS、EPUB、浏览器宿主及其它公开 `Result<T, String>` 入口继续排队，本条不表示 R1-12/R2/R6 阶段退出。
