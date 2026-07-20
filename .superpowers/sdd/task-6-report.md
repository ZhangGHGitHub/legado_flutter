# Task 6 Report: Group manage + bottom add/remove use tags; filter contains

**Status:** DONE

## Changes
- **`sources_page.dart`**
  - `group:xxx` filter uses `sourceHasGroupTag` (contains) instead of whole-string equality
  - Bottom「添加分组」unchanged — already calls `addGroupToSources` (appends tag, preserves others)
  - Bottom「移除分组」: dialog lists union of tags on selected sources; tap one → `removeGroupTagFromSources`; optional「清除全部分组」→ `clearGroupOnSources`
- **`source_group_manage_dialog.dart`** — no code change; already calls `renameGroup` / `deleteGroup`
- **`source_provider.dart`** — verified tag-aware: `renameGroup` uses `renameSourceGroupTag`, `deleteGroup` uses `removeSourceGroupTag`, `knownGroups` splits comma tags

## Verification
- `flutter analyze lib/pages/sources/sources_page.dart lib/widgets/source_group_manage_dialog.dart lib/providers/source_provider.dart lib/services/source_group_tags.dart` — no errors (1 pre-existing info on doc comment)

## Concerns
- `_batchSetGroup`（设置分组）still routes through `setSourcesGroup` → `addGroupToSources`;「清除分组」passes empty string and no-ops — separate from this task but worth QA
- Manual QA: multi-tag source appears under each `group:xxx` filter; remove one tag leaves others; manage rename/delete updates tags across sources

## Commit
`feat(sources): comma multi-group in manage UI`

---

## Follow-up fix (2026-07-21)

**Status:** DONE

### Changes
- **`sources_page.dart` `_batchSetGroup`**:「清除分组」(empty string) now calls `clearGroupOnSources` instead of `setSourcesGroup`/`addGroupToSources`
- **`_batchRemoveGroup`**: single-tag remove snackbar counts only selected sources that had the tag

### Verification
- `flutter analyze lib/pages/sources/sources_page.dart` — no issues found

### Commit
`fix(sources): clear group via clearGroupOnSources`
