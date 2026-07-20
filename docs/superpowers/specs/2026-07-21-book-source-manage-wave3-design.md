# 书源管理对齐 — 第三波设计

> 日期：2026-07-21  
> 状态：第三波已实现  
> 对照：Jingshiro `SourceMBookHelp.md`、`DragSelectTouchHelper`（BookSource 滑动多选）、网络导入 URL 历史（ACache）、校验过程行内文案  
> 前置：Wave 1 / Wave 2 已落地

## 1. 目标与范围

### 1.1 目标

1. **帮助** — 管理页帮助内容 + 菜单入口；首次进入可自动弹出一次  
2. **滑动多选** — checkbox 列按住拖动连续选/取消；边缘自动滚动  
3. **网络导入 URL 历史** — 最近 URL 持久化 + 导入 Dialog 回填/删除  
4. **行内校验 debug 文案** — 校验进行中显示步骤/摘要；可选「显示详细信息」开关  
5. **文档** — UI_REPLICATION_PLAN 标 Wave 3 完成

### 1.2 对照要点

| 能力 | Jingshiro | Flutter Wave 3 |
|------|-----------|----------------|
| 帮助 | `showHelp("SourceMBookHelp")` + assets md | `assets/help/SourceMBookHelp.md` + Dialog；prefs 版本 gate |
| 滑动多选 | `DragSelectTouchHelper` 在勾选区拖选 | checkbox 列 `Listener`/`GestureDetector` 拖选 + 边缘滚动 |
| URL 历史 | ACache 网络导入历史 | SharedPreferences 最近 20 条；Dialog 下拉/列表 |
| 行内文案 | `iv_debug_text` 校验步骤 | 行副标题/`SourceStatusDot` 旁短文；校验中实时更新 |

### 1.3 本波不做

- 校验结束后自动筛「失效」组  
- 完整 Markdown WebView 帮助站 / 新 pub 依赖  
- 其它页面的滑动多选  
- 桌面专用 Shift+Click 区间（可选增强，默认不做）

---

## 2. 帮助

### 2.1 资产

- 路径：`assets/help/SourceMBookHelp.md`  
- 内容基于 Jingshiro 管理帮助，按 Flutter 现状微调（菜单项与 Wave 1/2 一致：含按域名分组、分享等）

### 2.2 UI

- 溢出「帮助」→ `SourceManageHelpDialog`：标题「书源管理帮助」+ `SingleChildScrollView`  
- 轻量渲染：按行解析 `#` / `*` / 普通文本（无 `flutter_markdown`）  
- 首次进入：`LocalConfig`-风格 prefs `book_sources_help_version`；若落后于内置版本则自动弹出并写回

---

## 3. 滑动多选

### 3.1 行为

- 仅在列表行左侧勾选热区（约 checkbox 宽度）捕获拖动手势  
- 拖入/拖过行：按拖动起点意图切换选中（起点未选→沿途选中；起点已选→沿途取消）  
- 靠近列表上下边缘时 `ScrollController.animateTo` 自动滚动  
- 单击 checkbox 仍独立工作；编辑/Switch/⋮ 不受影响  
- `_groupByDomain` 分组列表同样支持（按可见行）

### 3.2 实现建议

- 抽取 `SourceSelectDragScope` 或在 `sources_page` 内用 `Listener` + 行 `GlobalKey`/`RenderBox` 命中测距  
- 不新增第三方包

---

## 4. 网络导入 URL 历史

### 4.1 Store

- `ImportUrlHistoryStore`：`SharedPreferences` key `book_source_import_url_history_v1`  
- API：`load() → List<String>`、`add(url)`（去重置顶，最多 20）、`remove(url)`、`clear()`

### 4.2 UI

- `_showImportUrlDialog`：TextField + 历史列表（或 `Autocomplete`/`Dropdown`）  
- 点历史项回填；长按/尾部图标删除  
- 成功发起导入后 `add(url)`

---

## 5. 行内校验 debug 文案

### 5.1 状态模型

- Provider 增加进行中 map：`url → String progressMessage`（如「搜索…」「目录…」「失败: …」）  
- 校验开始清/写；结束清除 progress，保留 `SourceValidationResult`

### 5.2 UI

- 行：若有 `progressMessage` 显示为灰色小字；否则可显示最近校验摘要一行（可选，默认仅进行中）  
- `CheckSourcePrefs` 增加 `show_debug_message`（默认 true）；关闭则不显示行内文案（状态点仍更新）

### 5.3 引擎接线

- 在现有 `validateSource` 流程各步前后 `notifyListeners` 更新文案；无细粒度回调时按阶段字符串推进即可

---

## 6. 验收

1. 「帮助」展示 md 要点；冷启动首次进管理页自动弹一次，之后不重复  
2. 在勾选列拖过多行可连续选中/取消；边缘滚动可用  
3. 网络导入历史可回填与删除；新成功 URL 出现在历史顶部  
4. 批量校验时可见行内步骤文案；关闭「显示详细信息」后不显示  
5. Wave 1/2 行为无回归  

---

## 7. 风险

- 拖选与 `ReorderableListView` 手势冲突 → 仅手动排序且可拖拽排序时，勾选列拖选优先或禁用排序把手冲突区  
- 桌面与触控命中差异 → 热区宽度 ≥ 40  
- 帮助自动弹打扰 → 仅版本号升级时一次
