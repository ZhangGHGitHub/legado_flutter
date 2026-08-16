# Task 1 Report: Help asset + dialog + prefs gate

## Status

DONE

## What Was Implemented

| File | Change |
|------|--------|
| `assets/help/SourceMBookHelp.md` | Chinese help (explore dots, group filter, overflow, bottom actions, validation notes) |
| `lib/services/source_manage_help_prefs.dart` | `currentVersion = 1`, `shouldAutoShow()` / `markShown()` via `book_sources_help_version` |
| `lib/widgets/source_manage_help_dialog.dart` | `SourceManageHelpDialog.show(context)` loads asset; light `#`/`*` parsing |
| `pubspec.yaml` | Registered `assets/help/SourceMBookHelp.md` |
| `lib/pages/sources/sources_page.dart` | Overflow「帮助」+ post-frame first-open auto show |

## Analyze

```
dart analyze lib/services/source_manage_help_prefs.dart lib/widgets/source_manage_help_dialog.dart lib/pages/sources/sources_page.dart
```

Result: **No issues found!**

## Commit

`feat(sources): book source manage help dialog`

Files committed:
- `assets/help/SourceMBookHelp.md`
- `lib/services/source_manage_help_prefs.dart`
- `lib/widgets/source_manage_help_dialog.dart`
- `pubspec.yaml`
- `lib/pages/sources/sources_page.dart`

## Concerns

- Help md notes Flutter does not auto-filter「失效」after validate (Wave 3 spec scope).
- Bumping `currentVersion` will re-trigger auto-show for users who already saw v1.
