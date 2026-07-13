# Phase F：UI 一比一复刻 Jingshiro/Legado — 差距分析与开发计划

> **开发流程：** [DEVELOPMENT_PROCESS.md](./DEVELOPMENT_PROCESS.md) · **文档索引：** [README.md](./README.md)  
> **对标项目：** [Jingshiro/legado](https://github.com/Jingshiro/legado)  
> **参照源码：** `app/src/main/java/io/legado/app/ui/` + `app/src/main/res/layout/`  
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

**顶栏 / 更多菜单**

- [x] 书名（完整）— UI-1：顶栏标题显示书名
- [x] 换源、刷新 — UI-1 已接线；离线缓存入口已有，行为占位 SnackBar（→ UI-13）
- [x] 更多：书签、拷贝内容、书籍信息已落地；翻页动画/云端进度/反转/替换净化/重新分段/更新目录为明确占位文案（勿静默）
- [x] 章节 + 书源地址（两行）— 章头标题 + 书源名/URL
- [x] 顶栏自动隐藏 — 点击中区切换；进入后约 3s 自动收起

**底栏**

- [x] 章节跳转（前/后章）
- [x] **本章进度滑块**（slide：章内页；scroll/单页：全章索引）
- [x] 信息区基础版：时间、页码、全书进度%（电量开关已接，真值待 battery 插件）

**朗读面板**（`dialog_read_aloud`）

- [ ] 上/下章、上/下句、播放/停止（UI-2：设置内入口 + 明确占位 SnackBar）
- [ ] 定时、语速滑块、TTS 引擎选择、后台播放

**界面面板**（`dialog_read_bg_text` / `dialog_read_book_style`）

- [ ] 字重（中/粗/细）、缩进、简繁
- [x] 字体（内置系统/衬线/等宽骨架；自定义导入占位）
- [x] 边距（左右/上下调节）
- [x] 信息区开关（页码/时间/电量）
- [x] 字号/行距（段距/字距仍缺）
- [ ] 翻页动画、文字颜色/背景（主题预设已有）
- [ ] 主题 zip 导入（取消共用布局 → 长按主题）

**设置面板**（阅读设置子页）

- [ ] 屏幕方向、屏幕超时
- [ ] 隐藏状态栏/导航栏、扩展到刘海
- [ ] 文字两端对齐、文字底部对齐
- [x] 音量键翻页开关（蓝牙翻页器仍缺）
- [ ] 朗读时音量键翻页
- [ ] 自动换源、长按选择文本
- [ ] 显示亮度调节控件
- [ ] 点击区域设置、自定义翻页按键（UI-2：入口 + 明确占位）
- [x] 自动阅读入口（明确占位，未实现定时翻页）

**目录浮层**

- [ ] 目录 / 书签 Tab 切换
- [ ] 当前章节高亮、未缓存标识

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
| 2 | `activity_book_read.xml` | 阅读器 | ✅ `reader_page.dart` | UI-1/UI-2 可落地项已接；TTS/自动阅读/点击区/电量真值/仿真等仍开放 |
| 3 | `activity_book_info.xml` | 书籍详情 | ✅ `book_info_page.dart` | 需核对布局：封面+信息+按钮+目录 |
| 4 | `activity_book_search.xml` | 搜索 | ✅ `search_page.dart` | **需核对是否按书源分组（ExpansionTile）** |
| 5 | `activity_book_source.xml` | 书源管理 | ✅ `sources_page.dart` | **缺绿/红点、分组标题、批量操作栏** |
| 6 | `activity_book_source_edit.xml` | 书源编辑 | ✅ `source_editor_page.dart` | 需核对字段完整度 |
| 7 | `activity_chapter_list.xml` | 目录 | ✅ `toc_sheet.dart` | **缺正序/倒序切换、已缓存图标、当前章高亮** |
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
| 20 | `activity_all_bookmark.xml` | 书签列表 | ⚠️ `bookmark_page.dart`（空壳） | **缺书签数据+跳转逻辑** |
| 21 | `activity_arrange_book.xml` | 书架整理 | ❌ **缺失** | 需要新建 |
| 22 | `activity_cache_book.xml` | 缓存管理 | ✅ `cache_service.dart` 有数据 | **缺 UI 页面** |
| 23 | `activity_source_debug.xml` | 书源调试 | ✅ `source_debug_panel.dart` | 需核对 |
| 24 | `activity_source_login.xml` | 书源登录 | ❌ **缺失** | 需要新建（含动态表单） |
| 25 | `activity_ai_chat.xml` | AI 聊天 | ✅ `ai_chat_page.dart` | **缺工具调用UI、配置入口** |
| 26 | `activity_welcome.xml` | 欢迎页 | ✅ 隐私协议 Dialog | 需核对 |
| 27 | `activity_web_view.xml` | WebView | ⚠️ `webview_flutter` 已引入 | 需核对 |
| 28 | `activity_code_edit.xml` | 代码编辑器 | ❌ **缺失**（低优） | |
| 29 | `activity_file_manage.xml` | 文件管理 | ❌ **缺失**（低优） | |
| 30 | `activity_donate.xml` | 捐赠 | ❌ **缺失**（低优） | |
| 31 | `activity_dict_rule.xml` | 字典规则 | ❌ **缺失**（低优） | |
| 32 | `activity_manga.xml` | 漫画阅读 | ❌ **缺失** | **新功能模块** |
| 33 | `activity_qrcode_capture.xml` | 扫码 | ❌ **缺失**（低优） | |
| 34 | `activity_audio_play.xml` | 有声播放 | ❌ **缺失** | **新功能模块** |
| 35 | `activity_video_player.xml` | 视频播放 | ❌ **缺失**（低优） | |
| 36 | `activity_search_content.xml` | 正文搜索 | ❌ **缺失** | 阅读器内全文搜索 |
| 37 | `activity_txt_toc_rule.xml` | TXT 目录规则 | ❌ **缺失**（低优） | |
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
| 22 | `dialog_click_action_config.xml` | ❌ **缺失** | 点击行为配置 |
| 23 | `dialog_simulated_reading.xml` | ❌ **缺失** | 模拟阅读 |
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
| 书架更新角标 | `BadgeView` | ❌ **缺失** | |
| 默认首页 | `AppConfig.defaultHomePage` | ❌ **缺失** | |
| 发现/订阅可配置隐藏 | `showDiscover/showRss` pref | ❌ **缺失** | |

### 2.2 书架页 (`ui/main/bookshelf/` ⚔ `bookshelf_style1/2_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| 分组 Tab | `TabLayout` + 全部/自定义分组 | 有分组选择 ✅ | 需核对 UI 形式 |
| 列表项布局 | 封面左 + 书名/作者/进度/当前章 | ✅ | 需核对间距/字号 |
| "读完" / "N刷" 标签 | `read_badge` | ❌ **ReadBadge widget 是否存在？** | 需植入列表项 |
| 长按菜单 | 置顶/删除/移动分组/详情 | ⚠️ 只有删除 | **缺置顶/移动分组/详情** |
| 更多菜单 | 添加本地/缓存全部/分组管理/整理 | ✅ 已有大部分 | **缺"整理"入口** |
| style2 网格 | 3 列封面墙 + 分组 Drawer | ✅ `bookshelf_style2_page.dart` | 需核对列数/间距 |
| 下拉刷新 | `SwipeRefreshLayout` | ✅ `RefreshIndicator` | |

### 2.3 「我的」页 (`ui/main/my/MyFragment` ⚔ `my_page.dart`)

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| **快捷四格** | 备份恢复 / WebDAV / Web服务 / 阅读记录 | ✅ | 需核对图标+文案+圆角 12dp |
| Web 服务状态 | 「已开启」/「未开启」+ IP:端口 | ✅ `web_api_settings_card.dart` | 需核对位置是否在四格 |
| **设置列表 14 项** | 见下 | Flutter 当前 | 差距 |
| 1. 书源管理 | → BookSourceActivity | ✅ | |
| 2. TXT 目录规则 | → TxtTocRuleActivity | ❌ **占位/缺失** | |
| 3. 替换净化 | → ReplaceRuleActivity | ✅ | |
| 4. 字典规则 | → DictRuleActivity | ❌ **占位/缺失** | |
| 5. 主题模式 | Dialog (跟随系统/浅色/深色) | ✅ | |
| 6. 备份与恢复 | → ConfigPage(backup) | ✅ | |
| 7. 主题设置 | → ConfigPage(theme) | ✅ | |
| 8. 其它设置 | → ConfigPage(other) | ✅ `other_settings_card.dart` | |
| 9. 书签与想法 | → AllBookmarkActivity | ⚠️ 有空页 | **数据未连接** |
| 10. 文件管理 | → FileManageActivity | ❌ **缺失** | |
| 11. 阅读 Skill | → ReadingSkillActivity | ⚠️ 有空页 | 需核对 |
| 12. AI 助手 | → AiChatActivity | ✅ | 需核对入口 |
| 13. 关于 | → AboutActivity | ✅ 内嵌 | |
| 14. 退出 | `finish()` | ✅ | |
| 长按备份恢复 | 本地备份（不在 WebDAV） | ❓ 待确认 | |
| Web 服务长按 | 复制地址/浏览器打开 | ❓ 待确认 | |

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
| 封面 + 书名/作者/书源 | ✅ | ✅ | 需核对布局 |
| 简介 | 可展开/收起 | ❓ 待确认 | |
| 操作按钮 | 加入书架 / 阅读 / 换源 | ✅ 加入/阅读 | **缺"换源"按钮明显位置** |
| 缓存进度 | 进度条 + x/y 已缓存 | ✅ | |
| 读完/N刷 标签 | `readStatus` | ❌ | **需 Book 模型扩展** |
| 章节目录 | 嵌入或跳转 | ✅ | |
| 目录已缓存图标 | `isDownloaded` 图标 | ❌ | |
| 目录正序/倒序 | `toggleOrder()` | ❌ | |
| 当前章高亮 | `currentChapter` 高亮 | ❓ 待确认 | |

### 2.6 阅读器 (`ui/book/read/ReadBookActivity` ⚔ `reader_page.dart`)

**这是差距最大的页面** — Jingshiro 有 ~2000 行 ReadBookActivity + 多层 Dialog。

| 对照项 | Jingshiro | Flutter 现状 | 差距 |
|--------|-----------|-------------|------|
| **顶栏** | 自动隐藏；返回/书名/更多(目录/设置/AI/书票) | ✅ UI-1 自动隐藏+书名+更多菜单 | 书票 overlay 已有；菜单部分项占位 |
| **正文** | 左右翻页/滚动/仿真 | ✅ | 需核对仿真翻页手势 |
| **阅读主题** | 米黄/白/暗/绿 + 自定义 | ✅ | 需核对预设值 |
| **底栏** | 章节进度条 + 页码 + 时间(可选) | ✅ UI-1/UI-2 | 电量开关已接，真值待插件 |
| **设置面板** | 字号/行距/翻页/主题/字体/边距/TTS/更多 | ⚠️ UI-2 部分 | 字体骨架+边距+信息区+音量键；TTS/自动阅读/点击区为明确占位 |
| **TTS 朗读** | `dialog_read_aloud.xml` | ⚠️ 入口占位 | 设置内 SnackBar，非静默 |
| **自动阅读** | `dialog_auto_read.xml` 定时翻页 | ⚠️ 入口占位 | 同上 |
| **正文搜索** | `activity_search_content.xml` | ❌ | |
| **目录浮层** | BottomSheet + 当前章高亮 | ✅ `toc_sheet.dart` | 需核对 |
| **书签** | 点击书签按钮保存 | ✅ UI-1 阅读器内可加书签 | 书签页仍偏「想法」列表 |
| **想法/批注** | 长按选文 → 写想法 | ⚠️ 有 `note_editor_sheet` | **需确认交互已连接** |
| **书票 overlay** | 首尾显示评分+时长 | ❌ | **BookplateService 已有数据层** |
| **换源** | 阅读器内换源 | ✅ `change_source_page.dart` | |
| **模拟阅读** | `dialog_simulated_reading.xml` | ❌ | |
| **点击行为配置** | `dialog_click_action_config.xml` | ⚠️ 入口占位 | UI-2 |
| **翻页按键配置** | `dialog_page_key.xml` | ⚠️ 音量键开关 | 蓝牙翻页器仍缺 |
| **AI 入口** | 侧滑/FAB → AiChat | ✅ `ai_chat_page.dart` | 需核对入口位置 |
| **亮度** | 跟随系统/手动 | ❓ 待确认 | |
| **屏幕方向** | 锁定/自由 | ❌ | |
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
| 绿/红点 | `source_status_dot` | ✅ `source_status_dot.dart` | 需核对判定逻辑 |
| 分组标题 | 按 `bookSourceGroup` 分组 | ❓ 待确认 | |
| 批量操作 | 多选→启用/禁用/分组/校验/删除 | ❓ 待确认 | |
| 导入方式 | JSON/URL/二维码/本地文件/剪贴板 | ✅ 已有大部分 | **缺二维码扫描** |
| 校验书源 | `CheckSourceActivity` | ✅ `validate_source()` | |
| 搜索书源 | 书源内搜索 | ❓ 待确认 | |
| 排序 | 按名称/分组/启用状态 | ❓ 待确认 | |

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

#### Task UI-2: 阅读器设置补全 (`reader_settings.dart`) — 🟡 可落地项完成（2026-07-14）

对齐 `dialog_read_bg_text.xml` + `dialog_read_book_style.xml`：

- [x] **字体选择器**（骨架）— 系统/衬线/等宽；自定义导入明确占位
- [x] **边距设置** — 左右/上下调节（非四角完全独立，够用）
- [x] **信息区开关** — 页码/时间/电量
- [x] **音量键翻页** — 设置开关 + Focus 接线
- [x] **TTS / 自动阅读 / 点击区域** — 设置入口 + SnackBar 占位（勿静默）
- [ ] **TTS 朗读设置**（`dialog_read_aloud.xml`）— 语速/音调/引擎（未实现）
- [ ] **自动阅读**（`dialog_auto_read.xml`）— 定时翻页速度（未实现）
- [ ] **点击行为配置**（`dialog_click_action_config.xml`）— 上/中/下区域行为（未实现）
- [ ] **更多设置入口** — 屏幕方向/亮度/蓝牙翻页器

另：正文阻塞修复同轮收尾 — 空解析 `Err`、坏占位不缓存、`toEngineJson` 保嵌套规则、失败展示真实错误。

#### Task UI-3: 搜索页书源分组 (`search_page.dart`)

- [ ] `ExpansionTile` 每组一书源（标题=书源名 + 结果数）
- [ ] 组内 `BookListTile` 展示搜索结果
- [ ] 精准搜索 Toggle
- [ ] 搜索 Scope 选择（`dialog_search_scope.xml`）
- [ ] 底栏「共 N 本 · M 个书源」

#### Task UI-4: 书源管理对齐 (`sources_page.dart`)

- [ ] 按 `bookSourceGroup` 分组展示（`StickyHeader` 或 `ExpansionTile`）
- [ ] 批量操作栏（多选模式）
- [ ] 分组标题 + 绿/红/灰点验证
- [ ] 书源搜索/排序

#### Task UI-5: 目录页增强 (`toc_sheet.dart`)

- [ ] 正序/倒序切换
- [ ] 已缓存章节图标（`isDownloaded` ✓）
- [ ] 当前章高亮背景
- [ ] 章节搜索（可选）

#### Task UI-6: 书籍详情补全 (`book_info_page.dart`)

- [ ] 「换源」按钮明显入口
- [ ] 简介可展开/收起
- [ ] 读完/N刷标签

#### Task UI-7: 书架长按菜单 (`bookshelf_style1_page.dart`) — 🟡 基本完成（2026-07-14）

- [x] 置顶（本地 prefs `shelf_pinned_ids`）
- [x] 移动分组
- [x] 详情（跳转 BookInfo）
- [x] "整理"入口（占位页 → UI-10）
- [x] 移除（原长按确认保留为菜单项）

#### Task UI-8: 「我的」页菜单补齐 (`my_page.dart`)

- [ ] TXT 目录规则 → 占位页
- [ ] 字典规则 → 占位页
- [ ] 文件管理 → 基础文件浏览器
- [ ] 书签与想法 → 实现数据连接（已有空页 `bookmark_page.dart`）
- [ ] 快捷四格长按行为（备份→本地备份，Web服务→复制地址）
- [ ] Web 服务状态实时刷新

---

### 3.2 🟡 中优先级 — 补全新页面

#### Task UI-9: 阅读器正文搜索 (`activity_search_content.xml`)

- [ ] 新页面：搜索框 + 章节内搜索结果列表
- [ ] 点击结果跳转到对应位置
- [ ] 需要 Rust API 支持（`search_in_chapter(chapter_id, keyword)`）

#### Task UI-10: 书架整理 (`activity_arrange_book.xml`)

- [ ] 拖拽排序界面
- [ ] 批量选择→移动到分组
- [ ] 批量删除

#### Task UI-11: 书源登录 (`activity_source_login.xml` + `dialog_login.xml`)

- [ ] 根据书源 `loginUi` JSON 渲染动态表单
- [ ] 表单类型：text/password/button/toggle/select/checkbox
- [ ] JS 登录脚本执行
- [ ] 登录状态展示

#### Task UI-12: RSS 文章列表 + 阅读 (`activity_rss_artivles.xml` + `activity_rss_read.xml`) — ⏸ 延后

> 优先级放后：订阅 Tab 与源管理已有骨架；文章列表/阅读/WebView 方案待 S3 末再定。

- [ ] RSS 订阅源 → 文章列表页
- [ ] RSS 文章阅读页（WebView 或纯文本 / 外链，方案待定）
- [ ] 收藏/已读标记

#### Task UI-13: 缓存管理页面 (`activity_cache_book.xml`)

- [ ] 书籍缓存列表
- [ ] 按书籍展示缓存大小
- [ ] 清除选中/全部缓存

#### Task UI-14: AI 配置 Dialog (`dialog_ai_config.xml` + `dialog_ai_memory.xml`)

- [ ] API URL + Key + Model 配置
- [ ] 记忆管理
- [ ] 预设 System Prompt

#### Task UI-15: Obsidian 导出配置 (`dialog_obsidian_export.xml`)

- [ ] REST API 模式：URL + Token + Vault 路径
- [ ] 本地文件模式：文件夹路径
- [ ] 导出范围选择（当前书/全部）

#### Task UI-16: 下载选项 (`dialog_download_choice.xml`)

- [ ] 下载范围：全部/未缓存/N章
- [ ] 下载格式：纯文本/HTML
- [ ] 并发数设置

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

#### Task UI-20: TXT 目录规则 (`activity_txt_toc_rule.xml`)

- [ ] 自定义 TXT 章节识别正则
- [ ] 预设模板（"第X章"/"Chapter X"等）

#### Task UI-21: 字典规则 (`activity_dict_rule.xml` + `dialog_dict_rule_edit.xml`)

- [ ] 查词规则管理
- [ ] 规则测试

#### Task UI-22: 有声播放器 (`activity_audio_play.xml`)

- [ ] TTS 播放控件（播放/暂停/快进/后退）
- [ ] 播放列表
- [ ] 定时关闭

#### Task UI-23: 漫画阅读器 (`activity_manga.xml`)

- [ ] 图片加载/预加载
- [ ] 缩放/平移手势
- [ ] 阅读方向（左→右/右→左/上→下）
- [ ] 滤镜（`dialog_manga_color_filter.xml`）
- [ ] 墨水屏模式（`dialog_manga_epaper.xml`）

#### Task UI-24: 模拟阅读 (`dialog_simulated_reading.xml`)

- [ ] 定时自动翻页 + 统计

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
Task UI-2:  阅读器设置补全（字体/TTS/自动阅读/点击行为/翻页键）  🟡 可落地项完成；TTS/自动阅读/点击区本体仍开放
Task UI-3:  搜索页按书源分组 + 精准搜索 + 搜索 Scope
Task UI-4:  书源管理分组展示 + 批量操作 + 绿红点验证
Task UI-5:  目录页正序/倒序 + 已缓存图标 + 当前章高亮
Task UI-6:  书籍详情换源入口 + 简介展开 + 读完标签
Task UI-7:  书架长按菜单完整化  ✅ 基本完成（2026-07-14）
Task UI-8:  我的页菜单补齐 + 快捷四格行为
```

### S2 — 页面补全（2-3 周）：缺失页面 + 对话框

```
Task UI-9:  阅读器正文搜索
Task UI-10: 书架整理
Task UI-11: 书源登录（动态表单 + JS）
Task UI-13: 缓存管理页面
Task UI-14: AI 配置 Dialog
Task UI-15: Obsidian 导出配置
Task UI-16: 下载选项 Dialog
Task UI-20: TXT 目录规则
```

### S3 — 功能模块（3-4 周）：新功能 + 低优先级

```
Task UI-17: 扫码导入
Task UI-18: 文件管理
Task UI-19: 规则订阅
Task UI-21: 字典规则
Task UI-22: 有声播放器 (TTS)
Task UI-23: 漫画阅读器
Task UI-24: 模拟阅读
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
| 书架 | 88% | UI-7 长按菜单（置顶/分组/详情/整理占位/移除）；整理拖拽仍开放 |
| 我的页 | 75% | 14 项大部分就位，缺 4 项占位/长按行为 |
| 搜索 | 70% | 功能就位，缺分组展示/精准搜索/Scope |
| 发现 | 85% | 接近完成 |
| 书籍详情 | 75% | 基础就位，缺换源入口明显/标签/简介展开 |
| 目录 | 60% | 基础就位，缺正序倒序/缓存图标/章搜索 |
| **阅读器** | **72%** | UI-1+UI-2 可落地项完成；TTS/自动阅读/点击区本体、电量真值、正文搜索仍开放 |
| 书源管理 | 70% | 缺分组标题/批量操作/搜索排序 |
| RSS | 50% | Tab+源管理已有；**文章/阅读延后 S4** |
| 新模块(有声/漫画/扫码等) | 5% | 全部缺失 |
| **综合** | **~60%** | |

---

> 最后更新：2026-07-14 | 引擎 v0.5.6 | Focus: UI 复刻（S1：UI-1/UI-2 可落地 + UI-7 长按；正文阻塞收尾；RSS 延后）| 参考：[语雀 Wiki](https://www.yuque.com/legado/wiki)
