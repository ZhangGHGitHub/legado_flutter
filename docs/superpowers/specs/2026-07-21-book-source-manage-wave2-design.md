# 书源管理对齐 — 第二波设计

> 日期：2026-07-21  
> 状态：**第二波已实现**（2026-07-21）  
> 对照：Jingshiro / gedoor `ImportBookSourceDialog`、`CheckSource` / `CheckSourceConfig`、`BookSource.addGroup`/`removeGroup`（逗号多分组）  
> 本地可参照：`lib/pages/rule_sub/rule_sub_page.dart` 的 `_RuleSubImportDialog`、`strings_zh.xml` 校验文案、Wave 1 已落地的 `SourceProvider` / `sources_page`

## 1. 目标与范围

### 1.1 目标

在 Wave 1 日常管理能力之上，对齐目标软件的：

1. **导入预览** — 解析后勾选再写入，区分新增 / 更新 / 已存在  
2. **校验关键词 + 校验设置** — 可配超时与校验项；批量/单源可改关键词  
3. **多分组逗号标签** — `bookSourceGroup = "A,B,C"` 的筛选与增删标签  
4. **校验结果轻量持久化** — 重启后状态点仍可用；成功时更新 `respondTime`（若有耗时）

### 1.2 对照要点（目标软件逻辑）

| 能力 | Jingshiro 行为（摘要） | Flutter Wave 2 做法 |
|------|------------------------|---------------------|
| 导入 | `ImportBookSourceDialog`：列表勾选，确认后 upsert | 新 `ImportBookSourceDialog`；本地/URL/二维码先 parse → 预览 → 确认导入；复用规则订阅勾选 UX |
| 校验设置 | `CheckSourceConfig`：超时秒、校验项目开关 | `CheckSourcePrefs` + 设置页/Dialog；驱动现有 Rust/Dart 校验管线能覆盖的项 |
| 校验关键词 | 弹窗输入；源可有 `checkKeyWord` | 批量校验前 Dialog；默认 `checkKeyWord`（raw）或 `defaultValidationKeyword` |
| 多分组 | 逗号分隔；`addGroup`/`removeGroup` 改标签 | `source_group_tags.dart` 纯函数 + Provider API；筛选 `contains` 标签；分组管理按标签改写 |
| 校验持久化 | 会话 Debug map；部分状态可回写 | SharedPreferences：`url → {allOk, searchOk, …, searchTimeMs}`；加载进 `_validationResults` |

### 1.3 本波不做（第三波）

帮助页、滑动多选、行内逐步 debug 文案、网络导入 URL 历史下拉、校验后自动筛「失效」组（可选轻量：若实现成本低可顺带，默认不做）。

---

## 2. 导入预览

### 2.1 流程

```
本地文件 / URL / 二维码
  → 解析为 List<BookSource>（不写库）
  → ImportBookSourceDialog（勾选 + 状态标签）
  → 用户确认
  → upsert 勾选项
```

### 2.2 Dialog UI

- 标题：`导入书源 (N)`  
- 列表：`CheckboxListTile`，副标题或尾标：`新增` / `更新` / `相同`（按 `bookSourceUrl` 与现库比对；可选简单比较 `lastUpdateTime` 或 JSON 指纹）  
- 操作：取消 / 全选(反选) / 导入  
- 默认：新增+更新勾选，相同可不勾（或全勾，与规则订阅一致默认全勾——**采用默认全勾**，与 `_RuleSubImportDialog` 一致）

### 2.3 API

- `SourceProvider.parseSourcesForImport(String text) → List<BookSource>?`（URL 则先拉网）  
- `SourceProvider.importParsedSources(List<BookSource>)`（只 upsert 传入列表）  
- 现有 `importSources` 可改为：parse → 若调用方要预览则返回列表；**管理页入口全部走预览**；规则订阅可继续直接导入或复用同一 Dialog（本波管理页必做；规则订阅可选复用）

---

## 3. 校验关键词 + 校验设置

### 3.1 `CheckSourcePrefs`

| Key | 默认 | 含义 |
|-----|------|------|
| `check_source_timeout_sec` | `30` | 单源超时（秒） |
| `check_search` | `true` | 校验搜索 |
| `check_discovery` | `true` | 校验发现 |
| `check_info` | `true` | 校验详情（若引擎无独立 info 步，可映射到 toc 前步骤或跳过并在 UI 注明） |
| `check_toc` | `true` | 校验目录 |
| `check_content` | `true` | 校验正文 |

现有 `SourceValidationResult` 含 search/discovery/toc/content — **以这四项为主**；「详情」若引擎未单独暴露，UI 仍显示开关但实现映射到 toc 或隐藏，**优先隐藏未接线项，只暴露引擎真实支持的四项**。

### 3.2 UI

- 校验前 Dialog：`TextField` 关键词 + 中性按钮「校验设置」打开设置页/Dialog  
- 底栏「校验所选」、行「校验」均走该流程（可记住上次关键词于 prefs）  
- 设置：超时 Slider/输入 + Switch 列表；保存后返回

### 3.3 管线

- `validateSource` / `validateSources` 接受 `keyword`、`timeout`、以及跳过项（未勾选项对应步骤记为跳过/视为 ok，避免红点误伤）  
- 超时写入：若 `searchTimeMs` 可用则 `copyWith(respondTime: searchTimeMs)` 并持久化

---

## 4. 多分组逗号标签

### 4.1 规则

- 标签：按 `,` / `，` 分割，trim，去空，去重保序  
- 显示名：Wave 1 的 `名称 (分组)` 仍显示**整串**或主标签——保持整串以对齐 Jingshiro `getDisplayNameGroup()`  
- 筛选 `group:xxx`：`tags.contains(xxx)`  
- `addGroupToSources`：若无该标签则追加  
- `clearGroupOnSources` / 移除分组：弹出标签选择或输入要移除的名；去掉该标签后重拼  
- `renameGroup` / `deleteGroup`：对每个源的标签列表 rename/remove，再写回字符串  

### 4.2 纯函数（可测）

`lib/services/source_group_tags.dart`：

```dart
List<String> splitSourceGroups(String raw);
String joinSourceGroups(Iterable<String> tags);
String addSourceGroupTag(String raw, String tag);
String removeSourceGroupTag(String raw, String tag);
String renameSourceGroupTag(String raw, String from, String to);
bool sourceHasGroupTag(String raw, String tag);
```

---

## 5. 校验结果持久化

- Key：`source_validation_v1` → JSON map  
- 加载：`SourceProvider.loadSources` 后 merge 进 `_validationResults`  
- 每次校验结束：写入该源条目  
- 删除书源：清对应 key  
- 结构足够驱动 `SourceStatusDot`（至少 `allOk` 或四步 bool + errors 可选）

---

## 6. 文件影响（预期）

| 文件 | 职责 |
|------|------|
| `lib/widgets/import_book_source_dialog.dart` | 导入预览 |
| `lib/services/check_source_prefs.dart` | 校验设置持久化 |
| `lib/widgets/check_source_config_dialog.dart`（或 page） | 校验设置 UI |
| `lib/services/source_group_tags.dart` | 多分组纯函数 |
| `lib/services/source_validation_store.dart` | 校验结果持久化 |
| `lib/providers/source_provider.dart` | parse/import、校验参数、分组标签 API、持久化挂钩 |
| `lib/pages/sources/sources_page.dart` | 接线入口 |
| `lib/widgets/source_group_manage_dialog.dart` | 重命名/删除走标签语义 |
| tests | tags、prefs、parse 对比、import 选择逻辑 |

---

## 7. 验收

1. 本地/URL/二维码导入弹出预览；取消不写库；确认后仅勾选项入库。  
2. 校验弹出关键词；设置超时与项目后再次校验行为符合开关。  
3. 源可同时属于多组；添加/移除分组不抹掉其它标签；筛选按标签命中。  
4. 校验后杀进程重启，状态点仍反映上次结果。  
5. Wave 1：排序/拖拽/导出/分享/行菜单 — 无回归。

---

## 8. 风险

- 引擎校验项与 UI 开关不一致 → 只暴露已接线四项。  
- 大 JSON 导入预览列表性能 → `ListView.builder` + 默认全选。  
- 多分组与旧「整串相等」筛选迁移 → 一律改为标签 contains。
