# Book Source Manage Wave 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align book-source manage import preview, check-source prefs/keyword, comma multi-group tags, and validation result persistence with Jingshiro.

**Architecture:** Pure tag helpers + prefs/stores; Provider APIs for parse/import/validate/group; UI dialogs wired from `sources_page`. Reuse `_RuleSubImportDialog` UX patterns for import preview.

**Tech Stack:** Flutter/Dart, SharedPreferences, existing SourceDao / SourceValidationResult / LegadoEngineBridge.validateSource.

**Spec:** `docs/superpowers/specs/2026-07-21-book-source-manage-wave2-design.md`

## Global Constraints

- Wave 2 only — no help page, slide multi-select, URL import history, inline debug step text
- Expose only validation steps the engine already returns: search / discovery / toc / content
- Multi-group: comma/Chinese-comma split; add/remove tags without wiping other tags
- Manage-page import paths must go through preview dialog
- No new pub dependencies
- Chinese copy from `strings_zh.xml` where applicable (`check_source_config`, `import_book_source`, etc.)

## File map

| File | Responsibility |
|------|----------------|
| `lib/services/source_group_tags.dart` | Pure multi-group tag helpers |
| `test/services/source_group_tags_test.dart` | Tag helper tests |
| `lib/services/check_source_prefs.dart` | Timeout + step toggles |
| `test/services/check_source_prefs_test.dart` | Prefs defaults / round-trip (optional memory fake) |
| `lib/services/source_validation_store.dart` | Persist validation map |
| `test/services/source_validation_store_test.dart` | Serialize/deserialize |
| `lib/widgets/import_book_source_dialog.dart` | Import preview UI |
| `lib/widgets/check_source_config_dialog.dart` | Check settings UI |
| `lib/widgets/check_source_keyword_dialog.dart` | Keyword + open settings |
| `lib/providers/source_provider.dart` | parse/importSelected, validate with prefs, tag group APIs, load/save validation |
| `lib/pages/sources/sources_page.dart` | Wire import/validate/group |
| `lib/widgets/source_group_manage_dialog.dart` | Rename/delete via tags |
| Docs | Spec status + UI_REPLICATION_PLAN §2.8 Wave 2 note |

---

### Task 1: Multi-group tag helpers

**Files:**
- Create: `lib/services/source_group_tags.dart`
- Create: `test/services/source_group_tags_test.dart`

**Interfaces:**
- `List<String> splitSourceGroups(String raw)`
- `String joinSourceGroups(Iterable<String> tags)`
- `String addSourceGroupTag(String raw, String tag)`
- `String removeSourceGroupTag(String raw, String tag)`
- `String renameSourceGroupTag(String raw, String from, String to)`
- `bool sourceHasGroupTag(String raw, String tag)`

- [ ] **Step 1: Write failing tests**

```dart
test('split handles comma and Chinese comma', () {
  expect(splitSourceGroups('A, B，C'), ['A', 'B', 'C']);
});

test('add does not duplicate', () {
  expect(addSourceGroupTag('A,B', 'A'), 'A,B');
  expect(addSourceGroupTag('A', 'B'), 'A,B');
});

test('remove keeps others', () {
  expect(removeSourceGroupTag('A,B,C', 'B'), 'A,C');
});

test('rename updates one tag', () {
  expect(renameSourceGroupTag('A,B', 'A', 'X'), 'X,B');
});

test('has tag', () {
  expect(sourceHasGroupTag('A,B', 'B'), true);
  expect(sourceHasGroupTag('A,B', 'C'), false);
});
```

- [ ] **Step 2: Run FAIL** — `flutter test test/services/source_group_tags_test.dart`
- [ ] **Step 3: Implement helpers**
- [ ] **Step 4: Run PASS**
- [ ] **Step 5: Commit** `feat(sources): multi-group tag helpers`

---

### Task 2: CheckSourcePrefs + validation store

**Files:**
- Create: `lib/services/check_source_prefs.dart`
- Create: `lib/services/source_validation_store.dart`
- Create: `test/services/check_source_prefs_test.dart`
- Create: `test/services/source_validation_store_test.dart`

**Interfaces:**

```dart
class CheckSourcePrefs {
  static Future<int> timeoutSec(); // default 30
  static Future<void> setTimeoutSec(int v);
  static Future<bool> checkSearch(); // default true
  // checkDiscovery, checkToc, checkContent — same pattern
  static Future<void> setCheckSearch(bool v); // etc.
  static Future<String> lastKeyword(); // default ''
  static Future<void> setLastKeyword(String v);
}

class SourceValidationStore {
  static Future<Map<String, SourceValidationResult>> load();
  static Future<void> saveAll(Map<String, SourceValidationResult> map);
  static Future<void> put(String url, SourceValidationResult r);
  static Future<void> remove(String url);
}
```

Serialize result as JSON: `searchOk`, `discoveryOk`, `tocOk`, `contentOk`, `searchTimeMs`, `errors`.

- [ ] **Step 1: Failing tests** for defaults + round-trip encode/decode (can test pure encode helpers without SharedPreferences by extracting `resultToJson` / `resultFromJson`)
- [ ] **Step 2–4: Implement + PASS**
- [ ] **Step 5: Commit** `feat(sources): check-source prefs and validation persistence`

---

### Task 3: Provider — parse/import, tag groups, validate+persist

**Files:**
- Modify: `lib/providers/source_provider.dart`

**Interfaces:**
- `Future<List<BookSource>?> parseSourcesForImport(String text)` — no DB write
- `Future<bool> importParsedSources(List<BookSource> sources)` — upsert only
- Replace `addGroupToSources` / `clearGroupOnSources` / `renameGroup` / `deleteGroup` to use tag helpers (remove tag ≠ clear all unless last tag)
- Add `Future<void> removeGroupTagFromSources(Iterable<String> urls, String tag)`
- `loadSources`: merge `SourceValidationStore.load()` into `_validationResults`
- After each validate: `SourceValidationStore.put`; update `respondTime` from `searchTimeMs` when > 0
- `validateSource` / `validateSources`: accept keyword; apply `CheckSourcePrefs` timeout; skip unchecked steps (mark ok/skipped so allOk ignores skipped)

For skip semantics: if `checkToc == false`, treat `tocOk` as `true` for `allOk` aggregation when storing display result — document in code comment.

- [ ] **Step 1: Unit-test tag rewrite via public helpers already tested; add small test for import parse extraction if extractable**
- [ ] **Step 2: Implement provider changes**
- [ ] **Step 3: `dart analyze` provider**
- [ ] **Step 4: Commit** `feat(sources): import parse, tag groups, validate persist`

---

### Task 4: Import preview dialog + wire manage imports

**Files:**
- Create: `lib/widgets/import_book_source_dialog.dart`
- Modify: `lib/pages/sources/sources_page.dart` (`_importFromJsonFile`, `_importFromQr`, `_showImportUrlDialog`)

**Behavior:**
- Dialog takes `List<BookSource> candidates` + existing URL set
- Show 新增/更新 (url exists) badge
- Confirm → `importParsedSources(selected)`
- File/QR/URL flows: parse → if empty SnackBar → else show dialog

- [ ] **Step 1: Implement dialog**
- [ ] **Step 2: Rewire three import entry points**
- [ ] **Step 3: Analyze**
- [ ] **Step 4: Commit** `feat(sources): import book source preview dialog`

---

### Task 5: Check keyword + config dialogs + wire validate

**Files:**
- Create: `lib/widgets/check_source_config_dialog.dart`
- Create: `lib/widgets/check_source_keyword_dialog.dart`
- Modify: `lib/pages/sources/sources_page.dart` (batch + row validate)

**Behavior:**
- Keyword dialog: field +「校验设置」+ 确定校验
- Config: timeout + 4 switches; save prefs
- `_onBottomMore('validate')` and row validate open keyword dialog first

- [ ] Implement + analyze + commit `feat(sources): check keyword and config dialogs`

---

### Task 6: Group manage + bottom add/remove use tags; filter contains

**Files:**
- Modify: `lib/widgets/source_group_manage_dialog.dart`
- Modify: `lib/pages/sources/sources_page.dart` (`_filter` group case, `_batchSetGroup` / add/remove group)

**Behavior:**
- Filter `group:xxx` uses `sourceHasGroupTag`
- Bottom「添加分组」→ `addGroupToSources` (tag add)
- Bottom「移除分组」→ pick tag or clear one tag via `removeGroupTagFromSources`
- Manage rename/delete uses tag rename/remove across sources

- [ ] Implement + analyze + commit `feat(sources): comma multi-group in manage UI`

---

### Task 7: Docs + verification

**Files:**
- Modify: `docs/UI_REPLICATION_PLAN.md` §2.8
- Modify: `docs/superpowers/specs/2026-07-21-book-source-manage-wave2-design.md` status → 第二波已实现

```bash
flutter test test/services/source_group_tags_test.dart test/services/check_source_prefs_test.dart test/services/source_validation_store_test.dart
dart analyze lib/services/source_group_tags.dart lib/services/check_source_prefs.dart lib/services/source_validation_store.dart lib/widgets/import_book_source_dialog.dart lib/widgets/check_source_config_dialog.dart lib/widgets/check_source_keyword_dialog.dart lib/providers/source_provider.dart lib/pages/sources/sources_page.dart
```

- [ ] Docs + tests PASS + commit `docs: record book source manage wave 2`

---

## Spec coverage

| Spec | Task |
|------|------|
| §2 Import preview | 3–4 |
| §3 Check prefs/keyword | 2, 5 |
| §4 Multi-group | 1, 3, 6 |
| §5 Validation persist | 2, 3 |
| §7 Acceptance | 7 |
