# 统一设计与当前实现差距

日期：2026-08-01
依据：[统一设计](./LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md)、当前代码、`REFACTOR_PLAN.md`、`DEVELOPMENT_PROCESS.md`。

## 结论

当前工程已经满足 Rust + Flutter 的主要分层方向，但尚未满足统一设计稿的严格技术要求。以下缺口必须按 `REFACTOR_PLAN.md` 的收敛顺序逐项关闭。

| 设计要求 | 当前证据 | 状态 | 后续门禁 |
|---|---|---|---|
| UI 不直连基础设施 | 架构边界脚本通过；Feature/Widget/Provider 直接基础设施扫描为 0 | 基本符合 | 增加 Notifier 和业务编排检查 |
| Riverpod/Notifier | 已加入 `flutter_riverpod`，CoreApi 有首个 Notifier 样板；业务页面仍使用 Provider | 部分完成 | 逐模块迁移并保持 Widget 回归 |
| freezed 镜像模型 | `SearchResultItem` 已完成 freezed/json 生成；Book/Chapter/BookSource 仍为手写模型 | 部分完成 | 先 Book/Chapter/BookSource，再扩展其它模型 |
| CoreApi + Mock/Real | 书架/搜索 CoreApi、MockCoreApi、RealCoreApi 和契约测试已建立 | 基本完成首批 | 接入组合根并迁移首个页面 |
| 统一 AppError | `search/explore/get_book_info/get_toc/get_content/validate_source` 已使用 Rust `AppError`；其它 FFI 公开 API 仍大量 `Result<T, String>` | 部分完成 | 继续迁移调试、数据库边界 |
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

本报告只固化差距和执行顺序；CoreApi 首批、Riverpod 样板、CI 门禁和书源主链 `AppError` 已完成，下一批继续迁移调试/数据库错误边界，不改变 Provider 或正文行为。
