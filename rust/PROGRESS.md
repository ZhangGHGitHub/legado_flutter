# Rust + Flutter 重构进度

更新时间：2026-07-29

## 本轮完成

本轮先对照只读原版 `legado-main/`，再完成以下互不重叠的功能任务：

1. RuleSub 规则订阅更新：依据原版 `RuleUpdate.kt` 的版本时间判断，RSS 远端版本较新时才更新；静默更新保留本地分组，非静默更新进入确认缓存。实现位于 `lib/services/rule_sub_import_service.dart`，新增可注入抓取函数和 3 个回归测试。
2. 书架批量更新目录：补齐批次去重、并发更新、成功/失败/跳过统计、失败原因、目录持久化和异常后的状态清理；两个书架样式统一展示结果。实现位于 `lib/providers/book_provider.dart`、`lib/features/bookshelf/bookshelf_style1_page.dart` 和 `lib/features/bookshelf/bookshelf_style2_page.dart`，新增 2 个回归测试。
3. RuleSub 数据契约：补齐原版订阅实体的 `js`、`showRule`、`sourceUrl` 字段，保持 null、空字符串、旧 JSON、序列化往返和 `copyWith` 语义。实现位于 `lib/models/rule_sub.dart`，新增 5 个契约测试。
4. HTTP TTS 音频缓存：新增可注入缓存端口和文件缓存服务，缓存键区分配置、文本和速度；命中复用、相同请求合并、失败不落盘，并接入 `TtsService`。实现位于 `lib/domain/ports/http_tts_cache_port.dart`、`lib/services/http_tts_cache_service.dart`、`lib/services/http_tts_service.dart` 和 `lib/services/tts_service.dart`，新增 9 个定向测试。
5. RuleSub 管理页功能域收敛（涉及 Flutter app，无 Rust crate）：将 `RuleSubPage` 从 `lib/pages/rule_sub/` 迁入 `lib/features/sources/`，更新 MainShell/RSS 入口，保持订阅导入、自动更新和确认交互不变。
6. 音频播放页功能域收敛（涉及 Flutter app，无 Rust crate）：将 `AudioPlayPage` 从 `lib/pages/audio/` 迁入 `lib/features/reader/`，更新 Reader 入口；仅调整文件边界，不实现原版 Android 后台 `AudioPlayService`。
7. Explore 功能域收敛（涉及 Flutter app，无 Rust crate）：将 `lib/pages/explore/` 三个文件迁入 `lib/features/explore/`，更新 MainShell、SourcesPage 和测试入口，保持分类、校验、搜索列表行为不变。
8. CodeEdit 功能域收敛（涉及 Flutter app，无 Rust crate）：将编辑器 UI/格式化/高亮/主题/键盘工具栏迁入 `lib/features/code_edit/`；将 `CodeEditPrefs` 偏好服务归位到 `lib/services/`，消除功能域对基础设施的直接依赖，保持偏好键和会话日志语义不变。
9. Cache 功能域收敛（涉及 Flutter app，无 Rust crate）：将缓存管理、下载选择和下载辅助迁入 `lib/features/cache/`，生产入口显式传入 `ChapterContentCachePort`，消除功能域对文件缓存 adapter 的直接依赖，保持缓存行为不变。
10. HTTP TTS 缓存管理入口（涉及 Flutter app，无 Rust crate）：在设置页接入已有 `TtsService.clearHttpTtsCache()`，增加清理按钮和成功/失败提示；未改变真实 Android TTS 或缓存实现。

前两项功能新增 Flutter 测试共 5 个；本轮后续又新增 RuleSub 5 个、HTTP TTS 9 个；上一批功能域迁移未新增测试文件，本批在既有设置测试中新增 HTTP TTS 清理用例 1 个。未修改 `legado-main/`，未修改正文、目录顺序、分页、章节身份或第 3 条断行规则；未推进 Web/WASM/PWA、真实 Android TTS 或外部 WebDAV 验收。

## 验证结果

- `cargo check --workspace`：通过。
- `cargo test --workspace`：通过；`legado_engine` 单元测试 127 个通过，workspace 其他测试也全部通过，既有网络/WebDAV 条件测试按配置跳过。
- `cargo test -p legado_engine rule::js_engine::tests`：18 个 QuickJS 集成测试通过。
- `flutter analyze --no-pub`：`No issues found`。
- `flutter test --no-pub --concurrency=1`：540 个测试通过，3 个既有条件测试跳过。
- 本批 RuleSub 功能域与音频页定向回归：16/16 通过（RuleSub 11、TTS 播放模式 5）；新增测试文件 0 个。
- 本批 Explore、CodeEdit 与 SourceEditor 定向回归：19/19 通过（Explore 2、CodeEdit 13、规则完整 4）；新增测试文件 0 个。
- 本批 Cache 与设置页定向复核：19/19 通过；新增测试用例 1 个，新增测试文件 0 个。
- RuleSub 定向测试：6/6 通过。
- 书架批量更新定向测试：2/2 通过；相关 BookProvider 测试 11 个通过。
- RuleSub 与 HTTP TTS 定向测试：25/25 通过，其中本批新增 RuleSub 契约测试 5 个、HTTP TTS 测试 9 个。
- `scripts/check_architecture_boundaries.ps1`：`Architecture boundary check passed`。
- `git diff --check`：通过，仅有 Windows LF/CRLF 换行提示。

## 验证缺口

目标命令 `cargo test -p legado-js --features quickjs` 已按原样执行，但当前 `rust/Cargo.toml` workspace 只有 `legado_engine` 和 `legado-webdav`，不存在 `legado-js` 包，Cargo 返回 `cannot specify features for packages outside of workspace`。当前 QuickJS 实际由 `legado_engine` 的 `rquickjs` 依赖承载，已用 `cargo test -p legado_engine rule::js_engine::tests` 完成等价定向验证；未伪造 `legado-js` 通过结果。

HTTP TTS 缓存目前提供 `TtsService.clearHttpTtsCache()` 清理端口，尚未增加设置页面中的显式清理按钮；真实 Android TTS 和平台音频行为仍按计划暂停验收。

原版 `AudioPlayService.kt` 是 Android 后台 ExoPlayer、媒体会话、音频焦点、WakeLock/Wi-Fi 锁和播放进度服务；当前 Flutter 已有 `lib/features/reader/audio_play_page.dart`、`tts_service.dart` 和 HTTP TTS 文件缓存，但没有等价的后台音频服务。真实 Android TTS/平台音频验收按既定计划继续暂停，应另立平台任务，不在本轮伪装为已移植。

书源调试已有 `BookSourceDebugPort`、FRB adapter、`SourceDebugPage`、日志格式化器及定向测试，当前未发现本轮需要重复实现的缺口；后续只在原版行为对照发现差异时继续扩展。

## 当前工作树规则

- 本轮未自动 stage、commit 或 push。
- 后续 GitHub 提交信息使用中文说明。
- `legado-main/` 继续作为只读原版基线。
