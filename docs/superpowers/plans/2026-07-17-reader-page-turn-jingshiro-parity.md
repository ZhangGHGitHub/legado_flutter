# Jingshiro 翻页 1:1 保真 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 Jingshiro `*PageDelegate` 修正现有翻页引擎：idle 预截图 + 拖动零截图 + Scroller 等价收尾 + 仿真/覆盖/滑动绘制保真，消除闪/卡/假。

**Architecture:** 在现有 `ReaderTurnView` 上引入 `PageSnapshotCache`（双缓冲预截）；`PageTurnController` 收尾时长对齐 `PageDelegate.startScroll`；painters 对照 KT 逐函数 diff。不以第三方 curl 包、不换回 PageView。

**Tech Stack:** Flutter、`dart:ui` Image、`RepaintBoundary.toImage`、`CustomPainter`、`AnimationController`；真源 `.superpowers/sdd/*PageDelegate.kt`。

**规格：** [2026-07-17-reader-page-turn-jingshiro-parity-design.md](../specs/2026-07-17-reader-page-turn-jingshiro-parity-design.md)

## Global Constraints

- 以 Jingshiro KT 为唯一真源；行为变更须能指出对应 Kotlin 行  
- 拖动 / 收尾路径 **禁止** `await toImage`  
- 不引入第三方 page-curl 包；不恢复 PageView 透视 hack  
- 提交信息英文 concise；规格/计划中文  
- 每 Task：`flutter analyze` 相关文件无 error；可测部分跑 `flutter test`  
- 仅 stage 本任务文件；勿提交 `.reasonix/`、analyze dump、XML dump  

---

## 文件结构（锁定）

| 路径 | 职责 |
|------|------|
| `lib/pages/reader/turn/page_snapshot_cache.dart` | 预截 prev/cur/next + 双缓冲 swap |
| `lib/pages/reader/turn/page_snapshot.dart` | 保留 `captureBoundary`（cache 调用） |
| `lib/pages/reader/turn/reader_turn_view.dart` | idle 预截；MOVE 只用缓存；程序化翻页前补截 |
| `lib/pages/reader/turn/page_turn_controller.dart` | 收尾时长 = `(speed * abs(dx)) / viewWidth` |
| `lib/pages/reader/turn/painters/simulation_curl_painter.dart` | 仿真绘制 diff |
| `lib/pages/reader/turn/painters/cover_page_painter.dart` | Cover 二次对照 |
| `lib/pages/reader/turn/painters/slide_page_painter.dart` | Slide 二次对照 |
| `lib/pages/reader/reader_page.dart` | 传入 `backPageColor`（尽量少改） |
| `test/pages/reader/turn/page_snapshot_cache_test.dart` | 缓存/swap 单测 |
| `test/pages/reader/turn/page_turn_controller_test.dart` | 扩展收尾时长断言 |

---

### Task 1: PageSnapshotCache（预截 + 双缓冲）

**Files:**
- Create: `lib/pages/reader/turn/page_snapshot_cache.dart`
- Test: `test/pages/reader/turn/page_snapshot_cache_test.dart`
- Reuse: `lib/pages/reader/turn/page_snapshot.dart` → `captureBoundary`

**Interfaces:**
- Produces:
  - `class PageSnapshotTriple { ui.Image? prev, cur, next; void dispose(); }`
  - `class PageSnapshotCache` with:
    - `PageSnapshotTriple? get display`
    - `Future<bool> refresh({required GlobalKey prevKey, required GlobalKey curKey, required GlobalKey nextKey, required double pixelRatio, required bool hasPrev, required bool hasNext})` → 成功则 swap 进 `display`，失败保留旧 `display` 并返回 false
    - `void invalidate()` → dispose display（及 pending）
    - `bool get hasCur` → `display?.cur != null`
- Consumes: `captureBoundary`

- [ ] **Step 1: 写失败单测**

```dart
test('refresh 成功后 display.cur 非空；失败不清掉旧 display', () async {
  // 用 1x1 Picture→Image 注入，或 Widget 泵 RepaintBoundary
  // 断言：第二次 refresh 故意失败时 display 仍指向第一次的 cur
});
```

- [ ] **Step 2: 实现 cache（双缓冲：pending 全成功再 dispose 旧 display 并替换）**
- [ ] **Step 3: `flutter test` + `flutter analyze` → Commit**

```bash
git commit -m "feat(reader): add PageSnapshotCache with double-buffer swap"
```

---

### Task 2: ReaderTurnView — idle 预截，MOVE 零截图

**Files:**
- Modify: `lib/pages/reader/turn/reader_turn_view.dart`
- Test: 可选 smoke；重点手工/逻辑：MOVE 路径无 `captureBoundary` 调用

**Interfaces:**
- Consumes: `PageSnapshotCache`
- 行为：
  - `initState` / `didUpdateWidget`(pageIndex/pageCount/mode) / 翻页完成后 → `scheduleWarmSnapshots()`
  - `onPointerMove` 方向锁定后：**立刻**用 `cache.display` 开 overlay；**禁止** `await _ensureSnapshotsFor`
  - 若 `!hasCur`：该手势回退瞬间跳页（none）或忽略拖动（规格 §5.4）
  - `turnByAnim`：若缺图则 **await refresh** 一次，再开动画

- [ ] **Step 1: 接入 cache，删除 MOVE 内 `_ensureSnapshotsFor` await**
- [ ] **Step 2: idle `addPostFrameCallback` 预截；overlay 用 `cache.display`**
- [ ] **Step 3: analyze + turn 包测试 → Commit**

```bash
git commit -m "feat(reader): precache page snapshots; no capture during drag"
```

---

### Task 3: 收尾时长对齐 PageDelegate.startScroll

**Files:**
- Modify: `lib/pages/reader/turn/page_turn_controller.dart`
- Modify: `test/pages/reader/turn/page_turn_controller_test.dart`

**Interfaces:**
- 对照 `.superpowers/sdd/PageDelegate.kt` L73–79：
  - `durationMs = dx != 0 ? (animationSpeed * abs(dx)) ~/ viewWidth : (animationSpeed * abs(dy)) ~/ viewHeight`
  - `max(durationMs, 1)`
- 曲线保持线性（Scroller 等价）

- [ ] **Step 1: 单测固定 dx/viewWidth/speed，断言 settle 时长**
- [ ] **Step 2: 实现 / 修正 `_startSettle` duration**
- [ ] **Step 3: Commit**

```bash
git commit -m "fix(reader): align page-turn settle duration with Jingshiro Scroller"
```

---

### Task 4: SimulationCurlPainter 逐函数 diff

**Files:**
- Modify: `lib/pages/reader/turn/painters/simulation_curl_painter.dart`
- Optionally: `lib/pages/reader/turn/simulation_curl_math.dart`（仅缺字段时）
- Test: 既有 smoke + 必要时扩展

**Interfaces:**
- 对照 `.superpowers/sdd/SimulationPageDelegate.kt`：`drawCurrentPageArea` / `drawNextPageAreaAndShadow` / `drawCurrentPageShadow` / `drawCurrentBackArea`
- 阴影 ARGB 与 KT 一致；反射矩阵公式正确；`backPageColor` 由外部传入（本 Task 保证参数可用）

- [ ] **Step 1: 打开 KT 与 Dart 并排，按函数修 clip / 阴影 / 矩阵**
- [ ] **Step 2: smoke test + analyze → Commit**

```bash
git commit -m "fix(reader): align simulation curl painter with Jingshiro draw path"
```

---

### Task 5: Cover / Slide 二次对照 + backPageColor 接线

**Files:**
- Modify: `lib/pages/reader/turn/painters/cover_page_painter.dart`
- Modify: `lib/pages/reader/turn/painters/slide_page_painter.dart`
- Modify: `lib/pages/reader/turn/reader_turn_view.dart`（`backPageColor` 参数）
- Modify: `lib/pages/reader/reader_page.dart`（传入主题背景色）

**Interfaces:**
- Cover 阴影宽 30；Slide offset 边界对齐 KT  
- `ReaderTurnView(backPageColor: theme.background)` → `SimulationCurlPainter`

- [ ] **Step 1: Cover/Slide 对照 KT 修正（有注释说明与 KT 笔误分歧）**
- [ ] **Step 2: reader_page 传入背景色**
- [ ] **Step 3: analyze → Commit**

```bash
git commit -m "fix(reader): polish cover/slide painters and wire backPageColor"
```

---

### Task 6: 文档与回归

**Files:**
- Modify: `docs/UI_REPLICATION_PLAN.md`（写明 1:1 保真轮次）
- Modify: `docs/superpowers/specs/2026-07-17-reader-page-turn-jingshiro-parity-design.md` 状态 → 已实施（可选）

- [ ] **Step 1: `flutter test test/pages/reader/turn/` 全绿**
- [ ] **Step 2: `flutter analyze lib/pages/reader/turn/ lib/pages/reader/reader_page.dart`**
- [ ] **Step 3: 更新计划文档 → Commit**

```bash
git commit -m "docs: note Jingshiro page-turn parity pass"
```

---

## Spec 覆盖自检

| 规格章节 | Task |
|----------|------|
| §5 预截 + 双缓冲 + MOVE 零截图 | 1–2 |
| §6.2 startScroll 时长 | 3 |
| §7.1 仿真 diff | 4 |
| §7.2–7.3 Cover/Slide + backPageColor | 5 |
| §10 验收 / 文档 | 6 |
