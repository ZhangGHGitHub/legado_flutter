# Legado Flutter — 当前进度 & 后续开发计划

> **开发流程：** [DEVELOPMENT_PROCESS.md](./DEVELOPMENT_PROCESS.md) · **文档索引：** [README.md](./README.md)  
> 目标：对齐 [Jingshiro/legado](https://github.com/Jingshiro/legado) 增强版  
> 目标平台：Android / iOS / Windows / macOS / Linux / Web (WASM)  
> 最后更新：2026-07-11  
> 引擎版本：**v0.5.6** | DB Schema：**v9** | FRB：**2.11.1**

---

## 一、项目现状总览

### 1.1 核心数据

| 维度 | 状态 |
|------|------|
| Rust 引擎版本 | **v0.5.6** |
| DB Schema | **v9**（5 张表：books, book_sources, chapters, replace_rules, reading_records, notes） |
| FRB | **已完成 codegen**，`lib/src/rust/` 16 个生成文件，全部 async |
| Rust crate 数量 | **2**（`legado_engine` + `legado-webdav`） |
| Flutter .dart 文件 | **93 个** |
| 测试文件 | **31 个**（Rust 单元/E2E/bench + Dart widget/service/integration） |
| 已构建平台 | Android ✅ / Windows ✅ |
| 未构建平台 | iOS ❌ / macOS ❌ / Linux ❌ / Web（配置未测试）⚠️ |

### 1.2 架构

```
┌──────────────────────────────────────────────┐
│              Flutter UI (Dart)               │
│          Provider / ChangeNotifier           │
│         ~~ #[frb] async FFI ~~               │
├──────────────────────────────────────────────┤
│  flutter_rust_bridge 2.11.1                  │
│  lib/src/rust/ (16 generated dart files)     │
├──────────────────────────────────────────────┤
│           legado_engine (Rust)               │
│                                              │
│  api/   — FRB 导出层（14 个 API 模块）        │
│  rule/  — CSS/XPath/Legado DSL/JSONPath/rquickjs │
│  http/  — reqwest async + Cookie + 限速 + 代理   │
│  db/    — rusqlite (bundled) Schema v9       │
│  web_server.rs — axum HTTP API               │
│  notes_store.rs — 笔记 CRUD                  │
├──────────────────────────────────────────────┤
│           legado-webdav (Rust)               │
│  WebDAV client (list/upload/download/delete) │
└──────────────────────────────────────────────┘
```

---

## 二、已完成清单 ✅（无需继续开发）

### 2.1 Rust 书源引擎 — 完成度 95%

| 模块 | 状态 | 文件 |
|------|:---:|------|
| 搜索（HTML + JSON API） | ✅ | `api/search.rs` + `rule/html_search.rs` + `rule/json_search.rs` |
| 发现（Explore） | ✅ | `api/explore.rs` + `rule/html_explore.rs` + `rule/json_explore.rs` |
| 书籍详情 | ✅ | `api/book_info.rs` + `rule/html_book_info.rs` + `rule/json_book_info.rs` |
| 目录获取（分页/HTML/JSON） | ✅ | `api/toc.rs` + `rule/html_toc.rs` + `rule/json_toc.rs` |
| 正文获取（分页/替换/JS清洗） | ✅ | `api/content.rs` + `rule/html_content.rs` + `rule/json_content.rs` |
| 书源校验 | ✅ | `api/validate.rs`（search→explore→toc→content 串行验证） |
| 书源调试（逐步匹配日志） | ✅ | `api/debug.rs` |
| JS 引擎 (rquickjs 0.12) | ✅ | `rule/js_engine.rs` |
| CSS/XPath/Legado DSL/JSONPath | ✅ | `rule/` 模块 |
| HTTP（代理/DNS/Cookie/Charset/Gzip） | ✅ | `http/` 模块 |
| 限速器 (async tokio) | ✅ | `http/rate_limit.rs` |

### 2.2 Rust 数据库 & 基础设施 — 完成度 95%

| 功能 | 状态 |
|------|:---:|
| SQLite CRUD（全部 5 张表） | ✅ |
| 书籍/书源/章节/替换规则 CRUD | ✅ |
| 阅读记录 CRUD + 统计 + 导出 (CSV/JSON) | ✅ |
| 笔记 CRUD + Markdown 导出 | ✅ |
| 数据库备份/恢复 (JSON) | ✅ |
| WebDAV 客户端 (list/up/down/del) | ✅ |
| Web API 服务器 (axum + token auth + CORS) | ✅ |
| 网络代理/DNS 配置 | ✅ |
| 本地 TXT/EPUB 解析 | ✅ |

### 2.3 Flutter UI — 完成度 85%

| 页面 | 状态 |
|------|:---:|
| MainShell（4 标签页） | ✅ |
| 书架（列表/网格/分组切换） | ✅ |
| 发现页（书源选择器/分页） | ✅ |
| 搜索页（跨源聚合/历史） | ✅ |
| 书籍详情页 + 目录 Sheet | ✅ |
| 阅读器（分页/主题/字体/亮度/章节切换） | ✅ |
| 阅读器设置（字体/行距/翻页模式/主题） | ✅ |
| 书源管理（CRUD/导入/校验/调试面板） | ✅ |
| 书源编辑器 + 书源市场 | ✅ |
| 替换规则管理（含预览面板） | ✅ |
| RSS 订阅管理 | ✅ |
| 设置中心 + 主题配置 + 备份配置 | ✅ |
| Web API 配置 + 网络配置 | ✅ |
| "我的"页（阅读记录/统计图表） | ✅ |
| AI 聊天页（基础聊天 UI） | ✅ |
| 修改封面/换源功能 | ✅ |
| 隐私协议弹窗 | ✅ |

### 2.4 Flutter 服务层 — 完成度 90%

| 服务 | 状态 |
|------|:---:|
| BookSourceService（Rust 门面） | ✅ |
| DatabaseHelper（→ Rust rusqlite） | ✅ |
| BackupService（本地 + WebDAV） | ✅ |
| CacheService | ✅ |
| LocalBookService（TXT/EPUB 导入） | ✅ |
| ReadingRecordService | ✅ |
| ReplaceService + 预设库（20+） | ✅ |
| BookplateService（数据层） | ✅ |
| NoteService + NoteExportService（Markdown 导出） | ✅ |
| ThemeImportService | ✅ |
| WebApiService + WebApiPrefs | ✅ |
| WebDavPrefs | ✅ |
| NetworkPrefs | ✅ |
| SettingsBackup | ✅ |
| SearchHistory | ✅ |
| AppPaths | ✅ |
| SourceDebugFormatter | ✅ |
| ContentProcessor | ✅ |
| BookHelp（章节文件缓存） | ✅ |

### 2.5 测试

| 类型 | 文件数 |
|------|:---:|
| Rust 单元测试 | `src/tests.rs` |
| Rust E2E 测试 | 3 个（builtin / phase3 / web_api） |
| Rust 性能基准 | `benches/rule_bench.rs` |
| Dart Widget 测试 | 11 个 |
| Dart Service 测试 | 10 个 |
| Dart Integration 测试 | 5 个 |
| **总计** | **31+** |

---

## 三、仍需开发 ❌ / ⚠️

### 🔴 高优先级 — 核心缺位（6 项）

#### #1 — 多平台构建（iOS / macOS / Linux / Web）

| 平台 | 当前 | 目标 | 工作内容 |
|------|:---:|:---:|------|
| **iOS** | ❌ 从未构建 | 真机 + 模拟器 | `rustup target add aarch64-apple-ios{,sim}` → FRB generate → Xcode 配置 ATS → CocoaPods → TestFlight |
| **macOS** | ❌ 从未构建 | Apple Silicon | `rustup target add aarch64-apple-darwin` → FRB generate → 构建 |
| **Linux** | ❌ 从未构建 | x86_64 | 安装 GTK dev 库 → FRB generate → Snap/AppImage 打包 |
| **Web** | ⚠️ 配置未测试 | PWA | WASM 编译链路验证 → `wasm-pack build` → dart:js interop → Service Worker → PWA deploy |

**详细步骤（iOS 为例）**：
```bash
# 1. iOS target (需要 macOS + Xcode)
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
flutter_rust_bridge_codegen generate
cd ios && pod install
# 2. 修复编译错误（如有）
flutter build ios --debug --no-codesign
# 3. Info.plist ATS 例外
# 4. TestFlight 分发

# Web:
cd rust/legado_engine
# 条件编译 wasm32 target
rustup target add wasm32-unknown-unknown
# 配置 WASM 导出（当前 FRB 不支持 web，需要独立 wasm-pack 路线）
wasm-pack build --target web
# Flutter Web 侧集成 WASM 模块
flutter build web
```

#### #2 — <js> 书源兼容性验证 & 提升

| 子任务 | 说明 |
|--------|------|
| 2a. 收集测试书源集 | 从社区收集 50+ 个不同类型的书源（HTML 搜索 / JSON API / @js: URL / <js> 正文清洗） |
| 2b. 批量兼容性测试 | 对每个书源运行 search→toc→content 全流程，记录通过率 |
| 2c. rquickjs 差异修复 | 分析失败案例，补充缺失的 JS API 注入（如 `java.headerMap`、`org.jsoup.Jsoup` 特殊用法） |
| 2d. 建立 CI 回归测试 | 将测试书源集加入 CI，每次 PR 自动运行兼容性检测 |

#### #3 — 书源登录 UI

Legado 支持 `loginUrl` + `loginUi`（自定义表单）实现需要登录的书源。

| 子任务 | 说明 |
|--------|------|
| 3a. Flutter 登录表单页 | 根据书源 `loginUi` JSON 渲染动态表单（text/password/button/toggle/select/checkbox） |
| 3b. JS 登录逻辑执行 | 用户填写表单→拼接 JS 变量→调用 rquickjs 执行登录脚本 |
| 3c. Cookie 持久化 | 登录成功后 Cookie 由 Rust `CookieJar` 自动管理（✅ 已支持），验证手动登录后搜索/正文是否可复用 |

#### #4 — 想法/笔记系统（阅读器内交互）

Rust 端笔记 CRUD 已完成 ✅，缺失的是阅读器内的交互 UI。

| 子任务 | 说明 |
|--------|------|
| 4a. 阅读器长按菜单 | `ReaderSelectableText` 选中文字 → 弹出菜单（复制/划线/写想法） |
| 4b. 想法编辑器 | 半屏 `BottomSheet`：显示选中原文 + 文本输入框 + 保存按钮 |
| 4c. 划线高亮展示 | 阅读器中已保存的想法位置显示下划线/高亮标记 |
| 4d. "我的想法"聚合页 | 按书籍分组展示所有想法，支持编辑/删除 |

#### #5 — AI 助手工具调用

AI 聊天页已完成 ✅，缺失的是 LLM 工具调用能力。

| 子任务 | 说明 |
|--------|------|
| 5a. Rust LLM Client | 实现 OpenAI/Claude 兼容的 chat completions + function calling |
| 5b. 工具定义 | `search_books(kw)` — 搜索书架；`get_book_info(name)` — 书籍详情；`get_reading_stats()` — 阅读统计；`add_note(book, text)` — 添加想法 |
| 5c. 流式输出 UI | `StreamBuilder` 逐 token 渲染，工具调用展示状态卡片（"正在搜索..."→"找到 3 本书"） |
| 5d. 配置页 | API URL + Key + Model 配置，支持 OpenAI / Anthropic / 本地模型 |

#### #6 — 阅读小票卡片 UI

BookplateService（数据层）已完成 ✅，缺失的是 UI 卡片。

| 子任务 | 说明 |
|--------|------|
| 6a. `BookplateOverlay` Widget | 书籍首页/尾部叠加卡片：评分 ⭐ + 阅读时长 + 开始/完成日期 + 阅读章数 |
| 6b. 书架标记 | 书架上已读完的书显示小票图标，点击可查看 |

---

### 🟡 中优先级 — 体验完善（4 项）

#### #7 — 读完/N刷标签

| 子任务 | 说明 |
|--------|------|
| 7a. Book 模型 | 新增 `readStatus` 字段（unread / reading / finished / rereading） |
| 7b. 数据库迁移 | Schema v10：`books` 表添加 `read_status TEXT DEFAULT 'reading'` |
| 7c. 书架 UI | 书籍卡片角标（"已读完" / "N刷"），筛选/分组支持按状态 |

#### #8 — 书签功能完善

页面已存在（`bookmark_page.dart`）✅，需确认功能完整性。

| 子任务 | 说明 |
|--------|------|
| 8a. 阅读器内添加书签 | 点击书签按钮 → 保存 `(chapterIndex, position, text)` |
| 8b. 书签列表跳转 | 书签页点击 → 跳转到对应章节和位置 |

#### #9 — 发现页多源聚合

当前每次只能选一个书源查看发现内容。

| 子任务 | 说明 |
|--------|------|
| 9a. 多源并发发现 | 同时调用多个书源的 `explore()`，结果合并去重 |
| 9b. 统一榜单 UI | 综合榜 / 分类榜 tabs，下拉可以筛选书源 |

#### #10 — Web API 端点扩展

当前有基础端点，对照 Jingshiro 的 `LEGADO_WEB_API.md` 扩展。

| 缺失端点 | 说明 |
|----------|------|
| `GET/POST /api/notes` | 想法 CRUD |
| `GET /api/records` | 阅读记录查询 |
| `GET /api/books/search` | 跨源搜索 API |
| `POST /api/sources/validate` | 远程触发书源校验 |
| `GET /api/export/notes` | 笔记导出下载 |

---

### 🟢 低优先级 — 锦上添花（5 项）

#### #11 — 图片/封面解密

rquickjs 中未注入图片解密相关回调。

| 子任务 | 说明 |
|--------|------|
| 11a. `java.decryptImage(bytes, sourceKey)` | JS 返回解密后的 `ByteArray` → Rust 侧应用解密并缓存 |
| 11b. `java.decryptCover(stream, sourceKey)` | 封面 InputStream 解密 |

#### #12 — 字体解析/替换

| 子任务 | 说明 |
|--------|------|
| 12a. `java.queryTTF(fontPath)` | 解析 TTF 字体元数据 |
| 12b. `java.replaceFont(text, fontFamily)` | 将文本中的字体替换为指定字体 |

#### #13 — Legado Skill 系统

书源自动化脚本引擎（独立功能，不影响核心阅读链路）。

| 子任务 | 说明 |
|--------|------|
| 13a. Skill 模型 | `id, name, trigger (manual/schedule/webhook), actions[]` |
| 13b. Skill 引擎 | 注册 Skills → 触发执行 → Action 链 |
| 13c. Skill 市场 | 从 URL 导入 Skill 包 |

#### #14 — 分享卡片生成

| 子任务 | 说明 |
|--------|------|
| 14a. 想法卡片截图 | `Screenshot` widget → PNG → `share_plus` 分享 |
| 14b. 阅读小票分享 | 书籍评分卡片生成并分享 |

#### #15 — Web PWA 完善

| 子任务 | 说明 |
|--------|------|
| 15a. Service Worker | 离线缓存策略（HTML/JS/WASM + 书籍数据 IndexedDB） |
| 15b. manifest.json | PWA 图标/名称/主题色配置 |
| 15c. 响应式适配 | 移动端/平板/桌面端布局自适应 |

---

## 四、已完成 vs 计划对比

| 计划 Phase | 计划内容 | 实际状态 |
|------------|----------|:---:|
| Phase 0 | FRB codegen + iOS/WASM 编译链 + CI | FRB codegen ✅ / iOS ❌ / WASM ❌ / CI ❌ |
| Phase 1.1 | 规则引擎完整化（XPath/JSONPath/JS） | ✅ **已完成** |
| Phase 1.2 | Rust 业务 API（search/toc/content/book_info） | ✅ **已完成**（远超计划：额外完成 explore/validate/debug/read_record/notes/backup） |
| Phase 1.3 | Flutter UI 核心页面 | ✅ **已完成**（远超计划：额外完成 RSS/AI 聊天/主题配置/备份配置） |
| Phase 2 | 体验增强（本地书籍/阅读记录/调试器/Web API/MD3） | ✅ **全部已完成** |
| Phase 3 | 移除 Dart 引擎 + 发布 | ⚠️ Dart 引擎已移除 ✅ / 多平台发布 ❌ |
| Phase 4 | 增值功能（AI/笔记/小票/备份/主题/Skill） | ⚠️ 备份/WebDAV/主题 ✅ / AI/笔记 部分完成 / Skill ❌ |

---

## 五、详细开发路线图（剩余工作）

### 第一步：补齐缺失的核心功能（4-6 周）

```
Week 1-2:  <js> 书源兼容性验证
  ├── 收集测试书源集（50+）
  ├── 批量兼容性测试
  ├── rquickjs 差异修复
  └── CI 回归测试集成

Week 3-4:  想法/笔记系统（阅读器交互）
  ├── 阅读器长按菜单 + 选择文字
  ├── 想法编辑器 BottomSheet
  ├── 划线高亮展示
  └── "我的想法"聚合页

Week 5-6:  AI 助手工具调用
  ├── Rust LLM Client
  ├── 工具定义 + function calling
  ├── 流式输出 UI
  └── 配置页（API/Key/Model）
```

### 第二步：多平台构建验证（2-3 周）

```
Week 7:    iOS + macOS
  ├── iOS target 编译链配置
  ├── macOS target 编译链配置
  ├── 修复平台兼容问题
  └── 真机/模拟器验证

Week 8:    Linux + Web
  ├── Linux GTK 编译 + AppImage 打包
  ├── Web WASM 编译链路
  ├── WASM ↔ Flutter Web 桥接
  └── PWA 部署验证

Week 9:    全平台 CI
  ├── GitHub Actions 矩阵构建
  ├── 自动发布流水线
  └── 平台特定问题修复
```

### 第三步：体验完善（2-3 周）

```
Week 10-11:
  ├── 读完/N刷标签（模型 + DB + UI）
  ├── 书源登录 UI（动态表单 + JS 登录）
  ├── 发现页多源聚合
  ├── Web API 端点扩展
  └── 阅读小票卡片 UI

Week 12:
  ├── 书签功能完善
  ├── 分享卡片生成
  └── Web PWA 完善
```

### 第四步：锦上添花（按需，2-3 周）

```
  ├── 图片/封面解密（rquickjs 注入）
  ├── 字体解析/替换（rquickjs 注入）
  ├── Legado Skill 系统
  └── Obsidian 一键导出笔记
```

---

## 六、功能完成度总结

| 大类 | 完成度 | 说明 |
|------|:---:|------|
| **Rust 书源引擎** | 95% | 核心全完成，缺图片解密/字体替换（低优） |
| **Rust DB & 基础设施** | 95% | rusqlite + WebDAV + Web API + 备份 + 笔记 全部完成 |
| **Flutter UI** | 85% | 核心页面全有，缺笔记交互/小票卡片/登录表单 |
| **Jingshiro 差异化功能** | 60% | 笔记后端✅/AI 基础✅，缺交互+工具调用+小票UI |
| **多平台** | 29% | 仅 Android/Windows 可用 |
| **测试覆盖** | 70% | 31+ 测试文件，缺 <js> 兼容率系统测试 |
| **综合** | **~72%** | 核心引擎极强，缺多平台 + 笔记交互 + AI tool |

---

## 七、时间线预估（剩余工作）

| 步骤 | 内容 | 工期 |
|------|------|:---:|
| 第一步 | <js> 兼容性 + 笔记交互 + AI tool | 4-6 周 |
| 第二步 | iOS/macOS/Linux/Web 构建 | 2-3 周 |
| 第三步 | 体验完善（标签/登录/聚合/Web API/小票） | 2-3 周 |
| 第四步 | 锦上添花（解密/字体/Skill/Obsidian） | 2-3 周 |
| **总计** | | **10-15 周** |

---

> 最后更新：2026-07-11 | 引擎 v0.5.6 | DB Schema v9
