# 书架布局 Dialog 完整对齐（方案 1）

> 日期：2026-07-17  
> 对照：Jingshiro `dialog_bookshelf_config.xml` + `BaseBookshelfFragment.configBookshelf()`

## 目标

- `bookGroupStyle`：仅 Tab / Folder（chrome）
- `bookshelfLayout`：列表 / 紧凑 / 网格 2–6
- 排序、未读、更新时间、待更新数、快速滚动、书名显示、边距 — 与 PreferKey 对齐
- 双壳页面共用 config，body 随 layout 切换

## 已有

- `BookshelfPrefs` / `BookshelfConfig` / `BookshelfConfigDialog`
- `Book.updatedAt` + DB SELECT
- `BookshelfPage` 按 groupStyle 分发（待接 config 参数）

## 待做

- style1/style2 接收 `config` + `onConfigChanged`
- 菜单「书架布局」打开 Dialog 并刷新
- 列表/网格 body、排序、角标、边距、书名、滚动条
- 主框架待更新角标受 `showWaitUpCount` 控制
