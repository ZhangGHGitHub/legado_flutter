### Task 1: Help asset + dialog + prefs gate

**Files:**
- Create: `assets/help/SourceMBookHelp.md`
- Create: `lib/services/source_manage_help_prefs.dart`
- Create: `lib/widgets/source_manage_help_dialog.dart`
- Modify: `pubspec.yaml` (assets)
- Modify: `lib/pages/sources/sources_page.dart` (help menu + first-open)

**Interfaces:**
- `SourceManageHelpPrefs.currentVersion = 1`
- `Future<bool> shouldAutoShow()` / `Future<void> markShown()`
- `SourceManageHelpDialog.show(context)` loads asset via `rootBundle`

Help md content (Chinese) covering: explore green/red dots, group menu, overflow actions, bottom select actions, validation notes — adapted from Jingshiro `SourceMBookHelp.md`.

- [ ] **Step 1: Add asset + prefs + dialog**
- [ ] **Step 2: Wire menu `help` + `initState`/`post-frame` auto-show**
- [ ] **Step 3: Analyze + commit** `feat(sources): book source manage help dialog`

---
