# Task 3 Report: Checkbox-lane drag multi-select

## Status

DONE

## What Was Implemented

### `lib/pages/sources/sources_page.dart`

| Feature | Behavior |
|---------|----------|
| Checkbox lane (48dp) | `Listener` on left lane; 4px slop before drag starts |
| Sticky mode | First touched row sets select vs deselect; anchor→current range applied via snapshot restore |
| Auto-scroll | `ScrollController` + 48dp edge zone; 16ms timer while dragging |
| ReorderableListView | Drag handle moved to row end (right); left lane is select-only |
| Flat list | `ListView.separated` + manual-sort `ReorderableListView` both wrapped |
| Domain-grouped list | Visible-row index map; same drag scope over grouped `ListView` |
| Single tap | `Checkbox.onChanged` unchanged; drag uses slop to avoid double-toggle |

## Manual Sanity Notes

1. Manual sort + no filter/search: reorder handle on far right; drag-select on checkbox column only.
2. Drag down/up past viewport edges should scroll list and extend selection range.
3. Start on unchecked row → drag selects range; start on checked → drag deselects range.
4. Domain-grouped view: selection follows visible flat order (headers skipped).
5. Switch / edit / ⋮ taps unaffected (outside checkbox lane).

## Verification

```
dart analyze lib/pages/sources/sources_page.dart
```

Result: **PASS** (exit 0; 2 pre-existing info hints only)

## Commit

```
feat(sources): drag multi-select on checkbox lane
```

## Concerns / Follow-ups

1. **No widget test** — drag/auto-scroll best verified on device/emulator.
2. **Reorder handle moved** — was left of checkbox; now right per spec to avoid gesture conflict.
3. **Grouped headers** — not selectable; index hit-test skips header rows naturally.
4. **Desktop** — lane width 48dp meets spec; Shift+click range deferred per design §1.3.
