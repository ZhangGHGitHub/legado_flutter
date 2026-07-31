# Legado Flutter — Jingshiro/legado Rust + Flutter 重构开发流程

> 本文档定义项目的**正规协作流程**，补齐「有计划、无流程」的缺口。  
> 最后更新：2026-07-15

---

## 官方 UI 对标目标

本项目的总体目标是将 [Jingshiro/legado](https://github.com/Jingshiro/legado) 的 Android/Kotlin 实现重构为 Rust + Flutter 跨平台实现。Jingshiro/legado 源码用于行为、数据格式和 UI 的兼容性验收；UI 复刻只是其中一个验收维度。

| 项 | 值 |
|----|-----|
| **对标项目** | [Jingshiro/legado](https://github.com/Jingshiro/legado) |
| **权威说明** | 原 `gedoor/legado` 已不在 GitHub；**Jingshiro fork 为 UI 布局与 Activity 源码的唯一参照** |
| **布局源码** | `app/src/main/java/io/legado/app/ui/` |
| **XML 布局** | `app/src/main/res/layout/` |
| **本地克隆** | `reference/Jingshiro-legado/`（浅克隆，不入库；克隆失败则直接用 GitHub URL） |
| **功能验收** | [语雀 Wiki](https://www.yuque.com/legado/wiki)（用户向交互；**布局仍以 Jingshiro 源码为准**） |

---

## 一、现状诊断

### 已有

| 类别 | 资产 |
|------|------|
| 技术路线图 | `REFACTOR_PLAN.md`；历史 UI 功能库存见 `archive/UI_REPLICATION_PLAN.md` |
| Phase 设计 | `superpowers/specs/`、`superpowers/plans/` |
| 发布说明 | `RELEASE.md` |
| 专题文档 | `JS_COMPAT.md`、`LEGADO_ARCH_REFERENCE.md` |
| 外部参考 | [Jingshiro/legado](https://github.com/Jingshiro/legado)（UI 权威）、[语雀 Wiki](https://www.yuque.com/legado/wiki) |
| CI | `.github/workflows/apple-build.yml`（仅 macOS/iOS） |
| 测试脚本 | `scripts/run_js_compat.ps1`、`flutter test`、`cargo test` |

### 缺失（本流程要补的）

| 缺口 | 影响 |
|------|------|
| **无统一流程文档** | 每人/每次 AI 会话做法不一致，容易跳步 |
| **无文档索引** | 计划散落，不知道先看哪份 |
| **无质量门禁** | 合并前跑什么测试、什么叫「做完」不明确 |
| **无 CONTRIBUTING.md** | 贡献入口和协作约定仍需单独整理 |
| **无 Issue/PR 模板** | 需求描述、测试说明格式不统一 |
| **CI 不完整** | 仅 Apple Build，Windows/Android 测试无自动跑 |
| **Phase 完成标准模糊** | REFACTOR / UI 计划里的 checkbox 与代码状态易脱节 |

---

## 二、文档体系与职责

### 2.1 写哪份、何时更新

| 文档 | 谁维护 | 何时更新 |
|------|--------|----------|
| `REFACTOR_PLAN.md` | 负责人 | 引擎版本变更、大功能完成/新增、多平台状态变化 |
| `archive/UI_REPLICATION_PLAN.md` | 归档 | 历史 UI Task 与旧差距记录，不作为新重构任务入口 |
| `superpowers/specs/*.md` | 设计阶段 | **新 Phase 或大改前**写规格，批准后不动（除非变更） |
| `superpowers/plans/*.md` | 实施阶段 | 拆 Task、记步骤；可与 UI/REFACTOR 计划合并维护 |
| `JS_COMPAT.md` 等专题 | 专题负责人 | 该主题测试/规则变化时 |
| `DEVELOPMENT_PROCESS.md` | 全员 | 流程本身变更时 |
| `CHANGELOG.md` | 负责人 | **每个逻辑变更完成时**更新；对外发布时整理为版本条目 |

### 2.2 单一事实来源

- **引擎能力与版本** → `REFACTOR_PLAN.md` + `rust/legado_engine` 中 `engine_version()`
- **当前 UI/架构验收** → `REFACTOR_PLAN.md` 的 R0-R6、`LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md` 和 `R0_REBASELINE.md`；`UI_REPLICATION_PLAN.md` 仅保留历史功能库存。
- **怎么开发** → 本文档
- **怎么发布** → `RELEASE.md`
- **每次变更记录** → `CHANGELOG.md`

避免在 README 里维护长进度表；README 只保留快速开始 + 指向 `docs/README.md`。

---

## 三、标准开发流程

适用于每一个 Task（如 UI-1、JS 兼容 2a、引擎 Phase 2C）。

```
┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
│ 1.选题  │ → │ 2.对齐  │ → │ 3.实现  │ → │ 4.自测  │ → │ 5.记录  │ → │ 6.合并  │
└─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### Step 1 — 选题

1. 在 `REFACTOR_PLAN.md` 的当前 R0-R6 阶段中找到迁移单元；历史 `UI-*` Task ID 只能用于追溯已有功能。
2. 确认依赖已满足（例如 UI-2 依赖 UI-1 底栏骨架）。
3. 大功能（新 Phase、跨 Rust+Flutter）先查 `superpowers/specs/` 是否已有规格；没有则先写简短设计再动手。

### Step 2 — 对齐

开工前明确三件事（可写在 PR 或 commit 说明里）：

| 项 | 说明 |
|----|------|
| **对标** | UI：Jingshiro 哪个 XML/Activity；引擎：哪条 legado 行为 |
| **范围** | 本 Task 做啥、**不做啥**（防止 scope creep） |
| **验收** | 可检查的条目（语雀 checklist、测试命令、截图） |

### Step 3 — 实现

原则（与 `.cursorrules` / 用户约定一致）：

- **最小 diff**：只改本 Task 相关文件
- **沿用现有风格**：命名、Provider、页面结构跟周边代码一致
- **引擎优先 Rust**：UI 不引入 Dart 规则引擎
- **占位要可见**：未实现功能用明确文案（如「开发中」），不要静默失败

### Step 4 — 自测（质量门禁）

合并前**至少**通过下表对应项：

| 改动类型 | 必跑命令 |
|----------|----------|
| 任意 Dart | `flutter analyze` + `flutter test` |
| Rust 引擎 | `cd rust/legado_engine && cargo test` |
| JS 兼容相关 | `.\scripts\run_js_compat.ps1` |
| UI 阅读器/书源 | 手动：`flutter run -d windows`，走一遍主路径 |
| Apple 相关 | 本地或等 CI `apple-build.yml` |

**Definition of Done（单个 Task）**

- [ ] 计划文档中对应条目已勾选或注明「部分完成 + 剩余项」
- [ ] 上述测试通过（或注明平台限制，如 Web 无 Rust）
- [ ] 无无关文件进提交（调试 xml、analyze 输出等）
- [ ] 若改引擎版本，`engine_version()` 与 `REFACTOR_PLAN.md` 一致

### Step 5 — 记录

1. 更新对应阶段记录（`REFACTOR_PLAN.md`、`R0_REBASELINE.md` 或专题兼容计划）；不再以历史 UI Task 清单声明重构完成。
2. 若行为/用法变化，更新专题 doc（如 `JS_COMPAT.md`）。
3. 按本文“变更可追溯规则”更新 `CHANGELOG.md`，写明变更、测试和已知限制。

### Step 5A — 变更可追溯规则（强制）

以下规则适用于代码、测试、配置、文档、数据库 schema、Rust 引擎和 Flutter UI 的每一个逻辑变更；“只改了一点”不能豁免。

1. **先确认范围。** 开始工作前确认当前分支和工作区状态；已有未提交修改必须保留、识别归属，不能把无关修改混入本次变更。
2. **必须记录计划。** 在 `REFACTOR_PLAN.md`、`R0_REBASELINE.md` 或对应专题文档中更新当前迁移状态。未完成项、平台限制和外部依赖必须明确写出，不能只写“完成”。
3. **必须更新日志。** 每个逻辑变更都在根目录 `CHANGELOG.md` 的 `[Unreleased]` 下记录，至少包含：变更内容、影响范围、验证命令/结果、已知限制。修复问题还要写明问题表现和修复结果。
4. **必须可由 Git 追溯。** 每个可交付逻辑变更应形成独立 Git commit，commit message 必须能说明 Task/模块和结果。未获得提交授权时，不得擅自 commit；此时必须明确报告“未提交”，并提供拟提交文件和 commit message。
5. **测试结果必须和变更绑定。** 报告“已完成”前必须列出实际执行的测试/构建命令及结果；跳过、失败和环境限制必须原样记录，不能用历史结果冒充当前结果。
6. **发布必须有版本标识。** 对外发布前必须递增 `pubspec.yaml` 的 App 版本，核对 Rust engine/schema 版本，更新 `CHANGELOG.md` 的版本条目，并创建对应 Git tag。没有版本号和 tag 的工作区只能称为开发中或未发布版本。
7. **禁止虚假完成。** 脏工作区、未更新日志、未记录测试、存在未披露失败门禁或未完成外部验收时，不得把本次变更描述为“全部完成”或“已发布”。

本规则优先于旧文档中“CHANGELOG 待建”“发布时再记录”等过渡性描述；旧文档与本规则冲突时，以本规则为准。

### Step 6 — 合并

- 默认分支：`master`
- 功能分支命名建议：`feat/ui-1-reader-chrome`、`fix/apple-ci-link` 等
- **仅用户明确要求时** `git commit` / `git push` / 开 PR
- PR 描述建议包含：Task ID、对标、测试命令、截图（UI 改动）

---

## 四、Phase 门控

Phase 不是「写了很多代码」，而是满足**退出标准**才能进下一 Phase。

### Phase F（UI 复刻）示例

| 阶段 | 进入条件 | 退出标准 |
|------|----------|----------|
| **S1** | 主框架可导航 | UI-1～UI-7 验收 checklist 通过；`flutter test` 绿 |
| **S2** | S1 完成 | 缺失页面有入口非占位；备份/Web 服务可配置 |
| **S3** | S2 完成 | 换源/AI/DB 扩展可用 |
| **S4** | 用户排期 | RSS 阅读链路可用 |

### 引擎 Phase 示例

| 标记 | 退出标准 |
|------|----------|
| JS 兼容 2a | 50+ 源离线清单 + 通过率报表 |
| JS 兼容 2d | CI 回归 job 绿 |
| 多平台 | `RELEASE.md` 中该平台构建命令本地验证通过 |

---

## 五、测试策略

### 5.1 测试金字塔

```
        ┌─────────────┐
        │  手动探索   │  UI 1:1 对照、真机
        ├─────────────┤
        │  集成测试   │  test/integration/
        ├─────────────┤
        │  服务/Widget│  test/services/ test/widgets/
        ├─────────────┤
        │  Rust 单元  │  rust/legado_engine/tests/
        └─────────────┘
```

### 5.2 关键回归套件

| 套件 | 路径 | 用途 |
|------|------|------|
| Flutter 全量 | `flutter test` | Dart 逻辑回归 |
| Phase 3 对齐 | `cargo test --test phase3_alignment` | 引擎规则对齐 |
| JS 兼容 | `scripts/run_js_compat.ps1` | `<js>` / jsLib 回归 |
| Apple 构建 | `.github/workflows/apple-build.yml` | macOS/iOS 链接 |

### 5.3 新功能测试要求

- 修 bug：**先复现再修**，能写测试则写（不强制 widget 烟测）
- 新引擎规则：Rust 单元测试 + fixture HTML/JSON
- 新 UI 页：至少手动主路径；复杂交互记入 `UI_REPLICATION_PLAN` 验收项

---

## 六、分支与版本

### 6.1 版本号约定（建议）

| 层级 | 位置 | 规则 |
|------|------|------|
| App 版本 | `pubspec.yaml` `version:` | `主.次.补丁+build` |
| 引擎版本 | Rust `engine_version()` | 与 `REFACTOR_PLAN.md` 同步，功能变更时 bump |
| DB Schema | 迁移脚本版本号 | 破坏性变更才 +1，写迁移说明 |

### 6.2 发布流程（摘要）

完整步骤见 `RELEASE.md`。发布前检查：

1. `flutter test` + 相关 `cargo test` 通过
2. 目标平台构建成功
3. `CHANGELOG.md` 已更新，版本条目与 `pubspec.yaml`、引擎版本和 schema 一致
4. 打 tag（若对外发布）

---

## 七、对标验证流程

### UI 改动

1. **布局**：[Jingshiro/legado](https://github.com/Jingshiro/legado) 的 `app/src/main/res/layout/` + `app/src/main/java/io/legado/app/ui/`（或本地 `reference/Jingshiro-legado/` 同路径）
2. **功能完整性**：[语雀 Wiki](https://www.yuque.com/legado/wiki) 对应章节（历史对照库存见 `archive/UI_REPLICATION_PLAN.md`）
3. **截图对比**：同一状态（书架/阅读器/设置）并排对比

### 引擎改动

1. 原 legado / Jingshiro 行为描述
2. fixture 或在线 probe 测试
3. `phase3_alignment` / `js_compatibility` 无回归

---

## 八、待补齐清单

按优先级建议实施：

| 优先级 | 资产 | 说明 |
|:---:|------|------|
| P0 | ✅ `docs/README.md` | 文档索引 |
| P0 | ✅ `docs/DEVELOPMENT_PROCESS.md` | 本文档 |
| P1 | `CONTRIBUTING.md` | 贡献者入口，链到本文档 |
| P1 | ✅ `CHANGELOG.md` | 版本变更记录 |
| P1 | `.github/workflows/ci.yml` | `flutter test` + `cargo test` on push/PR |
| P2 | `.github/pull_request_template.md` | Task ID + 测试说明 |
| P2 | `.github/ISSUE_TEMPLATE/` | bug / feature 模板 |
| P3 | ADR 目录 `docs/adr/` | 重大架构决策记录 |

---

## 九、当前推荐执行顺序

在继续 UI-1 等实现任务之前，建议用 **1～2 天** 完成流程基建：

```
Day 1  流程文档 ✅（本文 + docs/README）
       CHANGELOG.md ✅；CONTRIBUTING.md 初稿
       基础 CI（flutter test + cargo test）

Day 2  PR/Issue 模板
       统一 REFACTOR_PLAN / UI_REPLICATION_PLAN 顶部「状态」字段
       选定下一个 S1 Task（建议 UI-1）并按 § 三 走一遍完整流程
```

这样后续每个 Task 都有章可循，避免「直接写代码、计划文档越来越滞后」。

2026-07-30 当前 R6 记录：AppLog 页面及书架/书签/笔记写入边界、四轮 Feature 偏好/展示/业务能力端口，以及本轮 AppPaths/Clipboard/SourceDebug、RSS ReaderFont、主题 Clipboard、Sources ReaderFont、Backup AppPaths、ReadRecord Clipboard、Web API Clipboard、SourceEditor Clipboard、DictRule Clipboard、TxtToc Clipboard 和 ContentEdit Clipboard 边界均按“先定向测试、再全量门禁、最后记录”流程完成；本批由主 agent 与四个子 agent 并行完成规则偏好、点击区域、正文搜索、模拟阅读、阅读样式、阅读图片缓存、Web API 配置偏好、TocSheet 笔记读取、BookInfoPage 书源搜索/类型语义、Explore、SourceMarket、ReadRecord、阅读样式 ZIP、ReaderSettings 字体、ReplacePage、ConfigPage 和 CacheBookPage 端口，架构扫描由 `110` 降至 `87` 条既有 Feature→service backlog，未将剩余 Feature 依赖白名单化。四子线定向均通过；ReaderFont fake 接口缺口已修复后受影响宿主 `11/11`；Flutter 全量 `732` 通过、`3` 项既有条件跳过，Rust 核心 `184/184`，analyze 和 `git diff --check` 通过。相关实际命令和结果以 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 与 `docs/REFACTOR_ARCHITECTURE_BASELINE.md` 为准。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 RSS 阅读/收藏、主题导入和二维码图片解码端口。新增端口由组合根注入，测试宿主显式补齐依赖；Android SVG 集成测试改用图片缓存端口薄适配器，未削弱断言。实际验证为：受影响定向 `19/19`；`flutter test --no-pub --concurrency=1 --reporter compact` 为 `739` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描 `83` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `RssArticlesPage` 收藏写入端口。`RssStarPrefsPort` 增加 `toggle` 契约，页面和测试宿主改用注入端口，保留既有 SharedPreferences 和 UI 语义；定向 `10/10`，Flutter 串行全量 `740` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `82` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `SourceEditorPage` 二维码能力端口。`QrCodePort` 完整承载 PNG 编码与图片解码，页面和测试宿主改用注入端口，保留既有二维码导入/分享语义；定向 `8/8`，Flutter 串行全量 `741` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `81` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `SourceEditorPage` 代码编辑偏好与会话日志端口。页面改用已有 `CodeEditPrefsPort`，测试宿主注入 fake store adapter，保留自动补全和会话日志语义；定向 `15/15`，Flutter 串行全量 `741` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `80` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：继续按“先定向测试、再全量门禁、最后记录”推进 `SourceEditorPage` 书源登录 Cookie 清理端口。新增完整清理用例端口，adapter 保留 SharedPreferences、Rust CookieJar 和 WebView 清理语义；定向 `6/6`，Flutter 串行全量 `742` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `79` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：四个子 agent 按不重叠写入范围并行推进 AI 配置、书签页、书架排列和漫画阅读偏好；主线完成组合根接入、书架默认 adapter 边界修正和 owner 验收。子线定向证据 AI `9/9`、书签 `25`、书架 `8/8`、漫画 `11`，owner 合并定向 `16/16`；Flutter 串行全量 `755` 通过、`3` 项既有条件跳过，`flutter analyze --no-pub` 为 `No issues found`，架构扫描 `69` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。相关记录见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：两条不重叠 agent 线完成书架展示/配置和 MyPage，主线完成 MainShell 启动端口及组合根接入。受影响定向 `20/20`；Flutter 串行全量 `769` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `69` 降至 `57` 条既有 Feature→service backlog。首轮全量发现测试宿主缺少 `MyPagePort`，补齐 fake 后最终门禁通过，未削弱断言。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：两条不重叠 agent 线完成书架书单导入/导出和 RemoteBook，主线完成四类 adapter 的组合根接入。受影响定向 `25/25`，RemoteArchive/Sort 既有回归 `5/5`；Flutter 串行全量 `779` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描由 `57` 降至 `52` 条既有 Feature→service backlog。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

2026-07-31 当前 R6 记录：C1/C2 两条不重叠 agent 线完成书架样式分组/本地导入和 WebDAV 配置，主线完成两个 Provider 接入及测试宿主补齐。定向组合回归 `34/34`，`test/widget_test.dart` `1/1`，MainShell/书架展示宿主回归 `4/4`；Flutter 串行全量 `788` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub` 为 `No issues found`；架构扫描保持 `46` 条既有 Feature→service backlog。首轮全量发现 4 个测试宿主缺少 `BookGroupStorePort`，补齐 fake 后最终门禁通过，未削弱断言。Rust 未改动，本批不重复运行 Rust 测试；Web/WASM/PWA、正式/主流 WebDAV 和真实 Android TTS 继续按暂停门禁执行。详见 `CHANGELOG.md`、`docs/REFACTOR_PLAN.md` 和 `docs/REFACTOR_ARCHITECTURE_BASELINE.md`。

---

> 相关：[文档索引](./README.md) | [历史 UI 功能库存](./archive/UI_REPLICATION_PLAN.md) | [重构计划](./REFACTOR_PLAN.md)
