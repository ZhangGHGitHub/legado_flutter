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
