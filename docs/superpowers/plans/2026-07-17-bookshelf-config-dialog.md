# Bookshelf Config Dialog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Wire Jingshiro-aligned bookshelf layout dialog into Tab/Folder chrome pages so layout/sort/flags actually apply.

**Architecture:** Keep style1 (Tab) / style2 (Folder). Both take `BookshelfConfig`; menu opens `BookshelfConfigDialog`; body renders list or N-col grid from `bookshelfLayout`.

**Tech Stack:** Flutter, SharedPreferences via `BookshelfPrefs`, existing BookProvider.

## Global Constraints

- PreferKey-compatible prefs keys already in `BookshelfPrefs`
- No new pub dependencies
- Time sorts share `updatedAt` until separate timestamps exist

---

### Task 1: Wire style pages + menu Dialog

**Files:**
- Modify: `lib/pages/bookshelf/bookshelf_style1_page.dart`
- Modify: `lib/pages/bookshelf/bookshelf_style2_page.dart`
- Modify: `lib/pages/bookshelf/bookshelf_page.dart` (already passes config)
- Modify: `lib/pages/main/main_shell.dart` (wait-up badge gate)
- Modify: `lib/pages/config/config_page.dart` if it still misuses groupStyle as grid

- [ ] Style pages accept `config` + `onConfigChanged`
- [ ] Layout menu → Dialog → save → callback / reload
- [ ] `sortBooks` + unread/margin/bookname/scrollbar/grid-or-list
- [ ] `showWaitUpCount` gates main shell badge
- [ ] `flutter analyze` clean on touched paths
