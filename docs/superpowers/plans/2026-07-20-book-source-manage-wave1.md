# Book Source Manage Wave 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align Flutter book-source manage page with Jingshiro `BookSourceActivity` Wave 1: order fields, sort/drag, row UI/menus, bottom-bar batch more actions.

**Architecture:** Promote order/explore fields on `BookSource` and sync them through `toJson()`/`toEngineJson()` (DB stores engine JSON). Extend `SourceProvider` with batch APIs. Update `sources_page.dart` for sort/drag/row/bottom menus. Split explore helpers so manage filters do not require `enabled == true`.

**Tech Stack:** Flutter/Dart, existing `SourceDao`/`DatabaseHelper`, `share_plus`, `file_picker`, `SearchPage.initialRestrictSourceUrls`, `explore_utils.dart`.

**Spec:** `docs/superpowers/specs/2026-07-20-book-source-manage-wave1-design.md`

## Global Constraints

- Wave 1 only — no import preview, check-source config, comma multi-group tags, help page, slide multi-select
- Single-group string for 添加分组/移除分组 (set name / clear to `''`)
- Disable drag when `_groupByDomain == true`
- No new pub dependencies (`share_plus` / `file_picker` already in `pubspec.yaml`)
- Keep existing import/delete/validate/group-manage dialog behavior
- Chinese menu copy matches Jingshiro strings in `strings_zh.xml` where applicable

## File map

| File | Responsibility |
|------|----------------|
| `lib/models/book_source.dart` | First-class `customOrder`, `lastUpdateTime`, `weight`, `enabledExplore`, `respondTime`; JSON sync |
| `test/models/book_source_engine_json_test.dart` | Round-trip tests for new fields |
| `lib/pages/explore/explore_utils.dart` | Split `hasExploreUrl` / `isExploreEnabled` / tab `sourceHasExplore` |
| `test/pages/explore/explore_utils_test.dart` | Filter semantics tests (create) |
| `lib/providers/source_order.dart` | Pure reindex helpers for top/bottom/reorder |
| `lib/providers/source_provider.dart` | Batch explore/order/export/group helpers |
| `test/providers/source_order_logic_test.dart` | Order helper unit tests (create) |
| `lib/pages/sources/sources_page.dart` | Sort enum, drag list, row title/dot/menu, bottom more |
| `docs/UI_REPLICATION_PLAN.md` §2.8 | Correct overstated checkmarks after Wave 1 |

---

### Task 1: BookSource order / explore fields + JSON sync

**Files:**
- Modify: `lib/models/book_source.dart`
- Modify: `test/models/book_source_engine_json_test.dart`

**Interfaces:**
- Produces: `BookSource.customOrder` (`int`, default `0`), `lastUpdateTime` (`int`, default `0`), `weight` (`int`, default `0`), `enabledExplore` (`bool`, default `true`), `respondTime` (`int`, default `180000`)
- Produces: `fromJson` reads these keys; `toJson`/`toEngineJson` always write them (including when merging into `rawSourceJson` map alongside `enabled` / `bookSourceGroup`)
- Produces: `copyWith` accepts all five new fields (and still preserves rule fields)

- [ ] **Step 1: Write failing tests**

Append to `test/models/book_source_engine_json_test.dart`:

```dart
test('fromJson reads order and explore fields', () {
  final source = BookSource.fromJson({
    'bookSourceUrl': 'https://a.example',
    'bookSourceName': 'A',
    'customOrder': 3,
    'lastUpdateTime': 100,
    'weight': 9,
    'enabledExplore': false,
    'respondTime': 5000,
    'exploreUrl': '[]',
  });
  expect(source.customOrder, 3);
  expect(source.lastUpdateTime, 100);
  expect(source.weight, 9);
  expect(source.enabledExplore, false);
  expect(source.respondTime, 5000);
});

test('toEngineJson syncs order fields into raw map', () {
  final source = BookSource.fromJson({
    'bookSourceUrl': 'https://a.example',
    'bookSourceName': 'A',
    'ruleContent': {'content': r'$.x'},
    'customOrder': 1,
    'enabledExplore': false,
  }).copyWith(customOrder: 42, enabledExplore: true);
  final engine = jsonDecode(source.toEngineJson()) as Map<String, dynamic>;
  expect(engine['customOrder'], 42);
  expect(engine['enabledExplore'], true);
  expect(engine['ruleContent'], isA<Map>());
});
```

- [ ] **Step 2: Run tests — expect FAIL**

Run: `flutter test test/models/book_source_engine_json_test.dart`

Expected: FAIL (fields / getters missing)

- [ ] **Step 3: Implement model fields**

In `BookSource`:
1. Add five final fields + constructor defaults.
2. In `fromJson`, parse with helpers:

```dart
int safeInt(dynamic v, [int d = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return d;
}
// enabledExplore: if key missing → true; if false/0 → false
```

3. In `toJson()` raw-merge branch, after setting `enabled` / `bookSourceGroup`, also set:

```dart
out['customOrder'] = customOrder;
out['lastUpdateTime'] = lastUpdateTime;
out['weight'] = weight;
out['enabledExplore'] = enabledExplore;
out['respondTime'] = respondTime;
```

4. Flat `toJson` map: include the same five keys.
5. Expand `copyWith` to take optional new fields and pass through all rule fields unchanged (same pattern as today).

- [ ] **Step 4: Run tests — expect PASS**

Run: `flutter test test/models/book_source_engine_json_test.dart`

Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add lib/models/book_source.dart test/models/book_source_engine_json_test.dart
git commit -m "feat(sources): persist BookSource order and explore fields"
```

---

### Task 2: Explore URL helpers + manage-filter semantics

**Files:**
- Modify: `lib/pages/explore/explore_utils.dart`
- Create: `test/pages/explore/explore_utils_test.dart`

**Interfaces:**
- Produces: `bool hasExploreUrl(BookSource source)` — `exploreUrlOf(source).trim().isNotEmpty`
- Produces: `bool isExploreEnabled(BookSource source)` — `source.enabledExplore` (first-class)
- Produces: `bool sourceHasExplore(BookSource source)` — for **Discover tab**: `source.enabled && hasExploreUrl(source) && isExploreEnabled(source)`
- Consumes: Task 1 `enabledExplore`

- [ ] **Step 1: Write failing tests**

Create `test/pages/explore/explore_utils_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/pages/explore/explore_utils.dart';

void main() {
  BookSource src({
    bool enabled = true,
    bool enabledExplore = true,
    String exploreUrl = '[{"title":"a","url":"/"}]',
  }) {
    return BookSource.fromJson({
      'bookSourceUrl': 'https://x',
      'bookSourceName': 'X',
      'enabled': enabled,
      'enabledExplore': enabledExplore,
      'exploreUrl': exploreUrl,
    });
  }

  test('manage explore_on ignores source.enabled', () {
    final s = src(enabled: false, enabledExplore: true);
    expect(hasExploreUrl(s), true);
    expect(isExploreEnabled(s), true);
    expect(sourceHasExplore(s), false); // tab still requires enabled
  });

  test('explore_off is hasUrl && !enabledExplore', () {
    final s = src(enabledExplore: false);
    expect(hasExploreUrl(s) && !isExploreEnabled(s), true);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

Run: `flutter test test/pages/explore/explore_utils_test.dart`

- [ ] **Step 3: Implement helpers**

Replace body of `sourceHasExplore` and add `hasExploreUrl` / `isExploreEnabled` as above. Prefer first-class `enabledExplore` over digging raw JSON (raw still loaded via `fromJson`).

- [ ] **Step 4: Run — expect PASS**

- [ ] **Step 5: Commit**

```bash
git add lib/pages/explore/explore_utils.dart test/pages/explore/explore_utils_test.dart
git commit -m "fix(explore): split explore URL vs enabled for source filters"
```

---

### Task 3: SourceProvider batch order / explore / export / group

**Files:**
- Create: `lib/providers/source_order.dart`
- Modify: `lib/providers/source_provider.dart`
- Create: `test/providers/source_order_logic_test.dart`

**Interfaces:**
- Produces on `SourceProvider`:
  - `Future<void> setSourcesExploreEnabled(Iterable<String> urls, bool enabled)`
  - `Future<void> moveSourcesToTop(Iterable<String> urls)`
  - `Future<void> moveSourcesToBottom(Iterable<String> urls)`
  - `Future<void> reorderSources(List<String> orderedUrls)` — assign `customOrder = index` for each URL in order
  - `Future<String> exportSourcesJson(Iterable<String> urls)` — JSON array of `toJson()` maps
  - `Future<void> addGroupToSources(Iterable<String> urls, String group)` — set `bookSourceGroup`
  - `Future<void> clearGroupOnSources(Iterable<String> urls)` — set `bookSourceGroup` to `''`
- Share stays in UI via `Share.share` + `exportSourcesJson`

**Pure helper in `lib/providers/source_order.dart`:**

```dart
Map<String, int> customOrdersAfterMoveToTop(
  List<BookSource> all,
  Set<String> selected,
) {
  final sel = all.where((s) => selected.contains(s.bookSourceUrl)).toList();
  final rest = all.where((s) => !selected.contains(s.bookSourceUrl)).toList();
  final ordered = [...sel, ...rest];
  return {
    for (var i = 0; i < ordered.length; i++) ordered[i].bookSourceUrl: i,
  };
}

Map<String, int> customOrdersAfterMoveToBottom(
  List<BookSource> all,
  Set<String> selected,
) {
  final rest = all.where((s) => !selected.contains(s.bookSourceUrl)).toList();
  final sel = all.where((s) => selected.contains(s.bookSourceUrl)).toList();
  final ordered = [...rest, ...sel];
  return {
    for (var i = 0; i < ordered.length; i++) ordered[i].bookSourceUrl: i,
  };
}
```

- [ ] **Step 1: Write failing pure-logic tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/providers/source_order.dart';

void main() {
  test('move to top reindexes selected first', () {
    final all = [
      BookSource(bookSourceUrl: 'a', bookSourceName: 'a', customOrder: 0),
      BookSource(bookSourceUrl: 'b', bookSourceName: 'b', customOrder: 1),
      BookSource(bookSourceUrl: 'c', bookSourceName: 'c', customOrder: 2),
    ];
    final orders = customOrdersAfterMoveToTop(all, {'b'});
    expect(orders['b'], 0);
    expect(orders['a'], 1);
    expect(orders['c'], 2);
  });
}
```

- [ ] **Step 2: Run — FAIL**

Run: `flutter test test/providers/source_order_logic_test.dart`

- [ ] **Step 3: Implement `source_order.dart` + provider methods**

- `moveSourcesToTop` / `Bottom`: compute map → `copyWith(customOrder:)` → `_dao.update` each → reload `_sources`
- `reorderSources`: for each `(i, url)` update matching source
- `setSourcesExploreEnabled`: `copyWith(enabledExplore: enabled)` + update
- `exportSourcesJson`: `jsonEncode` of selected `toJson()` maps
- `addGroupToSources` / `clearGroupOnSources`: mirror `setSourcesGroup` persistence + `SourceGroupCatalog.mergeFromSources` when adding

- [ ] **Step 4: Run tests PASS + analyze touched files**

```bash
flutter test test/providers/source_order_logic_test.dart
dart analyze lib/providers/source_order.dart lib/providers/source_provider.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/providers/source_order.dart lib/providers/source_provider.dart test/providers/source_order_logic_test.dart
git commit -m "feat(sources): batch explore, order, export, and group APIs"
```

---

### Task 4: sources_page sort dimensions + manual drag

**Files:**
- Modify: `lib/pages/sources/sources_page.dart`

**Interfaces:**
- Consumes: Task 1 fields; Task 3 `reorderSources`; Task 2 `hasExploreUrl` / `isExploreEnabled`
- Extends `_SourceSort` with `auto`, `lastUpdate`, `respondTime`
- Flat list: when `_sort == manual && !_groupByDomain`, use `ReorderableListView.builder`
- Domain grouped: no drag

- [ ] **Step 1: Extend enum + sort menu**

```dart
enum _SourceSort { manual, auto, name, url, enabled, lastUpdate, respondTime }
```

Add checked items: 智能排序 / 更新时间排序 / 响应时间排序.

- [ ] **Step 2: Comparators in `_visibleSources`**

```dart
case _SourceSort.manual:
  list.sort((a, b) => a.customOrder.compareTo(b.customOrder));
case _SourceSort.auto:
  list.sort((a, b) => a.weight.compareTo(b.weight));
case _SourceSort.lastUpdate:
  list.sort((a, b) => a.lastUpdateTime.compareTo(b.lastUpdateTime));
case _SourceSort.respondTime:
  list.sort((a, b) => a.respondTime.compareTo(b.respondTime));
```

Then apply existing `_sortDesc` reverse.

- [ ] **Step 3: ReorderableListView for flat manual mode**

On reorder: rebuild URL list → `provider.reorderSources(urls)`.

- [ ] **Step 4: Fix explore filters**

```dart
case 'explore_on':
  list = list.where((s) => hasExploreUrl(s) && isExploreEnabled(s)).toList();
case 'explore_off':
  list = list.where((s) => hasExploreUrl(s) && !isExploreEnabled(s)).toList();
```

- [ ] **Step 5: Analyze**

Run: `dart analyze lib/pages/sources/sources_page.dart`

Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/pages/sources/sources_page.dart
git commit -m "feat(sources): add sort dimensions and manual drag reorder"
```

---

### Task 5: Row title, explore dual-color dot, row overflow menu

**Files:**
- Modify: `lib/pages/sources/sources_page.dart`

**Interfaces:**
- Consumes: explore helpers; `SearchPage(initialRestrictSourceUrls: {url})`; existing `source_debug_page.dart`
- Title: `group.isEmpty ? name : '$name ($group)'`
- Explore dot: green if `isExploreEnabled`, red otherwise; hide if `!hasExploreUrl`
- Row menu adds: 置顶/置底 (manual only), 搜索, 调试, 启用发现/禁用发现; keep edit/validate/login/enable/del

- [ ] **Step 1: Update `_buildSourceRow` title + explore dot**
- [ ] **Step 2: Expand `_showItemMenu` + handlers**
- [ ] **Step 3: Analyze clean**
- [ ] **Step 4: Commit**

```bash
git add lib/pages/sources/sources_page.dart
git commit -m "feat(sources): row display name, explore dots, and overflow actions"
```

---

### Task 6: Bottom bar more menu + export/share UI

**Files:**
- Modify: `lib/pages/sources/sources_page.dart`

**Interfaces:**
- Consumes: Task 3 APIs; `share_plus` `Share.share`; `FilePicker.platform.saveFile`

Extend `LegadoBottomBarPopupButton` items + `_onBottomMore`:

- 启用发现 / 禁用发现
- 添加分组 / 移除分组
- 置顶所选 / 置底所选
- 导出所选 / 分享书源

`add_group`: TextField dialog → `addGroupToSources`  
`remove_group`: `clearGroupOnSources`  
`export`: save JSON bytes via `FilePicker.platform.saveFile`  
`share`: `Share.share(json, subject: '书源')`  

Require non-empty selection (same as today).

- [ ] **Step 1: Extend itemBuilder + switch**
- [ ] **Step 2: Smoke export/share on Windows if available**
- [ ] **Step 3: Commit**

```bash
git add lib/pages/sources/sources_page.dart
git commit -m "feat(sources): bottom bar explore, order, export, and share"
```

---

### Task 7: Docs + verification gate

**Files:**
- Modify: `docs/UI_REPLICATION_PLAN.md` §2.8 / UI-4
- Modify: `docs/superpowers/specs/2026-07-20-book-source-manage-wave1-design.md` (status → 第一波已实现)

- [ ] **Step 1: Correct §2.8 overstated claims; note Wave 2 still open**
- [ ] **Step 2: Run verification**

```bash
flutter test test/models/book_source_engine_json_test.dart test/pages/explore/explore_utils_test.dart test/providers/source_order_logic_test.dart
dart analyze lib/models/book_source.dart lib/providers/source_provider.dart lib/providers/source_order.dart lib/pages/sources/sources_page.dart lib/pages/explore/explore_utils.dart
```

Expected: tests PASS; analyze no errors

- [ ] **Step 3: Commit**

```bash
git add docs/UI_REPLICATION_PLAN.md docs/superpowers/specs/2026-07-20-book-source-manage-wave1-design.md
git commit -m "docs: record book source manage wave 1 parity"
```

---

## Spec coverage

| Spec section | Task |
|--------------|------|
| 2.1–2.2 model + JSON | Task 1 |
| 2.3 provider APIs | Task 3 |
| 3.1 sort + drag | Task 4 |
| 3.2 row title + dots | Task 5 |
| 3.3 row menu | Task 5 |
| 3.4 bottom more | Task 6 |
| 3.5 explore filter | Task 2 + 4 |
| §5 acceptance | Task 7 |
| §1.3 out of scope | Not scheduled |
