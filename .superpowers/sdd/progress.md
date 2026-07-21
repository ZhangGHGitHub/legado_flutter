# SDD Progress — book source manage wave 3
Plan: docs/superpowers/plans/2026-07-21-book-source-manage-wave3.md
Branch: cursor/s1-reader-content-fixes
Started: 2026-07-21

Task 1: complete (4f838e1)

Task 2: complete (92f8cf2)

Task 3: complete (1757dcc)

Task 4: complete (0507ea0)

Task 5: complete (8f0799c)
All Wave 3 tasks: DONE

## Next wave

Plan: docs/superpowers/plans/2026-07-21-rust-flutter-legado-next-wave.md

- Wave 1: 阅读会话稳定性完成
- 已完成：正文内存缓存 key 增加 `bookId` 隔离
- 已完成：目录并发 key 增加 `sourceUrl` 隔离
- 已完成：缓存隔离、坏缓存删除、替换净化切换回归测试
- 已验证：Flutter Wave 1 回归 9/9；Rust Phase 3 对齐 13/13
- 已完成：正文预加载与目录并发 Provider 异步 harness
- 已完成：切书、换源、退出后的旧正文结果丢弃
- 已验证：Flutter `test/model test/providers test/services` 107 项通过
- Wave 2 Rust fixture、FFI 字段契约与网络策略已完成

## Wave 2 / Wave 3 核心进展

- 已完成：Rust `get_toc` / `get_content` 本地 HTTP fixture 与网络错误/响应大小测试
- 已完成：`BookSource` JS 能力契约、显式代理、非 2xx 和 8 MiB 响应上限
- 已完成：自动换源、缓存 TXT 导出/分享、全文搜索范围选择与全书联网搜索
- 已完成：HTTP TTS URL/POST 音频播放、简繁高频词匹配
- 待处理：RSS/有声/漫画 chrome、捐赠页及 RSS 调试页低优先级 UI 返工

