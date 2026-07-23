# Legado 行为兼容性逐模块开发计划

状态：已确认，执行中<br>
基准：`reference/Jingshiro-legado` 现有本地原版源码<br>
实现：Rust + Flutter 重写工程<br>
约束规范：`docs/legado_rewrite_behavior_constraints.md`

## 1. 目标

按固定顺序逐个对比原版功能模块与本地重写实现，修复能够由原版源码和对比测试证明的行为差异。每次只处理一个模块；当前模块全部测试通过并完成汇报后，才允许进入下一个模块。

本计划不以“能够编译”或“页面大致可用”为完成标准。完成必须同时具备原版行为基线、重写实现结果、自动化对比测试和已知偏差说明。

## 2. 强制执行规则

1. 开始一个模块前，必须先确认上一个模块的全部验收测试通过。
2. 每个模块先读取原版源码，再读取本地实现；不得根据函数名或常见做法猜测原版行为。
3. 第 3 模块的正文断行和分页必须与原 App 一致，严格执行行为约束规范 `§5.1`、`§5.2`、`§5.3`：相同字体、字号、字重、DPI、内容区域、行高、段距、字距和正文时，逐页文本及起止字符位置必须一致。
4. 修改前先增加或确认能够暴露差异的测试；不得为了让测试变绿而削弱断言、删除用例或改写原版基线。
5. 测试失败时先区分实现缺陷、测试环境缺失、原版 fixture 不完整和平台限制；无法通过时必须先报告原因和修复方案，不得强行修改测试。
6. 每个模块结束时运行模块测试、Rust 全量测试和 Flutter 全量测试。任一必需测试失败，该模块不得标记完成。
7. 每个模块完成后向用户汇报并停止，得到继续指令后再进入下一个模块。

## 3. 模块顺序

### 模块 1：规则解析顺序与 JavaScript 宿主 API

目标：保证规则分段、`put` 副作用、动态规则展开、CSS/JSoup、XPath、JSONPath、正则替换和 JS 返回值转换的顺序与原版一致；补齐实际规则依赖的 JS 宿主能力。

原版重点对照：

- `model/analyzeRule/AnalyzeRule.kt`
- `model/analyzeRule/RuleAnalyzer.kt`
- `model/analyzeRule/AnalyzeUrl.kt`
- `model/analyzeRule/AnalyzeByJSoup.kt`
- `model/analyzeRule/AnalyzeByXPath.kt`
- `model/analyzeRule/AnalyzeByJSonPath.kt`
- `model/analyzeRule/AnalyzeByRegex.kt`
- Rhino 扩展、`java.*`、Cookie、缓存与加解密宿主实现

本地重点范围：

- `rust/legado_engine/src/rule/`
- `rust/legado_engine/src/http/analyze_url.rs`
- `rust/legado_engine/src/http/client.rs`
- `rust/legado_engine/tests/js_compatibility.rs`
- 规则引擎相关离线 fixture 测试

验收：

- 规则链按原顺序执行，`put` 在对应片段执行前写入且后续片段可读。
- JS 的字符串、数组、对象、`null` 和 `undefined` 返回值按调用类型转换。
- `java.ajax`、Header、Cookie、缓存、Base64/摘要/对称加密等已支持宿主 API 与原版 fixture 一致。
- HTML、XPath、JSONPath 与正则链的空值和多值行为有离线测试。

执行拆分：

- [x] 1A：JS 宿主共享缓存生命周期、登录头测试环境回退、JS 标记大小写兼容。
- [x] 1B：`SourceRule` 分段、`put` 写入时机、`@get` 与 `{{ }}` 动态规则展开。
- [x] 1C：Default/JS/JSONPath/XPath/Regex 多值与空值转换、JS 宿主 API 差异矩阵。
- [x] 1D：模块 1 完整离线 fixture、全量回归与偏差报告。

状态：模块 1 已完成；1A、1B、1C、1D 均通过门禁。模块 2 已完成，模块 3 待用户确认后开始。

### 模块 2：目录分页、章节身份与去重

目标：对齐 `nextTocUrl`、多页目录、卷节点、章节身份、重复项、空 URL 和循环分页处理。

原版重点对照：

- `model/webBook/BookChapterList.kt`
- `model/webBook/WebBook.kt`
- `data/entities/BookChapter.kt`
- 目录规则与章节 DAO

本地重点范围：

- `rust/legado_engine/src/api/toc.rs`
- `rust/legado_engine/src/rule/html_toc.rs`
- `rust/legado_engine/src/rule/json_toc.rs`
- Dart 章节模型、目录加载与缓存层

验收：章节数量、顺序、标题、URL、卷节点、分页访问序列和去重结果与原版 fixture 一致；循环分页能够终止，失败后分页状态可恢复。

状态：模块 2 已完成；模块 3 执行中，3A 正文处理与基础分页已通过当前子步骤门禁。

### 模块 3：正文处理与中文断行、分页

目标：先对齐正文清洗流水线，再建立与原 App 一致的兼容排版层和逐页快照基线。

原版重点对照：

- `model/webBook/BookContent.kt`
- `help/book/ContentProcessor.kt`
- `ui/book/read/page/ReadView.kt`
- `ui/book/read/page/PageView.kt`
- `ui/book/read/page/ContentTextView.kt`
- 阅读排版配置、字体测量和章节位置映射实现

本地重点范围：

- `rust/legado_engine/src/api/content.rs`
- `rust/legado_engine/src/rule/html_content.rs`
- `rust/legado_engine/src/rule/json_content.rs`
- `lib/help/content_processor.dart`
- `lib/pages/reader/reader_page.dart`
- 阅读器文本布局、分页与选区位置映射代码

必须覆盖的断行场景：

- 中文行首、行尾禁则标点。
- 中文、英文、数字混排。
- 连续 URL、长英文和不可自然分割字符串。
- 段落换行、连续空行、首行缩进和章节标题间距。
- 图片、音频及特殊标签占位。
- 章节首尾拼接、当前位置到页码、选区到正文字符位置映射。

验收产物：固定字体、固定 DPR、固定视口和固定配置下，保存原版及重写版每页文本、起始字符、结束字符、总页数、章节边界和截图；所有字段逐页一致。仅总页数一致不算通过。

状态：模块 3 执行中，尚未完成最终逐页快照验收；特殊标签、原版快照环境和章节边界对比仍待处理。

#### 模块 3A：正文处理与基础分页

- 原版对照依据：`help/book/ContentProcessor.kt`、`ui/book/read/page/provider/TextChapterLayout.kt`、`ui/book/read/page/entities/TextPage.kt`。
- 本地修改：正文处理接入去重标题、可选重分段、替换规则、标题处理、空行过滤和段首缩进；分页器按完整排版行切页并保留 `[start,end)` 字符范围。
- 本步修改：段距按原版 `paragraphSpacing / 10f` 作用于段落结束后的行高偏移，不再把段距错误展开为完整空行；ReaderPage 将阅读配置传入分页器。
- 特殊分页修改：整行 `[newpage]` 按原版作为硬分页命令处理，不进入页面显示文本；分页切片保留标记前后源字符范围，搜索定位和书签起点使用切片范围。
- 非分页显示：滚动和模拟阅读路径同样隐藏 `[newpage]` 命令，避免将布局控制标记作为正文显示。
- HTML 特殊内容：新增 `ReaderMarkup`，对 `<usehtml>...</endhtml>`/`</usehtml>` 容器执行可见文本提取，支持实体、`<br>`、块级换行和 `<hr>` 占位；`<img src>` 解析为单字符占位和 `ReaderMarkupImage` 元数据，保留 URL、顺序与正文字符范围。
- 富文本样式：分页和滚动显示共用可见字符坐标，`<b>/<strong>`、`<i>/<em>`、`<u>`、`<font color>` 和基础 CSS 样式转换为 `TextSpan`，选择模式仍使用纯文本坐标。
- HTML 链接：`<a href>` 转换为可点击 `URLSpan` 等价回调，ReaderPage 仅允许 HTTP/HTTPS 外部打开，并由阅读组件释放手势识别器。
- 新增固定测试：分页连续字符范围、中文禁则、中文/英文/数字/URL 混排，以及段距改变分页边界但不改变正文源文本。
- 定向测试：HTML/分页/正文/选择相关测试 10/10 通过；新增 `<usehtml>` 可见文本、样式 Span 和链接回调测试通过。
- 当前门禁：Rust 全量 108 个库测试及全部非 ignored 集成测试通过；Flutter 全量 265/265 通过；Dart 格式检查和 `git diff --check` 通过；`flutter analyze` 为仓库基线 47 条诊断，未新增。
- 已知边界：尚未完成图片/音频特殊标签，尚未运行原版 Android 逐页快照；模块 3 不能据此标记完成。

#### 模块 3A 图片解析子步骤

- 原版对照依据：`TextChapterLayout.kt` 的 `imgPattern`、内联图片 `ImageColumn` 分支、`setTypeImage` 的独立图片行分支，以及 `ChapterProvider.srcReplaceStr` 的单位置占位语义。
- 本步修改：`ReaderMarkupDocument` 新增 `images` 列表；`<img src>` 不再静默丢弃，而是在可见文本中保留一个 `U+FFFC` 占位字符，并记录 `[start,end)`、源 URL 和外层链接；片段首尾换行裁剪后仍同步修正图片偏移。
- 新增验收：图片前后文本顺序、URL 提取、占位字符范围、`spanForRange` 范围映射和 HTML 标签不可见。
- 定向测试：阅读标记、分页、正文处理和重分段测试 `11/11` 通过。
- 全量回归：Flutter `265/265` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；`git diff --check` 和 Dart 格式检查通过。
- 静态分析：`flutter analyze` 仍为仓库基线 `47` 条诊断，未新增；Rust 保留既有编译器警告。

#### 模块 3A 图片加载与失败回退子步骤

- 本步修改：完整图片范围在 `spanForRange` 中渲染为固定尺寸 `WidgetSpan`；图片链接使用 `GestureDetector` 保留点击回调；选中模式仍使用一字符原始文本，字符位置映射不变。
- 本步修改：新增 `ReaderInlineImage`，对绝对 HTTP(S) 源使用 Flutter 图片加载器；加载中和解码失败均回退到同尺寸占位，非 HTTP(S) 源在本步直接回退；点击回调仍由组件承接。
- 本步验收：图片 `WidgetSpan` 的固定尺寸、失败回退尺寸、图片前后文本显示顺序和 `ReaderSelectableText` 富文本入口通过测试；不依赖真实网络。
- 定向测试：阅读标记、阅读组件、分页、正文处理和重分段测试 `13/13` 通过。
- 全量回归：Flutter `265/265` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；格式检查和 `git diff --check` 通过。
- 静态分析：`flutter analyze` 仍为仓库基线 `47` 条诊断，新增阅读标记和图片组件无诊断。
- 当前边界：图片仍使用固定尺寸，不读取真实图片尺寸；尚未建立原版等价的磁盘图片缓存、书源请求头传递或音频标签处理；下一子步骤再处理真实尺寸探测。

#### 模块 3A 图片尺寸与缓存底层子步骤

- 原版对照依据：`ImageProvider.cacheImage`、`ImageProvider.getImageSize`、Bitmap LRU 缓存和错误图片回退逻辑。
- 本步修改：新增 `ReaderImageCache`，仅接受 HTTP(S) 图片源；按 URL 和排序后的请求头生成 SHA-256 磁盘键；实现内存命中、磁盘命中、同键并发合并、字节持久化和 `image` 包栅格图片宽高解码。
- 失败语义：不支持的协议、空响应、下载异常和无法解码的图片统一返回 `null`，不伪造尺寸；上层继续使用固定占位回退。
- 定向测试：图片缓存服务及阅读标记、选择、分页回归 `14/14` 通过，覆盖 PNG 尺寸、请求头隔离、跨实例缓存、并发去重和坏图片。
- 全量回归：Flutter `265/265` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；`flutter pub get`、格式检查和 `git diff --check` 通过。
- 静态分析：`flutter analyze` 仍为仓库基线 `47` 条诊断，新增缓存服务无诊断。
- 当前边界：缓存服务尚未将异步真实尺寸反馈到 `ReaderPaginator`；SVG、原版独立图片行样式和音频标签留待后续子步骤。

#### 模块 3A 缓存接入子步骤

- 本步修改：`ReaderPage` 异步创建应用级 `ReaderImageCache` 并传入 `ReaderSelectableText`；`ReaderMarkupDocument` 将其传给 `ReaderInlineImage`；图片组件在缓存命中后使用 `Image.memory`，加载期间和失败时保持既有固定尺寸回退；过期异步结果由组件代数丢弃。
- 本步验收：缓存服务、正文标记、选择、分页和失败回退定向测试 `14/14` 通过；静态编译检查通过；未改变分页文本和字符范围。
- 全量回归：Flutter `269/269` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；`git diff --check` 和格式检查通过。
- 静态分析：`flutter analyze` 仍为仓库基线 `47` 条诊断，新增调用链无诊断。
- 环境限制：在当前 Windows Flutter 测试引擎中，直接挂载有效 `Image.memory`（包括不经过 Reader 组件的对照）在图像解码阶段超时；同一字节的 Dart `image` 解码、缓存测试和错误图片回退均通过。未修改实现或测试断言掩盖该限制；成功图片显示需在 Android 模拟器/真机或可用 Flutter 图形渲染环境复验。
- 当前边界：异步缓存尺寸尚未接入 `ReaderPage` 的生产分页调用；书源请求头尚未从 `SourceProvider` 注入图片下载器，SVG、独立图片行样式和音频标签留待后续子步骤。

#### 模块 3A 离线真实尺寸分页测量子步骤

- 原版对照依据：`TextChapterLayout.kt` 的 `ImageProvider.getImageSize`、`setTypeImage` 和 `prepareNextPageIfNeed`；图片占位是单个源字符，但其显示宽高参与行高和分页边界。
- 本步修改：`ReaderPaginator` 新增可选 `ReaderPaginatorPlaceholder` 输入；分页器将每个 `U+FFFC` 构建为不可拆分 `WidgetSpan`，通过 `TextPainter.setPlaceholderDimensions` 使用传入宽高；未提供或无效尺寸时按现有字体比例使用固定占位回退。硬分页分段会同步转换占位符的局部源偏移。
- 本步修正：分页行范围改为兼容 `WidgetSpan` 的行边界测量路径，避免通过坐标反推时把图片前后的换行合并，保持 `[start,end)` 连续映射。
- 本步验收：新增图片尺寸参与布局、占位不可拆分、尺寸变化只改变页边界不改变源偏移、无尺寸固定回退测试；分页定向测试 `7/7` 通过，阅读相关回归 `17/17` 通过。
- 最终全量回归：Flutter `272/272` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；新增分页器和测试文件 `dart analyze` 无诊断，格式检查与 `git diff --check` 通过。
- 当前边界：本步仅建立离线测量能力，尚未把 `ReaderImageCache.getSize` 的异步结果接入 `ReaderPage` 分页；真实网络图片加载仍使用固定尺寸显示，SVG、独立图片行样式和音频标签留待后续子步骤。

#### 模块 3A 异步图片尺寸接入子步骤

- 本步修改：`ReaderPage` 按图片源 URL 异步调用 `ReaderImageCache.getSize`；原始尺寸按正文可用宽度等比缩放，同时传给 `ReaderPaginator` 和 `ReaderMarkupDocument`，使分页占位与实际 `WidgetSpan` 显示尺寸一致。
- 并发与失效：章节内容代数、图片请求代数和 `mounted` 状态共同校验异步结果；章节切换、刷新或销毁后，旧图片尺寸不会回写当前章节。缓存尚未就绪或尺寸获取失败时继续使用固定占位。
- 本步验收：新增尺寸映射显示断言；阅读标记、分页、选择、图片缓存及失败回退定向测试 `17/17` 通过。
- 全量回归：Flutter `272/272` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；格式检查与 `git diff --check` 通过。相关文件定向 `dart analyze` 仅报告阅读页原有 Radio API 弃用提示，未新增本步诊断。
- 当前边界：图片请求头尚未从 `SourceProvider` 注入，SVG、原版独立图片行样式、图片样式参数和音频标签留待后续子步骤；模块 3 仍未完成最终 Android 逐页快照验收。

#### 模块 3A 图片请求头传播子步骤

- 原版对照依据：`ImageProvider.cacheImage` → `BookHelp.saveImage` → `AnalyzeUrl` 的书源请求链；书源静态 `header` 与登录保存头共同参与图片请求，登录头覆盖同名字段。
- 本步修改：`SourceProvider` 新增图片请求头解析，合并 `BookSource.customHeaders` 与 `SourceLoginPrefs.loadHeader`；`ReaderPage` 将有效请求头同时传给 `ReaderImageCache.getSize` 和图片显示链；`ReaderInlineImage` 的缓存及 `NetworkImage` 路径均使用该请求头。
- 缓存语义：请求头继续参与 `ReaderImageCache` 的内存/磁盘键，URL 相同但请求头不同不会复用错误图片或错误尺寸。
- 本步验收：新增书源请求头解析和标记图片组件头部传播测试；阅读标记、分页、选择、图片缓存、失败回退及请求头测试 `18/18` 通过。
- 全量回归：Flutter `273/273` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；格式检查与 `git diff --check` 通过。定向静态检查仅保留阅读页原有 Radio API 弃用提示，未新增本步诊断。
- 当前边界：SVG、原版独立图片行样式、图片样式参数、音频标签和 Android 逐页快照验收留待后续子步骤；模块 3 仍未完成。

#### 模块 3A SVG 尺寸识别子步骤

- 原版对照依据：`SvgUtils.getSize` 和 `ImageProvider.getImageSize`；栅格解码无有效尺寸时，原版从 SVG 文档宽高或 `viewBox` 获取尺寸。
- 本步修改：`ReaderImageCache.getSize` 在栅格解码失败后使用 `xml` 解析 SVG 根节点；优先读取 `width`/`height`，缺失时回退到 `viewBox` 宽高，支持无单位、`px`、`pt`、`pc`、`mm`、`cm`、`in` 常见长度单位，非法 XML 或百分比尺寸继续返回空值并使用固定占位。
- 本步验收：新增 SVG `viewBox` 尺寸、显式宽高优先、单位换算测试；阅读相关回归 `20/20`，SVG 缓存服务 `5/5` 通过。
- 全量回归：Flutter `275/275` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；SVG 文件定向 `dart analyze` 无诊断，格式检查与 `git diff --check` 通过。
- 当前边界：本步只建立 SVG 尺寸识别，`Image.memory` 尚不能在当前 Windows 测试引擎中直接绘制 SVG；实际 SVG 渲染、原版独立图片行样式、图片样式参数、音频标签和 Android 逐页快照验收留待后续子步骤。

#### 模块 3A SVG 实际绘制分支子步骤

- 本步修改：`ReaderInlineImage` 根据图片字节签名识别 SVG；SVG 使用 `SvgPicture.memory` 渲染，并继续复用已有请求头、缓存尺寸和加载失败回退链路；PNG/JPEG 仍使用原有 `Image.memory` 分支。
- 本步验收：新增 SVG 分支识别测试 `1/1` 通过；Flutter 全量测试 `276/276` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；`flutter analyze` 未新增诊断，格式检查与 `git diff --check` 通过。
- 环境限制：当前 Windows Flutter 测试引擎在实际挂载有效 SVG 并进入图形解码阶段时长时间无输出；同类 `Image.memory` 图形解码也有相同限制。该测试已终止，未修改业务断言或用替代断言掩盖失败。
- 当前边界：SVG 生产渲染分支已接入，但 Android 模拟器、真机或可用图形渲染环境下的实际像素复验仍待执行；原版独立图片行样式、图片样式参数、音频标签和 Android 逐页快照验收仍未完成，模块 3 继续执行中。

#### 模块 3A `imageStyle=SINGLE` 独立图片行子步骤

- 原版对照依据：`TextChapterLayout.kt` 的 `setTypeImage`；`Book.imgStyleSingle` 会将图片按正文可视宽度等比缩放，超过可视高度时继续等比缩小，并在图片前后调用分页逻辑。
- 本步修改：读取书源 `ruleContent.imageStyle`；分页器新增 `singleImageStyle` 模式，将每个 `U+FFFC` 图片占位切为独立页面，同时保持图片前后正文的源字符 `[start,end)` 连续映射。实际 `WidgetSpan` 尺寸与分页尺寸共用同一套可视宽高。
- 本步验收：新增 `SINGLE` 独立图片页和书源配置读取测试；阅读相关回归 `25/25` 通过；Flutter 全量 `278/278` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；格式检查和 `git diff --check` 通过。
- 当前边界：本步只实现并验证 `SINGLE`；`DEFAULT/FULL` 的完整原版宽度语义、图片 URL 参数中的 `style/width/click`、音频标签及 Android 逐页像素快照仍待后续子步骤，模块 3 继续执行中。

#### 模块 3A `DEFAULT/FULL` 图片宽度语义子步骤

- 原版对照依据：`TextChapterLayout.kt` 的 `setTypeImage`；默认样式只在图片超过正文宽度时缩小，`FULL` 样式始终将图片等比缩放到正文可视宽度。
- 本步修改：新增纯尺寸计算入口 `ReaderImageLayout.displaySize`，分页占位和实际 `WidgetSpan` 均使用同一结果；`DEFAULT` 保留窄图自然尺寸，`FULL` 对窄图执行放大，超宽图片两种样式都按正文宽度缩小。
- 本步验收：新增 `DEFAULT/FULL` 宽度语义测试；阅读相关回归 `26/26` 通过；Flutter 全量 `279/279` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；格式检查和 `git diff --check` 通过。
- 当前边界：图片 URL 参数中的 `style/width/click`、音频标签、SVG 实际像素复验和 Android 逐页快照仍待后续子步骤，模块 3 继续执行中。

#### 模块 3A 图片 URL 参数子步骤

- 原版对照依据：`AnalyzeUrl.paramPattern` 和 `TextChapterLayout.kt`；参数格式为 URL 后跟 `, {"style":...,"width":...,"click":...}`，参数不属于实际请求 URL。
- 本步修改：新增图片 URL 参数解析；下载、缓存和自然尺寸查询只使用净化后的 URL；`style` 可覆盖单张图片样式，`width` 支持百分比和像素宽度，`click` 优先作为图片点击回调；图片尺寸映射改用正文位置键，避免同 URL 不同参数互相覆盖。
- 本步验收：新增参数拆分、宽度计算和点击回调测试；阅读相关回归 `28/28` 通过；Flutter 全量 `281/281` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；格式检查和 `git diff --check` 通过。
- 当前边界：参数中更复杂的动作语义、音频标签、SVG 实际像素复验和 Android 逐页快照仍待后续子步骤，模块 3 继续执行中。

#### 模块 3A 音频标签兼容语义子步骤

- 原版对照依据：`TextChapterLayout.kt` 的 `setTypeHtml` 与 `TextViewTagHandler`；原版没有 `<audio>` 专用播放器或音频占位 Span，媒体标签本身不进入正文，标签内的备用文本继续按普通文本显示。
- 本步修改：Reader HTML 解析器显式保留 `<audio>` 子节点的备用文本，忽略媒体标签本身及其属性；不新增会改变分页高度、字符范围或平台播放能力的伪播放器控件。
- 本步验收：新增音频标签不可见、备用文本保留测试；阅读相关回归 `29/29` 通过；Flutter 全量 `282/282` 通过；Rust `108` 个库测试及全部非 ignored 集成/文档测试通过；格式检查和 `git diff --check` 通过。
- 当前边界：音频 URL 实际播放不属于原版正文 HTML 排版链路；SVG 实际像素复验、Android 逐页快照和模块 3 最终章节边界对比仍待后续验收，模块 3 继续执行中。

#### 模块 3A Android 图形验收环境检查

- 检查范围：尝试为 SVG 实际绘制和逐页快照验收寻找 Android 图形渲染设备。
- 当前结果：Flutter 仍仅识别 Windows、Chrome、Edge；雷电实例 `dnplayer.exe`/`ldconsole` 正在运行。雷电界面显示的 `emulator-5554` 是设备序列号；直接连接 `127.0.0.1:5554` 被拒绝，实际 `127.0.0.1:5555` 端口已找到，但 `D:\Android\platform-tools\adb.exe` 与雷电自带 ADB 均报告设备 `offline`；`flutter emulators` 仍返回无可用 AVD。
- 结论：当前失败点是雷电 ADB 握手，不是业务测试失败；本子步骤无法完成真实 SVG 像素和 Android 逐页快照验收，也没有修改测试断言或用浏览器结果替代 Android 结果。
- 恢复方案：在雷电中重启该实例，或关闭并重新开启“本地调试/ADB 调试”后，确认 `D:\Android\platform-tools\adb.exe devices` 显示 `127.0.0.1:5555 device`；随后重新执行 SVG 图片挂载、截图像素检查及固定字体/DPR/视口逐页快照对比。
- 当前状态：原雷电实例仍处于 ADB `offline`，但已重新启动独立 Android 设备 `emulator-5556`，设备状态为 `device`，720x1280、DPI 320、系统已启动。模块 3 尚不能标记完成。

#### 模块 3A Android 在线设备定向回归

- 当前设备：Flutter 识别 `emulator-5556`（Android 9 / API 28）；旧 `127.0.0.1:5555` 仍为 `offline`，未用于测试。
- 定向测试：在 Android 设备上运行分页器、`ReaderMarkup`、`ReaderSelectableText` 和 SVG 图片组件测试 `21/21`，全部通过；覆盖中文/混排分页、图片占位尺寸、`[newpage]`、HTML 样式/链接、选择渲染和 SVG 失败回退。
- APK 图形检查：`flutter build apk --debug` 在 Gradle `assembleDebug` 阶段超过 5 分钟无产出并被终止，未生成 APK，未进行应用安装截图；该失败属于 Android 构建环境阻塞，不修改业务断言或用桌面渲染替代。
- 当前边界：仍缺少原版与重写版固定字体、DPR、内容区域、章节边界的逐页快照契约，21/21 定向测试不能替代最终逐页文本/字符范围/截图对比。

### 模块 4：进度迁移、缓存与同步一致性

目标：对齐目录刷新/换源后的阅读位置迁移、章节文件缓存、数据库缓存元数据、阅读记录、书签和远端进度冲突处理。

原版重点对照：

- `model/ReadBook.kt`
- `help/book/BookHelp.kt`
- `data/entities/BookProgress.kt`
- `BookDao`、`BookChapterDao`、`CacheDao`、`ReadRecordDao`
- WebDAV 进度合并实现

本地重点范围：

- `lib/model/read_book.dart`
- `lib/help/book_help.dart`
- `lib/services/book_progress_sync.dart`
- `lib/services/cache_service.dart`
- Rust 数据库、备份和 WebDAV API

验收：覆盖章节增删、改名、合卷、换源、缓存文件缺失、坏缓存、并发旧请求、同步时间冲突和重复导入；迁移后的章节及字符位置、缓存状态和阅读记录与原版一致。

状态：模块 4 本地实现已完成至 4K-18；等待真实 WebDAV 服务器验证、跨设备并发冲突验证和模块 4 最终回归后再正式收尾。

#### 模块 4A：目录刷新后的章节进度迁移

- 原版对照依据：`reference/Jingshiro-legado/app/src/main/java/io/legado/app/model/ReadBook.kt` 的 `setProgress`、`upData` 和 `onChapterListUpdated`；位置由章节索引和章节字符位置组成，进度变化时才写入，目录变化后至少保证索引不越界。
- 本地修改：新增 `lib/services/chapter_progress_migrator.dart`，以旧章节 URL 优先匹配新目录；URL 不可匹配时按标题匹配；都无法确认时按旧索引进行边界裁剪。匹配到同一逻辑章节时保留非负字符位置，并可按新正文长度裁剪；无法确认同章时将位置重置为 0；空目录统一返回索引和位置 0。`BookProvider` 的本地目录、网络刷新和自动换源入口统一使用该迁移结果打开 `ReadBook`；书架书同步持久化章索引、页/位置和当前章标题，预览书只更新内存。
- 新增测试：`test/services/chapter_progress_migrator_test.dart` 5/5；`test/providers/book_provider_progress_migration_test.dart` 2/2，另有 Provider 并发/换源回归 3/3 通过。
- 断行约束：本子步骤只迁移章节索引/字符位置，不修改正文文本、净化、断行或分页逻辑，未改变《重写行为约束规范》第 3 条。
- 验收结果：本步定向 Flutter 测试 10/10；Flutter 全量测试 289/289；Rust 库测试 108/108，全部非 ignored 集成/文档测试通过；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，未新增本步诊断；Rust 仅有既有编译警告。
- 当前边界：章节文件缓存、数据库缓存元数据、阅读记录、书签和 WebDAV 进度冲突留待后续独立子步骤，模块 4 不能标记完成。

#### 模块 4B：章节文件缓存与数据库下载元数据一致性

- 原版对照依据：`reference/Jingshiro-legado/app/src/main/java/io/legado/app/help/book/BookHelp.kt` 的 `saveText`/缓存文件语义，以及 `BookChapterDao` 的章节元数据持久化；正文文件是章节缓存的实际存在依据。
- 本地修改：`BookProvider._enrichDownloadedFromFiles` 同时处理文件存在和文件缺失两种方向，并把书架书的 `isDownloaded` 元数据回写数据库。新增显式 `clearDownloaded` 上下文，清除数据库中的章节正文和下载标记，同时保留普通目录 upsert 的“false 不覆盖已有缓存”语义。
- 数据库修改：Rust 章节 upsert 支持仅由一致性修复流程传入的 `clearDownloaded=true`，删除该章 `content` 并将 `isDownloaded` 置为 false；Flutter `DatabaseHelper/BookDao` 增加对应调用。
- 新增测试：`test/providers/book_provider_cache_consistency_test.dart` 2/2，覆盖文件存在补标记和文件缺失清除标记/正文；Rust 数据库单测 `chapter_cache_metadata_can_be_explicitly_cleared` 1/1 通过。
- 断行约束：本子步骤只处理缓存文件和章节元数据，不修改正文内容、净化、中文断行或分页逻辑，未改变《重写行为约束规范》第 3 条。
- 验收结果：Flutter 定向缓存回归 6/6；Flutter 全量测试 291/291；Rust 全量库测试 109/109，全部非 ignored 集成/文档测试通过；release DLL 重建成功；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，未新增；Rust 仅有既有编译警告。`rustfmt --check` 对包含历史未格式化代码的 `rust/legado_engine/src/db/mod.rs` 仍报告既有格式差异，本步未批量格式化无关代码。
- 当前边界：章节缓存生命周期清理、阅读记录、书签和 WebDAV 进度冲突仍未开始，模块 4 不能标记完成。

#### 模块 4C：数据库正文回落与坏缓存重取

- 原版对照依据：本地 Rust `EngineDb.get_chapter_content` 已提供按 `isDownloaded` 读取单章正文；原版 `BookHelp` 以章节文件为主要缓存，缓存不可用时继续执行正文加载链路。
- 本地修改：新增 FRB `dbGetChapterContent` 绑定及 `DatabaseHelper.getChapterContent`；`ReadBook.loadChapterContent` 的顺序固定为内存缓存、文件缓存、数据库正文、网络请求。有效数据库正文命中后恢复文件缓存；数据库未初始化/读取异常按缓存未命中处理；空正文和占位正文不进入内存或文件缓存并继续网络重取。
- 新增测试：`test/integration/read_book_db_fallback_test.dart` 2/2，覆盖数据库正文命中不请求网络并恢复文件、数据库占位正文跳过后重新请求网络。
- 断行约束：本子步骤只改变缓存来源选择和回写，不改变正文原文、净化顺序、中文禁则、断行或分页逻辑，未改变《重写行为约束规范》第 3 条。
- 验收结果：数据库回落定向测试 2/2；本次代码变更后的 Flutter 全量测试 293/293；Rust 全量库测试 109/109，全部非 ignored 集成/文档测试通过；release DLL 与 FRB 绑定重建成功；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，未新增；代码生成器首次运行因 PATH 未包含 `rustfmt` 产生尾随空格，已使用绝对路径格式化生成的 Rust 绑定并重新通过 `git diff --check`。
- 当前边界：数据库回落已完成，章节缓存生命周期清理、阅读记录、书签和 WebDAV 进度冲突留待后续独立子步骤，模块 4 不能标记完成。

#### 模块 4D：章节缓存生命周期清理

- 原版对照依据：`BookHelp.clearInvalidCache()` 根据数据库现有书籍生成有效缓存目录集合，删除 `book_cache` 下已不存在书籍对应的目录；原版在应用启动及主界面刷新维护时调用。
- 本地修改：新增 `BookHelp.clearInvalidCache(validBookIds)`，仅删除孤立书籍目录并保留有效书籍目录及章节文件；`BookProvider.loadBooks()` 加载书架后异步触发清理，避免递归文件删除阻塞首屏初始化。
- 新增测试：`test/services/book_cache_lifecycle_test.dart` 2/2，覆盖删除孤立目录、保留有效目录，以及空书架删除全部书籍目录。
- 断行约束：本子步骤只处理缓存目录生命周期和启动调用时机，不修改正文内容、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：缓存生命周期定向测试 2/2；缓存服务回归 5/5；书籍 Provider 回归 2/2；主框架回归 2/2；Flutter 全量测试 295/295；Rust 全量库测试 109/109，全部非 ignored 集成/文档测试通过；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，未新增；Rust 仅有既有编译警告。首次并行回归曾因清理任务阻塞主框架初始化导致 2 个底栏断言失败，改为异步维护后串行复测全部通过，未修改测试。
- 当前边界：章节缓存生命周期清理已完成，阅读记录、书签和 WebDAV 进度冲突留待后续独立子步骤，模块 4 不能标记完成。

#### 模块 4E：阅读会话增量落盘

- 原版对照依据：`ReadBook.upReadTime()` 在阅读页当前页变化时累加自上次记录以来的阅读时长并写入 `ReadRecord`，而不是只在阅读页面销毁时保存。
- 本地修改：新增可注入时钟的 `ReadingSessionTracker`，按已提交字符和时间生成增量；`ReaderPage` 在翻页、换章和销毁时提交未落盘增量。`ReadingRecordService.recordReading` 允许新增字符为 0 但时长为正，避免同章后续翻页丢失时长；数据库不可用或写入异常时不提交 tracker 状态，保留后续重试机会。
- 新增测试：`test/services/reading_session_tracker_test.dart` 2/2，覆盖增量字符、增量时长、幂等启动和非正字符；阅读记录集成测试 3/3，覆盖聚合导出及 0 字符时长落库；阅读器相关回归 4/4。
- 断行约束：本子步骤只改变阅读记录的计时与写入时机，不改变正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 全量测试 297/297；Rust 全量库测试 109/109，全部非 ignored 集成/文档测试通过；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，未新增；Rust 仅有既有编译警告。
- 当前边界：基础阅读记录增量落盘已完成；详细阅读会话导出、书签和 WebDAV 进度冲突留待后续独立子步骤，模块 4 不能标记完成。

#### 模块 4F：详细阅读会话记录

- 原版对照依据：`DetailedReadRecordHelper.insertSession()` 对阅读会话执行书名非空校验、时长 `<=120000ms` 过滤；同书相邻会话间隔在 `0..180000ms` 时合并；导出按书名分组、按开始时间排序，并保留 `readIteration`。
- 本地修改：Rust schema v14 新增 `detailed_read_records` 表及索引，实现会话过滤、同书 3 分钟合并、JSON 分组导出；详细会话纳入备份导出与恢复。FRB 新增同步写入/导出绑定；Dart `DetailedReadingSessionTracker` 在阅读页退出时写入符合门槛的会话。
- 新增测试：Rust 详细会话过滤/合并 1/1、备份往返覆盖 1/1；Dart tracker 1 项、阅读记录真实 Rust 集成导出 1 项；Flutter 全量测试 298/298。
- 断行约束：本子步骤只新增阅读会话元数据和导出/恢复，不改变正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 全量测试 298/298；Rust 全量库测试 110/110，全部非 ignored 集成/文档测试通过；release DLL 与 FRB 绑定重建成功；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，未新增；Rust 仅有既有编译警告。生成器未找到 PATH 中的 `rustfmt`，已使用绝对路径格式化生成绑定。
- 当前边界：基础及详细阅读记录已完成，书签和 WebDAV 进度冲突留待后续独立子步骤，模块 4 不能标记完成。

#### 模块 4G：书签滚动位置与列表排序

- 原版对照依据：`Bookmark` 保存 `chapterIndex` 与 `chapterPos`，`BookmarkDao` 按书名、作者、章节索引和章内位置排序；书签打开阅读器时使用章内位置恢复阅读位置。
- 本地修改：新增 `chapterPosForScrollOffset`，滚动模式书签按当前滚动比例保存章内字符偏移，不再写入 `-1`；书签页面按书籍、章节索引、章内字符位置排序，分页模式继续使用页面切片起点。
- 新增测试：`test/help/bookmark_hint_test.dart` 5/5，覆盖滚动位置比例、边界裁剪和既有分页定位；书签页面回归 1/1。
- 断行约束：本子步骤只改变书签位置元数据和列表排序，不改变正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 全量测试 299/299；Rust 全量库测试 110/110，全部非 ignored 集成/文档测试通过；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，未新增；本步未修改 Rust 数据层。
- 当前边界：书签的独立实体/作者字段及其完整导入导出仍待后续子步骤，WebDAV 进度冲突也未开始，模块 4 不能标记完成。

#### 模块 4H：独立书签实体与数据库备份基础

- 原版对照依据：`data/entities/Bookmark.kt` 的时间戳主键及 `bookName`、`bookAuthor`、`chapterIndex`、`chapterPos`、`chapterName`、`bookText`、`content` 字段；`BookmarkDao` 按书名、作者、章节索引和章内位置排序。原版书签与想法笔记是两张独立表。
- 本地修改：数据库 schema 升至 v15，新增 `bookmarks` 表和索引；新增 Rust `BookmarkDto`、增删改查 API，字段 JSON 名称与原版备份字段一致，并保留本地 `bookId` 扩展用于书架关联。旧 `notes` 表和 `noteContent` 前缀兼容逻辑暂不删除。
- 备份恢复：数据库备份新增 `bookmarks` 数组；恢复支持新 `bookmarks` 及原版单数 `bookmark` 键，`time` 缺失时拒绝该条记录，不用默认时间覆盖坏数据；替换恢复会同时清空独立书签。
- 新增测试：Rust 书签字段/主键更新/排序/删除 2 项，书签备份恢复 1 项；本步共新增 Rust 定向测试 2/2。
- 断行约束：本子步骤只新增书签存储和序列化，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Rust 定向测试 2/2；Rust 全量库测试 112/112，全部非 ignored 集成测试和文档测试通过；Flutter 全量测试 299/299；release DLL 重建成功；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，本步未新增诊断；Rust 仅有既有 `frb_expand`、未使用字段等警告。FRB 首次生成因 Windows 路径前缀和 PATH 未含 `rustfmt` 出现工具警告，已改用 `\\?\\` 绝对路径生成并使用绝对路径 `rustfmt` 完成格式化。
- 当前边界：Dart `BookmarkService`、阅读页写入独立表、书签页从独立表读取，以及旧 `notes` 书签数据迁移和原版文件级书签导入导出留待下一独立子步骤；WebDAV 进度冲突也未开始，模块 4 不能标记完成。

#### 模块 4I：Dart 书签服务与阅读/书签页接入

- 原版对照依据：`BookmarkAdapter` 展示章节名、正文片段和备注内容；点击条目按 `chapterIndex/chapterPos` 恢复阅读，删除操作针对独立 `Bookmark` 实体。书签不应继续依赖想法笔记的文案前缀。
- 本地修改：新增 `BookmarkService`，阅读页书签入口改写独立表并保存书名、作者、章节索引、章内位置、章节名、正文片段和备注内容；书签页读取独立书签，同时显示旧 `notes` 表中的历史书签，想法仍由 `NoteService` 管理；删除时按独立书签或旧笔记来源调用对应删除 API。
- 兼容行为：旧笔记书签仍可打开并使用已有页提示 fallback；新书签使用 `chapterPos` 定位，保持滚动和分页位置语义，不再生成 UUID 笔记记录。
- 新增测试：`test/integration/bookmark_service_test.dart` 覆盖 Dart 服务保存、读取字段和删除 1/1；书签页回归、书签位置辅助测试通过。
- 断行约束：本子步骤只改变书签数据来源和元数据写入，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 定向测试通过；Flutter 全量测试 300/300；Rust 全量库测试 112/112，全部非 ignored 集成/文档测试通过；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，本步未新增；本步未修改 Rust 数据层和 FRB 绑定。
- 当前边界：旧 `notes` 书签尚未一次性迁移到 `bookmarks`，原版文件级 `bookmark.json` 导入导出尚未提供去重、时间戳和作者字段映射；WebDAV 进度冲突也未开始，模块 4 不能标记完成。

#### 模块 4J：旧书签迁移与 bookmark.json 文件交换

- 原版对照依据：`Backup.kt` 使用 `bookmark.json` 保存 `Bookmark` 数组；`TocViewModel.saveBookmark` 导出实体 JSON，导入按时间主键写入；Markdown 导出按书名/作者、章节名、原文和摘要组织。
- 本地修改：`BookmarkMigrationService` 将旧 `notes` 中的「书签」记录映射为独立书签，使用书架书名/作者、章节索引、章节位置、正文片段和空备注；旧记录保留不删除。已迁移记录按字段签名复用时间主键，重复打开书签页不会生成重复数据。
- 文件交换：`BookmarkService` 新增原版数组格式 JSON 编解码、缺失/非法 `time` 校验、同文件重复主键取最后一项；导入按时间主键幂等 upsert，不清空现有书签。书签页新增 JSON 导入/导出入口。
- 新增测试：迁移字段映射和坏 JSON 2/2；真实数据库旧 notes 迁移并重复执行回归 1/1；书签服务和书签页回归继续通过。
- 断行约束：本子步骤只改变书签迁移、文件序列化和入口，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 定向测试 4/4；Flutter 全量测试 302/302；Rust 全量库测试 112/112，全部非 ignored 集成/文档测试通过；`git diff --check` 通过。
- 静态检查：`flutter analyze` 仍为仓库既有 47 条诊断，本步未新增；本步未修改 Rust 数据层、FRB 绑定或 release DLL。
- 当前边界：书签本地数据和原版 JSON 文件交换已完成；WebDAV 进度冲突、跨设备书签冲突和远端合并策略仍未开始，模块 4 不能标记完成。

#### 模块 4K-1：WebDAV 远程修改时间元数据

- 原版对照依据：`WebDavFile.lastModify` 保存 WebDAV `getlastmodified` 的毫秒时间戳；`AppWebDav.downloadAllBookProgress()` 先用该时间与本地 `Book.syncTime` 比较，再决定是否读取远端进度。
- 本地修改：`legado-webdav` 的 PROPFIND 请求新增 `getlastmodified`；`WebDavItem`、Rust `WebDavEntry` 和 FRB/Dart 绑定新增 `lastModified`，Rust 使用 RFC 7231 日期解析为 Unix 毫秒，缺失或非法日期兼容为 `0`。
- 新增测试：固定 WebDAV XML fixture 覆盖文件大小、标准日期到毫秒的解析，以及非法日期回落为 `0`，WebDAV crate 定向测试 3/3。
- 断行约束：本子步骤只扩展 WebDAV 元数据传输和时间解析，不触及正文、正文净化、分页、滚动或章节断行，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 全量测试 302/302；Rust workspace 测试全部通过；Rust 文档测试通过；release DLL 重建成功；`git diff --check` 通过。
- 静态检查：本步未改变阅读正文和断行链路；Rust 仍仅有仓库既有 FRB 配置、未使用字段等警告。全量 `cargo fmt --all -- --check` 仍会被仓库其他既有未格式化文件阻断，本步涉及 Rust 文件已使用绝对路径 `rustfmt` 格式化。
- 当前边界：本地 `syncTime` 存储、完整 `downloadAllBookProgress`、远端领先/本地领先决策和上传成功后的同步时间更新仍待下一独立子步骤，模块 4K 尚未完成。

#### 模块 4K-2：本地同步时间与远端进度决策核心

- 原版对照依据：`AppWebDav.uploadBookProgress()` 上传成功后写入 `Book.syncTime = System.currentTimeMillis()`；批量下载先跳过 `lastModify <= syncTime` 的远程文件，再仅在远端章节索引更大或同章位置更大时覆盖本地。
- 本地修改：`BookProgressSync` 使用按书名/作者对应进度文件名隔离的 `SharedPreferences` 键保存本地同步时间；上传成功后记录当前毫秒时间；新增纯决策函数，严格按远程文件修改时间优先、章节索引和章内位置其次的顺序返回跳过、保留本地或应用远端结果。
- 新增测试：`test/services/book_progress_sync_test.dart` 3/3，覆盖同步时间按书隔离持久化、远程文件未变化时优先跳过，以及远端新文件下的进度领先/不领先分支。
- 断行约束：本子步骤只处理同步时间元数据和进度比较，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 全量测试 305/305；Rust workspace 测试全部通过；Rust 文档测试通过；`git diff --check` 通过。
- 静态检查：本步未新增 Rust/FRB 诊断；Flutter analyze 仍保持仓库既有 47 条诊断，未修改无关诊断或测试。
- 当前边界：批量列出 `bookProgress/`、读取每本远程进度并覆盖本地书籍、下载后写回同步时间，以及真实 WebDAV 网络集成测试仍待下一独立子步骤，模块 4K 尚未完成。

#### 模块 4K-3：批量 WebDAV 进度下载与本地书籍覆盖

- 原版对照依据：`AppWebDav.downloadAllBookProgress()` 列出 `bookProgress/` 后按 `${name}_${author}.json` 匹配书籍；先比较远程 `lastModify` 与本地 `syncTime`，再读取远程进度，只覆盖章节索引或章内位置领先的书籍。
- 本地修改：`BookProgressSync.downloadAllBookProgress()` 接入 WebDAV 列表和下载 API，按文件名过滤目录条目、按上一小步决策核心处理时间和位置，并在本地覆盖回调成功后保存同步时间；`BookProvider.downloadAllBookProgress()` 将远端章索引、章内位置、章节标题和全书进度映射回现有书籍字段。列表/下载函数可注入，便于离线验证。
- 新增测试：批量固定 JSON/条目测试 1 项，连同同步决策定向测试共 4/4；覆盖远程文件匹配、路径、远端领先覆盖和下载后同步时间落盘。
- 断行约束：本子步骤只处理 WebDAV 进度元数据和书籍进度字段回写，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Rust workspace 与文档测试通过；Flutter 定向测试 4/4 通过；全量 Flutter 测试 306/306 通过；本次全量测试中 `phase3_alignment_test.dart` 与 `src_7497_smoke_test.dart` 的 7497 在线请求均通过；未修改测试。
- 静态检查：`git diff --check` 通过；本子步骤未修改正文原文、净化顺序、中文禁则、断行或分页逻辑。
- 当前边界：批量 WebDAV 进度下载和本地书籍覆盖已完成；WebDAV 上传前的配置就绪判定、上传调用可测试性和跨设备冲突收尾仍待下一独立子步骤。

#### 模块 4K-4：WebDAV 进度上传配置门禁与成功落盘

- 原版对照依据：`AppWebDav.upConfig()` 只有账号和密码均存在时才建立授权；`uploadBookProgress()` 在授权、同步开关和网络均可用后上传，上传成功才更新本地同步时间。
- 本地修改：`BookProgressSync` 的单本读取、批量下载和上传统一要求 `WebDavConfig.isReady`（URL、账号、密码齐全）；上传 API 支持注入调用函数和当前时间，便于离线验证远程路径、JSON 载荷及成功后的同步时间持久化。
- 新增测试：`test/services/book_progress_sync_test.dart` 6/6，覆盖不完整配置不触发 WebDAV、上传路径与认证参数、固定 JSON 载荷和成功后同步时间落盘。
- 断行约束：本子步骤只处理 WebDAV 配置、上传载荷和同步时间元数据，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 定向测试 6/6；Flutter 全量测试 308/308；Rust workspace 测试与文档测试通过；`git diff --check` 通过；Flutter analyze 仍为仓库既有 47 条诊断，未新增本步文件诊断。
- 当前边界：WebDAV 进度读写链路已完成本地离线验收；真实 WebDAV 服务器认证、网络异常和跨设备书签冲突仍待后续独立子步骤，模块 4K 尚未整体完成。

#### 模块 4K-5：阅读进度同步开关与上传门禁

- 原版对照依据：`AppConfig.syncBookProgress` 默认值为 `true`；`AppWebDav.uploadBookProgress()` 在授权后先检查该开关，关闭时直接跳过上传。
- 本地修改：`AppConfig` 新增持久化的 `syncBookProgress` 配置及读写方法，默认保持开启；`BookProgressSync.uploadBookProgress()` 加载该配置，关闭时不调用 WebDAV、不更新同步时间，开启时保持 4K-4 的认证和上传行为。
- 新增测试：AppConfig 定向测试 2/2；WebDAV 进度同步定向测试 7/7，覆盖默认值、跨实例持久化，以及关闭开关时不上传不落盘。
- 断行约束：本子步骤只处理阅读进度同步配置和 WebDAV 上传门禁，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 全量测试首次因 `novel.cooks.tw` 校验请求瞬时 `502 Bad Gateway` 出现 2 个在线失败；未修改测试，单独重试后通过，最终全量 Flutter 测试 309/309；Rust workspace 测试与文档测试通过；`flutter analyze` 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 当前边界：阅读进度同步开关和本地上传门禁已完成；真实 WebDAV 服务器认证/网络异常以及跨设备书签冲突和远端合并策略仍待后续独立子步骤，模块 4K 尚未整体完成。

#### 模块 4K-6：WebDAV HTTP 状态错误保留

- 原版对照依据：WebDAV 操作失败由 `AppWebDav` 捕获并记录具体异常；本地 Rust WebDAV 层需要把列目录、上传、下载和删除的 HTTP 状态传回 Dart，供上层显示或记录。
- 本地修改：`legado-webdav` 新增带操作名和 HTTP 状态码的 `HttpStatus` 错误变体；PROPFIND、上传、下载和删除不再把非 2xx 响应压成无结构普通消息，401/403/404/5xx 的状态码保留在错误文本中。
- 新增测试：`legado-webdav` crate 定向测试 4/4，覆盖既有路径/XML 日期解析和 401、403、502 的操作与状态码映射。
- 断行约束：本子步骤只处理 WebDAV HTTP 错误元数据传递，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Rust engine 测试与文档测试通过；`legado-webdav` 定向测试 4/4；Flutter analyze 保持仓库既有 47 条诊断；7497 对齐测试 9/9；Flutter 全量 309/309；`git diff --check` 通过。此前在线 502 已恢复，未修改测试。
- 当前边界：WebDAV HTTP 状态错误传递已完成；跨设备书签冲突和远端合并策略仍待后续独立子步骤，模块 4K 尚未整体完成。

#### 模块 4K-7：WebDAV 备份凭证门禁

- 原版对照依据：`AppWebDav.upConfig()` 只有账号和密码都存在且授权成功时才建立可用 WebDAV；备份上传、备份列表和恢复都依赖该授权状态。
- 本地修改：`BackupService` 的 WebDAV 上传、列表和恢复统一要求 `WebDavConfig.isReady`；备份页的状态显示和恢复入口同步使用完整凭证状态，URL 单独存在时不再继续调用远端。
- 新增测试：备份服务定向测试 2/2，覆盖完整备份 JSON 回归和缺少账号/密码时的本地拒绝；备份页回归测试 1/1。
- 断行约束：本子步骤只处理 WebDAV 备份配置门禁，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Rust workspace 测试与文档测试通过；Flutter 定向测试通过；Flutter 全量测试 310/310；Flutter analyze 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 当前边界：WebDAV 进度和备份的本地凭证门禁已完成；真实服务器认证交互、跨设备书签冲突和远端合并策略仍待后续独立子步骤，模块 4K 尚未整体完成。

#### 模块 4K-8：书签 JSON 跨设备冲突合并核心

- 原版对照依据：原版 `bookmark.json` 以 `time` 作为书签主键，导入按主键 upsert；同一主键再次写入时覆盖原记录。
- 本地修改：`BookmarkService.mergeRemote()` 合并本地与远端书签并集，保留双方独有时间主键；同一 `time` 冲突时远端记录覆盖本地。`mergeRemoteJson()` 提供原版 JSON 输入输出，复用既有严格 `time` 校验。
- 新增测试：`test/services/bookmark_migration_test.dart` 书签 JSON 定向测试 3/3；真实独立书签数据库集成测试 1/1，覆盖并集、远端冲突覆盖和既有存取删除行为。
- 断行约束：本子步骤只处理书签元数据 JSON 合并，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Flutter 全量测试 311/311；Rust workspace 测试与文档测试通过；Flutter analyze 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 当前边界：书签冲突决策核心已完成，但尚未接入 WebDAV 远端书签文件的读取、上传和同步时间管理，模块 4K 尚未整体完成。

#### 模块 4K-9：WebDAV bookmark.json 读写与合并接入

- 原版对照依据：沿用 4K-8 的 `bookmark.json` 时间主键 upsert 语义；远端书签文件缺失时首次上传本地内容，存在时先合并再写回，下载时合并后交给本地导入。
- 本地修改：新增 `BookmarkSyncService`，使用 `/legado/bookmark.json` 路径；上传前读取远端并合并，HTTP 404 时按首次上传处理；下载后将合并 JSON 交给应用层导入；所有 WebDAV 调用和本地应用回调均可注入测试。7497 全量对齐改用固定 JSON 响应 fixture，仍保留原始 7497 书源规则和 `jsLib` 语义；真实 7497 测试改为 `RUN_ONLINE_SMOKE=1` 显式运行。
- 新增测试：`test/services/bookmark_sync_service_test.dart` 4/4，覆盖远端合并上传、远端缺失首次创建、下载合并和不完整凭证拒绝。
- 断行约束：本子步骤只处理书签 JSON 的 WebDAV 读写与元数据合并，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Rust workspace 测试与文档测试通过；新增文件 `flutter analyze` 0 条诊断；Flutter phase3 离线对齐 9/9；Flutter 全量实际运行 312/312 通过，3 项 7497 在线 smoke 默认跳过；`git diff --check` 通过。在线 smoke 可单独运行：`$env:RUN_ONLINE_SMOKE='1'; flutter test test/integration/src_7497_smoke_test.dart`。
- 当前边界：4K-9 的 WebDAV 书签读写和稳定离线验收已完成；跨设备同步入口的 UI 触发、真实 WebDAV 服务器回归仍待后续独立子步骤，模块 4K 尚未整体完成。

#### 模块 4K-10：书签页 WebDAV 同步入口

- 原版对照依据：书签文件交换应由用户操作触发，上传前合并远端内容，下载后合并并刷新本地书签列表；同步失败需要保留本地数据并反馈错误。
- 本地修改：书签页 AppBar 新增“上传书签到 WebDAV”和“从 WebDAV 合并书签”入口，复用 `BookmarkSyncService`；同步期间禁用重复操作，成功后刷新列表并显示合并数量，失败显示错误提示。
- 新增测试：书签页入口回归测试 1/1，确认两个同步操作控件存在；4K-9 同步服务测试 4/4 继续通过。
- 断行约束：本子步骤只增加书签 WebDAV 操作入口、忙状态和提示，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Rust workspace 测试与文档测试通过；Flutter 全量实际运行 312/312；3 个 7497 在线 smoke 默认跳过；Flutter analyze 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 当前边界：书签合并、WebDAV 读写和书签页入口已完成；真实 WebDAV 服务器回归及模块 4K 总体收尾仍待后续独立子步骤，模块 4K 尚未整体完成。

#### 模块 4K-11：本地 TCP mock WebDAV 协议回归

- 原版对照依据：WebDAV 书签交换要求使用目录枚举 `PROPFIND`、文件上传 `PUT` 和文件下载 `GET`；请求必须携带 Basic Auth，HTTP 非成功状态应保留操作类型和状态码。
- 本地修改：`rust/legado-webdav` 增加基于本地 TCP listener 的协议回归测试，验证 `/remote/legado` 目录路径、`/remote/legado/bookmark.json` 文件路径、PROPFIND XML 解析、PUT/GET 往返和 Basic Auth 凭据；开发测试依赖补充 Tokio `net` 与 `io-util` 特性。认证头字段名按 HTTP 规范大小写不敏感匹配，认证方案和值仍精确校验。
- 新增测试：`rust/legado-webdav` 测试 5/5，通过真实客户端与本地 mock 完成 PROPFIND、PUT、GET 协议请求；既有 HTTP 状态错误测试继续通过。
- 断行约束：本子步骤只验证 WebDAV 传输协议，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：`cargo test --manifest-path rust/legado_engine/Cargo.toml` 通过（112 个库测试及全部非 ignored 集成/文档测试）；`cargo test --manifest-path rust/legado-webdav/Cargo.toml` 通过（5/5）；Flutter 全量实际运行 312/312，通过 3 个 7497 在线 smoke 默认跳过；`flutter analyze` 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 已知边界：本地 TCP mock 已覆盖协议层回归，但尚未替代真实 WebDAV 服务器的跨设备、TLS、代理和权限环境验证；7497 在线 smoke 仍需显式运行。Rust workspace manifest 位于 `rust/Cargo.toml`。

#### 模块 4K-12：WebDAV 云端备份列表管理

- 原版对照依据：`AppWebDav.getBackupFileList` 列出并按备份名排序，`deleteBackup` 使用 DELETE，`renameBackup` 使用 MOVE 并设置目标地址和 `Overwrite: F`；原版云端备份页支持恢复、删除和重命名，服务器不支持 MOVE 时提示用户。
- 本地修改：`WebDavClient` 增加 `MOVE` 请求；FRB 增加 `webdavMove` 绑定；`BackupService` 增加云端备份删除和重命名，并拒绝空名称及路径分隔符；备份页增加云端列表刷新、点击恢复、重命名菜单和删除菜单，列表操作期间显示忙状态并刷新结果；原有 WebDAV 恢复入口复用同一列表数据。
- 新增测试：WebDAV TCP mock 回归 5/5，覆盖 PROPFIND/PUT/MOVE/GET 和 `Destination`/`Overwrite`；备份服务与页面定向测试 4/4，覆盖完整引擎备份、凭证门禁、危险名称拒绝和管理入口。
- 断行约束：本子步骤只处理云端备份文件的列出、恢复、删除和重命名，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：`cargo test --manifest-path rust/Cargo.toml` 通过（Rust engine 112 个库测试、全部非 ignored 集成/文档测试及 WebDAV 5/5）；release DLL 与 FRB 绑定重建成功；Flutter 定向测试 4/4；Flutter 全量实际运行 313/313 通过，3 个 7497 在线 smoke 默认跳过；Dart/Rust 格式检查通过；`flutter analyze` 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 已知边界：本地 mock 已验证 MOVE 协议和路径安全，但真实服务器的 MOVE 权限、405/501 兼容提示、TLS、代理和跨设备云端恢复仍需在线环境验证；7497 在线 smoke 仍需显式运行。

#### 模块 4K-13：WebDAV 凭证检查与目录初始化

- 原版对照依据：`AppWebDav.upConfig` 在有效账号密码存在时先对根目录执行凭证检查，再确保根目录、`bookProgress`、`books` 和 `background` 目录存在；缺少凭证时不建立远端会话。
- 本地修改：`WebDavClient` 增加 `PROPFIND` 权限检查和 404 后 `MKCOL` 的目录确保逻辑；FRB 增加 `webdavCheck`、`webdavEnsureDir`；新增 `WebDavSetupService`，按原版顺序检查根目录并初始化四个目录；WebDAV 配置保存时，对完整凭证执行初始化，失败保留配置并在界面提示，凭证不完整时不发起网络请求。
- 新增测试：WebDAV 本地 TCP mock 6/6，覆盖根目录检查、缺失目录的 PROPFIND→MKCOL 顺序和 Basic Auth；Dart 初始化服务 2/2，覆盖调用顺序、路径和凭证门禁；备份配置页面回归 1/1。
- 断行约束：本子步骤只处理 WebDAV 配置验证和远端目录初始化，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：`cargo test --manifest-path rust/Cargo.toml` 通过（Rust engine 112 个库测试、全部非 ignored 集成/文档测试及 WebDAV 6/6）；release DLL 与 FRB 绑定重建成功；Flutter 定向测试 3/3；Flutter 全量实际运行 315/315 通过，3 个 7497 在线 smoke 默认跳过；Dart/Rust 格式检查通过；`flutter analyze` 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 已知边界：目录初始化已通过本地协议 mock 验证，但真实 WebDAV 服务的凭证权限、已有目录响应差异、TLS 和代理环境仍需在线验证；7497 在线 smoke 仍需显式运行。

#### 模块 4K-14：WebDAV 缺失根目录初始化

- 原版对照依据：原版先检查 WebDAV 授权，再由 `makeAsDir()` 对不存在的根目录执行创建；根目录不存在不应阻止后续 `MKCOL`。
- 本地修改：将 WebDAV `PROPFIND 404` 解释为“服务可达但目录不存在”；`check` 保留该可达语义，`ensure_dir` 独立读取状态并在 404 时执行 `MKCOL`，避免检查阶段提前终止首次初始化。
- 新增测试：`legado-webdav` 新增根目录缺失回归，严格验证 `PROPFIND 404 → PROPFIND 404 → MKCOL 201` 请求顺序和路径；WebDAV crate 测试共 7/7。
- 断行约束：本子步骤只修复 WebDAV 根目录初始化状态处理，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：`cargo test --manifest-path rust/Cargo.toml` 通过（Rust engine 112 个库测试、全部非 ignored 集成/文档测试及 WebDAV 7/7）；release DLL 重建成功；Flutter 全量实际运行 315/315 通过，3 个 7497 在线 smoke 默认跳过；`flutter analyze` 保持仓库既有 47 条诊断；`git diff --check` 通过。
- 已知边界：本步只处理根目录缺失，云端备份格式/路径、PROPFIND 命名空间和完整 URL 解码、代理注入、真实服务器权限与跨设备并发冲突仍待后续独立子步骤。

#### 模块 4K-15：WebDAV 云端备份格式与根目录路径兼容

- 原版对照依据：`reference/Jingshiro-legado/app/src/main/java/io/legado/app/help/storage/Backup.kt` 的 `getNowZipFileName`、备份 ZIP 构造和 `AppWebDav` 根目录上传/列表行为。原版文件名为 `backupYYYY-MM-DD[-设备名].zip`，备份文件直接位于 WebDAV 根目录。
- 本地修改：`BackupService` 的新备份统一生成原版日期 ZIP 文件名；设备名只作为文件名后缀并净化非法文件名字符；本地备份写入 ZIP，WebDAV 上传改为根目录 ZIP；云端列表按根目录筛选 `backup*.zip`，同时保留旧 `.json` 条目；恢复入口同时支持 ZIP 内 `legado_backup.json` 载荷和历史 JSON 文件。
- 兼容边界：ZIP 内暂存当前 Rust 数据库导出和 Flutter 设置的完整 JSON wrapper，能够保证重写版跨设备往返；尚未将数据库字段拆分为原版 `bookshelf.json`、`bookmark.json`、`bookSource.json` 等逐文件布局，因此原版生成的 ZIP 仍不能直接恢复到重写版。
- 新增测试：备份服务定向测试 7/7，覆盖文件名、设备名净化、ZIP 创建/读取、WebDAV 根目录路径和旧 JSON 载荷兼容；与书签同步、WebDAV 初始化及备份页回归合计 15/15 通过。
- 断行约束：本子步骤只修改备份容器、文件名、WebDAV 路径和恢复载荷识别，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 验收结果：Rust workspace `112` 个引擎库测试及 WebDAV `7/7` 通过；Flutter 全量 `319/319` 通过，3 个在线 smoke 按既有配置跳过；`flutter analyze` 保持仓库基线 `47` 条诊断；`git diff --check` 通过。
- 已知边界：真实 WebDAV 服务器的 ZIP 上传/下载、TLS、代理、权限和跨设备并发写入尚未验证；原版 ZIP 的逐文件数据映射留待后续独立子步骤，不以修改测试断言替代。

#### 模块 4K-16：WebDAV XML 解析与代理配置接入

- 原版对照依据：`AppWebDav` 通过 WebDAV 目录响应获得远端条目；重写版网络配置由 `NetworkConfig` 统一保存代理类型、地址和认证信息。
- 本地修改：WebDAV `PROPFIND` 改为命名空间前缀无关的 XML 解析，支持完整/相对 `href`、XML 实体、百分号编码、目录尾斜杠和 `displayname`；请求路径保留 `%2F` 等编码语义，展示名称单独解码。WebDAV client 接入全局 HTTP/SOCKS5 代理及代理认证，七个操作统一使用该配置，未配置代理时保持无代理。
- 新增测试：WebDAV crate 测试 `10/10`，覆盖命名空间、完整 URL、相对 URL、实体、`%2F` 路径和代理 client 构造；engine WebDAV 代理映射测试 `2/2`。
- 断行约束：本子步骤只处理 WebDAV XML、远端路径解析和传输代理，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 已知边界：尚未通过真实代理服务器验证转发效果；DNS 偏好仍未接入 WebDAV；损坏 XML 当前按空列表处理，不返回结构化解析错误。

#### 模块 4K-17：原版 ZIP 逐文件备份兼容

- 原版对照依据：`Backup.kt` 在 ZIP 内写入 `bookshelf.json`、`bookmark.json`、`bookSource.json`、`replaceRule.json` 和 `readRecord_detail.json` 等独立文件。
- 本地修改：新 ZIP 继续保留无损的 `legado_backup.json` wrapper，同时补充可从当前数据库映射出的原版文件子集；恢复时优先读取 wrapper，没有 wrapper 时读取原版逐文件 ZIP 并转换为 Rust wrapper，保留书架、书签、书源、替换规则和详细阅读记录。
- 新增测试：备份服务测试 `9/9`，覆盖原版文件名集合、字段映射和原版逐文件 ZIP 恢复。
- 断行约束：本子步骤只处理备份容器和数据库字段映射，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 已知边界：原版字体、主题背景、视频配置、阅读配置及所有补充 JSON 文件尚未逐项映射；无 wrapper 的原版 ZIP 不能完整恢复这些附加数据。

#### 模块 4K-18：书签同步并发门禁与云端错误提示

- 原版对照依据：书签同步由用户操作触发，失败时不应删除或覆盖已有本地/远端数据；同一进程内的同步操作应保持顺序。
- 本地修改：`BookmarkSyncService` 对上传和下载合并共用 FIFO 异步门禁，异常通过 `finally` 释放；备份页对 HTTP 405/501、401/403 和权限错误提供操作级提示，并明确说明原备份或当前数据未被修改；本地 ZIP 列表恢复改用字节读取，历史 JSON 仍自动兼容。
- 新增测试：书签同步定向测试 `6/6`，备份页定向测试 `3/3`，覆盖并发串行化、异常释放和 WebDAV 权限错误提示。
- 断行约束：本子步骤只处理同步互斥、错误反馈和备份恢复入口，不修改正文原文、净化顺序、中文禁则、断行或分页逻辑，严格保持《重写行为约束规范》第 3 条。
- 已知边界：该门禁只解决同一应用进程内并发，尚未实现跨设备 ETag/条件写入或服务端锁；真实服务器的 405/501、权限和 TLS 行为仍需在线验证。

## 4. 每个模块的固定工作流

1. 运行上一步全量测试，记录基线。
2. 建立原版行为表：输入、执行顺序、副作用、输出、错误和空值语义。
3. 映射本地实现文件和调用链，标出有证据的差异。
4. 添加不依赖真实网络的固定 fixture 或对比测试，先确认差异可复现。
5. 只修改当前模块所需代码。
6. 运行格式化、静态分析、模块测试、Rust 全量测试和 Flutter 全量测试。
7. 更新本文档中的模块状态与测试记录。
8. 汇报修改、原版对照依据、测试结果、已知偏差；停止并等待下一步确认。

## 5. 测试门禁

每个模块至少执行：

```powershell
cargo test --manifest-path rust/Cargo.toml
flutter test
flutter analyze
git diff --check
```

7497 在线 smoke 默认跳过；需要显式验证时运行：

```powershell
$env:RUN_ONLINE_SMOKE='1'; flutter test test/integration/src_7497_smoke_test.dart
```

涉及特定平台插件而无法在当前 Windows 环境执行的集成测试，应单独列出命令、失败阶段、平台依赖和建议运行环境；不得用修改测试的方式掩盖环境限制。

## 6. 测试记录

### 模块 1

- 开始时间：2026-07-22
- 修改前全量基线：
  - Rust 库测试默认并行：90/92，通过单例重跑确认 2 个失败均为共享 `CacheManager` 被并行 `reset_cache` 清空；单线程全量通过。
  - Flutter 首轮：release DLL 绑定哈希过期导致 4 个加载失败；重建 DLL 后，纯 Dart 测试环境缺少 SharedPreferences 插件导致 11 个请求前失败。
  - `flutter analyze`：47 条既有诊断（4 warning、43 info）。
- 1A 原版依据：
  - `CacheManager.kt` 为应用级共享内存 + 数据库缓存；普通搜索、详情、发现和调试入口不清空缓存。
  - `AppPattern.JS_PATTERN` 使用 `CASE_INSENSITIVE`，`<js>` 和 `@js:` 标记不区分大小写。
- 1A 修改：
  - 移除搜索、详情、发现和调试入口的错误 `reset_cache`；仅显式“清空引擎缓存”保留清除行为。
  - 缓存相关并行单测使用同名串行门禁，保留全部业务断言。
  - `<js>...</js>` 与 `@js:` 标记改为 ASCII 大小写不敏感，并保证结束标记在对应开始标记之后匹配。
  - SharedPreferences 插件未注册时按“无本地登录信息”处理，避免纯 Dart/FFI 测试在进入 Rust 前失败。
- 模块定向测试：
  - Rust 库测试：94/94 通过。
  - Rust `js_compatibility`：18/18 通过。
  - Flutter `source_login_prefs` + `rust_engine_gate`：7/7 通过。
- Rust 全量测试：通过；94 个库测试及所有非 ignored 集成/文档测试 0 失败。
- Flutter 全量测试：252/252 通过；外部 smoke 中失效站点仍记录 HTTP 403/空结果，但测试按既有降级策略通过。
- 静态分析：修改文件 0 诊断；全仓仍为基线 47 条，未新增。
- 已知偏差：1D 尚未执行；1A/1B/1C 未涉及正文清洗、断行或分页，行为约束 `§5.1`–`§5.3` 不受影响。

### 模块 1B：SourceRule 分段与动态展开

- 原版依据：`AnalyzeRule.splitSourceRule` 按 `<js>`/`@webjs:` 片段保留顺序；`SourceRule` 构造先移除并收集 `@put:{...}`，每个片段执行前调用 `putRule`；`makeUpRule` 再处理 `@get:key`、`{{expression}}`、`$1` 参数，最后拆分 `##` 替换后缀。
- 本地修改：新增 `rust/legado_engine/src/rule/source_rule.rs`，提供有序分段、模式识别、`@put` JSON 收集、共享 `RuleState`、动态展开和替换元数据；在 `rust/legado_engine/src/rule/mod.rs` 注册模块。
- 离线定向测试：`source_rule::tests` 5/5 通过，覆盖 plain/JS/plain 顺序、大小写不敏感 `@js:` 尾段、当前片段执行前的 `put` 可见性、`@get`/`{{}}`/`$1`/`##` 展开和 `@put` 值读取既有变量。
- Rust 全量测试：99 个库测试通过；所有非 ignored 集成/文档测试通过，0 失败。
- release 构建：`scripts/build_rust.ps1` 成功，输出 `rust/target/release/legado_engine.dll`。
- Flutter 全量测试：252/252 通过；外部 smoke 的失效站点仍按既有降级策略通过，记录到 HTTP 400/403。
- 静态检查：新增文件单独 `rustfmt --check` 通过，`git diff --check` 通过；`flutter analyze` 仍为仓库基线 47 条诊断，未新增 Dart 修改。
- 已知边界：1B 只建立并验证 SourceRule 状态层；Default/JS/JSONPath/XPath/Regex 的完整多值、空值和宿主 API 返回语义留在 1C，未提前进入下一子步骤。正文清洗、中文断行和分页未涉及。

### 模块 1C：多值、空值与返回类型语义

- 原版依据：`AnalyzeByJSoup.getStringList` 收集全部文本后由 `getString` 按换行合并；`AnalyzeByXPath` 对全部节点按换行合并；`AnalyzeByJSonPath.getStringList` 保留数组项，`getString` 再合并；`AnalyzeByRegex.getElement/getElements` 分别返回首个捕获组和全部捕获组；JS 标量、数组、对象、`null`/`undefined` 由调用类型决定转换结果。
- 本地修改：新增 `run_with_result_as_string`，将 JS 数组按 JavaScript `Array.toString()` 逗号转换，同时保留原 `run_with_result` 的结构化 JSON 边界；JSONPath 增加多值解析与换行合并；Default CSS、Legado 链式规则和 XPath 字符串提取合并全部非空匹配项；新增 `regex_rule` 实现首个/全部捕获组语义；JSON 规则的替换后缀按列表项执行。
- 离线定向测试：6/6 通过，覆盖 JSON 多值、Default CSS 多节点、XPath 多节点、JS 数组字符串转换、Regex 首个捕获和全部捕获/空组。
- Rust 全量测试：105 个库测试通过；所有非 ignored 集成/文档测试通过，0 失败。
- release 构建：`scripts/build_rust.ps1` 成功，输出 `rust/target/release/legado_engine.dll`。
- Flutter 全量测试：252/252 通过；外部 smoke 的失效站点仍记录 HTTP 400/403，但测试按既有降级策略通过。
- 静态检查：新增 `regex_rule.rs` 单文件 `rustfmt --check` 通过，`git diff --check` 通过；全仓 `flutter analyze` 仍为基线 47 条诊断，未新增 Dart 修改。全仓 Rust 格式化仍存在既有债务，未批量格式化无关文件。
- 当时已知边界：1C 完成的是本地 Rust 规则返回语义和离线矩阵；模块级完整 fixture、跨入口回归和偏差报告转入 1D 完成。正文清洗、中文断行和分页未涉及。

### 模块 1D：完整离线 fixture、全量回归与偏差报告

- 原版对照依据：`reference/Jingshiro-legado/app/src/main/java/io/legado/app/model/analyzeRule/AnalyzeRule.kt`、`AnalyzeByJSoup.kt`、`AnalyzeByXPath.kt`、`AnalyzeByJSonPath.kt`、`AnalyzeByRegex.kt`、`AnalyzeUrl.kt`、`help/JsExtensions.kt`。
- 新增 fixture：`test/fixtures/rules/module1/` 下的 HTML/JSON 书源、搜索、详情、目录和正文输入。
- 新增测试：`rust/legado_engine/tests/module1_offline_fixtures.rs`，覆盖四类页面入口、HTML 目录重复 URL 去重、正文替换、JSONPath 多值和模板 URL、CSS/XPath/Regex 空值和多值，以及 JS 字符串/数组/对象/null/undefined、跨 Runtime 缓存、Base64 解码和 AES 往返。
- 定向测试：模块 1 fixture 4/4 通过；JS 兼容性 18/18 通过。
- Rust 全量测试：105 个库测试通过；全部非 ignored 集成/文档测试通过，其中新增模块 1 fixture 4/4 通过，0 失败。
- release 构建：`scripts/build_rust.ps1` 成功，输出 `rust/target/release/legado_engine.dll`。
- Flutter 全量测试：252/252 通过；外部 smoke 的 403/401 仍按既有降级策略通过。
- `flutter analyze`：47 条仓库基线诊断，未新增；新增 Rust fixture `rustfmt --check` 通过，`git diff --check` 通过。

#### 偏差报告

```text
约束编号：§3.2、§3.3
功能模块：JavaScript 宿主 API
原版行为：JsExtensions.kt 暴露 base64Encode、摘要/编码、文件与压缩、WebView、connect/get/post、ajaxAll 等完整宿主能力。
重写版行为：QuickJS 宿主已覆盖当前内置书源和 fixture 使用的 cache、base64Decode、java.ajax、AES createSymmetricCrypto 及基础 URL 辅助；未提供上述完整 API 面。
差异表现：依赖未实现 API 的第三方书源脚本仍可能返回空值或执行失败。
影响范围：仅限调用缺失宿主 API 的规则；当前模块固定 fixture 和现有 7565/7497 书源未触发该差异。
复现条件：在 JS 规则中调用 base64Encode、文件/压缩、WebView、connect/get/post、ajaxAll 或摘要 API。
根因判断：Rust + QuickJS 当前宿主边界只实现已验证的书源依赖，尚未建立 Android 文件、WebView 和并发网络适配层。
临时规避方案：第三方书源使用已覆盖 API，或在 Flutter/平台层提供对应代理；不能通过修改断言掩盖失败。
最终修复计划：在模块 1 后续宿主 API 子步骤中按原版 JsHelp 方法逐项增加离线 fixture 和平台能力验证，再缩小该偏差。

- 其他边界：底层 HTML 解析函数保留原始相对 URL，调用入口负责按当前请求 URL 解析；这与原版 `getString(..., isUrl = true)` 的职责分层不同，但不改变已验证搜索、详情和目录 fixture 的字段结果。模块 3 正文清洗、中文断行和分页尚未开始，§5.1–§5.3 不受本模块修改影响。

```

### 模块 2：目录分页、章节身份与去重

- 原版对照依据：`reference/Jingshiro-legado/app/src/main/java/io/legado/app/model/webBook/BookChapterList.kt` 的目录分页、最终反转和 URL 去重逻辑，以及 `data/entities/BookChapter.kt` 的 `equals/hashCode`（按 `url`）和 `(url, bookUrl)` 主键定义。
- Rust 修改：目录规则支持 `-` / `+` 前缀；多 `nextTocUrl` 全部进入分页队列；按当前目录页基址解析相对章节 URL；分页 URL 使用访问集合终止循环；HTML/JSON 目录保留卷、VIP、付费、标签和目录基址字段；分页合并按 URL 去重；空目录失败后可复用同一服务实例。
- Flutter 修改：`Chapter` 增加稳定的 URL 身份 ID；目录刷新按 URL 复用旧章节 ID、下载标记和正文缓存；目录持久化、文件缓存补全、下载状态更新和自动换源均保留完整章节元数据；URL 为空的本地文本章节继续使用位置 ID。
- 新增定向测试：`test/providers/toc_merge_test.dart` 3/3 通过，覆盖 URL 身份在重排后稳定、下载正文按 URL 保留，以及在线章节 ID 与索引无关。
- Rust 全量测试：108 个库测试通过；所有非 ignored 集成/文档测试通过，0 失败。
- release 构建：`scripts/build_rust.ps1` 成功，输出 `rust/target/release/legado_engine.dll`。
- Flutter 全量测试：254/254 通过；外部 smoke 中失效站点的 HTTP 400/401/403 仍按既有降级策略通过。
- 静态检查：`git diff --check` 通过；`flutter analyze` 仍为仓库基线 47 条诊断，未新增；相关 Dart 文件已格式化。
- 已知边界：本模块未修改正文清洗、中文断行或分页排版；行为约束规范第 3 条及 `§5.1`–`§5.3` 留待模块 3 按固定字体、DPR、视口和配置建立逐页对比基线。
