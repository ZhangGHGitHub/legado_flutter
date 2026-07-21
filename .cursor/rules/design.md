---
description: Design system, visual standards, component behavior, and interaction patterns. Applies to all UI work.
alwaysApply: true
---

# Design: Legado Flutter

## 设计体系

- **UI 框架**：Material Design 3（`useMaterial3: true`），所有页面遵循 MD3 设计规范。
- **设计令牌**：统一存放在 `lib/theme/legado_tokens.dart`，包括：
  - 圆角（`BorderRadius`）：卡片、对话框、按钮等
  - 间距（`EdgeInsets`）：页面边距、组件间距
  - 封面尺寸：书架网格/列表模式下的封面宽高比
  - 阅读页边距、行距、段距等
- **禁止硬编码**：任何 UI 数值（颜色、字号、间距、圆角）必须从 Token 或 Theme 中引用，不得在代码中直接写死。

### Token 设计参考

```dart
// lib/theme/legado_tokens.dart 示例结构（目标约定；与现有 LegadoTokens 对齐演进）
class LegadoDimens {
  // 页面边距
  static const pageHorizontal = 16.0;
  static const pageVertical = 12.0;

  // 间距
  static const spacingSmall = 4.0;
  static const spacingMedium = 8.0;
  static const spacingLarge = 16.0;
  static const spacingXLarge = 24.0;

  // 圆角
  static const radiusSmall = 4.0;
  static const radiusMedium = 8.0;
  static const radiusLarge = 12.0;
  static const radiusXLarge = 16.0;

  // 封面尺寸
  static const coverGridWidth = 120.0;
  static const coverGridHeight = 160.0;
  static const coverListWidth = 60.0;
  static const coverListHeight = 80.0;
  static const coverAspectRatio = 0.75; // 宽高比

  // 阅读页
  static const readerPaddingHorizontal = 20.0;
  static const readerLineHeight = 1.6; // 倍数字号
  static const readerParagraphSpacing = 8.0;
}
```

UI 布局对标 [Jingshiro/legado](https://github.com/Jingshiro/legado)，确保老用户零学习成本迁移。沿用项目自有 widgets，不另引无关 UI 库改审美。

---

## 布局与交互对标

- **导航栏动态显隐**：底部导航栏的 Tab（探索、订阅）根据 `AppConfig.showDiscovery` 和 `AppConfig.showRSS` 配置动态显示/隐藏。
- **书架双风格**：支持标签式分组（Tab 切换）和列表式分组（分组在列表中展开/收起）两种书架风格。
- **书源引擎**：仅使用 Rust 引擎（`EngineConfig` 无用户切换项）；Dart 双轨已退役。
- **翻页模式**：支持覆盖翻页、仿真翻页、滑动翻页、上下滚动四种模式。

---

## 状态与反馈

### 加载状态粒度

- **列表首次加载**：全屏骨架屏或 loading 指示器。
- **列表下拉刷新**：顶部刷新指示器，原有数据保留。
- **阅读页章节切换**：正文区域显示加载动画，控制栏和进度条保持可见。

### 错误可恢复性

- 错误视图（`error_view`）必须包含重试按钮，用户点击后重新发起请求。

### 乐观更新

- 书架操作（加入/移除/标记已读）采用乐观更新：UI 立即反馈，后台异步同步，失败时回滚并提示。

---

## 主题系统

### 颜色层级

- **应用主题色**：通过 `ColorScheme.fromSeed` 基于种子颜色生成，覆盖全局 UI（导航栏、按钮、卡片等）。
- **阅读页配色**：独立于应用主题管理，包括背景色（纯色/纹理）、文字颜色、高亮颜色等，不跟随系统深浅色模式切换。

### 主题配置存储

- 应用主题偏好存储在 `SharedPreferences` 中。
- 阅读页配色偏好存储在书籍的 `ReadConfig` 中，支持按书籍独立配置。

---

## 设置页结构

设置页按功能分组：

| 分组 | 包含设置项 |
| :--- | :--- |
| **通用** | 应用主题（跟随系统/浅色/深色）、书架风格（标签式/列表式）、显示探索 Tab、显示 RSS Tab |
| **阅读** | 翻页模式、背景色、字体、字号、行距、段距（每一项均独立存储于书籍的 `ReadConfig`） |
| **书源** | 书源管理、书源分组 |
| **备份** | WebDAV 配置、手动备份/恢复 |
| **关于** | 版本信息、开源许可证 |

**关键约束**：

- 应用级设置（通用/主题/底栏显隐）存储在 `SharedPreferences` 中。
- 阅读级设置（翻页/配色/字体）存储在对应书籍的 `ReadConfig` 中，支持按书籍独立配置。
- 阅读页配色**不跟随**系统深浅色模式，由用户在阅读设置中独立选择。
- 底栏 Tab 的显隐需实时生效，切换后无需重启应用。
