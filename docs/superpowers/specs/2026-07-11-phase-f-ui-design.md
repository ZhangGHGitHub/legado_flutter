# Phase F：UI 复刻 Jingshiro/Legado — 设计规格

> **状态：** 已批准（2026-07-11，v2 复刻版）  
> **对标项目：** [Jingshiro/legado](https://github.com/Jingshiro/legado)（Luoyacheng/legado 二改，MD3 UI）  
> **UI 源码索引：** [`app/.../ui/README.md`](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/README.md)  
> **前置：** Phase E 引擎 v0.4.6（Rust-only）已完成  
> **关联：** `docs/LEGADO_ARCH_REFERENCE.md`、`docs/REFACTOR_PLAN.md` Phase 1.3

---

## 1. 目标定义

### 1.1 复刻范围

**复刻** = 在 Flutter 中还原 Jingshiro Legado 的：

1. **信息架构** — 页面划分、导航层级、入口位置与原版一致  
2. **视觉语义** — MD3 卡片、分组列表、快捷四格、书架双布局、阅读器主题  
3. **交互路径** — 双击 Tab 回顶、长按备份、书源绿红点、搜索独立 Activity 等  
4. **Jingshiro 增量 UI** — 阅读记录、AI 助手、想法书签、阅读书票、主题导出、Reading Skill

**不复刻** = Android View/XML 像素级 1:1、Rhino 调试器 UI、墨水屏 E-Ink 模式（可后续加）。

### 1.2 技术约束

- Flutter 3.x + Material 3；阅读器内主题与 App 主题分离（对齐 `ThemeConfig` / `ReaderTheme`）
- 业务仍走 Rust FRB；UI 层不引入 Dart 规则引擎
- 桌面（Windows）优先验证；Android 布局适配 Phase F 末期

---

## 2. Jingshiro UI 模块对照表

依据 [`ui/README.md`](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/README.md) 与 `MainActivity.kt`：

| Jingshiro 模块 | Kotlin 路径 | Flutter 目标 | Phase F 优先级 |
|----------------|-------------|--------------|----------------|
| **主框架** | `ui/main/MainActivity` | `pages/main/main_shell.dart` | **F0 必做** |
| 书架 style1 | `main/bookshelf/style1` | `pages/bookshelf/bookshelf_style1_page.dart` | **F1 必做** |
| 书架 style2 | `main/bookshelf/style2` | `pages/bookshelf/bookshelf_style2_page.dart` | **F1 必做** |
| 发现 Tab | `main/explore/ExploreFragment` | `pages/explore/explore_tab_page.dart` | **F1 必做** |
| 订阅 Tab | `main/rss/RssFragment` | `pages/rss/rss_tab_page.dart` | F2 骨架 |
| 我的 Tab | `main/my/MyFragment` | `pages/my/my_page.dart` | **F0 必做** |
| 联合搜索 | `book/search` | `pages/search/search_page.dart` | **F1 必做** |
| 发现结果 | `book/explore` | `pages/explore/explore_list_page.dart` | **F1 必做** |
| 书籍详情 | `book/info` | `pages/book/book_info_page.dart` | **F1 必做** |
| 目录 | `book/toc` | `pages/book/toc_page.dart` 或 BottomSheet | **F1 必做** |
| 阅读器 | `book/read` | `pages/reader/reader_page.dart` | **F2 增强** |
| 换源 | `book/changeSource` | `pages/book/change_source_page.dart` | F3 |
| 换封面 | `book/changeCover` | `pages/book/change_cover_page.dart` | F3 |
| 书源管理 | `book/source/manage` | `pages/sources/sources_page.dart` | **F0 迁入我的** |
| 书源编辑/调试 | `book/source/edit` | `pages/sources/source_editor_page.dart` | 已有 |
| 替换净化 | `replaceRule` | `pages/replace/replace_page.dart` | 已有 |
| 本地导入 | `book/local` | 书架菜单入口 | 已有 |
| 配置中心 | `ui/config/ConfigActivity` | `pages/config/config_page.dart` | F2 |
| 主题设置 | `config/ThemeConfigFragment` | `pages/config/theme_config_page.dart` | F3 |
| 备份恢复 | `config/BackupConfigFragment` | `pages/config/backup_config_page.dart` | F3 |
| 阅读记录 | `about/ReadRecordActivity` + Web | `pages/my/read_record_page.dart` | F3 占位→WebView |
| AI 助手 | `book/read/ai/AiChatActivity` | `pages/reader/ai_chat_page.dart` | F4 |
| 书签想法 | `book/bookmark` | `pages/book/bookmark_page.dart` | F4 |
| 阅读书票 | `book/read` 内 Bookplate | Reader 内 overlay | F4 |
| 欢迎/隐私 | `welcome` + MainActivity | 首次启动 Dialog | F2 |
| 导入书源 | `association` | 已有 import 对话框 | 已有 |

---

## 3. 主框架（对齐 MainActivity）

### 3.1 底部导航

Jingshiro 使用 **BottomNavigationView + ViewPager**，4 项（发现/订阅可配置隐藏）：

| menu id | 文案 | Fragment | Flutter |
|---------|------|----------|---------|
| `menu_bookshelf` | 书架 | BookshelfFragment1/2 | `IndexedStack[0]` |
| `menu_discovery` | 发现 | ExploreFragment | `IndexedStack[1]` |
| `menu_rss` | 订阅 | RssFragment | `IndexedStack[2]` |
| `menu_my_config` | 我的 | MyFragment | `IndexedStack[3]` |

**与 legado_flutter 现 Tab 差异（必须改）：**

```
现：  书架 │ 发现(=搜索) │ 书源 │ 设置
目标：书架 │ 发现 │ 订阅 │ 我的
      搜索 → 独立 SearchPage（书架/发现 AppBar 进入）
      书源 → 我的 → 书源管理
```

### 3.2 Tab 交互（复刻行为）

| 行为 | Jingshiro | Flutter 实现 |
|------|-----------|--------------|
| 双击书架 Tab | `gotoTop()` 滚到顶 | `ScrollController.animateTo(0)` |
| 双击发现 Tab | `compressExplore()` 折叠分类 | Explore 页折叠/展开 |
| 再按返回 | 非书架 Tab → 切书架；书架再按 → 双击退出的 | `PopScope` + 2s 间隔 Toast |
| 书架更新角标 | `BadgeView` on Tab 0 | `NavigationDestination` badge |
| 默认首页 | `AppConfig.defaultHomePage` | `SharedPreferences` |

### 3.3 书架双布局（style1 / style2）

| 样式 | 特征 | 配置键 |
|------|------|--------|
| **style1** | 分组 Tab + 列表封面（经典 Legado） | `bookGroupStyle == 0` |
| **style2** | 网格封面墙 + 分组 Drawer | `bookGroupStyle == 1` |

设置项放在：**我的 → 其它设置** 或书架长按菜单；F1 默认 **style1**，F2 实现 style2 切换。

---

## 4. 「我的」页（对齐 MyFragment）

参考 [`MyFragment.kt`](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/my/MyFragment.kt)：

### 4.1 顶部快捷四格

| 按钮 | 短按 | 长按 | F 阶段 |
|------|------|------|--------|
| 备份恢复 | `CloudBackupActivity` | 本地备份 | F2 占位 / F3 实现 |
| WebDAV | 配置对话框 | — | F3 |
| Web 服务 | 开关 + 状态「已开启」 | 复制地址/浏览器打开 | F3 |
| 阅读记录 | 打开 [LegadoRecord](https://github.com/Jingshiro/LegadoRecord) Web | — | F3 WebView |

视觉：圆角 12dp 卡片按钮，按下态用 `accentColor`（对齐 `initQuickActions()`）。

### 4.2 设置列表（顺序对齐原版）

1. 书源管理 → `SourcesPage`  
2. TXT 目录规则 → 占位  
3. 替换净化 → `ReplacePage`  
4. 字典规则 → 占位  
5. 主题模式 → 对话框（跟随系统/浅色/深色）  
6. 备份与恢复 → `ConfigPage(backup)`  
7. 主题设置 → `ConfigPage(theme)`  
8. 其它设置 → `ConfigPage(other)`  
9. 书签与想法 → F4  
10. 文件管理 → 占位  
11. 阅读 Skill → F4  
12. AI 助手 → F4  
13. 关于  
14. 退出  

---

## 5. 核心阅读链路 UI

### 5.1 联合搜索（SearchActivity）

- 独立全屏页，**非** Bottom Tab  
- AppBar：搜索框 + 菜单（精准搜索、书源管理、搜索 scope）  
- 结果：**按书源分组** `ExpansionTile`（Jingshiro 默认），组内 `BookListTile`  
- 底栏统计：「共 N 本 · M 个书源」  
- 搜索历史 Chip 行（F2）

### 5.2 发现 Tab（ExploreFragment）

- 顶部：已启用且有 `exploreUrl` 的书源横向列表  
- 主体：当前书源的 `exploreUrl` JSON → 分类网格（7565 多分类+排行榜）  
- 点击分类 → `ExploreListPage`（`book/explore`）  
- AppBar 搜索图标 → `SearchPage`

### 5.3 书籍详情（BookInfoActivity）

**从 `reader_page.dart` 拆出**，对齐 `book/info`：

```
┌─────────────────────────────┐
│ AppBar: 书籍信息             │
├─────────────────────────────┤
│ [封面] 书名 / 作者 / 书源     │
│ 简介（可展开）               │
│ [加入书架] [阅读] [换源]     │
│ 缓存进度 / 读完·N刷 标签      │  ← Jingshiro
├─────────────────────────────┤
│ 章节目录 (x/y 已缓存)        │
│  · 第一章                    │
│  · 第二章  ← 当前            │
└─────────────────────────────┘
```

### 5.4 目录（TocActivity）

- 可从详情页下半部嵌入，或独立页 / BottomSheet  
- 支持「正序/倒序」、已缓存图标、当前章高亮  
- 点击 → `ReaderPage`

### 5.5 阅读器（ReadBookActivity）

对齐 Jingshiro MD3 阅读 UI + 增量：

| 区域 | 规格 |
|------|------|
| 顶栏 | 自动隐藏；返回 / 书名 / 更多（目录、设置、AI、书票） |
| 正文 | 左右翻页 / 滚动；`ReaderTheme` 米黄/白/暗/绿 |
| 底栏 | 章节进度 + 页码 + 时间（可选） |
| 设置面板 | 字号、行距、翻页、主题 — 已有 |
| **书票** | 章首/章尾 overlay（F4，对齐 README 书票） |
| **AI** | 侧滑或 FAB 进入 AiChat（F4） |
| **想法** | 长按选文 → 批注（F4） |

---

## 6. 设计系统（MD3 复刻语义）

### 6.1 参考 Jingshiro 主题体系

- App 级：`ThemeConfig.applyDayNight()` → Flutter `ThemeMode` + 自定义 `LegadoTheme`  
- 阅读级：`ReadBookConfig` 独立背景/字体/行距  
- 卡片：我的页、设置项使用 `Card` + 圆角 12，列表项间 `Divider` indent  
- 主色：可配置（F3 主题页）；默认 seed 保持蓝系，后续从 Jingshiro 主题 JSON 导入

### 6.2 Token（`lib/theme/legado_tokens.dart`）

| Token | 值 | 对标 |
|-------|-----|------|
| `radiusCard` | 12 | MyFragment 快捷按钮 corner |
| `radiusCover` | 8 | 书架封面 |
| `spacingPageH` | 16 | 标准水平边距 |
| `bookshelfGridCols` | 3 | style2 默认列数 |
| `sourceDotGreen` | Material green | 有发现且启用 |
| `sourceDotRed` | Material red | 有发现未启用 |

### 6.3 共用组件（`lib/widgets/`）

| 组件 | 用途 |
|------|------|
| `LegadoCard` | 统一 Card 圆角/内边距 |
| `BookCover` | Glide 等价：加载、占位、圆角 |
| `BookListTile` | 搜索/发现/详情列表项 |
| `SourceChip` | 书源名标签 |
| `SourceStatusDot` | 书源绿/红/灰点 |
| `LegadoListTile` | 我的/设置列表行（icon + title + subtitle + chevron） |
| `QuickActionButton` | 我的页四格按钮 |
| `EmptyState` | 空书架/空书源/空 RSS |
| `ReadBadge` | 「读完」「N刷」标签 |

---

## 7. 目录结构（Flutter 对齐 `ui/` 包）

```
lib/pages/
├── main/main_shell.dart
├── bookshelf/
│   ├── bookshelf_style1_page.dart    # style1 列表
│   ├── bookshelf_style2_page.dart    # style2 网格
│   └── bookshelf_arrange_page.dart   # F3 整理
├── explore/
│   ├── explore_tab_page.dart         # main/explore
│   └── explore_list_page.dart        # book/explore
├── rss/rss_tab_page.dart
├── my/my_page.dart
├── search/search_page.dart
├── book/
│   ├── book_info_page.dart
│   ├── toc_sheet.dart
│   ├── change_source_page.dart
│   └── bookmark_page.dart            # F4
├── reader/
│   ├── reader_page.dart
│   ├── reader_menu_overlay.dart
│   └── ai_chat_page.dart             # F4
├── sources/                          # 已有
├── replace/                          # 已有
└── config/
    ├── config_page.dart
    ├── theme_config_page.dart
    └── backup_config_page.dart
```

---

## 8. 分阶段交付

| 子阶段 | 内容 | 验收 |
|--------|------|------|
| **F0** | MainShell 四 Tab + MyPage 完整列表 + 书源迁入 | Tab 与 MyFragment 菜单一致 |
| **F1** | 书架 style1、发现 Tab、搜索独立、BookInfo 拆分 | 7565 发现+双源搜索+阅读 |
| **F2** | 书架 style2、搜索分组/历史、Config 骨架、隐私 Dialog | 交互对齐双击 Tab |
| **F3** | 换源、WebDAV/备份/Web 服务 UI、主题模式、书源校验点 | 我的页四格可点（部分占位） |
| **F4** | AI、书票、想法书签、阅读记录 WebView | Jingshiro README 增量功能入口齐全 |

**工期估算：** F0–F2 约 3 周（P0）；F3–F4 约 3 周（P1/P2 UI）。

---

## 9. 验收标准（复刻版）

| # | 标准 |
|---|------|
| 1 | 底部 **书架/发现/订阅/我的** 与 [MainActivity](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/MainActivity.kt) 一致 |
| 2 | **MyFragment** 快捷四格 + 14 项设置列表结构与文案对齐 |
| 3 | **SearchPage** 独立路由，结果按书源分组展示 |
| 4 | **ExploreTab** 可浏览 7565 分类并打开书籍列表 |
| 5 | **BookInfo** / **Reader** 分离，无 1500+ 行单文件 |
| 6 | 书架支持 **style1** 列表；F2 起支持 **style2** 网格切换 |
| 7 | 至少 8 个 `lib/widgets/` 组件在 3+ 页面复用 |
| 8 | `flutter test` + 手动 Windows 走通 搜索→详情→阅读 |

---

## 10. 参考链接

- [Jingshiro/legado 仓库](https://github.com/Jingshiro/legado) — README 功能列表（阅读记录、AI、书票、主题导出等）
- [ui/README.md](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/README.md) — 界面模块索引
- [MainActivity.kt](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/MainActivity.kt) — 主导航实现
- [MyFragment.kt](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/my/MyFragment.kt) — 我的页实现
- [LEGADO_WEB_API.md](https://github.com/Jingshiro/legado/blob/main/LEGADO_WEB_API.md) — Web 服务（F3）
