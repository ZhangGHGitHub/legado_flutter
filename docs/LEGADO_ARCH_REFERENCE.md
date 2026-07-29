# Legado 原项目架构参考

> 对照项目：[Jingshiro/legado](https://github.com/Jingshiro/legado)  
> 继承链：`gedoor/legado` → `Luoyacheng/legado` → `Jingshiro/legado`  
> 最后更新：2026-07-11

---

## 1. 项目定位

Legado 是 **高自由度阅读器**：不提供书籍资源，书源 JSON 定义搜索/发现/详情/目录/正文规则，引擎负责 HTTP + 规则解析 + JS 执行。

Jingshiro 分支在原有架构上新增：阅读记录、AI 助手、想法批注、阅读书票、WebDAV 增强、主题导出、Web API 扩展等。

---

## 2. 总体架构

Legado **不是** Clean Architecture / MVVM 分层，而是 **「规则引擎中心 + 功能模块分包」**：

```
app/src/main/java/io/legado/app/
├── api/          对外接口（ContentProvider + Web API Controller）
├── base/         Activity/Fragment 基类
├── constant/     常量、EventBus 事件
├── data/         Room 数据库、Entity、DAO
├── help/         HTTP、Cookie、缓存、配置、JS 扩展
├── model/        书源解析 + 阅读逻辑（核心）
├── service/      后台服务（缓存、朗读等）
├── ui/           全部界面
├── utils/        工具类
└── web/          内置 HTTP/WebSocket 服务
```

额外 Gradle 子模块：

| 模块 | 用途 |
|------|------|
| `modules/rhino` | Rhino JS 引擎封装 |
| `modules/web` | Web 管理端前端 (TypeScript) |
| `modules/book` | 书籍相关模块 |

---

## 3. 书源解析核心：四层分离

### 3.1 编排层 — `WebBook`

[`WebBook.kt`](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/model/webBook/WebBook.kt) 是网络书的 **唯一编排入口**：

| 方法 | 职责 |
|------|------|
| `searchBookAwait` | 搜索 |
| `exploreBookAwait` | 发现页 |
| `getBookInfoAwait` | 书籍详情 |
| `getChapterListAwait` | 目录（含 `preUpdateJs`） |
| `getContentAwait` | 正文（含分页、`webJs`） |
| `preciseSearchAwait` | 精准换源 |

固定模式：

```
AnalyzeUrl(构造请求) → getStrResponseAwait(发 HTTP) → loginCheckJs(可选)
→ BookList/BookInfo/BookChapterList/BookContent.analyze*(解析)
```

### 3.2 请求层 — `AnalyzeUrl`

[`AnalyzeUrl.kt`](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/model/analyzeRule/AnalyzeUrl.kt) 负责：

- 解析 Legado URL 格式：`url, {headers/body/method/charset}`
- 替换 `{{key}}`、`{{page}}`、`{{source.xxx}}`
- 执行 `<js>` / `@js:` URL 模板
- OkHttp 请求 + Cookie + 并发限速 + 代理 + WebView 回退
- 返回 `StrResponse`（body + 最终 URL + 重定向信息）

### 3.3 规则层 — `AnalyzeRule`

[`AnalyzeRule.kt`](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/model/analyzeRule/AnalyzeRule.kt) 组合：

| 子解析器 | 能力 |
|----------|------|
| `AnalyzeByJSoup` | CSS 选择器 `class.xxx@text@href` |
| `AnalyzeByXPath` | `@XPath:` |
| `AnalyzeByJSonPath` | `$.data.items[*]` |
| `AnalyzeByRegex` | `@Regex:`、`##替换##` |
| Rhino JS | `<js>`、`jsLib`、`cache` |

上下文：`RuleData` / `book` / `chapter` / `source` / `baseUrl` / `redirectUrl` / `result`

### 3.4 场景解析器 — `webBook` 子模块

| 类 | 职责 |
|----|------|
| `BookList.kt` | 搜索/发现列表 → `SearchBook[]` |
| `BookInfo.kt` | 详情页 → 更新 `Book` |
| `BookChapterList.kt` | 目录 → `BookChapter[]`（含 `nextTocUrl` 分页） |
| `BookContent.kt` | 正文 → `String`（含 `nextContentUrl` 分页） |
| `SearchModel.kt` | 多书源联合搜索调度 |

---

## 4. 完整数据流

### 4.1 搜索

```
SearchActivity/ViewModel
  → SearchModel (多书源协程并发)
    → WebBook.searchBookAwait(source, key)
      → AnalyzeUrl 解析 searchUrl
      → OkHttp GET/POST
      → BookList.analyzeBookList(body, ruleSearch)
        → AnalyzeRule.setContent(body) → 提取 name/author/url...
```

### 4.2 阅读

[`ReadBook.kt`](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/model/ReadBook.kt) 管理：

- 当前书/章节/前后章预加载
- `WebBook.getContentAwait` 拉正文
- `ContentProcessor` 替换净化
- `BookHelp` 本地缓存
- 阅读进度、预下载、朗读

```
ReadBookActivity → ReadBook → WebBook → BookContent → AnalyzeRule
                              → ContentProcessor → ReplaceRule
                              → BookHelp → book_cache/
```

---

## 5. 数据层

Room ORM（`data/`）：

- `BookSource` — 书源（嵌套 `ruleSearch/ruleToc/ruleContent/ruleBookInfo`）
- `Book` / `BookChapter` — 书籍与章节
- `ReplaceRule` — 替换净化
- `SearchBook` — 搜索结果
- Jingshiro：`DetailedReadRecord`、`ReadRecordShow` 等

规则 Entity（`entities/rule/`）：`SearchRule`、`TocRule`、`ContentRule`、`BookInfoRule`、`ExploreRule`…

---

## 6. HTTP / JS 基础设施

`help/http/`：

| 组件 | 作用 |
|------|------|
| `OkHttpUtils` / `HttpHelper` | 请求封装 |
| `CookieStore` / `CookieManager` | 书源级 Cookie |
| `ConcurrentRateLimiter` | `concurrentRate` 限速 |
| `BackstageWebView` | JS 渲染 / 反爬页面 |
| `StrResponse` | 统一响应对象 |

JS：Rhino + `JsExtensions.kt` + `SharedJsScope` + 书源 `jsLib`

---

## 7. UI 层

[`Jingshiro/legado` `ui/`](https://github.com/Jingshiro/legado/tree/main/app/src/main/java/io/legado/app/ui) 按功能域分包。**legado_flutter Phase F** 按此结构复刻：

```
ui/                          lib/pages/ (Phase F 目标)
├── main/                    main/main_shell.dart
│   ├── bookshelf/style1|2   bookshelf/bookshelf_style*_page.dart
│   ├── explore/             explore/explore_tab_page.dart
│   ├── rss/                 rss/rss_tab_page.dart
│   └── my/                  my/my_page.dart, read_record_page.dart
├── book/
│   ├── search/              search/search_page.dart
│   ├── explore/             explore/explore_list_page.dart
│   ├── info/                book/book_info_page.dart
│   ├── toc/                 book/toc_sheet.dart
│   ├── bookmark/            book/bookmark_page.dart (F4)
│   ├── changeSource/        book/change_source_page.dart (F3)
│   └── changeCover/         book/change_cover_page.dart (F3)
├── reader/                  reader/reader_page.dart, ai_chat_page.dart (F4)
├── config/                  config/config_page.dart, theme_config_page.dart
├── sources/                 sources/sources_page.dart
├── replace/                 replace/replace_page.dart
└── rss/                     rss/ (文章/源 F2+)
```

**主导航：** BottomNav + ViewPager 等价 → Flutter `NavigationBar` + `IndexedStack`（见 Phase F spec）。

---

## 8. Jingshiro 特有扩展

| 功能 | 位置 |
|------|------|
| 详细阅读记录 | `help/readrecord/`、`DetailedReadRecordDao` |
| AI 助手 | `ui/book/read/ai/` |
| 想法批注 | `BookThoughtController` |
| 阅读书票 | `BookplateDrawer.kt` |
| 主题导出 | `ThemeController` |
| WebDAV 增强 | `AppWebDav.kt`、`lib/webdav/` |
| Web API 扩展 | `api/controller/*` |

Web 服务：`web/HttpServer.kt`（nanohttpd）+ `modules/web/`（TS 前端）

---

## 9. legado_flutter 对齐映射

| Legado (Android) | legado_flutter 目标路径 | 状态 |
|------------------|---------------------------|------|
| `WebBook` | `lib/engine/web_book.dart` | ✅ Phase A |
| `AnalyzeUrl` | `lib/engine/analyze_url.dart` | ✅ Phase A |
| `AnalyzeRule` | `lib/services/analyze_rule.dart` | ✅ 已有 |
| `BookList` | `lib/engine/parsers/book_list.dart` | ✅ Phase A |
| `BookChapterList` | `lib/engine/parsers/book_chapter_list.dart` | ✅ Phase A |
| `BookContent` | `lib/engine/parsers/book_content.dart` | ✅ Phase A |
| `help/http/*` | `lib/engine/http/book_http_client.dart` | ✅ Phase A |
| `ReadBook` | `lib/model/read_book.dart` | ✅ Phase B |
| `BookHelp` | `lib/help/book_help.dart` | ✅ Phase B |
| `ContentProcessor` | `lib/help/content_processor.dart` | ✅ Phase B |
| Rust 引擎 | `rust/legado_engine/` | 搜索 only，待扩展 |

---

## 10. 重构阶段

### Phase A — 对齐核心引擎结构（当前）

```
lib/engine/
├── web_book.dart
├── analyze_url.dart
├── http/book_http_client.dart
└── parsers/
    ├── book_list.dart
    ├── book_chapter_list.dart
    └── book_content.dart
```

`BookSourceService` 退化为薄门面，委托 `WebBook`。

### Phase B — 阅读会话（当前 ✅）

```
lib/model/read_book.dart       ← ReadBook.kt 阅读会话 + 预加载
lib/help/book_help.dart        ← BookHelp.kt 章节文件缓存
lib/help/content_processor.dart ← ContentProcessor 替换净化
```

`BookProvider` 委托 `ReadBook` 加载正文；`ReplaceProvider` 同步规则到 `ContentProcessor`。

### Phase C — Rust WebBook 接口（当前 ✅ v0.3.0）

```rust
search() / explore() / get_book_info() / get_toc() / get_content()  // async FRB
```

```
rust/legado_engine/src/api/
  search.rs / explore.rs / book_info.rs / toc.rs / content.rs
rust/legado_engine/src/rule/
  html_search.rs / html_explore.rs / html_book_info.rs / html_toc.rs / html_content.rs
```

- HTTP：`reqwest` async + `tokio`（非阻塞 UI）
- JS：`js_engine`（QuickJS）执行 `<js>` / `@js:` / `jsLib` / `cache`
- **loginCheckJs（EN-09）**：`fetch_with_source_meta` 成功（及失败）后执行。`result`=StrResponse；`java` 绑定 `getHeaderMap` / `initUrl` / `getStrResponse`；`source.putLoginHeader` / `getLoginHeader` / `getHeaderMap(true)` 写入 Rust 登录头缓存并经 bridge 回写 `SourceLoginPrefs`。失败时若脚本返回可用 body 可采纳。`java.startBrowserAwait` 通过串行 FRB Dart callback 打开 Flutter 可见 WebView；QuickJS 在专用阻塞线程等待，返回后继续同一脚本上下文，并支持 2/3/4 参数、默认重新抓取、HTML/DOM、最终 URL 和 Cookie 同步。
- **preUpdateJs（EN-10）**：`get_toc` 入口在拉目录前执行 `ruleToc.preUpdateJs`；失败打日志不阻断

### Phase D — Jingshiro 增强

```
legado-ai/ / legado-webdav/ / legado-api/ / read_record/
```

---

## 11. 关键参考文件

| 优先级 | Legado 文件 |
|--------|-------------|
| P0 | `model/webBook/WebBook.kt` |
| P0 | `model/analyzeRule/AnalyzeRule.kt` |
| P0 | `model/analyzeRule/AnalyzeUrl.kt` |
| P0 | `model/webBook/BookList.kt` |
| P0 | `model/webBook/BookChapterList.kt` |
| P0 | `model/webBook/BookContent.kt` |
| P1 | `help/http/*` |
| P1 | `help/JsExtensions.kt` |
| P1 | `model/ReadBook.kt` |
| P1 | `help/book/BookHelp.kt` |
| P2 | `data/entities/rule/*` |
| P3 | Jingshiro AI/ReadRecord/Theme |
