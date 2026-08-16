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
