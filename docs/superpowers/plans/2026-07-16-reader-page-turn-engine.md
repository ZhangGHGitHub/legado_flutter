# 阅读器翻页引擎 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 用对齐 Jingshiro `*PageDelegate` 的截图层 + CustomPainter 翻页引擎，替换阅读器横向 `PageView` 透视 hack；五档齐全，仿真档完整跟指贝塞尔卷曲。

**Architecture:** `ReaderTurnView` 管理三页内容与截图；`PageTurnController` 负责手势/收尾；各模式 `CustomPainter` 按 Jingshiro 绘制。滚动模式保留现有 `ScrollView`。

**Tech Stack:** Flutter、`dart:ui` Image、`RepaintBoundary.toImage`、`CustomPainter`、`AnimationController`；对标源 `Jingshiro/legado` `SimulationPageDelegate.kt` 等。

**规格：** [2026-07-16-reader-page-turn-engine-design.md](../specs/2026-07-16-reader-page-turn-engine-design.md)

## Global Constraints

- 不以第三方 page-curl pub 包作为主路径  
- 仿真 = Jingshiro 贝塞尔卷曲完整移植（含跟指），非透视 rotateY  
- 保留 `_splitIntoPages` / `_pageIndex` / 本书 `pageAnim` 覆盖 / 滚动模式  
- 横向翻页不再依赖用户可见的 `PageController`  
- 每 Task 结束后 `flutter analyze` 相关文件无 error；可测部分跑 `flutter test`  
- 提交信息用英文 concise style；规格/计划已中文  

---

## 文件结构（锁定）

| 路径 | 职责 |
|------|------|
| `lib/pages/reader/turn/page_direction.dart` | `PageTurnDirection { none, prev, next }` |
| `lib/pages/reader/turn/simulation_curl_math.dart` | `calcCornerXY` / `calcPoints` 纯数学（可单测） |
| `lib/pages/reader/turn/page_snapshot.dart` | `RepaintBoundary` → `ui.Image` |
| `lib/pages/reader/turn/page_turn_controller.dart` | 状态机、触点、收尾动画 |
| `lib/pages/reader/turn/painters/slide_page_painter.dart` | 滑动绘制 |
| `lib/pages/reader/turn/painters/cover_page_painter.dart` | 覆盖 + 阴影 |
| `lib/pages/reader/turn/painters/simulation_curl_painter.dart` | 仿真绘制（调用 math） |
| `lib/pages/reader/turn/reader_turn_view.dart` | Widget + 手势 |
| `lib/pages/reader/reader_page.dart` | 接入 / 删除 PageView hack |
| `test/pages/reader/turn/simulation_curl_math_test.dart` | 数学单测 |

---

### Task 1: 方向枚举 + 仿真对角数学

**Files:**
- Create: `lib/pages/reader/turn/page_direction.dart`
- Create: `lib/pages/reader/turn/simulation_curl_math.dart`
- Test: `test/pages/reader/turn/simulation_curl_math_test.dart`

**Interfaces:**
- Produces:
  - `enum PageTurnDirection { none, prev, next }`
  - `class CurlCorner { final int cornerX; final int cornerY; }`
  - `CurlCorner calcCornerXY({required double x, required double y, required double viewWidth, required double viewHeight})`
  - `class CurlPoints { ... 全部 Bezier Point + mIsRtOrLb + mDegrees + mTouchToCornerDis ... }`
  - `CurlPoints calcPoints({required double touchX, required double touchY, required int cornerX, required int cornerY, required double viewWidth, required double viewHeight})`

- [ ] **Step 1: 写失败单测（对角象限）**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/pages/reader/turn/simulation_curl_math.dart';

void main() {
  test('calcCornerXY 右下象限', () {
    final c = calcCornerXY(x: 300, y: 500, viewWidth: 400, viewHeight: 800);
    expect(c.cornerX, 400);
    expect(c.cornerY, 800);
  });

  test('calcCornerXY 左上象限', () {
    final c = calcCornerXY(x: 50, y: 50, viewWidth: 400, viewHeight: 800);
    expect(c.cornerX, 0);
    expect(c.cornerY, 0);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

```bash
flutter test test/pages/reader/turn/simulation_curl_math_test.dart
```

Expected: FAIL（库不存在）

- [ ] **Step 3: 实现 `page_direction.dart` + `calcCornerXY`（对齐 Jingshiro）**

```dart
// simulation_curl_math.dart 核心（与 Kotlin 一致）:
// if (x <= viewWidth/2) cornerX=0 else cornerX=viewWidth.toInt()
// if (y <= viewHeight/2) cornerY=0 else cornerY=viewHeight.toInt()
```

完整 `calcPoints`：按 `SimulationPageDelegate.kt` `calcPoints()` / 相关字段逐行移植到纯 Dart（`dart:ui` 的 `Offset` 代替 `PointF`）。本 Task 至少实现 `calcCornerXY` + `calcPoints` 骨架并能编译；若 `calcPoints` 过长，可同 Task 内完成全文移植。

- [ ] **Step 4: 补一条 `calcPoints` 烟雾断言并跑通**

```dart
test('calcPoints 不抛且 touchToCornerDis > 0', () {
  final p = calcPoints(
    touchX: 200, touchY: 600,
    cornerX: 400, cornerY: 800,
    viewWidth: 400, viewHeight: 800,
  );
  expect(p.touchToCornerDis, greaterThan(0));
});
```

Run: `flutter test test/pages/reader/turn/simulation_curl_math_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/pages/reader/turn/page_direction.dart lib/pages/reader/turn/simulation_curl_math.dart test/pages/reader/turn/simulation_curl_math_test.dart
git commit -m "feat(reader): add page-turn direction and curl math"
```

---

### Task 2: 页面截图工具

**Files:**
- Create: `lib/pages/reader/turn/page_snapshot.dart`
- Test: `test/pages/reader/turn/page_snapshot_test.dart`（Widget 测）

**Interfaces:**
- Produces: `Future<ui.Image?> captureBoundary(GlobalKey key, {double? pixelRatio})`
- Consumes: Flutter `RepaintBoundary`

- [ ] **Step 1: 写 Widget 测（泵一个有色 Container + RepaintBoundary，断言 image 非空且宽高>0）**

```dart
testWidgets('captureBoundary 得到非空图像', (tester) async {
  final key = GlobalKey();
  await tester.pumpWidget(MaterialApp(
    home: RepaintBoundary(
      key: key,
      child: const SizedBox(width: 80, height: 120, child: ColoredBox(color: Colors.red)),
    ),
  ));
  await tester.pumpAndSettle();
  final img = await captureBoundary(key, pixelRatio: 1.0);
  expect(img, isNotNull);
  expect(img!.width, greaterThan(0));
  img.dispose();
});
```

- [ ] **Step 2: 跑测确认失败 → 实现 `captureBoundary` → 跑通 → Commit**

```dart
Future<ui.Image?> captureBoundary(GlobalKey key, {double? pixelRatio}) async {
  final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null || !boundary.hasSize) return null;
  final dpr = pixelRatio ?? ui.window.devicePixelRatio; // 或 View.of(context) 由调用方传入
  final capped = dpr.clamp(1.0, 2.5);
  try {
    return await boundary.toImage(pixelRatio: capped);
  } catch (_) {
    return null;
  }
}
```

（实现时用调用方传入的 `pixelRatio`，避免废弃 `window` API。）

```bash
git add lib/pages/reader/turn/page_snapshot.dart test/pages/reader/turn/page_snapshot_test.dart
git commit -m "feat(reader): add RepaintBoundary page snapshot helper"
```

---

### Task 3: PageTurnController 状态机

**Files:**
- Create: `lib/pages/reader/turn/page_turn_controller.dart`
- Test: `test/pages/reader/turn/page_turn_controller_test.dart`

**Interfaces:**
- Consumes: `PageTurnDirection`
- Produces:
  - `class PageTurnController extends ChangeNotifier`
  - 字段：`direction`, `touchX`, `touchY`, `startX`, `startY`, `isDragging`, `isSettling`, `isCancel`
  - `void onPointerDown(Offset p)`
  - `bool onPointerMove(Offset p, {required bool hasPrev, required bool hasNext, required double slop})` → 是否已锁定方向
  - `Future<void> onPointerUp({required TickerProvider vsync, required double viewWidth, required double viewHeight, required void Function(PageTurnDirection) onCompleted})`
  - `Future<void> turnByAnim(PageTurnDirection dir, {...})`
  - settle 用 `AnimationController` 线性插值触点

- [ ] **Step 1: 单测 — 超过 slop 后方向为 next**

```dart
test('右滑超过 slop 判定为 prev（手指右移看上一页，对齐阅读习惯需与 Jingshiro 一致）', () {
  // 先读 HorizontalPageDelegate：dx 符号与 NEXT/PREV 对应关系，测试写死该约定
});
```

**重要：** 打开 Jingshiro `HorizontalPageDelegate.onScroll`，把「dx>0 → PREV 或 NEXT」写进测试注释与断言，禁止猜。

- [ ] **Step 2: 实现 controller（无 UI）→ 测通过 → Commit**

```bash
git commit -m "feat(reader): add PageTurnController gesture state machine"
```

---

### Task 4: Slide + Cover Painter

**Files:**
- Create: `lib/pages/reader/turn/painters/slide_page_painter.dart`
- Create: `lib/pages/reader/turn/painters/cover_page_painter.dart`
- Test: 可选 golden 略过；用小型 `testWidgets` 泵 `CustomPaint` 不崩溃即可

**Interfaces:**
- Consumes: `ui.Image? cur/prev/next`, `PageTurnDirection`, `touchX`, `startX`, `viewSize`
- Produces: `SlidePagePainter`, `CoverPagePainter` extends `CustomPainter`

- [ ] **Step 1: 按 `SlidePageDelegate.onDraw` / `CoverPageDelegate.onDraw` 移植平移与 clip**
- [ ] **Step 2: Cover 边缘阴影宽约 30 逻辑像素（对齐 `setBounds(0,0,30,viewHeight)`）**
- [ ] **Step 3: Commit**

```bash
git commit -m "feat(reader): add slide and cover page painters"
```

---

### Task 5: SimulationCurlPainter 完整绘制

**Files:**
- Create: `lib/pages/reader/turn/painters/simulation_curl_painter.dart`
- Modify: `lib/pages/reader/turn/simulation_curl_math.dart`（若绘制还需额外量）
- Test: 扩展 math 测；painter 烟雾 `testWidgets`

**Interfaces:**
- Consumes: `calcPoints` / `CurlPoints`, images, direction, touch, corners, size
- Produces: `SimulationCurlPainter.paint` 对齐 draw 顺序：  
  NEXT: current area → next+shadow → current shadow → back area

- [ ] **Step 1: 逐函数移植 `drawCurrentPageArea` / `drawNextPageAreaAndShadow` / `drawCurrentPageShadow` / `drawCurrentBackArea`**
- [ ] **Step 2: 阴影用 `Paint.shader = LinearGradient(...).createShader(rect)` 代替 `GradientDrawable`**
- [ ] **Step 3: 烟雾测试 + Commit**

```bash
git commit -m "feat(reader): port Jingshiro simulation curl painter"
```

---

### Task 6: ReaderTurnView 组装

**Files:**
- Create: `lib/pages/reader/turn/reader_turn_view.dart`

**Interfaces:**
- Consumes: controller, painters, snapshot, page builders
- Produces:

```dart
class ReaderTurnView extends StatefulWidget {
  const ReaderTurnView({
    super.key,
    required this.mode, // PageAnimMode: none/cover/slide/simulation
    required this.pageIndex,
    required this.pageCount,
    required this.buildPage, // Widget Function(int index)
    required this.onPageChanged, // void Function(int)
    required this.onTurnChapterPrev, // void Function()
    required this.onTurnChapterNext,
    required this.hasChapterPrev,
    required this.hasChapterNext,
  });
}
```

- [ ] **Step 1: 实现 Stack：底层当前页 Widget；拖动中 CustomPaint 覆盖；三页 Offstage+RepaintBoundary 供截图**
- [ ] **Step 2: Listener/GestureDetector 接 controller；none 模式直接改 index**
- [ ] **Step 3: 章边界：index==0 且 PREV → `onTurnChapterPrev`；末页 NEXT 同理**
- [ ] **Step 4: Commit**

```bash
git commit -m "feat(reader): assemble ReaderTurnView with gestures and painters"
```

---

### Task 7: 接入 ReaderPage + 删除 hack

**Files:**
- Modify: `lib/pages/reader/reader_page.dart`（`_buildBodyText` 横向分支、`_nextPage`/`_prevPage`、模式切换）

**Interfaces:**
- Consumes: `ReaderTurnView`
- 横向：`paged && !_pageAnim.id=='scroll'` 时用 `ReaderTurnView`  
- `_nextPage`/`_prevPage`：若 turn key 可用则 `turnByAnim`，否则保留切章逻辑  

- [ ] **Step 1: 替换 `PageView.builder` 分支为 `ReaderTurnView`**
- [ ] **Step 2: 删除 `_decoratePageAnim` 与对用户翻页的 `PageController` 依赖（分页跳转可内部 index）**
- [ ] **Step 3: 点击热区 / 自动阅读 / 音量键走 `ReaderTurnView` 的 GlobalKey 调用 `turnByAnim`**
- [ ] **Step 4: `flutter analyze lib/pages/reader/` → 无 error**
- [ ] **Step 5: Commit**

```bash
git commit -m "feat(reader): wire ReaderTurnView and remove PageView anim hack"
```

---

### Task 8: 打磨与清单

**Files:**
- Modify: `docs/UI_REPLICATION_PLAN.md`（阅读器翻页条目：写明已换 Jingshiro 引擎）
- Modify: 仿真中段 Y 约束（对齐 `SimulationPageDelegate.onTouch` MOVE）

- [ ] **Step 1: 移植仿真 MOVE 时 `touchY` 中带钉死逻辑**
- [ ] **Step 2: 取消阈值与 Jingshiro `isCancel` 一致（对照 HorizontalPageDelegate）**
- [ ] **Step 3: 更新计划文档翻页相关过时「透视近似」描述**
- [ ] **Step 4: 全量相关 test + analyze → Commit**

```bash
git commit -m "fix(reader): polish curl gestures and update plan docs"
```

---

## Spec 覆盖自检

| 规格条目 | Task |
|----------|------|
| 五档 / 滚动保留 | 6–7 |
| 仿真跟指卷曲 | 1 + 5 + 8 |
| 截图层 | 2 + 6 |
| 手势+程序化同管线 | 3 + 6 + 7 |
| 删 PageView hack | 7 |
| 单测 math | 1 |
| 性能截图时机 | 3（方向锁定时触发 capture） |

无 TBD/TODO 占位步骤。
