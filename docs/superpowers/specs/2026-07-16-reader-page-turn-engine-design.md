# 阅读器翻页引擎 — 设计规格

> **日期：** 2026-07-16  
> **状态：** 待审阅草稿  
> **对标：** [Jingshiro/legado](https://github.com/Jingshiro/legado) 翻页 Delegate  
> **已定决策：** 五档动画 1:1 移植；仿真档含完整跟指拖拽卷曲  

---

## 1. 问题

当前 Flutter 阅读器翻页是 `PageView` + `Matrix4.rotateY` / 平移的权宜方案。  
Jingshiro 使用自定义 `ReadView` + `*PageDelegate`：

1. 截取上一页 / 当前页 / 下一页 Bitmap  
2. 手指拖动时用 Canvas 自绘  
3. 通过 `Scroller` 完成翻页或取消回弹  

仿真档采用经典贝塞尔书页卷曲（`SimulationPageDelegate.kt`，约 600 行）。  
观感差距是架构问题，不是调参能修好的。

---

## 2. 目标 / 非目标

### 目标

- 用对齐 Jingshiro 的翻页引擎替换横向翻页模式  
- 五档：**无 / 覆盖 / 滑动 / 仿真 / 滚动**  
- **仿真：完整跟指拖拽卷曲**（不是仅自动播放）  
- 手势翻页与程序化翻页（点击热区、音量键、自动阅读）走同一套管线  
- 保留现有分页（`_splitIntoPages`）、章节边界、本书翻页动画覆盖  

### 非目标（本轮不做）

- HTTP TTS、FontLoader、Web 服务  
- 改分页算法或正文排版  
- 以第三方 pub 卷曲包作为主实现路径  

---

## 3. 架构

```
ReaderPage（不变：正文加载、chrome、设置）
  │
  ├─ 滚动模式 → 现有 ScrollView 路径（保留）
  │
  └─ 横向模式（无 / 覆盖 / 滑动 / 仿真）
       └─ ReaderTurnView
            ├─ PageTurnController   // 手势 + 收尾动画（≈ PageDelegate + HorizontalPageDelegate）
            ├─ PageSnapshotCache    // 截取 prev/cur/next → ui.Image
            ├─ 页面内容栈           // 三页 offstage/onstage，供截图与静止展示
            └─ CustomPaint
                 ├─ SlidePainter
                 ├─ CoverPainter      （+ 边缘阴影）
                 ├─ SimulationCurlPainter  // 移植 SimulationPageDelegate
                 └─ 无动画：无绘制过渡，直接跳页
```

### 与 Jingshiro 对照

| Jingshiro | Flutter |
|-----------|---------|
| `ReadView` | `ReaderTurnView` |
| `PageDelegate` | `PageTurnController` 基类职责 |
| `HorizontalPageDelegate` | 共用横向手势 + 截图 |
| `CoverPageDelegate` | `CoverPainter` |
| `SlidePageDelegate` | `SlidePainter` |
| `SimulationPageDelegate` | `SimulationCurlPainter` |
| `ScrollPageDelegate` | 保留现有滚动 UI |
| `PageView` 截图 | `RepaintBoundary` → `toImage()` |
| `Scroller` | `AnimationController` + 触点线性插值 |

---

## 4. 交互模型

### 状态机

`idle`（空闲）→ `dragging`（拖动）→ `settling`（收尾）→ `idle`（或取消回弹）

### 拖动手势

1. **按下：** 中断进行中的动画；记录 `startX/Y`；`onDown()` 重置标志  
2. **移动超过 slop：** 由 dx 判定 `NEXT` / `PREV`；该方向无页则提示并中止  
3. **方向确定后：** 截取相关页快照（对齐 `setBitmap`）  
4. **移动中：** 更新 `touchX/Y`；仿真档应用 Jingshiro 中段 Y 约束（中带钉死 / 对角规则）  
5. **抬起/取消：** 判定 `isCancel`（回拖过阈值 / 方向错误）；从当前触点向终点或起点做收尾滚动  

### 程序化翻页（`nextPageByAnim` / `prevPageByAnim`）

对齐 Jingshiro 按键翻页：设定方向 → 截图 → 触点从边缘扫过整宽（带速度参数）→ `fillPage`。

### 点击热区 / 音量键 / 自动阅读

调用 `PageTurnController.next/prev` —— 横向模式**不再**驱动 `PageController`。

### 仿真档必移植项

- 按下时 `calcCornerXY`  
- `setDirection` 按 PREV/NEXT 调整对角  
- 每帧 `calcPoints` 计算贝塞尔控制点 / 顶点 / 终点  
- NEXT 绘制顺序：当前页区域 → 下一页+阴影 → 当前页阴影 → 背面区域  
- PREV：位图角色对调  
- 折痕 / 正面 / 背面 `GradientDrawable` 阴影 → Flutter `Paint` + `LinearGradient`  

---

## 5. 截图策略

1. 保留三页内容 Widget（prev/cur/next，已按阅读主题排版）。  
2. 各包一层带 `GlobalKey` 的 `RepaintBoundary`。  
3. 方向锁定 / 动画开始前：`boundary.toImage(pixelRatio: devicePixelRatio)` → `ui.Image`。  
4. 拖动与收尾期间**只画图片**（Widget 可置于下层或 offstage）。  
5. 动画成功结束：推进逻辑页码、重建邻页、释放旧图。  
6. 取消：丢弃邻页快照，留在当前页。  

**性能：** 仅在方向锁定或程序化翻页开始时截图；模式切换 / 换章 / dispose 时回收。  

**失败：** 截图失败则回退为瞬间跳页（等同「无」动画）并打一次日志。

---

## 6. 与 `ReaderPage` 的集成

### 横向模式停用 / 删除

- `PageView.builder` + `_decoratePageAnim`  
- 用户可见翻页中的 `PageController` animate/jump（迁移期可暂留，最终删除）

### 保留

- `_pages` 字符串列表 + `_pageIndex`  
- `_splitIntoPages`、`_goToChapter`、进度保存  
- `_pageAnim` / 本书级覆盖  
- 滚动模式分支  
- Chrome / 点击热区（接到翻页控制器）

### 章节边界

- 本章首页 + PREV → 上一章末页（沿用现有 `_prevPage` 切章逻辑）  
- 本章末页 + NEXT → 下一章首页  
- 章节正文就绪后再截图（必要时等待加载）

---

## 7. 文件规划

| 路径 | 职责 |
|------|------|
| `lib/pages/reader/turn/reader_turn_view.dart` | Widget + 手势竞争 |
| `lib/pages/reader/turn/page_turn_controller.dart` | 状态机、收尾动画 |
| `lib/pages/reader/turn/page_snapshot.dart` | RepaintBoundary 辅助 |
| `lib/pages/reader/turn/painters/slide_page_painter.dart` | 滑动 |
| `lib/pages/reader/turn/painters/cover_page_painter.dart` | 覆盖 + 阴影 |
| `lib/pages/reader/turn/painters/simulation_curl_painter.dart` | 完整贝塞尔移植 |
| `lib/pages/reader/turn/page_direction.dart` | 枚举 NEXT/PREV/NONE |
| `test/pages/reader/turn/simulation_curl_math_test.dart` | `calcPoints` / 对角数学单测 |

移植参照（可离线拷贝）：Jingshiro  
`app/.../page/delegate/{Page,Horizontal,Cover,Slide,Simulation}PageDelegate.kt`

---

## 8. 实施阶段

1. **骨架：** `ReaderTurnView` + 无/滑动（位图平移）接入 `ReaderPage`  
2. **覆盖：** 边缘阴影 + 裁剪  
3. **仿真数学移植：** `calcCornerXY` / `calcPoints`，对照已知点做黄金单测  
4. **仿真绘制：** Path + 阴影 + 背面区域  
5. **手势打磨：** 取消阈值、中段 Y、程序化动画速度  
6. **收尾：** 删除 `_decoratePageAnim` / 无用 `PageView` 路径；更新计划清单  

---

## 9. 验收标准

- [ ] 覆盖 / 滑动 / 仿真 / 无 在相同正文上观感接近 Jingshiro  
- [ ] 仿真：跟指实时卷曲；松手可完成或取消  
- [ ] 点击 / 音量键 / 自动阅读走同一套收尾动画  
- [ ] 章节边界翻页无黑闪  
- [ ] 模式切换（全局设置 + 本书覆盖）重建干净  
- [ ] 滚动模式行为不变  
- [ ] 改动文件 `flutter analyze` 无 error；数学单测通过  
- [ ] Apple Build 仍绿（无 macOS 专属回归）

---

## 10. 风险

| 风险 | 缓解 |
|------|------|
| 截图开销 / 卡顿 | 仅方向锁定时截图；结束前复用 |
| 贝塞尔移植偏差 | 按函数逐段移植；数学单测；与 Android 包对照 |
| 与长按选文手势冲突 | 保留选文手势竞技场；仅超过 slop 后翻页获胜 |
| 高 DPI 内存 | 必要时限制像素比（如 `min(dpr, 2.5)`） |

---

## 11. 范围外提醒

其它「故意简化·后做」项（HTTP TTS、超出 Jingshiro 贝塞尔的真 3D mesh 等）仍延后。  
本规格中的「仿真」指 **Jingshiro 贝塞尔卷曲**，不是另造一套 3D 网格。
