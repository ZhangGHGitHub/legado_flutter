# Phase F：UI 一比一复刻 Jingshiro/Legado — 差距分析与开发计划

> **开发流程：** [DEVELOPMENT_PROCESS.md](./DEVELOPMENT_PROCESS.md) · **文档索引：** [README.md](./README.md)  
> **对标项目（官方 UI 目标）：** [Jingshiro/legado](https://github.com/Jingshiro/legado) — 所有 UI 须 1:1 对齐此 fork  
> **说明：** 原 `gedoor/legado` 仓库已从 GitHub 下架；**Jingshiro/legado 为布局与源码参照的唯一权威来源**（继承链：gedoor → Luoyacheng → Jingshiro，见 [LEGADO_ARCH_REFERENCE.md](./LEGADO_ARCH_REFERENCE.md)）  
> **参照源码路径：** `app/src/main/java/io/legado/app/ui/` + `app/src/main/res/layout/`  
> **本地参照克隆（可选）：** `reference/Jingshiro-legado/`（已加入 `.gitignore`，供 Agent 离线读布局）  
> **用户文档：** [Legado 语雀使用说明（必看）](https://www.yuque.com/legado/wiki)（最后更新 2025-07-29）  
> **设计规格：** `docs/superpowers/specs/2026-07-11-phase-f-ui-design.md`  
> **实施计划（旧）：** `docs/superpowers/plans/2026-07-11-phase-f-ui-implementation.md`  
> **当前引擎：** Rust v0.5.6 | **本文档：** 2026-07-12 更新（RSS 订阅阅读延后 + 语雀参考）

---

## 参考文档

### 文档分工

| 来源 | 用途 | 优先级 |
|------|------|:---:|
| **Jingshiro 源码**（`res/layout/` + `ui/`） | 控件布局、尺寸、1:1 复刻 | 最高 |
| **[语雀 Wiki](https://www.yuque.com/legado/wiki)** | 用户可见功能、交互流程、验收 checklist | 高 |
| **内置 `appHelp.md`**（`app/src/main/assets/help/`） | FAQ、排错、书源/规则编写 | 中 |
| **`docs/superpowers/specs/`** | Phase F 设计规格 | 中 |

> 语雀 Wiki ≈ 官方 FAQ + **带截图的交互教程**；做 UI 时：**布局看 Jingshiro 源码，功能完整性看语雀 Wiki**。

### 语雀 Wiki 目录结构

| 章节 | 链接 slug | 内容概要 |
|------|-----------|----------|
| 简介 & 下载 | `xz` | 核心卖点：自定义书源、列表/网格书架、替换净化、本地 TXT/EPUB、高度自定义阅读 |
| 基础教程（新人必看） | `lrjc` | 一键导入订阅源、**务必备份** |
| 主界面介绍 | `glgoz7` | 书架/发现/订阅/我的 + 分组/搜索/更多菜单 |
| 阅读界面介绍 | `rzy3yu` | **最详细**：顶栏、底栏、TTS、目录、界面、设置（见下表） |
| 4 个基本名词解释 | `yg97rc` | 书源、发现、订阅源、替换净化 |
| 导入书源 | `xdroke` | 新建/本地/网络/扫码四种导入方式 |
| 导入替换净化 | `gnt3nq` | 同上四种方式 |
| 导入订阅 | `grqch2` | 订阅源导入（**延后 S4**） |
| 网页版看书（Web 服务） | `zbpv12` | 局域网开启 Web 服务：书架/书源/传书/订阅源 |
| 网页版看书（搭建教程） | `dssouf` | Docker 自建 reader 网页版 |
| WebDav 书籍简明教程 | `web` | 上传/下载本地书籍、多设备同步 |
| 书籍的缓存与导出 | `zy7a6it07npztqwe` | 书架更多 → 缓存/导出 |
| 坚果云注册与配置 | `fkx510` | WebDAV 备份配置（推荐） |
| Meow 云注册与配置 | `meow` | WebDAV 备选 |
| 设置阅读 WebDav 自动备份 | `mgu5qu` | 退出时自动备份 |
| 恢复备份 | `nxs89y` | 备份与恢复流程 |
| 导出书签 | `fl1ran4216vyuv0g` | 导出 MD 格式书签 |
| 主题排版 zip 导入 | `wmmf8glgz81mgkw9` | 阅读菜单 → 界面 → 长按主题导入 |
| 主题配色 | `vz1x0s` | 剪切板导入主题 JSON |
| 封面 | `gd8xtt` | 默认封面 / 封面换源 |
| 排版 | `av6m9o` | 阅读界面面板各模块说明 |
| 字体 | `ka9szl` | 字体文件夹 + 阅读界面选择 |
| 主界面背景 | `pgk7m1` | 主题设置 → 背景图片 |
| 启动页 | `at2knr` | 主题设置 → 启动页样式（白天/黑夜） |

### 语雀 → UI Task 映射

| 语雀章节 | 对应 Task | 验收要点 |
|----------|-----------|----------|
| 主界面介绍 | UI-7 书架、主框架 | 下拉刷新、未读角标、更多菜单（本地/缓存/整理/布局/分组） |
| 阅读界面介绍 | **UI-1、UI-2** | 见下方「阅读器验收 checklist」 |
| 导入书源 | UI-4 书源 | 本地/网络/新建/扫码导入 |
| 导入替换净化 | 已有 `replace_page` | 四种导入方式 + 分组/范围 |
| 网页版看书 | Web 服务卡片 | 四 Tab：书架/书源/传书/订阅源 |
| 书籍缓存与导出 | UI-13 缓存 | 书架更多 → 缓存/导出 |
| 数据备份系列 | 备份配置页 | 坚果云/Meow、自动备份、恢复 |
| 界面自定义系列 | 主题设置 + UI-2 | 主题 zip、配色、字体、背景、启动页 |
| 导入订阅 | **UI-12（S4）** | 用户决策：RSS 阅读延后 |

### 阅读器验收 checklist（来源：语雀 `rzy3yu`）

语雀将阅读器拆为 4 层，可作为 UI-1/UI-2 的**用户向验收标准**（布局仍以 Jingshiro `activity_book_read.xml` 为准）：

**顶栏 / 更多菜单**（2026-07-15 对齐截图 chrome）

- [x] 书名（完整）— 顶栏居中省略；点击进书籍详情
- [x] 换源、刷新、离线缓存、更多 — 顶栏右侧图标直达；缓存仍占位 SnackBar（→ UI-13）
- [x] 章节名 + 书源橙芯片 + 章节 URL 三行顶栏
- [x] 更多：书签、拷贝内容、书籍信息已落地；翻页动画/云端进度/反转/替换净化/重新分段/更新目录为明确占位文案（勿静默）
- [x] 全文搜索 / 模拟追读入口（菜单中文对齐 legado；全文搜索+上/下结果；模拟追读解锁章）
- [x] 顶栏自动隐藏 — 点击中区切换；进入后约 3s 自动收起

**底栏**（2026-07-15 对齐截图 chrome）

- [x] 圆钮行：搜索 / 原网页 / 自动翻页 / 亮度
- [x] 章节跳转文案「上一章|下一章」+ **橙色进度滑块**
- [x] 主入口：目录 | 朗读 | 界面(Aa) | 设置（界面=排版面板，设置=更多设置）
- [~] 信息区时间/页码/电量：开关仍在「界面」面板；菜单 overlay 已按截图移除信息行（页脚叠加待补）

**朗读面板**（`dialog_read_aloud`）

- [x] 上/下章、上/下页、上/下句、播放/停止（UI-2：`flutter_tts` 系统引擎 + 句级导航）
- [x] 定时、语速滑块、TTS 引擎选择、后台播放（系统 TTS 可发音；HTTP TTS 仍占位）

**界面面板**（`dialog_read_bg_text` / `dialog_read_book_style`）

- [x] 字重（中/粗/细）、缩进、简繁（字级表；词级 OpenCC/quick-transfer 词典仍缺）
- [x] 字体（内置系统/衬线/等宽骨架；自定义导入占位）
- [x] 边距（左右/上下调节）
- [x] 信息区开关（页码/时间/电量）
- [x] 字号/字距/行距/段距（芯片顺序对齐 `dialog_read_book_style`）
- [x] 翻页动画五档（覆盖/滑动/仿真/滚动/无）；仿真为透视近似（非真实书页卷曲）、主题色自定义仍偏预设
- [x] 主题 zip 导入（取消共用布局 → 长按主题）— UI-2：共用布局开关 + 长按主题打开 `BgTextConfigPanel`；本地/网络 zip（`readConfig.json`）；导出 zip；槽位色覆盖持久化；背景图可显示；自定义字体 FontLoader / 每主题独立排版仍开放

**设置面板**（阅读设置子页）

- [x] 屏幕方向（跟随/竖/横）；屏幕超时五档（默认/1/5/10分钟/常亮 · `wakelock_plus` + 计时）
- [x] 隐藏状态栏/导航栏、扩展到刘海（SystemChrome + SafeArea；菜单唤起时短暂显栏）
- [x] 文字两端对齐；文字底部对齐（分页不足一页贴底）
- [x] 音量键翻页开关；蓝牙翻页器（PageUp/Down·媒体键）
- [x] 朗读时音量键翻页（`volumeKeyPageOnPlay`）
- [ ] 自动换源、长按选择文本
- [x] 显示亮度调节控件（跟随系统 / 阅读遮罩亮度）
- [x] 点击区域设置；自定义翻页按键可录制（更多设置）
- [x] 自动阅读（间隔可调 + 定时翻页 + 角标停止）

**目录浮层**

- [x] 目录 / 书签 Tab 切换
- [x] 当前章节高亮、未缓存标识

### 语雀 vs Jingshiro 差异说明

| 项 | 语雀 | Jingshiro 源码 | 复刻策略 |
|----|------|----------------|----------|
| 「我的」设置项 | 9 项（较简） | 14 项（含 TXT 规则、字典、AI、文件管理等） | **以 Jingshiro 为准** |
| RSS / 订阅 | 描述较泛（杂志、直播等） | 完整 RSS 源/文章/阅读 Activity | Tab+源管理先做，阅读 **S4** |
| 主题模式 | 含 E-ink 电子墨水屏 | 跟随系统/浅色/深色 | Jingshiro 有则做，语雀作补充 |
| 阅读器控件 | 截图标注，无 dp 值 | XML 精确尺寸 | 布局看源码，功能看语雀 |

---

## 优先级说明（2026-07-12）

| 决策 | 说明 |
|------|------|
| **RSS 订阅（UI-12 及文章/阅读/编辑/调试）** | **延后至 S3 末 / S4**，先做阅读器、搜索、书架、书源、登录等核心链路 |
| RSS Tab / 源管理现状 | 保留现有 `rss_tab_page`、源管理入口，点击源仍可为占位，不影响主流程 |

---

## 一、Jingshiro UI 全景 vs Flutter 当前覆盖

### 1.1 Activity 页面对照（按 Jingshiro `res/layout/` 逐个比对）

| # | Jingshiro XML | 对应页面 | Flutter 状态 | 差距 |
|---|---------------|---------|:---:|------|
| 1 | `activity_main.xml` | 主框架 (BottomNav + ViewPager) | ✅ `main_shell.dart` | 需核对 Tab 文案/图标/行为 |
| 2 | `activity_book_read.xml` | 阅读器 | ✅ `reader_page.dart` | UI-1/UI-2：更多设置+系统 TTS+电量+沉浸栏+字重/缩进/简繁字级+翻页五档+屏幕超时分档+全文搜索+模拟追读+主题 zip；HTTP TTS/真仿真卷曲/词级简繁/内嵌字体加载仍开放 |
| 3 | `activity_book_info.xml` | 书籍详情 | ✅ `book_info_page.dart` | 需核对布局：封面+信息+按钮+目录 |
| 4 | `activity_book_search.xml` | 搜索 | ✅ `search_page.dart` | **需核对是否按书源分组（ExpansionTile）** |
| 5 | `activity_book_source.xml` | 书源管理 | ✅ `sources_page.dart` | UI-4：分组/绿红灰校验点/批量/搜索排序；扫码仍缺 |
| 6 | `activity_book_source_edit.xml` | 书源编辑 | ✅ `source_editor_page.dart` | 需核对字段完整度 |
| 7 | `activity_chapter_list.xml` | 目录 | ✅ `toc_sheet.dart` | UI-5：全页 AppBar（返回/目录·书签 Tab/搜索/⋮）+ 缓存字数/云标 + 底栏进度 |
| 8 | `activity_explore_show.xml` | 发现结果列表 | ✅ `explore_list_page.dart` | 需核对 |
| 9 | `activity_config.xml` | 设置中心 | ✅ `config_page.dart` | **缺完整子页：备份/主题/其它** |
| 10 | `activity_about.xml` | 关于 | ✅ my_page 内嵌 | 需核对 |
| 11 | `activity_read_record.xml` | 阅读记录 | ✅ `read_record_page.dart` | 需核对 |
| 12 | `activity_reading_skill.xml` | 阅读 Skill | ✅ `reading_skill_page.dart` | 需核对 |
| 13 | `activity_replace_rule.xml` | 替换净化列表 | ✅ `replace_page.dart` | 需核对 |
| 14 | `activity_replace_edit.xml` | 替换规则编辑 | ⚠️ 内嵌在 replace_page | 需核对 |
| 15 | `activity_cloud_backup.xml` | 云端备份 | ✅ `backup_config_page.dart` | 需核对 |
| 16 | `activity_import_book.xml` | 本地导入 | ✅ 书架菜单 | 需核对 |
| 17 | `activity_rss_source.xml` | RSS 源管理 | ✅ `rss_source_manage_page.dart` | 需核对 |
| 18 | `activity_rss_artivles.xml` | RSS 文章列表 | ❌ **缺失** | 需要新建 |
| 19 | `activity_rss_read.xml` | RSS 阅读 | ❌ **缺失** | 需要新建 |
| 20 | `activity_all_bookmark.xml` | 书签列表 | ✅ `bookmark_page.dart` | UI-8：书签/想法 Tab；跳转阅读器仍开放 |
| 21 | `activity_arrange_book.xml` | 书架整理 | ❌ **缺失** | 需要新建 |
| 22 | `activity_cache_book.xml` | 缓存管理 | ✅ `cache_service.dart` 有数据 | **缺 UI 页面** |
| 23 | `activity_source_debug.xml` | 书源调试 | ✅ `source_debug_panel.dart` | 需核对 |
| 24 | `activity_source_login.xml` | 书源登录 | ❌ **缺失** | 需要新建（含动态表单） |
| 25 | `activity_ai_chat.xml` | AI 聊天 | ✅ `ai_chat_page.dart` | **缺工具调用UI、配置入口** |
| 26 | `activity_welcome.xml` | 欢迎页 | ✅ 隐私协议 Dialog | 需核对 |
| 27 | `activity_web_view.xml` | WebView | ⚠️ `webview_flutter` 已引入 | 需核对 |
| 28 | `activity_code_edit.xml` | 代码编辑器 | ❌ **缺失**（低优） | |
| 29 | `activity_file_manage.xml` | 文件管理 | ✅ `file_manage_page.dart` | UI-8：数据目录基础浏览 |
| 30 | `activity_donate.xml` | 捐赠 | ❌ **缺失**（低优） | |
| 31 | `activity_dict_rule.xml` | 字典规则 | ✅ 基本完成（2026-07-15） | UI-21 |
| 32 | `activity_manga.xml` | 漫画阅读 | ✅ **基本完成** | UI-23 漫画阅读器（引擎图片章后续） |
| 33 | `activity_qrcode_capture.xml` | 扫码 | ❌ **缺失**（低优） | |
| 34 | `activity_audio_play.xml` | 有声播放 | ✅ **基本完成** | UI-22 TTS 播放器（MP3 流后续） |
| 35 | `activity_video_player.xml` | 视频播放 | ❌ **缺失**（低优） | |
| 36 | `activity_search_content.xml` | 全文搜索 | 🟡 `search_content_page.dart` | 当前章+缓存章搜索；上/下结果；未缓存网络章跳过（对齐 legado） |
| 37 | `activity_txt_toc_rule.xml` | TXT 目录规则 | ✅ 基本完成（2026-07-15） | UI-20 |
| 38 | `activity_rss_source_debug.xml` | RSS 源调试 | ❌ **缺失** | |
| 39 | `activity_rss_source_edit.xml` | RSS 源编辑 | ❌ **缺失** | |
| 40 | `activity_rule_sub.xml` | 规则订阅 | ❌ **缺失**（低优） | |
| 41 | `activity_translucence.xml` | 半透明容器 | — | 不是独立页面 |

### 1.2 Dialog 对话框对照（关键项）

| # | Jingshiro Dialog | Flutter 状态 | 说明 |
|---|------------------|:---:|------|
| 1 | `dialog_book_thought.xml` | ⚠️ `note_editor_sheet.dart` | 需核对是否对齐：选中原文+想法的布局 |
| 2 | `dialog_share_thought.xml` | ✅ `note_share_card.dart` | 需核对 |
| 3 | `dialog_bookmark.xml` | ❌ **缺失** | 书签操作对话框 |
| 4 | `dialog_read_aloud.xml` | ❌ **缺失** | TTS 朗读设置 |
| 5 | `dialog_read_bg_text.xml` | ⚠️ `reader_settings.dart` 内嵌 | 需核对是否完整 |
| 6 | `dialog_read_book_style.xml` | ⚠️ 同上 | 与阅读器设置合并？ |
| 7 | `dialog_font_select.xml` | ❌ **缺失** | 字体选择器 |
| 8 | `dialog_book_change_source.xml` | ✅ `change_source_page.dart` | 需核对 |
| 9 | `dialog_change_cover.xml` | ✅ `change_cover_page.dart` | 需核对 |
| 10 | `dialog_ai_config.xml` | ❌ **缺失** | AI 模型/API 配置 |
| 11 | `dialog_ai_memory.xml` | ❌ **缺失** | AI 记忆设置 |
| 12 | `dialog_bookshelf_config.xml` | ❌ **缺失** | 书架布局/排序配置 |
| 13 | `dialog_obsidian_export.xml` | ⚠️ `note_export_service.dart`（纯逻辑） | **缺 UI 配置对话框** |
| 14 | `dialog_search_scope.xml` | ❌ **缺失** | 搜索范围选择 |
| 15 | `dialog_download_choice.xml` | ❌ **缺失** | 下载选项 |
| 16 | `dialog_book_group_picker.xml` | ✅ 书架分组页内嵌 | 需核对 |
| 17 | `dialog_custom_group.xml` | ❌ **缺失** | 自定义分组名输入 |
| 18 | `dialog_content_edit.xml` | ❌ **缺失** | 正文编辑（校对用） |
| 19 | `dialog_source_picker.xml` | ⚠️ `source_chip.dart` | 可能已覆盖 |
| 20 | `dialog_login.xml` | ❌ **缺失** | 书源登录表单 |
| 21 | `dialog_auto_read.xml` | ❌ **缺失** | 自动阅读设置 |
| 22 | `dialog_click_action_config.xml` | ✅ `click_action_panel.dart` | 九宫格 + 全量动作选项；prefs 持久化 |
| 23 | `dialog_simulated_reading.xml` | 🟡 `simulated_reading_dialog.dart` | 模拟追读：对话框+章数解锁；Book/DB `simRead*` 已持久化；书架未读数联动仍开放 |
| 24 | `dialog_page_key.xml` | ❌ **缺失** | 翻页按键配置 |
| 25 | `dialog_read_padding.xml` | ⚠️ 可能内嵌 | 阅读边距设置 |
| 26 | `dialog_thought_underline_style.xml` | ❌ **缺失** | 想法下划线样式 |
| 27 | `dialog_edit_settings.xml` | ⚠️ | 编辑设置？ |
| 28 | `dialog_direct_link_upload_config.xml` | ❌ **缺失** | 直链上传配置 |
| 29 | `dialog_http_tts_edit.xml` | ❌ **缺失** | HTTP TTS 编辑 |
| 30 | `dialog_image_blurring.xml` | ❌ **缺失** | 图片模糊设置 |

---

## 二、核心页面逐页差距分析

### 2.1 主框架 (`activity_main.xml` → `main_shell.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| 底部 Tab | 书架 / 发现 / 订阅 / 我的 (可配置隐藏) | 书架 / 发现 / 订阅 / 我的 ✅ | 需核对图标+文案完全一致 |
| 双击书架 Tab | `gotoTop()` 滚到顶 | ❓ 待确认是否已实现 | 需要 |
| 双击发现 Tab | `compressExplore()` 折叠分类 | ❓ 待确认 | 需要 |
| 再按返回 | 非书架→书架；书架→双击退出 | ❓ 待确认 | 需要 `PopScope` |
| 书架更新角标 | `BadgeView` | 🟡 列表右侧角标（章节名推算） | 缺精确章数字段联动 |
| 默认首页 | `AppConfig.defaultHomePage` | ❌ **缺失** | |
| 发现/订阅可配置隐藏 | `showDiscover/showRss` pref | ❌ **缺失** | |

### 2.2 书架页 (`ui/main/bookshelf/` ⚔ `bookshelf_style1/2_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| 分组 Tab | `TabLayout` + 全部/自定义分组，顶栏左 + 主题色下划线 | ✅ AppBar 内横向分组 Tab（2026-07-15） | |
| 列表项布局 | 封面左 + 书名/作者(人)/进度(钟)/最新(罗盘) + 右角标 | ✅ 扁平四行 + 主题色图标（2026-07-15） | |
| 未读角标 | `BadgeView`：数量；有更新高亮 | 🟡 章节名推算未读数 + primary 高亮 | 缺 `totalChapterNum`/`durChapterIndex` 精确联动 |
| "读完" / "N刷" 标签 | `read_badge` | ✅ UI-6 `ReadBadge`（详情/网格）；列表模式已按截图去掉中间进度条，改右侧角标 | |
| 长按菜单 | 置顶/删除/移动分组/详情 | ✅ UI-7 | |
| 更多菜单 | 添加本地/缓存全部/分组管理/整理 | ✅（整理→UI-10 占位） | |
| style2 网格 | 3 列封面墙 + 分组 Drawer | ✅ `bookshelf_style2_page.dart` | 未按本次列表截图改网格 |
| 下拉刷新 | `SwipeRefreshLayout` + accent 色 + 松手即停转圈；后台 `upToc`；单书 `RotateLoading` | ✅ `LegadoRefreshIndicator` + `refreshShelfToc`（2026-07-15） | 主框架「待更新」角标、分组 `onlyUpdateRead`/`enableRefresh` 仍开放 |

### 2.3 「我的」页 (`ui/main/my/MyFragment` ⚔ `my_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| **快捷四格** | 备份恢复 / WebDAV / Web服务 / 阅读记录 | ✅ | UI-8：圆角/文案对齐 |
| Web 服务状态 | 「已开启」/「未开启」+ IP:端口 | ✅ | 四格文案「已开启」；地址在长按菜单 |
| **设置列表 14 项** | 见下 | Flutter 当前 | 差距 |
| 1. 书源管理 | → BookSourceActivity | ✅ | |
| 2. TXT 目录规则 | → TxtTocRuleActivity | ✅ 管理页 | UI-20 |
| 3. 替换净化 | → ReplaceRuleActivity | ✅ | |
| 4. 字典规则 | → DictRuleActivity | ✅ 管理页 | UI-21 |
| 5. 主题模式 | Dialog (跟随系统/浅色/深色) | ✅ | |
| 6. 备份与恢复 | → ConfigPage(backup) | ✅ | |
| 7. 主题设置 | → ConfigPage(theme) | ✅ | |
| 8. 其它设置 | → ConfigPage(other) | ✅ `other_settings_card.dart` | |
| 9. 书签与想法 | → AllBookmarkActivity | ✅ UI-8 Tab | 点击跳转阅读仍开放 |
| 10. 文件管理 | → FileManageActivity | ✅ UI-8 基础浏览 | |
| 11. 阅读 Skill | → ReadingSkillActivity | ⚠️ 有空页 | 需核对 |
| 12. AI 助手 | → AiChatActivity | ✅ | 需核对入口 |
| 13. 关于 | → AboutActivity | ✅ 内嵌 | |
| 14. 退出 | `finish()` | ✅ | |
| 长按备份恢复 | 本地备份（不在 WebDAV） | ✅ UI-8 | |
| Web 服务长按 | 复制地址/浏览器打开 | ✅ UI-8 | |

### 2.4 搜索页 (`ui/book/search/SearchActivity` ⚔ `search_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| 独立全屏 | Activity（非 Tab） | ✅ `Navigator.push` | |
| AppBar 搜索框 | `SearchView` + 菜单 | ✅ | 需核对菜单项 |
| 结果分组 | **按书源分组** `ExpandableListAdapter` | ❓ 待确认 | **核心差距** |
| 分组标题 | 书源名 + 结果数 | 待确认 | |
| 精准搜索 | `isCommonSearch` toggle | ❌ **缺失** | |
| 搜索 Scope | 选择搜索范围（书名/作者） | ❌ **缺失** | `dialog_search_scope.xml` |
| 搜索历史 | Chip 行 | ✅ `search_history.dart` | 需核对 UI |
| 底栏统计 | 「共 N 本 · M 个书源」 | ❓ 待确认 | |

### 2.5 书籍详情 (`ui/book/info/BookInfoActivity` ⚔ `book_info_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| AppBar 编辑/分享/更多 | ✅ | ✅ UI-6 对齐截图 | |
| 模糊封面英雄区 + 弧形过渡 | ✅ | ✅ UI-6 | 弧度/模糊强度可再微调 |
| 居中大标题 | ✅ | ✅ UI-6 | |
| 元数据行 + 红色操作芯片 | 作者/来源换源/最新/分组设置/目录查看 | ✅ UI-6 | 图标字形与原生略异 |
| 简介灰字两端对齐 | ✅ | ✅ UI-6（全文展示） | 无折叠（截图亦未折） |
| 底栏 删除书籍 / 阅读 | ✅ | ✅ UI-6；非书架书左钮为「加入书架」 | |
| 读完/N刷 | `readIteration` | ✅ 更多菜单「阅读状态」 | 主栏不再展示徽章 |
| 章节目录 | 芯片「查看目录」→ TocSheet | ✅ UI-6；不再嵌入整表 | 缓存进度条移至更多菜单 |
| 目录字数副标题 / 云标 / AppBar+底栏 | TocSheet 全页 | ✅ UI-5 | |

### 2.6 阅读器 (`ui/book/read/ReadBookActivity` ⚔ `reader_page.dart`)

**这是差距最大的页面** — Jingshiro 有 ~2000 行 ReadBookActivity + 多层 Dialog。

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| **顶栏** | 自动隐藏；返回/书名/更多(目录/设置/AI/书票) | ✅ UI-1 自动隐藏+书名+更多菜单 | 书票 overlay 已有；菜单部分项占位 |
| **正文** | 左右翻页/滚动/仿真 | ✅ | 需核对仿真翻页手势 |
| **阅读主题** | 米黄/白/暗/绿 + 自定义 | ✅ | 需核对预设值 |
| **底栏** | 章节进度条 + 页码 + 时间(可选) | ✅ UI-1/UI-2 | 电量 `battery_plus` 真值 |
| **设置面板** | 字号/行距/翻页/主题/字体/边距/TTS/更多 | ✅ UI-2 主路径 | 更多设置：方向/亮度/蓝牙·自定义键 |
| **TTS 朗读** | `dialog_read_aloud.xml` | ✅ 系统 TTS | `flutter_tts` + 上/下句；HTTP TTS 仍占位 |
| **自动阅读** | `dialog_auto_read.xml` 定时翻页 | ✅ UI-2 | 间隔 + Timer 翻页 |
| **正文搜索** | `activity_search_content.xml` | 🟡 UI-2 | 菜单「全文搜索」+ 结果页 + 上/下个结果；仅当前章与文件缓存章 |
| **目录页** | 全页目录（对齐截图 AppBar+列表+底栏） | ✅ `toc_sheet.dart` | UI-5：返回/Tab/搜索/⋮；缓存「N字」/未缓存云标；底栏进度+顶底跳转 |
| **书签** | 点击书签按钮保存 | ✅ UI-1 阅读器内可加书签 | 书签页仍偏「想法」列表 |
| **想法/批注** | 长按选文 → 写想法 | ⚠️ 有 `note_editor_sheet` | **需确认交互已连接** |
| **书票 overlay** | 首尾显示评分+时长 | ❌ | **BookplateService 已有数据层** |
| **换源** | 阅读器内换源 | ✅ `change_source_page.dart` | |
| **模拟追读** | `dialog_simulated_reading.xml` | 🟡 UI-24 | 对话框+章数解锁；配置写入 Book/DB（备份 JSON 含字段）；WebDAV/书架未读数联动仍开放 |
| **点击行为配置** | `dialog_click_action_config.xml` | ✅ UI-2 | 九宫格（对齐 AppConfig 默认）+ 选择操作列表；`ClickActionPrefs` 持久化 |
| **翻页按键配置** | `dialog_page_key.xml` | ✅ UI-2 | 音量键 + 蓝牙键 + 自定义录制 |
| **AI 入口** | 侧滑/FAB → AiChat | ✅ `ai_chat_page.dart` | 需核对入口位置 |
| **亮度** | 跟随系统/手动 | ✅ UI-2 | 阅读遮罩亮度（非系统亮度 API） |
| **屏幕方向** | 锁定/自由 | ✅ UI-2 | 跟随/竖/横 |
| **音量键翻页** | `volKeyTurnPage` | ✅ UI-2 开关 | 部分桌面/系统可能拦截 |
| **长按选择** | 选择文字+菜单(复制/划线/写想法) | ⚠️ `reader_selectable_text.dart` | 需核对 |

### 2.7 发现页 (`ui/main/explore/ExploreFragment` ⚔ `explore_tab_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| 书源横向 Chip | `RecyclerView` 水平 | ✅ `source_chip.dart` | |
| 分类网格 | 根据 exploreUrl JSON 展示 | ✅ | 需核对格式兼容 |
| AppBar 搜索 | → SearchPage | ✅ | |
| 双击 Tab 折叠 | `compressExplore()` | ❓ 待确认 | |

### 2.8 书源管理 (`ui/book/source/manage/` ⚔ `sources_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| 绿/红/灰点 | 校验通过/失败/未校验 | ✅ UI-4 `SourceStatusDot` | |
| 分组标题 | 按 `bookSourceGroup` 分组 | ✅ `SectionHeader` 分组 | |
| 批量操作 | 多选→启用/禁用/分组/校验/删除 | ✅ UI-4 底栏批量操作 | |
| 导入方式 | JSON/URL/二维码/本地文件/剪贴板 | ✅ 已有大部分 | **缺二维码扫描** |
| 校验书源 | `CheckSourceActivity` | ✅ `validate_source()` | |
| 搜索书源 | 书源内搜索 | ✅ UI-4 名称/分组/URL | |
| 排序 | 按名称/分组/启用状态 | ✅ UI-4 | |

---

## 三、缺失页面详细开发任务

### 3.1 🔴 高优先级 — 核心体验差异（必须修正）

#### Task UI-1: 阅读器底栏 (`reader_page.dart`) — 🟡 基本完成（2026-07-14）

```
┌─────────────────────────────────────────────┐
│ [自动隐藏顶栏]  书名              更多 ⠇     │
│                                             │
│              (正文内容)                       │
│                                             │
├─────────────────────────────────────────────┤
│ 第一章 第1/15页           ⏱ 21:30  🔋 85%  │
│ ████████████░░░░░░░░░░░ 章节进度条            │
└─────────────────────────────────────────────┘
```

- [x] 底部进度滑块 + 章节页码 + 时间/全书进度
- [x] 顶栏自动隐藏（中区点击切换；进入约 3s 自动收起）
- [x] 更多菜单可落地项（目录/设置/AI/换源/刷新/书签/拷贝/书籍信息）+ 其余明确占位
- [x] 信息区电量开关（真值待 battery 插件）；离线缓存真实下载、替换净化等深度行为仍开放

#### Task UI-2: 阅读器设置补全 (`reader_settings.dart`) — 🟡 超时分档+翻页五档（2026-07-14）

对齐 `dialog_read_bg_text.xml` + `dialog_read_book_style.xml`：

- [x] **字体选择器**（骨架）— 系统/衬线/等宽；自定义导入明确占位
- [x] **边距设置** — 左右/上下调节（非四角完全独立，够用）
- [x] **信息区开关** — 页码/时间/电量（`battery_plus`）
- [x] **音量键翻页** — 设置开关 + Focus 接线；**朗读时音量键翻页**（`volumeKeyPageOnPlay`）
- [x] **TTS / 自动阅读 / 点击区域** — 设置与菜单入口接面板（勿静默）
- [x] **TTS 朗读设置**（`dialog_read_aloud.xml`）— `flutter_tts` 系统发音 + 上/下句；HTTP TTS 仍占位
- [x] **自动阅读**（`dialog_auto_read.xml`）— 间隔滑块 + 定时翻页（期间强制常亮）
- [x] **点击行为配置**（`dialog_click_action_config.xml`）— 九宫格热区 + 默认动作对齐 AppConfig；设置 UI 全屏九宫格；prefs 持久化
- [x] **更多设置入口** — 屏幕方向/超时分档/亮度遮罩/蓝牙翻页器/自定义翻页键/文字底部对齐
- [x] **屏幕超时** — 默认 / 1 / 5 / 10 分钟 / 常亮（`wakelock_plus` + 计时重置；对齐 keepLight）
- [x] **状态栏/导航栏沉浸 + 扩展到刘海** — SystemChrome + SafeArea；菜单显时短暂恢复系统栏
- [x] **排版** — 中/粗/细、缩进 0–4、字距/段距、简繁字级表、两端对齐、底部对齐；芯片顺序对齐 `dialog_read_book_style`
- [x] **翻页动画** — 覆盖 / 滑动 / 仿真(透视近似) / 滚动 / 无
- [x] **全文搜索**（`activity_search_content`）— 结果页 + 阅读内上/下结果；当前章与缓存章
- [x] **模拟追读**（`dialog_simulated_reading`）— 开关/日期/起始章/日更；目录与后章裁剪；Book/DB `simRead*` 同步

- [x] **主题 zip**（`dialog_read_bg_text` 长按入口）— 共用布局 + 长按主题 → 导入/导出 zip + 文字/背景/强调色；`ReadStyleZipService` + 槽位覆盖 prefs

仍开放 / 缺口（勿误报完成）：

- 简繁：**词级**词典（OpenCC / quick-transfer）未接入，仅字级表
- 仿真翻页为透视近似，**非** legado 真·书页卷曲网格；HTTP TTS
- 主题 zip：自定义字体文件已落盘但阅读器未 `FontLoader`；关闭共用布局后排版仍全局（未做每主题独立字号行距）；内置 assets 背景图库未做
- 文字底部对齐为分页贴底，未做 legado 行距重分配式撑满
- 全文搜索：未做全书联网扫章（净化/正则菜单已落地）
- 模拟追读：Book/DB 字段已同步；WebDAV 远端合并与书架未读数联动仍开放；旧 SharedPreferences 会在进入阅读器时迁移

另：正文阻塞修复同轮收尾 — 空解析 `Err`、坏占位不缓存、`toEngineJson` 保嵌套规则、失败展示真实错误。

#### Task UI-3: 搜索页书源分组 (`search_page.dart`) — 🟡 基本完成（2026-07-14）

- [x] `ExpansionTile` 每组一书源（标题=书源名 + 结果数）
- [x] 组内 `BookListTile` 展示搜索结果
- [x] 精准搜索（书名包含 + 可选作者过滤）
- [x] 搜索范围（全部 / 按分组 / 自选书源）
- [x] 底栏「共 N 本 · M 个书源」（搜索中实时更新）
- [ ] 书源标签筛选（后续可加）

#### Task UI-4: 书源管理对齐 (`sources_page.dart`) — ✅ 基本完成（2026-07-14）

- [x] 按 `bookSourceGroup` 分组展示（`SectionHeader` 分组列表）
- [x] 批量操作栏（多选：启用/禁用/分组/校验/删除）
- [x] 分组标题 + 绿/红/灰点验证（通过/失败/未校验）
- [x] 书源搜索/排序（名称/分组/启用）

#### Task UI-5: 目录页增强 (`toc_sheet.dart`) — ✅ 对齐截图（2026-07-15）

- [x] 全页路由（阅读器 / 书籍详情共用 `TocSheet.show`）
- [x] AppBar：返回 | 「目录」「书签」Tab（主色下划线）| 搜索 | 溢出菜单（正序/倒序、定位当前）
- [x] 已缓存：标题 + 副标题字数「N字」（文件缓存统计）；未缓存：标题 + 右侧云标
- [x] 当前章高亮 + 打开时滚动定位
- [x] 底栏：当前章进度文案「标题(n/total)」+ 顶/底跳转
- [ ] 溢出菜单其余项（刷新目录/显示字数开关等）与 legado 逐项对齐

#### Task UI-6: 书籍详情补全 (`book_info_page.dart`) — ✅ 对齐 Jingshiro 截图（2026-07-15）

- [x] AppBar：编辑 / 分享 / 更多（换封面、阅读状态、刷新目录、缓存、目录、书架）
- [x] 模糊封面英雄区 + 居中封面 + 底部浅凹弧过渡白底
- [x] 元数据行：作者 / 来源+换源 / 最新 / 分组+设置分组 / 目录+查看目录（红芯片）
- [x] 简介全文灰字两端对齐；底栏「删除书籍|加入书架」+「阅读」
- [x] 读完/N刷仍经更多菜单；目录经 `TocSheet`（不再嵌整表）

#### Task UI-7: 书架长按菜单 + 列表对齐 (`bookshelf_style1_page.dart`) — ✅ 基本完成（2026-07-15）

- [x] 置顶（本地 prefs `shelf_pinned_ids`）
- [x] 移动分组
- [x] 详情（跳转 BookInfo）
- [x] "整理"入口（占位页 → UI-10）
- [x] 移除（原长按确认保留为菜单项）
- [x] 列表 UI 对齐 Jingshiro 截图：顶栏分组 Tab、扁平四行元数据（人/钟/罗盘）、右侧未读角标（章节名推算；精确章数仍开放）

#### Task UI-8: 「我的」页菜单补齐 (`my_page.dart`) — ✅ 基本完成（2026-07-14）

- [x] TXT 目录规则 → 占位页
- [x] 字典规则 → 占位页
- [x] 文件管理 → 基础文件浏览器（`file_manage_page.dart`：数据目录浏览/删除/分享）
- [x] 书签与想法 → 数据连接 + 书签/想法分 Tab（`NoteService`；书签=`noteContent` 以「书签」开头）
- [x] 快捷四格长按行为（备份→本地备份，Web服务→复制地址/浏览器打开）
- [x] Web 服务状态刷新（启停后 + 从子页返回 + App resume）

---

### 3.2 🟡 中优先级 — 补全新页面

#### Task UI-9: 阅读器正文搜索 (`activity_search_content.xml`) — 🟡 当前章+缓存（2026-07-14）

- [x] 新页面：搜索框 + 结果列表 + 「搜索结果」底栏（顶/底滚动）
- [x] 点击结果跳转 + 阅读内上/下个结果条（对齐 `view_search_menu`）
- [x] 当前章始终可搜；其余章仅文件缓存（对齐 legado 网络书跳过未缓存）
- [x] 净化/正则菜单（`menu_enable_replace` / `menu_enable_regex`）
- [ ] 全书联网边下边搜；结果内高亮滚动条快翻完善

#### Task UI-10: 书架整理 (`activity_arrange_book.xml`) — ✅ 基本完成（2026-07-15）

- [x] 拖拽排序界面（列表 ReorderableListView；网格长按调位）
- [x] 批量选择→移动到分组
- [x] 批量删除
- [x] 列表/网格整理切换；自定义顺序 prefs 持久化
- [ ] 换源批量/更新开关/区间滑选等待 legado 次级菜单项

#### Task UI-11: 书源登录 (`activity_source_login.xml` + `dialog_login.xml`) — 🟡 表单+URL（2026-07-15）

- [x] 根据书源 `loginUi` JSON 渲染动态表单（text/password/button/toggle/select/checkbox）
- [x] 登录信息 SharedPreferences 持久化；书源列表登录入口
- [x] `loginUrl` 为 http(s) 时外链打开
- [ ] `@js:` / `<js>` 动态 loginUi 与按钮 JS、引擎 `login()` 脚本执行
- [ ] WebView 内嵌登录（当前外链）

#### Task UI-12: RSS 文章列表 + 阅读 (`activity_rss_artivles.xml` + `activity_rss_read.xml`) — ⏸ 延后

> 优先级放后：订阅 Tab 与源管理已有骨架；文章列表/阅读/WebView 方案待 S3 末再定。

- [ ] RSS 订阅源 → 文章列表页
- [ ] RSS 文章阅读页（WebView 或纯文本 / 外链，方案待定）
- [ ] 收藏/已读标记

#### Task UI-13: 缓存管理页面 (`activity_cache_book.xml`) — ✅ 基本完成（2026-07-15）

- [x] 书籍缓存列表（`CacheBookPage`，对齐 `CacheActivity`：书名/作者/已缓存 N/M + 体积）
- [x] 按书籍展示缓存大小；播放/停止下载
- [x] 清除选中/全部缓存；搜索；入口：我的 / 书架更多 / 阅读顶栏下载
- [ ] 导出（txt/epub）仍开放

#### Task UI-14: AI 配置 Dialog (`dialog_ai_config.xml` + `dialog_ai_memory.xml`) — ✅ 基本完成（2026-07-15）

- [x] API URL + Key + Model 配置（含获取模型列表 / 测试可用性）
- [x] 记忆管理（列表 + 清除）
- [x] 预设 System Prompt（人设）、工具开关、头像 URL
- [ ] AI 对话聊天本体仍占位（配置已可保存）

#### Task UI-15: Obsidian 导出配置 (`dialog_obsidian_export.xml`) — ✅ 基本完成（2026-07-15）

- [x] REST API 模式：URL + Token + Vault 路径 + 测试连接
- [x] 本地文件模式：文件夹路径（file_picker）+ 相对子目录
- [x] 导出范围：全部想法（书签页入口）；可选 bookId
- [x] 自动导出开关偏好持久化（触发点后续可接写想法）

#### Task UI-16: 下载选项 (`dialog_download_choice.xml`) — ✅ 基本完成（2026-07-15）

- [x] 下载范围：全部 / 未缓存 / 从当前到结尾 / 后 N 章
- [x] 并发数设置（1–8，已接入 `downloadAllChapters`）
- [~] 格式：纯文本已支持；**HTML 导出延后**（用户确认后续再做）

---

### 3.3 🟢 低优先级 — 锦上添花 & 新功能模块

#### Task UI-17: 扫码导入 (`activity_qrcode_capture.xml`)

- [ ] `mobile_scanner` 或 `qr_code_scanner` 包
- [ ] 扫描书源 JSON URL → 导入

#### Task UI-18: 文件管理 (`activity_file_manage.xml`)

- [ ] 基础文件浏览器
- [ ] 支持查看/删除/分享

#### Task UI-19: 规则订阅 (`activity_rule_sub.xml` + `dialog_rule_sub_edit.xml`)

- [ ] 规则订阅源管理
- [ ] 从 URL 更新替换规则/书源

#### Task UI-20: TXT 目录规则 (`activity_txt_toc_rule.xml`) — ✅ 基本完成（2026-07-15）

- [x] 自定义 TXT 章节识别正则（管理页 + 编辑对话框）
- [x] 预设模板（Jingshiro 内置规则种子；导入/恢复默认）
- [x] SharedPreferences 持久化；Dart 分章回退优先启用规则
- [ ] 拖拽排序 / 在线·扫码导入 / 导出（后续）

#### Task UI-21: 字典规则 (`activity_dict_rule.xml` + `dialog_dict_rule_edit.xml`) — ✅ 基本完成（2026-07-15）

- [x] 查词规则管理（列表启用开关 / 编辑 / 多选操作栏 / 导入内置）
- [x] 规则测试（编辑对话框：测试词 + 简化 HTTP/`{{key}}`；`@js` 提示）
- [x] SharedPreferences 持久化 + Jingshiro `dictRules.json` 种子
- [ ] 拖拽排序 / 在线·扫码导入 / 完整 AnalyzeUrl+JS 查词（后续）

#### Task UI-22: 有声播放器 (`activity_audio_play.xml`) — ✅ 基本完成（2026-07-16）

- [x] TTS 播放控件（播放/暂停/快进/后退；句级进度条）
- [x] 播放列表（章节目录底栏 sheet）
- [x] 定时关闭（0–180 分钟 SliderPopup 对齐）
- [x] 语速 / 播放模式（列表播放·单曲循环·随机·列表循环）
- [x] 阅读器底栏「朗读」入口；长按仍打开朗读面板；面板可进全屏播放器
- [ ] 真有声源 MP3 流播放 / 歌词 LyricViewX / HTTP TTS（后续）

#### Task UI-23: 漫画阅读器 (`activity_manga.xml`) — ✅ 基本完成（2026-07-16）

- [x] 图片加载/预加载（正文 `<img>`/URL 解析 + `precacheImage`；空结果可重试 stub）
- [x] 缩放/平移手势（`InteractiveViewer`；可禁用）
- [x] 阅读方向（左→右/右→左/上→下）
- [x] 滤镜（`dialog_manga_color_filter.xml`：亮度/RGBA）
- [x] 墨水屏模式（`dialog_manga_epaper.xml`：阈值；灰度互斥）
- [ ] 真漫画源整章多页引擎联调 / Footer 配置弹窗（后续）

#### Task UI-24: 模拟追读 (`dialog_simulated_reading.xml`) — 🟡 Book/DB 已同步（2026-07-15）

> 对标 legado「模拟追读」：按开始日期 / 起始章节 / 日更章数解锁 TOC，**不是**自动翻页。

- [x] 对话框：开关 / 开始日期 / 起始章节 / 日更章数（中文文案对齐 `values-zh`）
- [x] `simulatedTotalChapterNum` 公式裁剪目录与后章翻页
- [x] 写入 Book 实体字段 + SQLite schema v11（`simRead*`）；进备份 JSON；旧 SharedPreferences 迁移
- [ ] WebDAV 远端合并策略 / 书架未读数联动（legado `durChapterIndex` 可见差）

#### Task UI-25: 捐赠页 (`activity_donate.xml`)

- [ ] 捐赠二维码/链接

#### Task UI-26: 欢迎页 (`activity_welcome.xml`)

- [ ] 首次启动引导（功能简介）
- [ ] 隐私协议确认（已有 Dialog ✅）

#### Task UI-27: 代码编辑器 (`activity_code_edit.xml`)

- [ ] JSON/JS 语法高亮（低优，已有 `source_editor_page.dart` 覆盖）

---

## 四、按开发阶段整理

### S1 — 立即修复（1-2 周）：阅读体验核心差异

```
Task UI-1:  阅读器底栏 + 顶栏自动隐藏 + 更多菜单  ✅ 基本完成（2026-07-14）
Task UI-2:  阅读器设置补全（字体/TTS/自动阅读/点击行为/翻页键）  🟡 超时分档+翻页五档+全文搜索+模拟追读+主题 zip；HTTP TTS/真仿真/词级简繁/FontLoader 仍开放
Task UI-3:  搜索页按书源分组 + 精准搜索 + 搜索范围  ✅ 基本完成（2026-07-14）
Task UI-4:  书源管理分组展示 + 批量操作 + 绿红灰点验证  ✅ 基本完成（2026-07-14）
Task UI-5:  目录页对齐截图（AppBar/字数·云标/底栏）  ✅ 对齐截图（2026-07-15）
Task UI-6:  书籍详情对齐 Jingshiro 截图（英雄区/元数据红芯片/底栏）  ✅（2026-07-15）
Task UI-7:  书架长按菜单完整化  ✅ 基本完成（2026-07-14）
Task UI-8:  我的页菜单补齐 + 快捷四格行为  ✅ 基本完成（2026-07-14）
```

### S2 — 页面补全（2-3 周）：缺失页面 + 对话框

```
Task UI-9:  阅读器正文搜索  🟡 当前章+缓存+上/下结果
Task UI-10: 书架整理
Task UI-11: 书源登录（动态表单 + JS）  🟡 表单+URL；JS/WebView 仍开放
Task UI-13: 缓存管理页面  ✅ 基本完成（2026-07-15）
Task UI-16: 下载选项 Dialog  ✅ 基本完成（HTML 导出延后）
Task UI-14: AI 配置 Dialog  ✅ 基本完成（2026-07-15）
Task UI-15: Obsidian 导出配置  ✅ 基本完成（2026-07-15）
Task UI-20: TXT 目录规则  ✅ 基本完成（2026-07-15）
Task UI-21: 字典规则  ✅ 基本完成（2026-07-15）
```

### S3 — 功能模块（3-4 周）：新功能 + 低优先级

```
Task UI-17: 扫码导入
Task UI-18: 文件管理
Task UI-19: 规则订阅
Task UI-22: 有声播放器 (TTS)  ✅ 基本完成（2026-07-16）
Task UI-23: 漫画阅读器  ✅ 基本完成（2026-07-16）
Task UI-24: 模拟追读  🟡 对话框+章数解锁+Book/DB 同步；WebDAV/书架未读数仍开放
Task UI-25: 捐赠页
Task UI-26: 欢迎引导页
Task UI-27: 代码编辑器（低优）
```

### S4 — 延后（RSS 订阅阅读）

```
Task UI-12:  RSS 文章列表 + 阅读（含 WebView/外链方案选型）
             activity_rss_source_edit / rss_source_debug（若与 UI-12 一并交付）
```

---

## 五、总工期

| 阶段 | 内容 | 工期 |
|------|------|:---:|
| **S1** | 核心体验差异修复（8 个 Task） | 1-2 周 |
| **S2** | 缺失页面补全（7 个 Task，不含 RSS） | 2-3 周 |
| **S3** | 新功能模块（11 个 Task） | 3-4 周 |
| **S4** | RSS 订阅阅读（UI-12 等） | 按需 |
| **总计** | S1–S3 主线 | **6-9 周** |

---

## 六、完成度评估

| 分类 | 完成度 | 说明 |
|------|:---:|------|
| 主框架 + 导航 | 85% | 四 Tab 就位，缺角标/默认首页/可配置隐藏 |
| 书架 | 92% | UI-7：长按菜单 + 列表布局对齐截图（顶栏 Tab/四行元数据/角标）；精确未读章数与整理拖拽仍开放 |
| 我的页 | 96% | UI-8：快捷四格长按+Web 状态；文件管理基础浏览；书签/想法 Tab；TXT 目录规则+字典规则已落地 |
| 搜索 | 90% | UI-3：按书源分组 + 精准搜索 + Scope |
| 发现 | 85% | 接近完成 |
| 书籍详情 | 96% | UI-6：截图布局（模糊头图/红芯片/删除+阅读底栏）；换源页后端仍占位；图标字形可再抠 |
| 目录 | 95% | UI-5：全页 AppBar+字数/云标+底栏；溢出菜单次级项仍可再抠 |
| **阅读器** | **93%** | UI-1+UI-2：超时分档+翻页五档+沉浸+系统 TTS+全文搜索(缓存)+模拟追读+主题 zip；HTTP TTS/真仿真卷曲/词级简繁/全书联网搜仍开放 |
| 书源管理 | 90% | UI-4：分组/绿红灰校验点/批量/搜索排序；扫码仍缺 |
| RSS | 50% | Tab+源管理已有；**文章/阅读延后 S4** |
| 新模块(有声/漫画/扫码等) | 28% | UI-22/23 有声+漫画基本完成；扫码等仍缺 |
| **综合** | **~60%** | |

---

---

## 七、动画与动效对齐（Motion）

> 参照：`fragment_books.xml` / `BooksFragment.kt` / `RotateLoading` / 阅读器 `PageAnim`

### 7.1 书架

| 动效 | Jingshiro | Flutter（2026-07-15） | 差距 |
|------|-----------|----------------------|------|
| 下拉刷新指示器 | `SwipeRefreshLayout`，`accentColor` 圆环，2dp 线宽 | `LegadoRefreshIndicator`：`primary` 色 + 120ms 即结束 | ✅ 行为对齐 |
| 刷新语义 | 松手即 `isRefreshing=false`；`upToc` 后台并行更目录 | `refreshShelfToc` 后台队列（默认并发 3） | ✅ |
| 单书更新中 | 隐藏未读角标 → `RotateLoading` 26dp | `LegadoShelfUpdatingIndicator` 替换角标/网格角标 | ✅ 近似（Flutter 为 `CircularProgressIndicator`） |
| 列表 overscroll 光晕 | `setEdgeEffectColor(primaryColor)` | `LegadoScrollBehavior` | ✅ |
| 滚到顶 | 双击书架 Tab `smoothScrollToPosition(0)` | `main_shell` 已有双击滚顶 | 需核对 E-Ink 模式用 `scrollTo` |
| 书架快速滚动条 | `FastScrollRecyclerView` 可配置 | ❌ 未做 | UI-7 开放 |
| 列表 item 动画 | `itemAnimator = null`（无插入动画） | 默认 Material 列表动画 | 可显式 `itemAnimator` 关闭 |

### 7.2 阅读器

| 动效 | Jingshiro | Flutter | 差距 |
|------|-----------|---------|------|
| 顶/底栏显隐 | 点击中区切换 + ~3s 自动隐藏 | ✅ UI-1 | 缓动曲线可再抠 |
| 翻页 | 覆盖/滑动/仿真卷曲/滚动/无 | 五档已有；仿真为透视近似 | 真·书页网格卷曲仍开放 |
| 菜单面板 | BottomSheet / Dialog 滑入 | `showModalBottomSheet` | 圆角/时长/遮罩透明度可再对齐 |
| 朗读/界面/设置面板 | 独立 Dialog XML | 内嵌 `reader_settings` | 分层面板切换动画未逐项对齐 |

### 7.3 主框架 / 其它

| 动效 | Jingshiro | Flutter | 差距 |
|------|-----------|---------|------|
| Tab 切换 | `ViewPager` 滑动（可关） | `IndexedStack` 无滑动 | 可选补横向切换动画 |
| 发现下拉刷新 | 无统一 SwipeRefresh（按页） | `RefreshIndicator` 拉发现列表 | 发现页 legado 无等价下拉 |
| 书架更新角标 | `BadgeView` + `onUpBooksLiveData` | `shelfUpdateActiveCount` 已埋点未接 UI | 主框架角标待接 |

### UI-7 / UI-10 动画备注

- **UI-7**：下拉刷新与单书 `RotateLoading` 已对齐；精确未读章数字段、`onlyUpdateRead` 分组策略、主框架待更新角标仍开放。
- **UI-10**：书架整理拖拽排序需 `ReorderableListView` + legado `itemAnimator=null` 无弹跳风格。

---

> 最后更新：2026-07-15 | 引擎 v0.5.6 | Focus: UI 复刻（模拟追读 Book/DB 已同步；HTTP TTS/真仿真卷曲网格/OpenCC/全书联网搜/书架未读数联动仍开放；RSS 延后）| 参考：[语雀 Wiki](https://www.yuque.com/legado/wiki)
