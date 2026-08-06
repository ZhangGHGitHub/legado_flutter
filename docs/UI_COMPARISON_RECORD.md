# UI 对照记录

状态：进行中。该记录只记录已实际采集的同设备证据，不把源码核对或不同数据状态截图记为像素通过。

## 2026-08-02：当前 Android 设备对照约定

- 当前设备：雷电模拟器 `emulator-5556`，Android 9 / API 28，`720x1280`，DPI `320`。
- UI 目标版本：重构前原版 `3.26.071309`；实机包为 `io.legado.app.releaseS`，关于页显示“阅读 Sigma”，桌面图标显示“阅读Beta”。重构版以当前工程实际 applicationId 单独验证。
- ADB：`D:\leidian\LDPlayer9\adb.exe`；所有 UI/功能对照均固定使用 `emulator-5556` 上述原版版本。
- 旧设备截图已移除，当前原版只读参考集需要在 `emulator-5556` 上重新采集；在重新采集完成前不宣称 UI 像素验收通过。
- 截图中的棕色/红色主题属于设备当前主题配置，不是固定色值；后续对照固定同数据、同主题、同启动状态。

## 2026-08-06：原版 UI 包名与版本实机复核

- `adb -s emulator-5556 shell pm list packages` 确认原版候选包为 `io.legado.app.releaseS`。
- `dumpsys package io.legado.app.releaseS` 确认 `versionName=3.26.071309`，启动 Activity 为 `io.legado.app.ui.welcome.WelcomeActivity`。
- `monkey -p io.legado.app.releaseS 1` 后截图保存于 `.tmp/ui-compare-20260806/releaseS-current.png`；截图与用户提供的“关于 / 阅读Sigma”界面一致。
- `io.legado.app.debug` 当前未安装；`com.legado.app.release` 为 `3.26080322`，均不作为本 UI 目标版本。

## 2026-07-27：Android 书架首屏初测

测试环境：

- 设备：雷电模拟器 `emulator-5556`，Android 9，物理分辨率 `720x1280`，DPI `320`，DPR `2`。
- 构建：重构版 `flutter build apk --debug`，安装包为 `build/app/outputs/flutter-apk/app-debug.apk`。
- 原版包：`io.legado.app.debug`，启动 Activity 为 `io.legado.app.ui.welcome.WelcomeActivity`。
- 重构版包：`com.legado.legado_flutter`，启动 Activity 为 `.MainActivity`。
- 参照源码：根目录只读 `legado-main/`，重点为 `app/src/main/java/io/legado/app/ui/` 和
  `app/src/main/res/layout/`；本次未修改该目录。

采集命令：

```text
D:\leidian\LDPlayer9\adb.exe -s emulator-5556 shell monkey -p io.legado.app.debug 1
D:\leidian\LDPlayer9\adb.exe -s emulator-5556 shell monkey -p com.legado.legado_flutter 1
D:\leidian\LDPlayer9\adb.exe -s emulator-5556 shell screencap -p /sdcard/...
```

本地证据文件（临时目录，不提交仓库）：

- 原版初始书架：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\original-bookshelf.png`
- 重构版首次启动隐私协议：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\rewrite-bookshelf.png`
- 重构版同意协议后空书架：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\rewrite-bookshelf-after-consent.png`

观察结果：

- 两端均进入四 Tab 主框架，书架、发现、订阅、我的的底部导航位置一致，属于结构性对照证据。
- 原版当前数据状态包含一本书；重构版同意协议后为空书架，因此书籍卡片、空状态和列表高度不能直接作像素结论。
- 原版当前主题顶栏为棕色，重构版默认主题为蓝色；主题配置未统一，颜色差异暂分类为“测试状态差异”，不是立即判定为实现缺陷。
- 重构版首次启动显示隐私协议，原版当前实例未显示同类弹窗；该差异记录为“首次启动流程差异”，不能在已有数据状态下复验。
- 重构版书架空状态文案和插图可见，原版没有空状态，需在同一数据状态下补采。

当前结论：

- 书架首屏 UI 对照已建立采集链路，但尚未通过同数据、同主题、同启动状态的最终验收。
- 本记录不改变第 3 条正文断行规则，也不替代目录、正文逐页快照门禁。

## 2026-07-27：Android 我的页面初测

证据文件（同一设备、同一临时目录）：

- 原版：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\original-my.png`
- 重构版：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\rewrite-my.png`

对照结果：

| 分类 | 原版 | 重构版 | 结论 |
|------|------|--------|------|
| 页面结构 | 标题、品牌卡、四项快捷入口、设置列表、底部四 Tab | 同样的主要层级和底部 Tab | 结构基本一致，仍需统一主题后复测 |
| 主题/颜色 | 棕色顶栏、淡紫卡片 | 蓝色顶栏、浅蓝卡片 | 测试配置差异，暂不判定为布局缺陷 |
| 品牌图标 | 黑色书法 logo 图片 | 蓝色书本图标 | 图标资源/品牌呈现差异，需按原版资源核对 |
| 快捷入口图标 | 文件夹、文件夹、地球、时钟 | 云端、云端、Wi-Fi、历史 | 图标语义和视觉风格不一致，列入 UI 差异 |
| 快捷入口文本 | `Web 服务` 含空格 | `Web服务` 无空格 | 文本差异，需按原版行为约束修正或登记平台差异 |
| 设置列表 | 书源、TXT、净化与高亮、字典规则 | 书源、TXT、离线缓存、替换净化 | 功能项顺序/集合不一致，需确认目标版本功能边界 |
| 底部导航 | 书架/发现/订阅/我的，图标为原版样式 | 相同标签和位置，图标不同 | 结构通过，图标未通过 |

结论：我的页面具备可用的同设备对照证据，但主题、图标资源和设置项集合仍存在可见差异；不能标记 UI 1:1 通过。

## 2026-07-27：Android 书源管理首屏初测

证据文件：

- 原版：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\original-sources.png`
- 重构版首次进入帮助：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\rewrite-sources.png`
- 重构版关闭帮助后：`C:\Users\admin\AppData\Local\Temp\legado-ui-compare-20260727\rewrite-sources-after-help.png`

对照结果：

| 分类 | 原版 | 重构版 | 结论 |
|------|------|--------|------|
| 页面结构 | 返回、搜索、排序/分组、更多、书源列表、底部批量操作 | 同样的主要区域 | 结构基本一致 |
| 首次进入状态 | 直接显示书源列表 | 首次显示“书源管理帮助”弹窗 | 首次流程差异已记录，需确认产品预期 |
| 数据状态 | 1 个书源 | 2 个书源 | 不同数据，不能直接做像素结论 |
| 主题/工具栏 | 棕色顶栏和深棕搜索框 | 蓝色顶栏和蓝色搜索框 | 主题配置差异 |
| 工具栏图标 | 排序、分组、更多图标 | 排序、网络节点式分组、更多图标 | 图标资源/语义呈现差异 |
| 列表行 | 书源名完整显示、单行开关 | 书源名截断、状态点和开关/编辑/更多操作 | 文本与行密度差异，需同数据复验 |
| 底部批量操作 | 全选、反选、删除、更多 | 同区域，但按钮尺寸和图标布局不同 | 布局细节差异 |

结论：书源管理对照链路有效，尚未满足同数据、同主题、同首次状态的 1:1 UI 验收。

待补证据：

1. 在原版和重构版分别导入相同书籍、书源和阅读进度。
2. 统一主题、字体、状态栏/导航栏策略后重新采集书架、目录、阅读器、搜索/书源、备份/WebDAV、我的/设置页面。
3. 保存原版与重构版截图，并按布局、文本、交互、状态、平台差异分类结论。
4. 对阅读器继续使用结构化分页快照和第 3 条断行门禁，不能只比较 PNG。
