### Task 6: Group manage + bottom add/remove use tags; filter contains

**Files:**
- Modify: `lib/widgets/source_group_manage_dialog.dart`
- Modify: `lib/pages/sources/sources_page.dart` (`_filter` group case, `_batchSetGroup` / add/remove group)

**Behavior:**
- Filter `group:xxx` uses `sourceHasGroupTag`
- Bottom「添加分组」→ `addGroupToSources` (tag add)
- Bottom「移除分组」→ pick tag or clear one tag via `removeGroupTagFromSources`
- Manage rename/delete uses tag rename/remove across sources

- [ ] Implement + analyze + commit `feat(sources): comma multi-group in manage UI`

---
