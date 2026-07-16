# Reader Page-Turn Engine — Design Spec

> **Date:** 2026-07-16  
> **Status:** Draft for review  
> **Target:** [Jingshiro/legado](https://github.com/Jingshiro/legado) page delegates  
> **Decision:** Full 1:1 port of five modes; simulation includes interactive finger-follow curl  

---

## 1. Problem

Current Flutter reader page animation is a `PageView` + `Matrix4.rotateY` / translate hack.  
Jingshiro uses a custom `ReadView` + `*PageDelegate` that:

1. Screenshots prev/cur/next page bitmaps  
2. Draws with Canvas under finger drag  
3. Completes/cancels via `Scroller`  

Simulation uses classic Bezier page-curl (`SimulationPageDelegate.kt`, ~600 lines).  
Visual quality gap is structural, not a tuning issue.

---

## 2. Goals / Non-Goals

### Goals

- Replace horizontal-paged modes with a Jingshiro-aligned turn engine  
- Five modes: **none / cover / slide / simulation / scroll**  
- **Simulation: full interactive drag curl** (not auto-only)  
- Gesture + programmatic turn (tap zones, volume keys, auto-read) share the same pipeline  
- Preserve existing pagination (`_splitIntoPages`), chapter boundary, book-level pageAnim override  

### Non-Goals (this work)

- HTTP TTS, FontLoader, Web service  
- Changing pagination algorithm or text layout  
- Shipping a third-party pub page-curl package as the primary path  

---

## 3. Architecture

```
ReaderPage (unchanged: content load, chrome, settings)
  │
  ├─ scroll mode → existing ScrollView path (keep)
  │
  └─ horizontal modes (none/cover/slide/simulation)
       └─ ReaderTurnView
            ├─ PageTurnController   // gesture + settle animation (≈ PageDelegate + HorizontalPageDelegate)
            ├─ PageSnapshotCache    // capture prev/cur/next → ui.Image
            ├─ Page content stack   // three offstage/onstage widgets for snapshot + idle display
            └─ CustomPaint
                 ├─ SlidePainter
                 ├─ CoverPainter      (+ edge shadow)
                 ├─ SimulationCurlPainter  // port of SimulationPageDelegate
                 └─ None: jump without paint transition
```

### Mapping to Jingshiro

| Jingshiro | Flutter |
|-----------|---------|
| `ReadView` | `ReaderTurnView` |
| `PageDelegate` | `PageTurnController` base |
| `HorizontalPageDelegate` | shared horizontal gesture + snapshot |
| `CoverPageDelegate` | `CoverPainter` |
| `SlidePageDelegate` | `SlidePainter` |
| `SimulationPageDelegate` | `SimulationCurlPainter` |
| `ScrollPageDelegate` | keep existing scroll UI |
| `PageView` screenshot | `RepaintBoundary` → `toImage()` |
| `Scroller` | `AnimationController` + linear tween of touch point |

---

## 4. Interaction model

### States

`idle` → `dragging` → `settling` → `idle` (or `cancel` settle back)

### Drag

1. **Pointer down:** abort in-flight anim; record `startX/Y`; `onDown()` resets flags  
2. **Move past slop:** determine `NEXT` / `PREV` from dx; if no page in that direction, show snack/toast and abort  
3. **On direction set:** capture snapshots of involved pages (`setBitmap`)  
4. **Move:** update `touchX/Y`; for simulation apply Jingshiro mid-band Y constraints (`touchY` pinned in center band / corner rules)  
5. **Up/Cancel:** decide `isCancel` (drag back past threshold / wrong direction); start settle scroll from current touch toward end or start  

### Programmatic turn (`nextPageByAnim` / `prevPageByAnim`)

Same as Jingshiro key turn: set direction, capture bitmaps, animate touch from edge across width (speed parameter), then `fillPage`.

### Click zones / volume / auto-read

Call `PageTurnController.next/prev` — **do not** drive `PageController` anymore for horizontal modes.

### Simulation-specific (must port)

- `calcCornerXY` on down  
- `setDirection` adjusts corner for PREV/NEXT  
- `calcPoints` Bezier control/vertex/end points each frame  
- Draw order for NEXT: current area → next+shadow → current shadow → back area  
- Draw order for PREV: mirrored bitmap roles  
- Folder / front / back `GradientDrawable` shadows → Flutter `Paint` + `LinearGradient` shaders  

---

## 5. Snapshot strategy

1. Keep three page content widgets (prev/cur/next text already laid out with reader theme).  
2. Wrap each in `RepaintBoundary` with a `GlobalKey`.  
3. On direction commit / before anim: `boundary.toImage(pixelRatio: devicePixelRatio)` → `ui.Image`.  
4. During drag/settle, **paint only from images** (widgets can stay under or offstage).  
5. On anim stop success: advance logical page index, rebuild neighbors, dispose old images.  
6. On cancel: discard neighbor snapshot, stay on current index.  

**Performance:** capture only when direction locks or programmatic turn starts; recycle images on mode change / chapter change / dispose.

**Failure:** if capture fails, fall back to instant jump (none behavior) and log once.

---

## 6. Integration with `ReaderPage`

### Remove / stop using for horizontal modes

- `PageView.builder` + `_decoratePageAnim`  
- `PageController` animate/jump for user-visible turns (may keep briefly for migration then delete)

### Keep

- `_pages` string list + `_pageIndex`  
- `_splitIntoPages`, `_goToChapter`, progress save  
- `_pageAnim` / book-level override  
- Scroll mode branch  
- Chrome / click zones (wire to turn controller)

### Chapter edges

- First page + PREV → previous chapter last page (existing `_prevPage` chapter logic)  
- Last page + NEXT → next chapter first page  
- Snapshot after chapter content ready (await load if needed)

---

## 7. File plan

| Path | Role |
|------|------|
| `lib/pages/reader/turn/reader_turn_view.dart` | Widget + gesture arena |
| `lib/pages/reader/turn/page_turn_controller.dart` | State machine, settle anim |
| `lib/pages/reader/turn/page_snapshot.dart` | RepaintBoundary helpers |
| `lib/pages/reader/turn/painters/slide_page_painter.dart` | Slide |
| `lib/pages/reader/turn/painters/cover_page_painter.dart` | Cover + shadow |
| `lib/pages/reader/turn/painters/simulation_curl_painter.dart` | Full Bezier port |
| `lib/pages/reader/turn/page_direction.dart` | enum NEXT/PREV/NONE |
| `test/pages/reader/turn/simulation_curl_math_test.dart` | Unit tests for `calcPoints` / corner math |

Reference during port (offline copy OK): Jingshiro  
`app/.../page/delegate/{Page,Horizontal,Cover,Slide,Simulation}PageDelegate.kt`

---

## 8. Implementation phases

1. **Scaffold:** `ReaderTurnView` + none/slide (bitmap translate) wired into `ReaderPage`  
2. **Cover:** edge shadow + clip  
3. **Simulation math port:** `calcCornerXY` / `calcPoints` with golden tests vs known points  
4. **Simulation draw:** paths + shadows + back area  
5. **Gesture polish:** cancel threshold, mid-band Y, programmatic anim speed  
6. **Cleanup:** delete `_decoratePageAnim` / unused `PageView` path; update plan checklist  

---

## 9. Acceptance

- [ ] Cover / slide / simulation / none look and feel close to Jingshiro on same content  
- [ ] Simulation: finger follows curl in real time; release completes or cancels  
- [ ] Tap / volume / auto-read use same settle animation  
- [ ] Chapter boundary turns work without black flash  
- [ ] Mode switch (settings + per-book) rebuilds cleanly  
- [ ] Scroll mode unchanged  
- [ ] `flutter analyze` clean on touched files; math unit tests pass  
- [ ] Apple Build still green (no macOS-specific break)

---

## 10. Risks

| Risk | Mitigation |
|------|------------|
| Snapshot cost / jank | Capture only on direction lock; reuse until stop |
| Bezier port bugs | Port function-by-function; math unit tests; side-by-side with Android apk |
| Text selection / long-press conflict | Keep selection gesture arena; turn wins after slop only |
| High DPI memory | Cap pixel ratio if needed (e.g. min(dpr, 2.5)) |

---

## 11. Out of scope reminders

Intentional simplifications elsewhere (HTTP TTS, true mesh curl beyond Jingshiro Bezier, etc.) stay deferred.  
This spec’s “simulation” means **Jingshiro Bezier curl**, not a new 3D mesh.
