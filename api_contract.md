# Legado CoreApi 契约（第一版）

状态：草案，作为 Flutter Mock 与 Rust/FRB Real 实现的共同输入。

本文只冻结书架和搜索两条首批链路。新增字段必须先更新本文、Mock、Rust DTO 映射和回归测试。

## 错误

目标错误类型：

```text
AppError = Network | Parse | Database | JsExecution | Validation | Unsupported | Cancelled
```

当前 Rust FFI 仍以 `String` 返回错误；在 AppError 迁移完成前，Real adapter 必须集中负责字符串到分类错误的映射，页面不得自行解析错误文本。

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
