# 书源管理对齐 — 第一波设计

> 日期：2026-07-20  
> 状态：**第一波已实现**（2026-07-21）；实现计划见 `docs/superpowers/plans/2026-07-20-book-source-manage-wave1.md`  
 
> 对照：Jingshiro `BookSourceActivity` + `BookSourceAdapter` + `menu/book_source*.xml` + `item_book_source.xml` + SelectActionBar `book_source_sel.xml`  
> 实现面：`lib/pages/sources/sources_page.dart`、`lib/models/book_source.dart`、`lib/providers/source_provider.dart`、相关 DAO/store

## 1. 目标与范围

### 1.1 目标

对齐 Jingshiro 书源管理页的**日常管理**能力：手动序与排序维度、列表行展示与行菜单、底栏批量「更多」操作。行为与文案以 Jingshiro 为准；布局沿用现有 Flutter chrome（搜索顶栏 + SelectActionBar）。

### 1.2 本波包含（P0/P1）

1. **模型一等字段**：`customOrder`、`lastUpdateTime`、`weight`、`enabledExplore`；`respondTime` 可读可排序（校验写回可第二波）。
2. **排序菜单**：现有降序/手动/名称/URL/启用 + **智能排序**、**更新时间排序**；（若字段就绪）**响应时间排序**。
3. **手动排序**：仅「手动」模式下可拖拽；置顶/置底写 `customOrder`；重启后顺序保持。
4. **列表行**：标题 `名称 (分组)`；发现点绿/红（无 exploreUrl 不显示）。
5. **行 ⋮**：置顶、置底（仅手动排序可见）、搜索（进搜索页并限定该书源）、调试、启用发现、禁用发现；保留编辑/校验/登录/启用禁用/删除。
6. **底栏更多**：启用/禁用发现、置顶/置底所选、导出所选、分享书源、添加分组、移除分组；保留启用/禁用所选、设置分组、校验所选。

### 1.3 本波不做（第二波+）

- 导入预览 Dialog（ImportBookSourceDialog）
- 校验关键词弹窗 + 校验设置页
- 逗号多分组完整语义（`A,B,C` 的 add/remove 标签语义）
- 帮助页 / 首次进入自动帮助
- 滑动多选、校验行内逐步 debug 文案
- 网络导入 URL 历史
- 文档中误标的 AppBar「粘贴/市场/校验已启用」（管理页溢出菜单不恢复这三项）

### 1.4 非目标

- 不重做书源编辑器 / 登录页
- 不改规则引擎或搜索引擎本身（仅打开搜索页并传入源限定）
- 不引入新的远程「书源市场」协议

---

## 2. 数据模型与持久化

### 2.1 `BookSource` 新增字段

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `customOrder` | `int` | `0` | 手动序；置顶=当前最小−1 或重编号；拖拽后按列表下标重写 |
| `lastUpdateTime` | `int` | `0` | 毫秒时间戳；导入/编辑保存时可更新 |
| `weight` | `int` | `0` | 智能排序；来自 JSON，本波不自动改写 |
| `enabledExplore` | `bool` | `true` | 发现开关；与 `exploreUrl` 配合 UI |
| `respondTime` | `int` | `180000` | 可读 + 排序；校验成功写回留给第二波 |

### 2.2 JSON / 存储

- `fromJson` / `toJson` / `copyWith` / `rawSourceJson` 同步读写上述字段（与 legado JSON 键名一致）。
- 已有书源：从 `rawSourceJson` 回填；缺省用上表默认值。
- DAO / SharedPreferences（或现有 source store）必须持久化这些字段，**禁止**只活在内存。

### 2.3 `SourceProvider` API（本波）

| 方法 | 行为 |
|------|------|
| `setSourcesExploreEnabled(urls, bool)` | 批量改 `enabledExplore` |
| `moveSourcesToTop(urls)` / `moveSourcesToBottom(urls)` | 调整 `customOrder` 并保存；列表刷新 |
| `reorderSources(orderedUrls)` | 按可见列表顺序重编号 `customOrder`（手动排序拖拽后） |
| `exportSources(urls)` | 返回/写出所选源 JSON 数组（文件保存） |
| `shareSources(urls)` | `share_plus` 分享 JSON 文本或临时文件 |
| `addGroupToSources(urls, group)` / `clearGroupOnSources(urls)` | 本波：**单分组字符串**——添加=设为该分组名；移除=清空 `bookSourceGroup`（不做逗号多标签） |

现有 `setSourcesEnabled`、`setSourcesGroup`（整串替换）、`deleteSources`、校验流程保持不变。

---

## 3. UI 行为

### 3.1 顶栏排序

- 菜单项（中文）：降序（开关）、手动排序、智能排序、名称、URL、启用状态、更新时间、（可选）响应时间。
- **手动**：列表顺序 = `customOrder` 升序（降序开关则反转）；启用 `ReorderableListView`（或等价）。
- **智能**：`weight`；**更新时间**：`lastUpdateTime`；**响应时间**：`respondTime`；其余同现逻辑。
- 非手动模式：隐藏行「置顶/置底」；禁用拖拽。

### 3.2 列表行

- 标题：`bookSourceGroup.trim().isEmpty ? name : '$name ($group)'`。
- 发现点：存在有效 explore URL 时显示；`enabledExplore` → 绿，否则红（对齐 Jingshiro 双色点，替换当前「仅绿点」）。
- 行布局骨架（勾选 / Switch / 编辑 / ⋮）保持现有对齐，不重做视觉主题。

### 3.3 行菜单

| 项 | 条件 / 行为 |
|----|-------------|
| 置顶 / 置底 | 仅 `_sort == manual` |
| 搜索 | `Navigator` → `SearchPage`（或现有搜索入口），限定单个 `bookSourceUrl` |
| 调试 | 打开已有 `source_debug_page.dart` |
| 启用发现 / 禁用发现 | 写 `enabledExplore` |
| 编辑 / 校验 / 登录 / 启用禁用 / 删除 | 保持现有 |

### 3.4 底栏「更多」

顺序建议对齐 Jingshiro `book_source_sel`（可微调，但文案一致）：

1. 启用所选 / 禁用所选（已有）
2. 启用发现 / 禁用发现
3. 设置分组（已有，整串替换）
4. 添加分组 / 移除分组（本波单分组语义，见 2.3）
5. 置顶所选 / 置底所选
6. 导出所选 / 分享书源
7. 校验所选（已有）

无选中时：与现逻辑一致——提示「请先选择书源」或禁用入口（优先与现底栏「删除」灰态一致）。

导出：系统文件保存或应用导出目录，成功 SnackBar。  
分享：系统分享面板；失败 SnackBar。

### 3.5 发现筛选修正

`explore_on` / `explore_off` 以 **是否有 exploreUrl + `enabledExplore`** 为准，**不**再强制要求 `enabled == true`（对齐 Jingshiro `enabledExplore` 查询语义）。工具函数 `sourceHasExplore` 若混入 enabled，本波拆成「有发现 URL」与「发现已启用」两个判断。

---

## 4. 文件影响（预期）

| 文件 | 变更 |
|------|------|
| `lib/models/book_source.dart` | 新字段 + JSON |
| Source DAO / store（现有路径） | 持久化字段 |
| `lib/providers/source_provider.dart` | 批量 API |
| `lib/pages/sources/sources_page.dart` | 排序/拖拽/行菜单/底栏 |
| `lib/pages/explore/explore_utils.dart` | 发现判断拆分 |
| `lib/widgets/...` 或行内组件 | 发现双色点（可改 `SourceStatusDot` 旁独立点） |
| 搜索页入口 | 支持「单源限定」参数（若尚无） |
| `docs/UI_REPLICATION_PLAN.md` §2.8 | 本波完成后修正过时 ✅ 描述 |

测试：模型 JSON round-trip；Provider 置顶/拖拽顺序；可选 widget 冒烟（有则补）。

---

## 5. 验收标准

1. 手动排序拖拽后杀进程重启，顺序不变。
2. 行/批量置顶、置底后 `customOrder` 与列表一致。
3. 有 exploreUrl 的源：启用发现=绿点，禁用=红点；筛选「启用发现/禁用发现」结果正确。
4. 标题显示 `名称 (分组)`。
5. 导出所选得到合法书源 JSON 数组；分享能调起系统面板。
6. 智能/更新时间（及响应时间若启用）排序结果符合字段方向 + 降序开关。
7. 现有：导入、删除、校验、分组管理 Dialog、网络/本地/二维码导入 — **无回归**。

---

## 6. 风险与依赖

- **搜索单源限定**：若 `SearchPage` 无 scope API，本波需最小参数扩展（P0 for 行「搜索」）。
- **大列表拖拽性能**：沿用 `ReorderableListView.builder`；域名分组模式下拖拽仅在「非域名分组」或仅 flat 列表启用（推荐：`_groupByDomain == true` 时禁用拖拽并 SnackBar 提示先关域名分组）。
- **单分组 vs 多分组**：添加/移除分组文案与 Jingshiro 接近，但语义简化；第二波再做逗号标签，避免本波半吊子多标签。

---

## 7. 后续波次（备忘）

- **第二波**：导入预览、校验关键词+设置、多分组逗号标签、校验结果持久化。
- **第三波**：帮助、滑动多选、行内校验 debug 文案、URL 导入历史、文档整体百分比回写。
