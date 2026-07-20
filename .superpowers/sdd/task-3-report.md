# Task 3 Report: SourceProvider batch order / explore / export / group

## Status

DONE

## What Was Implemented

### Pure helpers (`lib/providers/source_order.dart`)

| Function | Semantics |
|----------|-----------|
| `customOrdersAfterMoveToTop` | Selected sources first, stable relative order within each partition |
| `customOrdersAfterMoveToBottom` | Selected sources last, stable relative order within each partition |

### SourceProvider APIs (`lib/providers/source_provider.dart`)

| Method | Behavior |
|--------|----------|
| `setSourcesExploreEnabled` | `copyWith(enabledExplore:)` + `_dao.update` per match |
| `moveSourcesToTop` / `moveSourcesToBottom` | Compute order map via helpers → `_applyCustomOrders` |
| `reorderSources` | Assign `customOrder = index` for each URL in list |
| `exportSourcesJson` | `jsonEncode` of matching `toJson()` maps |
| `addGroupToSources` | Set `bookSourceGroup` + `SourceGroupCatalog.mergeFromSources` |
| `clearGroupOnSources` | Set `bookSourceGroup` to `''` |
| `_applyCustomOrders` | Shared persistence for order updates |

`setSourcesGroup` now delegates to `addGroupToSources` (same persistence, no duplication).

Share stays in UI via `Share.share` + `exportSourcesJson` (not in provider).

## TDD Evidence

### RED (Step 2)

```
flutter test test/providers/source_order_logic_test.dart
```

Result: **FAIL** — `source_order.dart` missing; `customOrdersAfterMoveToTop` / `customOrdersAfterMoveToBottom` not found.

### GREEN (Step 4)

```
flutter test test/providers/source_order_logic_test.dart
dart analyze lib/providers/source_order.dart lib/providers/source_provider.dart
```

Result: **PASS** — `00:00 +2: All tests passed!`  
Analyzer: **No issues found!**

Tests:

1. `move to top reindexes selected first`
2. `move to bottom reindexes selected last`

## Commit

```
4f517f3 feat(sources): batch explore, order, export, and group APIs
```

Files committed (only):

- `lib/providers/source_order.dart`
- `lib/providers/source_provider.dart`
- `test/providers/source_order_logic_test.dart`

## Out of Scope (per brief)

- UI wiring (`Share.share`, batch action menus) — later tasks
- Provider integration tests for DAO persistence — pure order logic only in tests

## Concerns / Follow-ups

1. ~~**`moveSourcesToTop/Bottom` preserve list order from `_sources`**, not `customOrder` sort~~ — **Fixed** (see Review Fix below).
2. **`exportSourcesJson` order follows `_sources` iteration**, not input URL order — acceptable for share; reorder if UI needs explicit ordering.
3. **`reorderSources` only updates URLs present in the list** — sources not listed keep existing `customOrder` (brief specifies index per URL in order only).
4. No provider-level tests for explore/group/export — brief TDD scope is pure order helpers only.

## Review Fix (Task 3)

### Change

- Added `sourcesInManualOrder` in `lib/providers/source_order.dart` — sorts by `customOrder` asc, tie-break `bookSourceUrl`.
- `moveSourcesToTop` / `moveSourcesToBottom` now pass `sourcesInManualOrder(_sources)` to order helpers instead of raw DAO list order.
- Added shuffled-list tests documenting correct behavior when list order disagrees with `customOrder`.

### Verification

```
flutter test test/providers/source_order_logic_test.dart
```

Result: **PASS** — `00:00 +4: All tests passed!`

Tests:

1. `move to top reindexes selected first`
2. `move to bottom reindexes selected last`
3. `move to top uses customOrder when list is shuffled`
4. `move to bottom uses customOrder when list is shuffled`

### Commit

```
fix(sources): move to top/bottom uses customOrder order
```

Files committed (only):

- `lib/providers/source_order.dart`
- `lib/providers/source_provider.dart`
- `test/providers/source_order_logic_test.dart`
- `.superpowers/sdd/task-3-report.md`
