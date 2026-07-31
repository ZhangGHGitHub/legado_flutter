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
| 统一 AppError | `search/explore/get_book_info/get_toc/get_content/get_content_with_next_chapter/validate_source/debug_search/debug_toc`、23 个 `db_*` 入口，以及 `fetch_public_text`/应用 HTTP 文本与二进制入口已改为 Rust `AppError`；其它 FFI 公开 API 仍有 `Result<T, String>` | 部分完成 | 继续迁移其它公开 FFI 错误和 Dart 统一映射 |
| QuickJS 5 秒超时 | 已接入 QuickJS；未见 interrupt handler/执行预算 | 不符合 | 死循环、超时、取消和资源上限 fixture |
| 统一 `init(app_dir)` | `init_engine()` 与 `db_init(path)` 分离 | 部分完成 | 统一初始化入口，保持旧入口兼容过渡 |
| 编码探测 | Rust 使用 `encoding_rs`；本地 TXT 仍有 Dart GBK fallback | 部分完成 | GBK/GB18030 fixture 和 Rust 唯一事实源 |
| Rust `core/ffi_bridge` 目录 | 实际为 `rust/legado_engine` | 部分符合 | 先按逻辑边界隔离，目录迁移需独立决策 |
| 模块映射和 API 清单 | 本批新增 `MODULE_MIGRATION_MAPPING.md` | 已建立初版 | 对照原版逐项补全 |
| CI | 已新增 Rust/Flutter/架构边界 push/PR workflow；Apple workflow 保留 | 部分完成 | GitHub runner 首次真实执行并补平台矩阵 |
| 多平台完整验收 | Android/Windows 有证据；Web/WASM/PWA 等暂停 | 未完成 | 依平台条件逐项验收 |

## 不得改变的行为契约

架构迁移不得改变正文内容、目录顺序、章节身份、分页、UTF-16 阅读位置和原版第 3 条断行规则。每次迁移必须先有定向回归，再运行对应全量门禁。

## 当前范围

本报告只固化差距和执行顺序；CoreApi 首批、Riverpod 样板、CI 门禁、书源主链、数据库入口和 HTTP 文本/二进制入口 `AppError` 已完成，下一批继续迁移其它公开 FFI 错误，不改变 Provider 页面事实源或正文行为。

## 2026-08-01 追溯补充

- 本批实际收敛了 `SearchResultItem`、`BookReadConfig`、`BookGroup` 的 Freezed 模型入口，以及 `BookshelfNotifier` 的首个书架状态编排样板；`BookshelfNotifier` 定向测试为 `8` 项通过。
- Rust 侧新增 `debug_search`、`debug_toc` 的 `AppError` 边界；FRB 生成链已恢复并验证。`cargo test -p legado_engine` 为 `190` 项通过，Flutter 串行全量为 `887` 项通过、`3` 项既有条件跳过，`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。
- 生成器仍提示 SDK `3.11.0` 高于 analyzer `3.9.0`，当前为非阻塞警告；其它公开 FFI `Result<T, String>`、Book/Chapter/BookSource 完整镜像和业务页面 Riverpod 迁移继续按既定 Phase 推进。本补充不改变正文/目录/分页/章节身份/UTF-16 阅读位置契约。
- 本批继续完成 `Chapter` Freezed 镜像、23 个数据库 FFI 入口的 `AppError::Database` 边界，以及组合根的真实 `RealCoreApi` ProviderScope 注入；Chapter 定向 `6` 项、组合根定向 `4` 项通过。
- 本批验证：Rust `192` 项通过；Flutter 定向联调 `18` 项通过，串行全量 `894` 项通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界扫描和 `git diff --check` 均通过。运行时回归曾发现 debug DLL 过期导致的 FRB 错误标签不匹配，按源码重建 `rust/target/debug/legado_engine.dll` 后定向和全量均恢复通过。
- `BookSource` 仍因嵌套规则/raw JSON 无损语义保留手写模型；书架页面仍使用 `BookProvider`，暂不与 `BookshelfNotifier` 并行作为第二事实源。其它公开 FFI `Result<T, String>`、Book/BookSource 完整镜像和业务页面 Riverpod 迁移继续按既定 Phase 推进。
- 网络边界批次将 `fetch_public_text`、应用 HTTP 文本请求和二进制请求迁移为 `AppError`，Rust 定向 `9/9` 通过；FRB 绑定已同步生成。其余网络配置、Cookie、裸 HTTP、RSS、JS、笔记和书签入口仍按后续低风险批次推进。
- 网络边界批次最终验证：Rust 全量 `199` 项、Windows FRB HTTP 集成 `2/2`、Flutter 串行全量 `894` 项通过，`3` 项既有条件跳过；`flutter analyze --no-pub` 通过。该结果不改变 QuickJS 超时、初始化、编码、Book/BookSource Freezed 和生产书架 Riverpod 等未完成差距。
