# 统一设计与当前实现差距

日期：2026-08-01
依据：[统一设计](./LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md)、当前代码、`REFACTOR_PLAN.md`、`DEVELOPMENT_PROCESS.md`。

## 结论

当前工程已经满足 Rust + Flutter 的主要分层方向，但尚未满足统一设计稿的严格技术要求。以下缺口必须按 `REFACTOR_PLAN.md` 的收敛顺序逐项关闭。

| 设计要求 | 当前证据 | 状态 | 后续门禁 |
|---|---|---|---|
| UI 不直连基础设施 | 架构边界脚本通过；Feature/Widget/Provider 直接基础设施扫描为 0 | 基本符合 | 增加 Notifier 和业务编排检查 |
| Riverpod/Notifier | `pubspec.yaml` 使用 `provider`；仍有 ChangeNotifier | 不符合 | 逐模块迁移并保持 Widget 回归 |
| freezed 镜像模型 | domain/model 为手写 Dart 类，无 freezed 生成文件 | 不符合 | 先 Book/Chapter/BookSource，再扩展其它模型 |
| CoreApi + Mock/Real | 尚无统一抽象；本批新增 `api_contract.md` 草案 | 部分完成 | 书架/搜索 Mock 与 Real 契约测试 |
| 统一 AppError | Rust FFI 公开 API 大量 `Result<T, String>` | 不符合 | 定义枚举、FRB 映射和 Dart 分类异常 |
| QuickJS 5 秒超时 | 已接入 QuickJS；未见 interrupt handler/执行预算 | 不符合 | 死循环、超时、取消和资源上限 fixture |
| 统一 `init(app_dir)` | `init_engine()` 与 `db_init(path)` 分离 | 部分完成 | 统一初始化入口，保持旧入口兼容过渡 |
| 编码探测 | Rust 使用 `encoding_rs`；本地 TXT 仍有 Dart GBK fallback | 部分完成 | GBK/GB18030 fixture 和 Rust 唯一事实源 |
| Rust `core/ffi_bridge` 目录 | 实际为 `rust/legado_engine` | 部分符合 | 先按逻辑边界隔离，目录迁移需独立决策 |
| 模块映射和 API 清单 | 本批新增 `MODULE_MIGRATION_MAPPING.md` | 已建立初版 | 对照原版逐项补全 |
| CI | 当前只有 Apple workflow | 不符合 | 增加 Rust/Flutter push/PR 门禁 |
| 多平台完整验收 | Android/Windows 有证据；Web/WASM/PWA 等暂停 | 未完成 | 依平台条件逐项验收 |

## 不得改变的行为契约

架构迁移不得改变正文内容、目录顺序、章节身份、分页、UTF-16 阅读位置和原版第 3 条断行规则。每次迁移必须先有定向回归，再运行对应全量门禁。

## 当前范围

本报告只固化差距和执行顺序，不在本批直接替换 Provider、模型生成或 FFI 错误类型。下一批从 `api_contract.md` 的书架/搜索 Mock 与 Real adapter 开始。
