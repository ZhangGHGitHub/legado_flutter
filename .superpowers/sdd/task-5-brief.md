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
