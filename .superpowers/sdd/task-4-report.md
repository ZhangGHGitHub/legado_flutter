# Task 4 Report: Inline validation progress + debug toggle

## Status

DONE

## What Was Implemented

| File | Changes |
|------|---------|
| `lib/services/check_source_prefs.dart` | `showDebugMessage()` / `setShowDebugMessage` (default true) |
| `lib/widgets/check_source_config_dialog.dart` | Switch「显示详细信息」load/save |
| `lib/providers/source_provider.dart` | `_validationProgress` map, `validationProgressOf`, stage messages during `validateSource`, clear in `finally` |
| `lib/pages/sources/sources_page.dart` | Row subtitle gray progress text when pref enabled; reload pref after keyword dialog |
| `test/services/check_source_prefs_test.dart` | Default + round-trip for `showDebugMessage` |

## Stage Messages

During validation: 搜索中… → 发现… → 目录… → 正文… (only enabled checks; 900ms timer while Rust runs). Success sets「完成」; errors set「失败: …」; cleared in `finally`.

## Verification

```
dart analyze lib/services/check_source_prefs.dart lib/widgets/check_source_config_dialog.dart lib/providers/source_provider.dart lib/pages/sources/sources_page.dart
→ exit 0 (2 pre-existing info hints in sources_page.dart)

flutter test test/services/check_source_prefs_test.dart
→ All tests passed (6)
```

## Commit

```
feat(sources): inline validation progress text
```
