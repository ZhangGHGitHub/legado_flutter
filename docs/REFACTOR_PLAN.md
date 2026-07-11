# Legado Flutter → Rust + Flutter 多平台重构方案

> 基于 [Jingshiro/legado](https://github.com/Jingshiro/legado) 功能对齐  
> 目标平台：Android / iOS / Windows / macOS / Linux / Web (WASM)  
> 最后更新：2026-07-11  
> 架构参考：[`docs/LEGADO_ARCH_REFERENCE.md`](LEGADO_ARCH_REFERENCE.md)

---

## 项目现状 (2026-07)

| 维度 | 当前状态 |
|------|---------|
| **Flutter** | 3.x + Dart 3.11.5，基础 UI 完成（书架/搜索/书源管理/阅读器/设置） |
| **Dart 引擎分层** | Phase A ✅ `lib/engine/` + Phase B ✅ ReadBook/BookHelp/ContentProcessor |
| **Rust 引擎** | v0.3.0：search/explore/get_book_info/get_toc/get_content (async FRB)，JS 书源仍回退 Dart |
| **Dart 规则引擎** | CSS / XPath（基础）/ JSONPath / QuickJS / Legado 规则 ✅ |
| **平台支持** | Android ✅ / Windows ✅ / Web（配置但未测试）/ iOS ❌ / macOS ❌ / Linux ❌ |
| **Jingshiro 功能** | AI 助手 / 阅读记录 / 想法笔记 / 阅读小票 / WebDAV / Web API / 主题导出 ❌ |

---

## 总体架构

```
┌──────────────────────────────────────────────────────────────┐
│                     Flutter UI (Dart)                         │
│                    Provider / ChangeNotifier                  │
│              ~~~~ async FFI calls ~~~~                        │
├──────────────────────────┬───────────────────────────────────┤
│    flutter_rust_bridge   │         wasm-pack                 │
│    (Android/iOS/Win/     │         (Web)                     │
│     Mac/Linux)           │                                   │
│    #[frb] async fn       │    #[wasm_bindgen] async fn       │
├──────────────────────────┴───────────────────────────────────┤
│                    Rust Core                                  │
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ legado-core │  │legado-engine│  │   legado-bridge     │  │
│  │ types/error │  │             │  │   (FRB DTO 薄壳)    │  │
│  │ + trait     │  │ • rule/     │  │                     │  │
│  │             │  │ • http/     │  │ search()            │  │
│  │             │  │ • js/       │  │ get_toc()           │  │
│  │             │  │ • db/       │  │ get_content()       │  │
│  │             │  │             │  │ get_book_info()     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                               │
│  内部 (不导出 FRB，使用扁平 DTO 桥接):                         │
│  ┌──────────┐ ┌──────────┐ ┌──────┐ ┌─────────┐            │
│  │ XPath    │ │JSONPath  │ │JsEng │ │rusqlite │            │
│  │ Parser   │ │(Legado)  │ │(rqjs)│ │(bundled)│            │
│  └──────────┘ └──────────┘ └──────┘ └─────────┘            │
└──────────────────────────────────────────────────────────────┘
```

**核心原则**：
- Rust 负责全部业务逻辑，Flutter 纯 UI，零 Dart 端规则引擎
- **全部 FRB 调用为 async**，不阻塞 UI 线程
- Rust 内部使用复杂类型（递归 enum / trait object），**FRB 导出层使用扁平 DTO**
- 数据库统一使用 `rusqlite(bundled)` 全平台编译（含 WASM）
- JS 引擎统一使用 rquickjs（QuickJS），Web 端编译为 WASM

---

## 关键架构决策

### 1. async FFI（非阻塞）

**所有 FRB 调用标记为 `#[frb]` (async)，禁止 `#[frb(sync)]`**。

原因：HTTP 请求可能耗时 1-30 秒，同步调用会冻结 Flutter UI 线程。

```rust
// ✅ 正确
#[frb]
pub async fn search(source_json: String, keyword: String) -> Result<Vec<SearchItem>, String> { ... }

// ❌ 禁止
#[frb(sync)]
pub fn search(source_json: String, keyword: String) -> Result<Vec<SearchItem>, String> { ... }
```

```toml
# 依赖变化
[dependencies]
tokio = { version = "1", features = ["rt-multi-thread", "macros"] }
reqwest = { version = "0.12", features = ["gzip", "deflate", "brotli", "rustls-tls"] }
# 去掉 reqwest "blocking" feature
# 去掉 tokio "sync" → 改为 tokio::sync::Mutex
```

### 2. 渐进式 Crate 拆分

**Phase 0-1：3 个 crate**
```
rust/
├── legado-core/       # 核心类型 + LegadoError + 内部 trait
├── legado-engine/     # 所有业务逻辑（rule/http/js/db）
└── legado-bridge/     # FRB 导出薄壳（类型映射 + 扁平 DTO）
```

**Phase 4 按需新增**（这些是独立模块，不需要提前创建）：
```
rust/
├── legado-ai/         # AI 助手（LLM client + tools）
├── legado-webdav/     # WebDAV 客户端
└── legado-api/        # 内置 Web API 服务器（axum）
```

好处：减少初始编译时间、简化依赖管理、Phase 0 更快启动。

### 3. 统一数据库后端

**rusqlite(bundled) 全平台**：`bundled` feature 将 SQLite C 源码编译到目标平台（含 WASM）。

```toml
# legado-engine/Cargo.toml
[dependencies]
rusqlite = { version = "0.32", features = ["bundled"] }
```

取消原方案中 rusqlite + IndexedDB 双后端设计，好处：
- 一套 SQL 迁移脚本，全平台共用
- Dart 端不再直接操作数据库（消除 `database_helper.dart` 的直接 SQLite 调用）
- 数据库迁移由 Rust 统一管理

FRB 导出的 DB API：
```rust
#[frb] pub async fn db_get_books() -> Result<Vec<Book>, String>;
#[frb] pub async fn db_add_book(book: Book) -> Result<(), String>;
#[frb] pub async fn db_get_sources() -> Result<Vec<BookSource>, String>;
#[frb] pub async fn db_add_source(source: BookSource) -> Result<(), String>;
// ...
```

### 4. 统一 JS 引擎

**rquickjs 全平台（含 WASM）**：QuickJS 的 Rust 绑定，ES2020 兼容。

| 平台 | JS 引擎 | 方案 |
|------|---------|------|
| 原生 (Android/iOS/Win/Mac/Linux) | rquickjs | QuickJS native 编译 |
| Web (WASM) | rquickjs | QuickJS 编译为 WASM（增加约 150KB） |

好处：
- **JS 执行行为完全一致**（同一引擎），书源兼容性只需验证一次
- **一套 JS standard lib 注入代码**
- 体积可通过 `wasm-opt` 压缩

退化方案（如果 WASM 体积不可接受）：
```rust
pub trait JsEngine: Send {
    fn evaluate(&self, code: &str, vars: &HashMap<String, Value>) -> Result<String, LegadoError>;
}

// #[cfg(not(target_arch = "wasm32"))] → rquickjs
// #[cfg(target_arch = "wasm32")]      → 浏览器 eval (via wasm-bindgen callback)
```

### 5. FRB DTO 层（扁平类型映射）

FRB v2 不支持：泛型、`Box<dyn Trait>`、递归 enum。

**原则**：Rust 内部使用复杂类型，FRB 导出层只暴露扁平 struct/enum。

```rust
// ❌ 内部复杂类型 — 不导出
pub(crate) enum Predicate {
    And(Box<Predicate>, Box<Predicate>),  // 递归，FRB 不支持
    Or(Box<Predicate>, Box<Predicate>),
    // ...
}

// ✅ FRB DTO — 扁平结构
#[frb]
pub struct SearchItem {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub book_url: String,
    pub kind: String,
    pub note: String,
}
```

### 6. async 限速器

```rust
use tokio::sync::Mutex;
use tokio::time::sleep;

static RATE_LIMITER: Lazy<Mutex<RateLimiter>> = Lazy::new(|| Mutex::new(RateLimiter::new()));

pub async fn wait_if_needed(source_url: &str) -> Result<(), String> {
    let mut limiter = RATE_LIMITER.lock().await;
    let wait_ms = limiter.calculate_wait(source_url);
    if wait_ms > 0 {
        sleep(Duration::from_millis(wait_ms)).await;  // 非阻塞
    }
    limiter.record_request(source_url);
    Ok(())
}
```

---

## 平台差异矩阵

| 平台 | FFI 方案 | Rust target | JS 引擎 | HTTP 客户端 | 数据库 |
|------|---------|-------------|---------|------------|--------|
| Android | flutter_rust_bridge (async) | `aarch64-linux-android` 等 | rquickjs (native) | reqwest (async) | rusqlite(bundled) |
| iOS | flutter_rust_bridge (async) | `aarch64-apple-ios` | rquickjs (native) | reqwest (async) | rusqlite(bundled) |
| Windows | flutter_rust_bridge (async) | `x86_64-pc-windows-msvc` | rquickjs (native) | reqwest (async) | rusqlite(bundled) |
| macOS | flutter_rust_bridge (async) | `aarch64-apple-darwin` | rquickjs (native) | reqwest (async) | rusqlite(bundled) |
| Linux | flutter_rust_bridge (async) | `x86_64-unknown-linux-gnu` | rquickjs (native) | reqwest (async) | rusqlite(bundled) |
| Web | wasm-pack + dart:js | `wasm32-unknown-unknown` | rquickjs (WASM) | web_sys::fetch (async) | rusqlite(bundled) (WASM) |

---

## 功能优先级分层

### 🔴 P0：核心阅读链路

书源引擎、书源管理、搜索与发现、书籍详情、目录获取、正文阅读、书架管理

### 🟡 P1：体验增强

本地书籍、替换规则、阅读记录、书源调试器、Web API、MD3 主题

### 🟢 P2：增值功能（最后实现）

AI 助手、想法笔记、阅读小票、备份与恢复、主题设置、其他设置、Legado Skill

---

## 开发时间线总览

| Phase | 内容 | 工期 | 里程碑 |
|-------|------|:---:|--------|
| **0** | 基础设施 | 2 周 | FRB async codegen / iOS build / WASM build / CI |
| **1.1** | 规则引擎完整化 | 3-4 周 | XPath/JSONPath/JS(rquickjs) 全部就位 |
| **1.2** | Rust 业务 API | 2 周 | search/get_toc/get_content/get_book_info (async) |
| **1.3** | Flutter UI 核心 | 2 周 | 书架/搜索/阅读器/发现/iOS+Web 适配 |
| **2** | 体验增强 | 3-4 周 | 本地书籍/阅读记录/调试器/Web API/MD3 |
| **3** | 去 Dart + 发布 | 3-4 周 | 移除 Dart 引擎 → 全平台上线 |
| **4** | 增值功能 | 4-6 周 | AI/笔记/小票/备份/主题/Skill |
| **总计** | | **19-24 周** | |

---

## Phase 0：基础设施就位（2 周）

### 0.1 FRB Codegen 完成（async 模式）

**现状**：`lib/bridge/legado_engine_bridge.dart` 中所有 Rust 调用为 `throw UnsupportedError` 占位。现有 Rust API 使用 `#[frb(sync)]`。

**变更**：全部改为 `#[frb]` async，HTTP 层从 `reqwest::blocking` 迁移到 `reqwest` async + tokio。

```bash
# 1. 更新 Cargo.toml（去掉 "blocking"，加 tokio）
# 2. 修改 api/mod.rs 和 api/search.rs 的 #[frb(sync)] → #[frb]
# 3. 修改 http/client.rs 从 blocking 改为 async
# 4. 修改 http/rate_limit.rs 从 thread::sleep 改为 tokio::time::sleep

# 5. 运行 codegen
cargo install flutter_rust_bridge_codegen --version 2.11.1
flutter_rust_bridge_codegen integrate --rust-crate-dir rust/legado_engine
flutter_rust_bridge_codegen generate
flutter pub get
```

**生成产物**：
- `lib/src/rust/frb_generated.dart` — FRB 运行时
- `lib/src/rust/frb_generated.io.dart` — 原生平台 FFI
- `lib/src/rust/api/` — Rust API 的 Dart 绑定（async 方法）

**桥接层改造**：
```dart
// lib/bridge/legado_engine_bridge.dart
import '../src/rust/frb_generated.dart';
import '../src/rust/api/mod.dart' as rust_api;

static Future<void> _initRustLib() async {
  await RustLib.init();
}

// 所有调用变为 async
static Future<List<Map<String, String>>> search(BookSource source, String keyword) async {
  final sourceJson = source.rawSourceJson.isNotEmpty
      ? source.rawSourceJson
      : jsonEncode(source.toJson());
  final items = await rust_api.search(sourceJson: sourceJson, keyword: keyword);
  return items.map((i) => {...}).toList();
}
```

**验证**：Windows 端 `await LegadoEngineBridge.search()` 不阻塞 UI

### 0.2 Rust 项目结构（3 crate workspace）

```
rust/
├── Cargo.toml                      # [workspace] members = ["legado-core", "legado-engine", "legado-bridge"]
├── legado-core/
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── types.rs                # Book, Chapter, BookSource, SearchItem 等
│       └── error.rs                # LegadoError enum
├── legado-engine/
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs
│       ├── rule/                   # 规则引擎
│       │   ├── mod.rs
│       │   ├── engine.rs
│       │   ├── css.rs
│       │   ├── xpath.rs
│       │   ├── jsonpath.rs
│       │   ├── js_engine.rs
│       │   ├── js_lib.rs
│       │   ├── prefix.rs
│       │   └── regex_chain.rs
│       ├── http/                   # HTTP 层（async）
│       │   ├── mod.rs
│       │   ├── client.rs           # reqwest async（去掉 blocking）
│       │   ├── cookie.rs
│       │   ├── charset.rs
│       │   └── rate_limit.rs       # tokio::sync::Mutex + tokio::time::sleep
│       └── db/                     # 数据库（rusqlite bundled）
│           ├── mod.rs
│           ├── models.rs
│           └── migrations.rs
└── legado-bridge/
    ├── Cargo.toml
    └── src/
        ├── lib.rs
        └── api.rs                  # 所有 #[frb] async fn（扁平 DTO）
```

**验证**：`cargo build --workspace` 编译通过

### 0.3 iOS Target 编译链

```bash
rustup target add aarch64-apple-ios
rustup target add aarch64-apple-ios-sim
flutter_rust_bridge_codegen generate
```

**Xcode 配置**：
- 引入 `legado_engine.xcframework`
- Info.plist 添加 ATS 例外：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 0.4 WASM 编译链

```bash
rustup target add wasm32-unknown-unknown
cargo install wasm-pack

cd rust/legado-bridge
# WASM 需要单独的导出 crate，或使用 cfg 条件编译
wasm-pack build --target web --out-dir ../../web/pkg
```

**产出物**：`web/pkg/legado_wasm.js` + `legado_wasm_bg.wasm`

**Flutter Web 桥接**：
```dart
// lib/bridge/wasm_engine_bridge.dart
import 'dart:js_interop';

class WasmEngineBridge {
  static Future<void> init() async {
    final module = await WasmModule.load('assets/legado_wasm_bg.wasm');
    // ... 导出函数绑定
  }

  static Future<List<Map<String, String>>> search(String sourceJson, String keyword) async {
    // 通过 JS interop 调用 WASM 导出的 search 函数
  }
}
```

### 0.5 CI/CD

GitHub Actions 多平台矩阵构建（Android / iOS / Web / Windows / macOS / Linux）。

### 0.6 测试框架

**Rust**：单元测试 + 集成测试 + criterion benchmarks  
**Flutter**：Widget tests + Integration tests  
**测试数据**：真实 Legado 书源 JSON 和 HTML 样本作为 fixtures

---

## Phase 1.1：Rust 规则引擎完整化（3-4 周）

### 1.1.1 XPath 1.0 完整实现

文件：`rust/legado-engine/src/rule/xpath.rs`

**当前**：Dart 端基础 XPath（child/descendant 轴 + 4 种谓语）  
**目标**：13 种轴 + 15 种谓语类型

```rust
pub struct XPath { steps: Vec<Step>; }

struct Step {
    axis: Axis,
    node_test: NodeTest,
    predicates: Vec<Predicate>,
}

// 13 种轴
enum Axis {
    Child, Descendant, Parent, Ancestor, AncestorOrSelf,
    DescendantOrSelf, Following, FollowingSibling, Preceding,
    PrecedingSibling, Self_, Attribute, Namespace,
}

// 节点测试
enum NodeTest {
    Name(String), Wildcard, Text, Node, Comment,
}

// 谓语（内部复杂类型，不导出 FRB）
pub(crate) enum Predicate {
    Position(usize),         // [n]
    Last,                    // [last()]
    PositionGt(usize),       // [position()>n]
    AttrEq(String, String),  // [@attr="val"]
    AttrExists(String),      // [@attr]
    Contains(String, String),// [contains(@attr, "val")]
    StartsWith(String, String), // [starts-with()]
    Not(Box<Predicate>),     // [not(...)]
    And(Box<Predicate>, Box<Predicate>),
    Or(Box<Predicate>, Box<Predicate>),
    NormalizeSpace,
    StringLength(usize),
    Substring(String, usize, Option<usize>),
    HasChild(String),
    Count(Box<XPath>),
    Sum(Box<XPath>),
}
```

**解析器**：递归下降，完整 XPath 1.0 语法  
**执行器**：基于 `scraper::ElementRef` 树遍历

### 1.1.2 JSONPath 增强

文件：`rust/legado-engine/src/rule/jsonpath.rs`

Legado 专有语法扩展：
- 多路径合并：`$.data[*].name + $.data[*].author`
- 模板变量：`{{name}}`
- 多字段选择：`$.data[*].{name, author}`
- 过滤器：`[?(@.price > 10)]`

```rust
pub struct LegadoJsonPath;

impl LegadoJsonPath {
    pub fn resolve(root: &Value, path: &str) -> Result<Vec<Value>, LegadoError>;
    pub fn resolve_template(template: &str, item: &Value) -> String;
    pub fn resolve_multi(root: &Value, paths: &[&str]) -> Result<Vec<Value>, LegadoError>;
    pub fn resolve_multi_field(root: &Value, base: &str, fields: &[&str]) -> Result<Vec<Value>, LegadoError>;
}
```

### 1.1.3 规则前缀系统

文件：`rust/legado-engine/src/rule/prefix.rs`

| 输入 | 识别为 | 引擎 |
|------|--------|------|
| `@@css_selector` | 默认规则 | CSS |
| `@XPath://div` | XPath | XPath |
| `@Json:$.data` | JSONPath | JSONPath |
| `@js:code` | JavaScript | JS |
| `:regex` | 正则 | Regex |
| `<js>code</js>` | JS 块 | JS |
| `//div[@class]` | 自动 XPath | XPath |
| `$.data[*]` | 自动 JSONPath | JSONPath |
| `tag.class#id` | 默认 CSS | CSS |

**操作符**：
- `||` — OR 链：第一个非空结果返回
- `&&` — AND 链：所有非空结果拼接
- `%%` — XOR 链：互斥匹配

**正则链**：`##pattern##replacement##` 格式

### 1.1.4 JS 引擎集成（rquickjs，全平台统一）

文件：`rust/legado-engine/src/rule/js_engine.rs`

```toml
[dependencies]
rquickjs = { version = "0.8", features = ["full-async", "rust-alloc"] }
```

**注入的 `java` 对象方法**：

| 方法 | 说明 |
|------|------|
| `java.ajax(url, options)` | HTTP 请求（调用 legado-engine http 模块） |
| `java.get(url)` | GET 请求 |
| `java.post(url, body)` | POST 请求 |
| `java.connect(url)` | 重定向拦截（返回最终 URL + body） |
| `java.md5Encode(str)` | MD5 哈希 |
| `java.base64Decode(str)` | Base64 解码 |
| `java.base64Encode(str)` | Base64 编码 |
| `java.createSymmetricCrypto(type, key, iv)` | 对称加密（AES/DES） |
| `java.encodeURI(str)` | URL 编码 |
| `java.randomUUID()` | 随机 UUID |
| `java.log(msg)` | 调试日志 |
| `java.toast(msg)` | Toast（通过 FRB callback 到 Flutter） |
| `java.startBrowser(url)` | 打开浏览器（通过 FRB callback 到 Flutter） |
| `java.webView(url, js)` | WebView 渲染（通过 FRB callback 到 Flutter） |
| `java.queryTTF(path)` | 查询字体 |
| `java.replaceFont(text, font)` | 替换字体 |

**注入的 `cache` 对象**：

| 方法 | 说明 |
|------|------|
| `cache.put(key, value)` | 写入内存 HashMap |
| `cache.get(key)` | 读取 |
| `cache.getFromMemory(key)` | 仅内存读取 |
| `cache.putFile(key, content)` | 写入 SQLite |
| `cache.delete(key)` | 删除 |

**注入的全局变量**：`baseUrl`, `result`, `book`, `source`, `chapter`, `cookie`, `src`

### 1.1.5 Legado JS 标准库

文件：`rust/legado-engine/src/rule/js_lib.rs`

将 Dart 端 `js_evaluator.dart` 的 `_legadoStdLib` 和 Jsoup polyfill 迁移为 JS 字符串，在 rquickjs 初始化时注入。

### 1.1.6 Rust HTTP 层增强（async）

文件：`rust/legado-engine/src/http/`

- reqwest 从 blocking 改为 async
- URL JS 参数：请求前执行 JS 设置自定义头
- bodyJs 参数：二次处理响应内容
- dnsIp 参数：强制 DNS 解析
- socks5/http 代理：reqwest proxy 配置
- 重定向拦截：`java.connect()` → 返回最终 URL + body

---

## Phase 1.2：Rust 业务 API（2 周）

### 1.2.1 search() — 搜索书籍

```rust
#[frb]
pub async fn search(source_json: String, keyword: String) -> Result<Vec<SearchItem>, String>;
```

流程：解析书源 → 处理 @js:/<js> URL → async 限速 → async HTTP → JSON/HTML 分支解析 → 返回

### 1.2.2 get_book_info() — 书籍详情

```rust
#[frb]
pub async fn get_book_info(source_json: String, book_url: String) -> Result<BookInfo, String>;

// FRB DTO（扁平）
#[frb]
pub struct BookInfo {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub kind: String,
    pub intro: String,
    pub last_chapter: String,
    pub word_count: String,
    pub status: String,
    pub toc_url: String,
}
```

### 1.2.3 get_toc() — 目录获取

```rust
#[frb]
pub async fn get_toc(source_json: String, toc_url: String) -> Result<Vec<ChapterItem>, String>;
```

支持：HTML 分页抓取、JSON API 分页、JS 模板 URL、最多 50 页、URL 去重

### 1.2.4 get_content() — 正文获取

```rust
#[frb]
pub async fn get_content(
    source_json: String,
    chapter_url: String,
    content_url_rule: String,
) -> Result<String, String>;
```

支持：正文提取、替换规则、分页合并（最多 20 页）、bodyJs 处理、<js> 清洗

### 1.2.5 validate_source() — 书源校验

```rust
#[frb]
pub async fn validate_source(source_json: String) -> Result<SourceValidation, String>;

#[frb]
pub struct SourceValidation {
    pub search_ok: bool,
    pub discovery_ok: bool,
    pub toc_ok: bool,
    pub content_ok: bool,
    pub search_time_ms: u64,
    pub errors: Vec<String>,
}
```

---

## Phase 1.3：Flutter UI 核心页面（2 周）

> **UI 复刻 Jingshiro/Legado（Phase F v2）：**  
> - 设计规格：`docs/superpowers/specs/2026-07-11-phase-f-ui-design.md`  
> - 实施计划：`docs/superpowers/plans/2026-07-11-phase-f-ui-implementation.md`  
> - 对标：[Jingshiro/legado](https://github.com/Jingshiro/legado) — 书架/发现/订阅/我的 + 独立搜索 + MyFragment 完整菜单  
> - 子阶段：**F0** 主框架 → **F1** 阅读链路 → **F2** 双布局 → **F3–F4** Jingshiro 增量 UI

### 1.3.1 书架页增强

| 功能 | 实现 |
|------|------|
| 网格/列表切换 | `SliverGrid` + `SliverList`，偏好持久化 |
| 读完/N刷标签 | Book 模型新增 `readStatus` 字段 |
| 拖拽排序 | `ReorderableListView` |
| 批量操作 | 长按多选 → 删除/移动分组 |

### 1.3.2 书源管理页增强

| 功能 | 实现 |
|------|------|
| 绿点/红点 | 有发现且启用 → 绿；有发现未启用 → 红 |
| 批量操作 | 启用/禁用/分组/校验 |
| 书源校验 | 调用 Rust `validate_source()` (async) |
| 书源分享 | 选中 → JSON → 剪贴板/文件 |

### 1.3.3 搜索页增强

| 功能 | 实现 |
|------|------|
| 跨源聚合 | 多源并发搜索，去重合并 |
| 搜索历史 | 最近 20 条持久化 |
| 结果缓存 | 内存缓存 5 分钟 |
| 封面预加载 | `CachedNetworkImage` |

### 1.3.4 阅读器页增强

| 功能 | 实现 |
|------|------|
| 仿真翻页 | `PageView.builder` + 手势动画 |
| 预加载 | 当前章 ±1 章 |
| 进度保存 | chapterIndex + pageIndex + scrollOffset |
| TTS 朗读 | `flutter_tts` |
| 亮度调节 | `ScreenBrightness` 插件 |
| 章节列表 | 底部浮窗快速跳转 |

### 1.3.5 发现页

展示已启用书源的发现规则（榜单/分类），点击展示书籍列表。

```rust
#[frb]
pub async fn get_discovery(source_json: String, url: String, page: i32) -> Result<Vec<SearchItem>, String>;
```

### 1.3.6 iOS 适配

安全区域、Cupertino 风格可选、手势导航兼容

### 1.3.7 Web 适配

响应式布局、PWA 配置（Service Worker + manifest）、WASM bridge 初始化

---

## Phase 2：体验增强（3-4 周）

### 2.1 本地书籍（TXT/EPUB）

**Rust 端**（legado-engine 内）：

```rust
// TXT 分章：正则匹配 "第X章" / "Chapter X" 等模式
pub fn parse_txt_chapters(content: &str) -> Vec<ChapterItem>;

// EPUB 解析：zip 解压 → XML 解析 → 提取章节
pub fn parse_epub(data: &[u8]) -> Result<Vec<ChapterItem>, String>;
```

**Flutter**：`file_picker` 选择文件 → 调用 Rust 解析 → 存入 DB

### 2.2 替换规则

- 实时预览：输入测试文本 → 实时显示替换结果
- 预设规则库：常见广告过滤

### 2.3 阅读记录

**数据库**：
```sql
CREATE TABLE reading_records (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    date TEXT NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    read_chars INTEGER DEFAULT 0,
    FOREIGN KEY (book_id) REFERENCES books(id)
);
```

**Rust API**：
```rust
#[frb] pub async fn record_reading(book_id: String, book_name: String, chars: i32) -> Result<(), String>;
#[frb] pub async fn get_reading_stats(range: &str) -> Result<ReadingStats, String>;
#[frb] pub async fn export_reading_records(format: &str) -> Result<String, String>;
```

**Flutter UI**：`fl_chart` 柱状图 + 日历热力图 + CSV/JSON 导出

### 2.4 书源调试器

分步展示：请求信息 → 响应信息 → 规则逐步匹配 → 结果预览

```rust
#[frb]
pub async fn debug_search(source_json: String, keyword: String) -> Result<DebugResult, String>;

#[frb]
pub struct DebugResult {
    pub request_url: String,
    pub response_status: String,
    pub response_charset: String,
    pub response_body_preview: String,
    pub rule_steps: Vec<RuleDebugStep>,  // 逐步匹配日志
    pub results: Vec<DebugItem>,
}
```

### 2.5 Web API 服务

**Rust 端**（Phase 4 拆分为独立 crate `legado-api`）：

```rust
// 基于 axum 的嵌入式 HTTP 服务器
GET    /api/books              # 书架列表
POST   /api/books              # 添加书籍
DELETE /api/books/:id          # 删除书籍
GET    /api/books/:id/chapters # 章节列表
GET    /api/sources            # 书源列表
GET    /api/records            # 阅读记录
```

**Flutter**：设置页 → Web API 开关 + 端口 + Token

### 2.6 MD3 主题

- Material Design 3 + Dynamic Color (`dynamic_color` 包)
- 预设 5+ 套方案（浅色/深色/护眼/纸质/夜间）

---

## Phase 3：移除 Dart 引擎 + 多平台发布（3-4 周）

### 3.1 功能对齐验证

| 功能 | Rust API | 验证方法 |
|------|----------|---------|
| 搜索（HTML） | `search()` | 笔趣阁搜索"斗破" → ≥ 1 条 |
| 搜索（JSON） | `search()` | JSON API 书源搜索 |
| 搜索（@js: URL） | `search()` | JS 搜索书源 |
| 书籍详情 | `get_book_info()` | 封面+简介+最新章节 |
| 目录（HTML） | `get_toc()` | ≥ 10 章 |
| 目录（JSON） | `get_toc()` | JSON 目录返回 |
| 目录（分页） | `get_toc()` | 多页正确合并 |
| 正文（HTML） | `get_content()` | 非空正文 |
| 正文（JSON） | `get_content()` | JSON 正文 |
| 正文（分页） | `get_content()` | 多页合并 |
| 正文（替换） | `get_content()` | replaceRegex 生效 |
| 正文（<js>） | `get_content()` | JS 清洗执行 |

### 3.2 移除代码清单

- `lib/services/rule_engine.dart` ✂️
- `lib/services/analyze_rule.dart` ✂️
- `lib/services/legado_json_path.dart` ✂️
- `lib/services/jsoup_polyfill.dart` ✂️
- `lib/config/engine_config.dart` → 简化为始终 Rust
- `lib/bridge/legado_engine_bridge.dart` 中 Dart 回退 ✂️
- `lib/services/book_source_service.dart` 中 Dart 搜索实现 ✂️
- `lib/database/database_helper.dart` → 简化为调用 Rust DB API

### 3.3 性能基准

```rust
// criterion benchmarks
- XPath 解析性能
- 搜索全流程性能（async）
- Rust vs Dart 引擎对比
```

### 3.4 多平台发布

| 平台 | 发布方式 |
|------|---------|
| Android | Google Play |
| iOS | TestFlight → App Store |
| Windows | Microsoft Store + 独立 EXE |
| macOS | Mac App Store |
| Linux | AppImage / Snap / Flatpak |
| Web | Vercel / Cloudflare Pages (PWA) |

---

## Phase 4：增值功能（4-6 周，最后实现）

### 4.1 主题设置

- 主题编辑器（12 色板）
- 主题 JSON 导出/导入
- 主题市场（URL 加载）
- 5+ 预设主题

### 4.2 备份与恢复

**独立 crate**：`legado-webdav`（Phase 4 才创建）

```rust
pub struct WebDavClient {
    pub fn new(url: &str, username: &str, password: &str) -> Self;
    pub async fn list(&self, path: &str) -> Result<Vec<WebDavItem>, String>;
    pub async fn upload(&self, local: &[u8], remote: &str) -> Result<(), String>;
    pub async fn download(&self, remote: &str) -> Result<Vec<u8>, String>;
    pub async fn delete(&self, remote: &str) -> Result<(), String>;
}
```

**Flutter**：WebDAV 配置 → 一键备份（DB+配置打包）→ 一键恢复

### 4.3 其他设置

代理（socks5/http）、DNS 自定义、缓存管理、数据目录配置

### 4.4 阅读小票

书籍首页/尾部卡片：评分 + 阅读时长 + 开始/完成日期 + 阅读章数

### 4.5 想法笔记

```sql
CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    chapter_title TEXT,
    selected_text TEXT NOT NULL,
    note_content TEXT,
    position INTEGER,
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (book_id) REFERENCES books(id)
);
```

- 阅读器长按 → 写想法（半屏编辑器）
- 分享卡片：`Screenshot` → PNG → 分享
- Obsidian 导出：REST API 或本地文件

### 4.6 AI 助手

**独立 crate**：`legado-ai`（Phase 4 才创建）

```rust
pub struct LlmClient {
    pub fn new(api_url: &str, api_key: &str, model: &str) -> Self;
    pub async fn chat_stream(
        &self,
        messages: Vec<ChatMessage>,
        tools: Vec<ToolDefinition>,
    ) -> Result<impl Stream<Item = Result<ChatChunk, String>>, String>;
}
```

**预置 Tools**：`search_books` / `get_book_info` / `get_reading_stats` / `add_note`

**Flutter UI**：聊天界面 + 流式输出 + Markdown + 工具调用状态卡片

### 4.7 Legado Skill

书源自动化脚本引擎：

```rust
pub struct Skill {
    pub id: String,
    pub name: String,
    pub trigger: SkillTrigger,   // manual / schedule / webhook / source_event
    pub actions: Vec<SkillAction>,
}

pub enum SkillAction {
    SearchAndAdd(String),
    BackupSources,
    CleanCache,
    SendWebhook(String, String),
    ExecuteJs(String),
}
```

- Skill 市场（URL 导入）
- 定时任务（cron 表达式）
- Webhook 触发

---

## Web 端特殊处理

| 限制 | 降级方案 |
|------|---------|
| 无原生 Web API 服务器 | 不提供 localhost API，仅作客户端 |
| CORS 跨域 | WASM 内 `web_sys::fetch` 或 Service Worker 代理 |
| 无本地文件 | 导入导出用 File API + 内存处理 |
| WASM 性能 | 约原生 60-80%，阅读器场景可接受 |
| WASM 体积 | QuickJS WASM 约 150KB，可通过 `wasm-opt` 压缩 |
| 离线 | Service Worker + PWA 缓存策略 |

---

## 风险与缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| rquickjs 不足以替代 Rhino | 部分 <js> 书源不可用 | 保留 Dart flutter_js 作为 fallback，逐步验证 |
| XPath 完整实现工作量大 | 进度延迟 | 先实现 80% 常用语法，边缘 case 后续迭代 |
| WASM 体积过大 | Web 端加载慢 | QuickJS WASM 压缩 + lazy load + 退化到浏览器 eval |
| FRB async 稳定性 | 某些平台可能有问题 | Phase 0 即验证所有目标平台 |
| iOS 签名 & 审核 | 上架延迟 | Phase 0 验证构建，Phase 3 提前提交 |

---

## 关键技术选型

| 维度 | 选择 | 理由 |
|------|------|------|
| FFI 调用方式 | `#[frb]` async（全平台） | 不阻塞 UI 线程 |
| 运行时 | tokio (multi-thread) | Rust 异步标准 |
| JS 引擎 | rquickjs (全平台，WASM 编译) | QuickJS ES2020 兼容，与 Legado Rhino 对齐 |
| HTTP 客户端 | reqwest async (native) / web_sys (WASM) | 平台最优 |
| 数据库 | rusqlite(bundled) 全平台 | 一套 SQL 统一管理 |
| HTML 解析 | scraper | Servo 的 CSS 选择器引擎 |
| XPath | 自实现 | Legado 兼容语法 |
| JSONPath | jsonpath-rust + 自研扩展 | Legado 专有语法 |
| Web API 服务器 | axum | 轻量、高性能 |
| 状态管理 | Provider（Phase 0-2）→ Riverpod 可选 | 渐进迁移 |

---

> 最后更新：2026-07-10
