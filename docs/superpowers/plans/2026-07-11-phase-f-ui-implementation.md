# Phase F UI 复刻 Jingshiro/Legado — Implementation Plan

> **For agentic workers:** 严格按 F0→F4 顺序；每 Task 后 `flutter analyze lib` + 手动走通阅读链路。  
> **Spec:** `docs/superpowers/specs/2026-07-11-phase-f-ui-design.md` (v2 复刻版)  
> **对标仓库：** [Jingshiro/legado](https://github.com/Jingshiro/legado)  
> **预估：** F0–F2 约 3 周（P0）；F3–F4 约 3 周（Jingshiro 增量 UI）

**Goal:** 在 Flutter 中复刻 Jingshiro Legado 的导航、页面结构、MD3 视觉语义与核心交互，引擎继续走 Rust v0.4.6。

**Architecture:** `MainShell` 四 Tab + 独立 SearchRoute；页面目录对齐 `ui/` 包；共用组件 `lib/widgets/` + `lib/theme/`。

**Tech Stack:** Flutter 3.x, Material 3, Provider, SharedPreferences, 现有 FRB 桥接

---

## Global Constraints

- UI 复刻 **不修改** Rust 引擎 API（换源校验等后端能力 F3 再补）
- 每个子阶段结束必须 `flutter run -d windows` 可演示
- Kotlin/XML 作 **行为与结构参考**，不引入 Android 依赖
- Jingshiro F4 功能（AI/书票）可先 **占位页 + SnackBar「即将推出」**，但入口位置必须与 MyFragment/Reader 一致
- 参考文件路径写死在 Task 中，implementer 可 `WebFetch` 或 clone 对照

---

## 参考速查（Jingshiro 源码）

| 功能 | 参考文件 |
|------|----------|
| 主导航 | `ui/main/MainActivity.kt` |
| 我的 | `ui/main/my/MyFragment.kt` |
| 书架 | `ui/main/bookshelf/style1/`、`style2/` |
| 发现 Tab | `ui/main/explore/ExploreFragment.kt` |
| 订阅 Tab | `ui/main/rss/RssFragment.kt` |
| 搜索 | `ui/book/search/SearchActivity.kt` |
| 书籍详情 | `ui/book/info/BookInfoActivity.kt` |
| 阅读 | `ui/book/read/ReadBookActivity.kt` |
| 书源 | `ui/book/source/manage/BookSourceActivity.kt` |

---

## F0：主框架 + 我的页（1 周）

### Task F0-1: 主题与基础组件

**Files:**
- Create: `lib/theme/legado_tokens.dart`, `lib/theme/app_theme.dart`
- Create: `lib/widgets/legado_card.dart`, `lib/widgets/legado_list_tile.dart`, `lib/widgets/quick_action_button.dart`, `lib/widgets/empty_state.dart`
- Modify: `lib/app.dart`

- [ ] 定义 MD3 主题（亮/暗/跟随系统 hook）
- [ ] `LegadoListTile`：icon + title + subtitle + trailing chevron（对齐设置列表）
- [ ] `QuickActionButton`：圆角 12、按下 accent（对齐 MyFragment 四格）
- [ ] `LegadoCard`：统一 margin/padding

### Task F0-2: MainShell 四 Tab

**Files:**
- Create: `lib/pages/main/main_shell.dart`
- Create: `lib/pages/rss/rss_tab_page.dart`（EmptyState 占位）
- Modify: `lib/app.dart` — 移除内联 MainShell

- [ ] Tab：**书架 / 发现 / 订阅 / 我的**（`NavigationBar`）
- [ ] `IndexedStack` 保留 Tab 状态
- [ ] 双击 Tab 回顶：书架 ScrollController（发现 F2）
- [ ] `PopScope`：非书架→书架；书架双击退出的（2s Toast）
- [ ] 删除 `/reader` 占位路由

### Task F0-3: MyPage 复刻 MyFragment

**Files:**
- Create: `lib/pages/my/my_page.dart`
- Modify: `lib/pages/settings/settings_page.dart` → 迁移或删除

- [ ] **快捷四格**：备份恢复 | WebDAV | Web服务 | 阅读记录（F0 点击 SnackBar 占位，文案与 Jingshiro 一致）
- [ ] **设置列表 14 项**（顺序见 spec §4.2）；已实现项接真实路由，未实现项占位
- [ ] 书源管理 → `SourcesPage`（从底部 Tab 移除）
- [ ] 替换净化 → `ReplacePage`
- [ ] 主题模式 Dialog（跟随系统/浅色/深色）
- [ ] 关于：显示 app 版本 + Rust 引擎版本
- [ ] 退出：`SystemNavigator.pop` / `exit(0)` desktop

### Task F0-4: 搜索入口调整

**Files:**
- Modify: `lib/pages/bookshelf/bookshelf_page.dart` — AppBar 搜索 → `SearchPage`
- Modify: `lib/pages/main/main_shell.dart` — 移除 SearchPage Tab

**Acceptance F0:** 四 Tab 正确；我的页菜单完整；书源仅从我的进入；书架可进搜索。

---

## F1：书架 + 发现 + 详情拆分（1 周）

### Task F1-1: 书架 style1

**Files:**
- Create: `lib/pages/bookshelf/bookshelf_style1_page.dart`
- Create: `lib/widgets/book_cover.dart`, `lib/widgets/read_badge.dart`
- Modify: `lib/pages/bookshelf/bookshelf_page.dart` — 委托 style1 或重命名

- [ ] 顶部分组 Chip（全部 + 自定义分组）
- [ ] 列表项：封面 + 书名 + 作者 + 进度 + 当前章
- [ ] 更多菜单：添加本地、缓存全部、分组管理（保留现有逻辑）
- [ ] AppBar 搜索、菜单

### Task F1-2: 发现 Tab

**Files:**
- Create: `lib/pages/explore/explore_tab_page.dart`
- Create: `lib/pages/explore/explore_list_page.dart`
- Create: `lib/widgets/book_list_tile.dart`, `lib/widgets/source_chip.dart`

- [ ] 筛选有 `exploreUrl` 的已启用书源
- [ ] 解析 7565 JSON 分类 → `GridView` 卡片
- [ ] 书源横向 Chip 切换
- [ ] `ExploreListPage` → `BookSourceService.explore()`
- [ ] AppBar 搜索 → SearchPage

### Task F1-3: BookInfo 拆分

**Files:**
- Create: `lib/pages/book/book_info_page.dart`
- Create: `lib/pages/book/toc_sheet.dart`（或内嵌列表）
- Modify: `lib/pages/reader/reader_page.dart` — 仅 Reader + Settings
- Modify: `lib/pages/search/search_page.dart`, explore_list — 跳转 BookInfoPage

- [ ] 迁移 `_BookDetailPageState` → `BookInfoPage`
- [ ] 加入/移出书架、缓存、目录列表、跳转 Reader
- [ ] SnackBar Timer + mounted 修复保留
- [ ] `reader_page.dart` < 700 行

### Task F1-4: 搜索页按书源分组

**Files:**
- Modify: `lib/pages/search/search_page.dart`

- [ ] 结果改 `ExpansionTile` 每组一书源（组标题 = 书源名 + 条数）
- [ ] 组内 `BookListTile`
- [ ] 保留 loading / 空态 / 统计栏

**Acceptance F1:** 7565 发现可用；双源搜索分组展示；搜索→详情→阅读通。

---

## F2：书架 style2 + 交互细节（1 周）

### Task F2-1: 书架 style2 网格

**Files:**
- Create: `lib/pages/bookshelf/bookshelf_style2_page.dart`
- Modify: `lib/pages/main/main_shell.dart` 或书架 wrapper — 按 pref 切换 style1/2

- [ ] 3 列网格封面墙
- [ ] 分组 Drawer 或侧栏
- [ ] `SharedPreferences`：`bookGroupStyle` 0/1

### Task F2-2: Tab 交互增强

- [ ] 双击发现 Tab → 折叠/展开分类（ExploreTab 状态）
- [ ] 书架 Tab 更新角标（可选：有更新书籍数，先 stub 0）

### Task F2-3: 搜索历史

- [ ] `SharedPreferences` 存 20 条历史
- [ ] 搜索框下方 Chip 展示

### Task F2-4: Config 骨架 + 欢迎

**Files:**
- Create: `lib/pages/config/config_page.dart`
- Modify: `lib/pages/my/my_page.dart` — 备份/主题/其它设置入口

- [ ] `ConfigPage` 带 Tab：备份 | 主题 | 其它（内容占位）
- [ ] 首次启动隐私协议 Dialog（简化 markdown 文本）

**Acceptance F2:** 书架双布局可切换；搜索有历史；Config 可打开。

---

## F3：书源增强 + 我的页四格（1 周）

### Task F3-1: 书源列表 Jingshiro 语义

**Files:**
- Create: `lib/widgets/source_status_dot.dart`
- Modify: `lib/pages/sources/sources_page.dart`

- [ ] 绿点：enabled + exploreUrl 非空
- [ ] 红点：!enabled + exploreUrl 非空
- [ ] 分组标题 `bookSourceGroup`

### Task F3-2: 换源 / 换封面占位

**Files:**
- Create: `lib/pages/book/change_source_page.dart`, `change_cover_page.dart`
- Modify: `book_info_page.dart` — 「换源」按钮

- [ ] UI 骨架 + 「功能开发中」

### Task F3-3: Web 服务 / WebDAV / 备份 UI

- [ ] WebDAV：Dialog 表单（url/account/password/dir/device）— 仅 SharedPreferences 存储
- [ ] Web 服务：Switch 状态展示（未实现服务时 UI 先行）
- [ ] 备份恢复：跳转 ConfigPage backup tab

### Task F3-4: 阅读器目录浮层 + 预加载

**Files:**
- Modify: `lib/pages/reader/reader_page.dart`, `lib/model/read_book.dart`

- [ ] 更多菜单 → 目录 BottomSheet（`TocSheet` 复用）
- [ ] 预加载当前章 ±1

**Acceptance F3:** 书源绿红点；BookInfo 有换源入口；Reader 可跳章。

---

## F4：Jingshiro 增量 UI（1–2 周，可并行后端）

### Task F4-1: 阅读记录 WebView

- [ ] `ReadRecordPage` → WebView `https://jingshiro.github.io/LegadoRecord/`

### Task F4-2: AI 助手入口

- [ ] `AiChatPage` 占位（MyPage + Reader 更多菜单）
- [ ] 独立模式 flag（对齐 `isStandalone`）

### Task F4-3: 书签与想法 / 阅读书票

- [ ] `BookmarkPage` 占位
- [ ] Reader 章首/章尾书票 overlay 占位 UI

### Task F4-4: Reading Skill

- [ ] `ReadingSkillPage` 占位（MyPage 入口）

### Task F4-5: 主题导出 UI 骨架

- [ ] `ThemeConfigPage`：预设列表 + 导出按钮占位（对齐 Jingshiro 主题导出 README）

**Acceptance F4:** MyFragment 全部 14 项均有目标页（含占位）；Jingshiro README 功能均有 UI 入口。

---

## F5: 文档与测试

- [ ] 更新 `docs/LEGADO_ARCH_REFERENCE.md` §7 UI 映射
- [ ] `test/widget/main_shell_test.dart` — 四 Tab  smoke
- [ ] `test/widget/my_page_test.dart` — 14 列表项存在
- [ ] 手动验收 spec §9 八条

---

## 实施时间线

```
Week 1   F0-1 ~ F0-4   主框架 + 我的页
Week 2   F1-1 ~ F1-4   书架/发现/详情/搜索分组
Week 3   F2-*           style2 + 历史 + Config
Week 4   F3-*           书源/换源/Reader 增强
Week 5-6 F4-* + F5      Jingshiro 增量 + 测试
```

---

## Commit 建议

```
docs: Phase F v2 UI replication spec for Jingshiro legado
feat(ui): F0 main shell and MyPage aligned with MyFragment
feat(ui): F1 explore tab, book info split, grouped search
feat(ui): F2 bookshelf style2 and search history
feat(ui): F3 source dots, reader toc sheet, webdav ui skeleton
feat(ui): F4 Jingshiro feature entry points (AI, bookplate, records)
```

---

## 风险

| 风险 | 缓解 |
|------|------|
| exploreUrl JSON 格式多样 | 先完整支持 7565；其它显示友好错误 |
| MyFragment 14 项工作量大 | F0 占位 + F4 补全，入口一次到位 |
| style2 网格性能 | 使用 `GridView.builder` + 封面缓存 |
| WebView 桌面依赖 | `webview_flutter` / `url_launcher` 外链兜底 |

---

## 验收命令

```bash
flutter analyze lib
flutter test
flutter run -d windows
# 对照 Jingshiro APK 或源码逐 Tab 核对
```
