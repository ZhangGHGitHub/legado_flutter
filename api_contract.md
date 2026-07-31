# Legado CoreApi 契约（第一版）

状态：草案，作为 Flutter Mock 与 Rust/FRB Real 实现的共同输入。

本文只冻结书架和搜索两条首批链路。新增字段必须先更新本文、Mock、Rust DTO 映射和回归测试。

## 错误

目标错误类型：

```text
AppError = Network | Parse | Database | JsExecution | Validation | Unsupported | Cancelled | Unknown
```

当前已迁移的 Rust FFI 入口使用结构化 `AppError`；尚未迁移的入口仍可能返回 `String`，由后续批次逐条收敛。Real adapter 必须集中负责过渡期错误映射，页面不得自行解析错误文本。

已完成的首批错误边界包括书源主链、调试入口、数据库入口、阅读记录/备份入口、书籍详情/字典入口、笔记/书签入口，以及统一 HTTP 文本和二进制请求入口。错误原文保留在对应 `AppError` 变体中；未迁移入口仍按后续批次处理。

## 模型

### Book

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | `String` | 书籍身份；不得因 UI 显示名变化而改变 |
| `name` | `String` | 书名 |
| `author` | `String` | 作者 |
| `coverUrl` | `String` | 封面 URL，可为空 |
| `type` | `String` | `online`、`local` 或原版类型值 |
| `progress` | `double` | 阅读进度 |
| `currentChapter` | `String?` | 当前章节显示名 |
| `lastChapter` | `String?` | 最新章节显示名 |
| `totalChapterNum` | `int` | 章节总数 |
| `durChapterIndex` | `int` | 当前章节索引 |
| `currentPageIndex` | `int` | 章节内 UTF-16 阅读位置对应的页索引 |
| `readConfig` | `Map<String, dynamic>` | 包含 `reverseToc` 及扩展字段 |
| `isFavorite` | `bool` | 收藏状态 |
| `sourceUrl` | `String` | 书籍来源 URL/本地路径 |
| `tocUrl` | `String` | 目录 URL |
| `description` | `String` | 简介 |
| `bookSourceUrl` | `String` | 书源 URL |
| `group` | `String` | 书架分组 |
| `readIteration` | `int` | 重读次数 |

### SearchResultItem

| 字段 | 类型 | 说明 |
|---|---|---|
| `name` | `String` | 书名 |
| `author` | `String` | 作者 |
| `bookUrl` | `String` | 详情 URL |
| `coverUrl` | `String` | 封面 URL，可为空 |
| `kind` | `String` | 类型 |
| `note` | `String` | 备注 |

## CoreApi

```dart
abstract interface class CoreApi {
  Future<List<Book>> getBookshelf();

  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  });
}
```

当前实现映射：

| CoreApi | 当前 Rust/Flutter 入口 | 目标适配层 |
|---|---|---|
| `getBookshelf` | `db_get_books` -> `BookRepository` | `RealCoreApi` |
| `searchBooks` | `search(sourceJson, keyword)` -> `BookSourceService` | `RealCoreApi` |

## Mock 约束

`MockCoreApi` 必须：

- 返回与 Real API 相同的字段和空值语义。
- 覆盖空书架、单书、多书、缺封面、中文作者、错误和加载中状态。
- 不依赖 Rust、SQLite、网络或平台插件。
- 被 Widget 测试和页面开发使用，页面不得根据 Mock/Real 分支编写不同业务逻辑。

## 变更门禁

1. 修改模型字段：先更新本文和 Dart/Rust 映射测试。
2. 修改错误：先更新 `AppError`、Dart 映射和 Mock 错误样本。
3. 修改函数签名：必须同时更新 Real adapter、Mock adapter、调用者和契约测试。
4. 契约测试通过后，才允许迁移下一条链路。

## 网络 HTTP 边界（2026-08-01）

| Rust 入口 | 成功输出 | 错误分类 |
|---|---|---|
| `fetch_public_text` | `String` | `Network` |
| `send_application_http_request` | `ApplicationHttpResponseDto` | `Validation`、`Parse`、`Network` |
| `send_application_binary_http_request` | `ApplicationBinaryHttpResponseDto` | `Validation`、`Network` |
| `http_fetch` | `String` | `Parse`、`Network` |
| `set_network_config`、`set_source_cookie`、`clear_source_cookie`、`source_cookie_domain` | `void`/`String` | `Validation` |
| `clear_engine_cache`、`start_http_request_trace` | `void` | `Unknown` 或 `JsExecution` |

## 书籍详情、字典、笔记与书签错误边界（2026-08-01）

| Rust 入口 | 成功输出 | 错误分类 |
|---|---|---|
| `get_book_info` | `BookInfoItem` | `Parse`、`Network`、`JsExecution` |
| `query_dict_rule` | `String` | `Validation`、`Parse`、`Network`、`JsExecution`、`Unsupported` |
| `upsert_note`、`delete_note`、`export_notes_markdown` | `void`/`String` | `Database` |
| `list_notes` | `Vec<NoteDto>` | `Database`、`Parse` |
| `upsert_bookmark`、`delete_bookmark` | `void` | `Database` |
| `list_bookmarks` | `Vec<BookmarkDto>` | `Database`、`Parse` |

这些入口保留原有成功输出、CRUD、排序、Markdown、UTF-16 位置和错误原文语义。目录/校验内部仍通过 `AppError::into_legacy` 过渡到旧 `String` 链，避免改变既有错误文本；FRB 公开入口使用结构化 `AppError`。浏览器宿主和其余公开 `Result<T, String>` 入口不在本批范围内。

输入校验、文本解码、SSRF、响应大小和传输错误均保留原错误文本；本批不改变请求方法、请求头、Cookie、超时、大小限制或非 2xx 响应行为。

## 本地书籍与 RSS 错误边界（2026-08-01）

| Rust 入口 | 成功输出 | 错误分类 |
|---|---|---|
| `parse_epub` | `LocalBookInfo` | `Parse` |
| `parse_remote_archive_book_files` | `Vec<RemoteArchiveBookFile>` | `Parse` |
| `get_rss_articles` | `RssArticlesResult` | `Network`、`Parse` |
| `get_rss_content` | `String` | `Network`、`Parse` |

EPUB/ZIP 保留解析、大小限制、路径安全、文件筛选和成功结果；RSS 保留请求参数、排序、分页、文章字段和正文解析。所有分类保留 Rust 原始错误文本；Dart FRB 适配层不使用 `AppError.toString()` 作为用户可见消息。此节不表示 RSS CoreApi、浏览器宿主或其它公开 FFI 的错误边界已经全部完成。

## JavaScript 执行错误边界（2026-08-01）

| Rust 入口 | 成功输出 | 错误分类 |
|---|---|---|
| `eval_js` | `String` | `JsExecution` |

`eval_js` 保留脚本成功结果、错误原文、纯 QuickJS 5 秒执行中断和 `script/jsLib` 单项 256 KiB 输入上限。该契约不覆盖宿主 `java.ajax`、`getStrResponse`、WebView 阻塞、取消或其它公开字符串错误入口。
