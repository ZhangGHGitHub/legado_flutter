# Book Source Manage Wave 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish Jingshiro book-source manage polish: help, drag multi-select, import URL history, inline validation progress text, docs.

**Architecture:** Asset help + prefs gate; prefs URL history store; checkbox-lane drag selection on `sources_page`; provider progress messages during validate; light markdown-ish dialog without new deps.

**Tech Stack:** Flutter/Dart, SharedPreferences, existing SourceProvider / CheckSourcePrefs / sources_page.

**Spec:** `docs/superpowers/specs/2026-07-21-book-source-manage-wave3-design.md`

## Global Constraints

- Wave 3 only — no auto-filter「失效」group, no flutter_markdown, no other-page drag-select
- No new pub dependencies
- Preserve Wave 1/2 import preview, check dialogs, multi-group tags
- Chinese copy aligned with Jingshiro help + `strings_zh.xml` where applicable

## File map

| File | Responsibility |
|------|----------------|
| `assets/help/SourceMBookHelp.md` | Help content |
| `pubspec.yaml` | Register asset |
| `lib/services/source_manage_help_prefs.dart` | Help version gate |
| `lib/widgets/source_manage_help_dialog.dart` | Help UI |
| `lib/services/import_url_history_store.dart` | URL history |
| `test/services/import_url_history_store_test.dart` | History tests |
| `lib/services/check_source_prefs.dart` | `showDebugMessage` |
| `lib/providers/source_provider.dart` | `validationProgress` map + updates |
| `lib/pages/sources/sources_page.dart` | Help wire, drag-select, URL history dialog, row progress |
| `docs/UI_REPLICATION_PLAN.md` | Wave 3 done |
| Spec status | 第三波已实现 |

---

### Task 1: Help asset + dialog + prefs gate

**Files:**
- Create: `assets/help/SourceMBookHelp.md`
- Create: `lib/services/source_manage_help_prefs.dart`
- Create: `lib/widgets/source_manage_help_dialog.dart`
- Modify: `pubspec.yaml` (assets)
- Modify: `lib/pages/sources/sources_page.dart` (help menu + first-open)

**Interfaces:**
- `SourceManageHelpPrefs.currentVersion = 1`
- `Future<bool> shouldAutoShow()` / `Future<void> markShown()`
- `SourceManageHelpDialog.show(context)` loads asset via `rootBundle`

Help md content (Chinese) covering: explore green/red dots, group menu, overflow actions, bottom select actions, validation notes — adapted from Jingshiro `SourceMBookHelp.md`.

- [ ] **Step 1: Add asset + prefs + dialog**
- [ ] **Step 2: Wire menu `help` + `initState`/`post-frame` auto-show**
- [ ] **Step 3: Analyze + commit** `feat(sources): book source manage help dialog`

---

### Task 2: Import URL history store + dialog UI

**Files:**
- Create: `lib/services/import_url_history_store.dart`
- Create: `test/services/import_url_history_store_test.dart`
- Modify: `lib/pages/sources/sources_page.dart` (`_showImportUrlDialog`)

**Interfaces:**
```dart
abstract final class ImportUrlHistoryStore {
  static const maxEntries = 20;
  static Future<List<String>> load();
  static Future<void> add(String url);
  static Future<void> remove(String url);
}
```

- [ ] **Step 1: TDD store tests (in-memory SharedPreferences if needed, or mock via setMockInitialValues)**
- [ ] **Step 2: Dialog shows history under field; tap fills; delete icon removes; successful import adds**
- [ ] **Step 3: Commit** `feat(sources): network import URL history`

---

### Task 3: Checkbox-lane drag multi-select

**Files:**
- Modify: `lib/pages/sources/sources_page.dart` (and optional small private widget in same file)

**Behavior:**
- Drag on checkbox lane toggles range with sticky mode from first hit
- Auto-scroll near edges via existing/list `ScrollController`
- Conflict: when `ReorderableListView` active, keep reorder handle on the right; left lane is select-drag only

- [ ] **Step 1: Implement drag select**
- [ ] **Step 2: Manual sanity notes in report; analyze**
- [ ] **Step 3: Commit** `feat(sources): drag multi-select on checkbox lane`

---

### Task 4: Inline validation progress + debug toggle

**Files:**
- Modify: `lib/services/check_source_prefs.dart` (+ optional test)
- Modify: `lib/widgets/check_source_config_dialog.dart` (switch 显示详细信息)
- Modify: `lib/providers/source_provider.dart`
- Modify: `lib/pages/sources/sources_page.dart` (row subtitle)

**Interfaces:**
- `CheckSourcePrefs.showDebugMessage()` / `setShowDebugMessage`
- `SourceProvider.validationProgressOf(url) → String?`
- During `validateSource`, set messages: 搜索中… / 发现… / 目录… / 正文… / 完成 or error; clear when done
- Row shows progress when prefs enabled

- [ ] **Step 1: Prefs + provider progress**
- [ ] **Step 2: Row UI + config switch**
- [ ] **Step 3: Commit** `feat(sources): inline validation progress text`

---

### Task 5: Docs + verification

**Files:**
- Modify: `docs/UI_REPLICATION_PLAN.md`
- Modify: `docs/superpowers/specs/2026-07-21-book-source-manage-wave3-design.md` status → 第三波已实现

```bash
flutter test test/services/import_url_history_store_test.dart
dart analyze lib/services/source_manage_help_prefs.dart lib/services/import_url_history_store.dart lib/widgets/source_manage_help_dialog.dart lib/widgets/check_source_config_dialog.dart lib/providers/source_provider.dart lib/pages/sources/sources_page.dart
```

- [ ] Docs + tests + commit `docs: record book source manage wave 3`

---

## Spec coverage

| Spec | Task |
|------|------|
| §2 Help | 1 |
| §4 URL history | 2 |
| §3 Drag select | 3 |
| §5 Inline debug | 4 |
| §6 Acceptance / docs | 5 |
