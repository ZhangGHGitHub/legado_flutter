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
