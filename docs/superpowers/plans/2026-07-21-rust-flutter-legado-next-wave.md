# Rust + Flutter Legado 下一阶段计划

状态：进行中

## 目标

以 Jingshiro/Legado 的行为和 UI 为参照，优先完成“书源引擎 → 阅读会话 → 缓存/数据库 → 阅读器 UI”的稳定闭环。页面清单只作为验收索引，不再作为主开发顺序。

## 开发原则

- Rust 负责网络、规则解析、目录和正文；Flutter 负责状态编排、缓存策略和 UI。
- 每个跨 FFI 功能必须同时有 Rust 离线 fixture 测试和 Flutter 集成边界测试。
- 网络测试默认离线；真实书源只作为手工 smoke test，不作为 CI 必需条件。
- 以 Jingshiro Kotlin 行为为准，UI 差异必须记录对应 XML/源码位置。
- 只在完成测试和文档验收后更新阶段状态，避免 README 与实际代码脱节。

## Wave 1：阅读会话稳定性

- [x] 正文内存缓存 key 包含 `bookId` 和 `chapterId`，避免跨书串缓存。
- [x] 目录并发 key 包含 `bookId` 和 `sourceUrl`，避免换源复用旧请求。
- [x] 为缓存隔离、坏缓存清理和替换净化切换补充单元测试。
- [x] 为正文预加载和目录并发 Provider 行为补充异步集成测试。
- [x] 检查阅读会话切书、换源、退出后的异步请求是否能丢弃旧结果。

Wave 1 验收记录：

- `ReadBook` 用会话代数隔离换书/换源后的正文请求，并用会话 token 管理相邻章预加载去重。
- `ReaderPage` 用请求代数丢弃切章或退出后的旧 UI 回写。
- `BookProvider` 支持注入 DAO / 书源服务，目录并发和旧源结果测试均为离线 fake harness。
- Flutter `test/model test/providers test/services`：107 项通过；针对性静态分析仅剩阅读器已有 `Radio` 弃用提示。

Wave 2 / Wave 3 核心验收记录：

- Rust 本地 TCP fixture 覆盖目录分页、正文分页、空响应、HTTP 503、响应超限。
- Rust 网络层只使用 legado 显式代理配置，单次响应限制 8 MiB；`@js:` 与 `<js>` 能力按流水线诊断。
- 阅读器已接入自动换源；缓存页支持选择书籍导出 TXT 或系统分享；全文搜索支持当前章、已缓存章和全书联网范围。
- HTTP TTS 已支持 Legado URL/POST 配置与音频播放；简繁增加高频歧义词匹配。
- 仍保留低优先级返工：RSS/有声/漫画 chrome、捐赠页及 RSS 调试细节。

## Wave 2：Rust 引擎契约收口

- [x] 为 Rust `get_toc` / `get_content` 增加本地 HTTP fixture，覆盖 HTML、JSON、分页和空响应错误。
- [x] 固化 `BookSource` 原始 JSON 在 Dart → FFI → Rust → 规则解析链路中的字段契约。
- [x] 统一超时、重定向、SSRF、响应大小和错误信息策略，避免 Dart/Rust 各自实现漂移。
- [x] 明确 `@js:`、`<js>` 的 Rust QuickJS 支持范围，并将不支持项变成可诊断错误。

## Wave 3：Jingshiro UI 收口

- [x] 从 UI 复刻表中清理已完成但仍标记缺失的页面条目。
- [x] 优先补阅读器剩余核心项：自动换源、长按选择文本、全文搜索范围和缓存导出。
- [x] 补齐 HTTP TTS、词级简繁高频词和全书联网搜索。
- [ ] 再处理低优先级返工：有声/漫画 chrome、捐赠页、RSS 调试页。

## 验收命令

```powershell
flutter analyze
flutter test test/model test/providers test/services
cargo test --manifest-path rust/legado_engine/Cargo.toml --lib
```

真实书源 smoke test 单独运行，不阻塞离线回归。
