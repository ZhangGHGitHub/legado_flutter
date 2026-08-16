# Task 2 Report: Import URL history store + dialog UI

## Status

DONE

## What Was Implemented

### `ImportUrlHistoryStore` (`lib/services/import_url_history_store.dart`)

SharedPreferences key `book_source_import_url_history_v1`; max 20 entries (dedupe + prepend).

| API | Behavior |
|-----|----------|
| `load()` | Returns stored URL list (newest first) |
| `add(url)` | Trim, skip empty, dedupe, prepend, cap at 20 |
| `remove(url)` | Remove one entry |
| `clear()` | Remove all entries |

### Dialog UI (`lib/pages/sources/sources_page.dart`)

- `_ImportUrlDialog`: TextField + scrollable「最近使用」list under field
- Tap row fills TextField; trailing ✕ removes from store
- `_parseAndPreviewImport`: adds URL to history when fetch/parse succeeds (`_looksLikeImportUrl`)

## TDD Evidence

```
flutter test test/services/import_url_history_store_test.dart
```

Result: **PASS** — `00:00 +6: All tests passed!`

## Commit

`92f8cf2 feat(sources): network import URL history`

Files committed:

- `lib/services/import_url_history_store.dart`
- `test/services/import_url_history_store_test.dart`
- `lib/pages/sources/sources_page.dart`

## Concerns

- History saved after successful parse, not after user confirms import preview dialog (matches spec「成功发起导入」= fetch OK).
- Dialog history list does not live-refresh after import (dialog already closed); next open shows updated list.
- No widget test for dialog UI; store covered by unit tests only.
