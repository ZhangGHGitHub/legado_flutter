### Task 3: Checkbox-lane drag multi-select

**Files:**
- Modify: `lib/pages/sources/sources_page.dart` (and optional small private widget in same file)

**Behavior:**
- Drag on checkbox lane toggles range with sticky mode from first hit
- Auto-scroll near edges via existing/list `ScrollController`
- Conflict: when `ReorderableListView` active, keep reorder handle on the right; left lane is select-drag only

- [ ] **Step 1: Implement drag select**
- [ ] **Step 2: Manual sanity notes in report; analyze**
- [ ] **Step 3: Commit** `feat(sources): drag multi-select on checkbox lane`

---
