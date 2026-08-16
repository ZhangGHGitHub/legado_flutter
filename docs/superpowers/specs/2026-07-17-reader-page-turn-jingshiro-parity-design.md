# 阅读器翻页 — Jingshiro 1:1 保真规格

> **日期：** 2026-07-17  
> **状态：** 待用户审阅规格文件  
> **对标：** [Jingshiro/legado](https://github.com/Jingshiro/legado) `*PageDelegate`  
> **前序规格：** [2026-07-16-reader-page-turn-engine-design.md](./2026-07-16-reader-page-turn-engine-design.md)（架构已落地，本规格修正保真缺口）  
> **用户决策：** 目标为与 Jingshiro **一模一样**；不引入第三方 curl 包；不换回 PageView 透视  

---

## 1. 问题

第一轮已落地 `ReaderTurnView` + 截图 + Slide/Cover/Simulation painters，架构对齐 Jingshiro，但观感差距大：

- **闪 / 白屏：** 方向锁定后才异步 `toImage`，拖动中途才出图  
- **卡 / 不跟手：** 手势路径上 `await` 截图；线性收尾不像 `Scroller`  
- **动画假：** 仿真背面矩阵 / ColorMatrix / 阴影与 KT 不完全一致；覆盖/滑动细节未二次对照  

根因是**实现保真不足**，不是架构选错。

---

## 2. 目标 / 非目标

### 目标

以 Jingshiro 源码为唯一真源，使五档横向翻页在手感与视觉上肉眼难分辨：

1. **截图时机**对齐 `HorizontalPageDelegate.setBitmap` / `setDirection`  
2. **拖动路径零截图**（只用缓存 `ui.Image`）  
3. **收尾物理**对齐 `PageDelegate.startScroll`（距离相关时长）  
4. **仿真绘制**对照 `SimulationPageDelegate` 逐函数 diff 修正  
5. **覆盖 / 滑动**对照 `Cover`/`Slide` `onDraw` 二次核对  

### 非目标

- 第三方 page-curl pub 包  
- 真 3D mesh（超出 Jingshiro 贝塞尔）  
- 改分页算法、正文排版、滚动模式  
- HTTP TTS / FontLoader 等无关项  

---

## 3. 源码真源（必须对照）

本地拷贝（优先）：`.superpowers/sdd/`

| 文件 | 用途 |
|------|------|
| `PageDelegate.kt` | `startScroll` 时长公式、`abortAnim`、`fillPage` |
| `HorizontalPageDelegate.kt` | `onScroll` 方向锁、`isCancel`、`setBitmap`、程序化翻页起点 |
| `CoverPageDelegate.kt` | 覆盖平移 / clip / 30px 阴影 |
| `SlidePageDelegate.kt` | 双页平移 |
| `SimulationPageDelegate.kt` | `onTouch` 中段 Y、`setDirection` 对角、`onAnimStart`、`onDraw` 四段绘制 |

上游：`Jingshiro/legado` → `app/.../ui/book/read/page/delegate/`

**禁止：** 凭感觉调参「好看一点」；任何行为变更须能指出对应 Kotlin 行。

---

## 4. 架构（在现有代码上修正，不大拆）

```
ReaderTurnView（已有）
  ├─ PageSnapshotCache（新增/强化）  // 空闲预截 prev/cur/next；双缓冲
  ├─ PageTurnController（已有）      // 收尾改为 Scroller 等价；拖动不触发截图
  └─ *Painter（已有）                // 仿真/覆盖/滑动保真修正
```

### 与前序规格的关键修正

| 前序写法 | 本规格要求（对齐 Jingshiro） |
|----------|------------------------------|
| 「方向锁定后截图」 | **页静止后预截**；`setDirection` 时 bitmap 已就绪 |
| 「仅方向锁定时截图」 | 拖动 / 收尾期间**禁止** `toImage` |
| 线性插值收尾 | 时长 = `(animationSpeed * abs(dx)) / viewWidth`（见 `PageDelegate.startScroll`） |
| 背面底色写死灰 | 使用当前阅读背景均值色（对齐 `ReadBookConfig.bgMeanColor`） |

---

## 5. 截图层（治闪 / 卡）

### 5.1 预截时机

在以下时机触发 `capture prev/cur/next`（可并行，需等一帧布局）：

1. 首次进入横向模式且分页就绪  
2. `pageIndex` / 章节内容变化且翻页动画已结束（`idle`）  
3. 主题 / 字号 / 边距等影响排版的设置变更后  
4. 程序化翻页开始前：若缓存缺失或过期，**先补截再开动画**（不得在 MOVE 中补截）  

### 5.2 双缓冲

- 持有 `display` 与 `pending` 两套图（或「就绪后再 swap」）  
- 新图全部成功后再替换展示用引用；失败则保留旧图  
- dispose 仅在 swap 成功或组件销毁时进行  

### 5.3 拖动路径

```
onPointerMove → 只用已缓存 Image → CustomPaint
```

**禁止**在 `onPointerMove` / 方向刚锁定时 `await captureBoundary`。

### 5.4 截图失败

- 预截失败：打日志；该方向手势回退为瞬间跳页（等同「无」），避免白屏  
- 不得展示空 `CustomPaint` 遮罩  

---

## 6. 手势与收尾（治跟手 / 回弹）

### 6.1 已对齐、保持不变

- `dx > 0 → PREV`，否则 `NEXT`（`HorizontalPageDelegate.onScroll`）  
- `isCancel = NEXT ? sumX > lastX : sumX < lastX`  
- 仿真按下 `calcCornerXY`；`setDirection` 对角调整  
- 仿真 MOVE 中段 Y 钉死（`SimulationPageDelegate.onTouch`）  

### 6.2 收尾动画（必须改）

对齐 `PageDelegate.startScroll`：

- `duration = (animationSpeed * abs(dx)) / viewWidth`（dx=0 时用 dy / height）  
- 触点从当前 `(touchX, touchY)` 插值到 `onAnimStart` 算出的终点  
- 曲线：可用线性（Android Scroller 默认接近线性插值）或极轻微 easeOut；**时长公式优先于曲线花活**  
- 完成且 `!isCancel` → `onCompleted` → 换页 → **idle 后再预截**  
- 取消 → 不换页 → 清 overlay → 保留/刷新当前缓存  

### 6.3 程序化翻页

对齐 `nextPageByAnim` / `prevPageByAnim` 的起点坐标；动画前确保缓存就绪。

---

## 7. 绘制保真（治假）

### 7.1 SimulationCurlPainter

对照 `SimulationPageDelegate.kt` 做逐函数 diff（至少）：

1. `drawCurrentPageArea` — `clipOutPath` 等价物  
2. `drawNextPageAreaAndShadow` — 阴影方向与宽度  
3. `drawCurrentPageShadow` — 正阴影两段旋转  
4. `drawCurrentBackArea` — 反射矩阵 + folder 阴影；`ColorMatrixColorFilter`（Jingshiro 现为恒等矩阵，Flutter 可保留 no-op 但矩阵公式必须正确）  
5. 阴影色值：与 KT `intArrayOf` / `-0xeeeeef` 等 ARGB 一致  

### 7.2 Cover / Slide

- Cover：`setBounds(0,0,30,viewHeight)` 阴影与 PREV 平移语义再对照（含已知 KT 疑似笔误处：Flutter 保持「视觉正确的 cover」并在注释标明）  
- Slide：双页 `offsetX` 边界与 KT 一致  

### 7.3 背面底色

从 `ReaderTheme` / 背景色传入 `backPageColor`，禁止写死 `#ECECEC`。

---

## 8. 文件规划

| 路径 | 变更 |
|------|------|
| `lib/pages/reader/turn/page_snapshot_cache.dart`（新）或扩 `page_snapshot.dart` | 预截 + 双缓冲 API |
| `lib/pages/reader/turn/reader_turn_view.dart` | 去掉 MOVE 内截图；idle 预截；swap |
| `lib/pages/reader/turn/page_turn_controller.dart` | 收尾时长对齐 `startScroll` |
| `lib/pages/reader/turn/painters/simulation_curl_painter.dart` | 绘制 diff 修正 |
| `lib/pages/reader/turn/painters/cover_page_painter.dart` | 二次对照 |
| `lib/pages/reader/turn/painters/slide_page_painter.dart` | 二次对照 |
| `lib/pages/reader/reader_page.dart` | 传入背景色等；尽量少改 |
| `test/pages/reader/turn/...` | 缓存状态机测；收尾时长测；数学回归 |

参照源码：`.superpowers/sdd/*PageDelegate.kt`

---

## 9. 实施阶段

1. **SnapshotCache + 预截 + 双缓冲**（先消闪/卡）  
2. **ReaderTurnView 去 MOVE 截图**；程序化翻页前补截  
3. **收尾时长对齐 `startScroll`**  
4. **Simulation 绘制逐函数 diff**  
5. **Cover / Slide 二次对照 + backPageColor**  
6. **侧录验收 + 更新 `UI_REPLICATION_PLAN.md`**  

---

## 10. 验收标准

- [ ] 拖动开始无白闪、无明显「先顿一下再出动画」  
- [ ] 跟指连续，无每帧截图卡顿感  
- [ ] 仿真 / 覆盖 / 滑动与 Jingshiro 同书同页侧录对比，肉眼难分辨  
- [ ] 松手完成 / 取消回弹手感接近 Jingshiro  
- [ ] 点击热区 / 音量键 / 自动阅读走同一管线且不闪  
- [ ] 章边界换页后预截成功，无黑页  
- [ ] `flutter analyze` 相关文件无 error；既有 turn 单测通过；新增缓存/时长测通过  

---

## 11. 风险

| 风险 | 缓解 |
|------|------|
| 预截仍耗时 | idle 后台截；DPR `clamp(1, 2.5)`；双缓冲避免空窗 |
| Path.combine 与 Android clipOut 差异 | 对照截图逐帧比；必要时 saveLayer |
| 矩阵移植符号错误 | 用固定 touch/corner 黄金点对 Android 输出（可手工记一组） |
| 热重载后缓存脏 | 设置/分页变更时 invalidate |

---

## 12. 与前序规格关系

- 前序规格确立架构与文件树，**仍然有效**。  
- 本规格**覆盖**前序 §5「方向锁定后截图」与 §10「仅方向锁定时截图」的性能策略，改为 **idle 预截 + 拖动零截图**。  
- 其它章节（模式枚举、章节边界、不引入第三方）不变。
