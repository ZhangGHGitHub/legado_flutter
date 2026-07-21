# SDD Progress — Jingshiro page-turn parity
Plan: docs/superpowers/plans/2026-07-17-reader-page-turn-jingshiro-parity.md
Branch: cursor/s1-reader-content-fixes
Started: 2026-07-17

Task 1: complete

Task 2-6: complete (precache, settle, painter colors, backPageColor, docs)
Parity pass: DONE — hot-restart and side-by-side with Jingshiro

Task 3-5: complete (horizontal settle + cover base + wired)
Task 6: docs touched; tests 21/21

**Post-parity refinements (2026-07-20):**

- CoverPagePainter: changed idle draw strategy, relies on ReaderTurnView underlay
  instead of explicit _drawPage(cur), matching Jingshiro CoverPageDelegate.onDraw.
  Added devicePixelRatio param for correct shadow width at high DPI.
- SlidePagePainter: reordered early-return chain to match Jingshiro
  SlidePageDelegate.onDraw (invalid offset, distanceX, !isRunning, draw).
  Removed spurious direction == none shortcut.
- CoverPagePainter: removed redundant direction == none guard (already covered
  by the !isRunning early return, matching Jingshiro).

