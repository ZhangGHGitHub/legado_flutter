# Legado Flutter — 文档索引

> 最后更新：2026-07-27
> **重构来源与兼容性基线：** [Jingshiro/legado](https://github.com/Jingshiro/legado)；本项目目标是将其 Android/Kotlin 实现重构为 Rust + Flutter 版本。根目录 `legado-main/` 仅是只读原版核对基线，不是主源码目录。

## 怎么用这些文档

| 你想… | 先看 |
|--------|------|
| 了解项目怎么协作、提交流程 | **[DEVELOPMENT_PROCESS.md](./DEVELOPMENT_PROCESS.md)** |
| 查看每次开发变更记录 | [CHANGELOG.md](../CHANGELOG.md) |
| 查看项目重构主计划与阶段进度 | [REFACTOR_PLAN.md](./REFACTOR_PLAN.md) |
| 查看统一目标架构与强制设计要求 | [LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md](./LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md) |
| 查看重构前架构基线与依赖边界 | [REFACTOR_ARCHITECTURE_BASELINE.md](./REFACTOR_ARCHITECTURE_BASELINE.md) |
| 查看 R0 架构残留、工件分类与边界检查 | [R0_REBASELINE.md](./R0_REBASELINE.md) |
| 查看现有工作树的可追溯提交分组 | [R0_WORKTREE_GROUPS.md](./R0_WORKTREE_GROUPS.md) |
| 查看当前原版数据库迁移门禁 | [REFACTOR_PLAN.md](./REFACTOR_PLAN.md#r1-12kotlin-room-v99-数据迁移门禁当前) |
| 查历史 UI/Phase 功能库存 | [archive/UI_REPLICATION_PLAN.md](./archive/UI_REPLICATION_PLAN.md) |
| 查 Jingshiro 架构对照 | [LEGADO_ARCH_REFERENCE.md](./LEGADO_ARCH_REFERENCE.md) |
| 发布到各平台 | [RELEASE.md](./RELEASE.md) |
| `<js>` 书源兼容性 | [JS_COMPAT.md](./JS_COMPAT.md) |
| 查官方用户功能说明（截图/交互） | [语雀 Wiki](https://www.yuque.com/legado/wiki) |

原版边界：`legado-main/` 只用于核对原版行为、数据结构、UI 和错误语义，不参与本项目构建，禁止直接修改。

## 文档分层

```
战略层（做什么、做到哪了）
 REFACTOR_PLAN.md          — 引擎 + 功能路线图
  LEGADO_FLUTTER_RUST_UNIFIED_ARCHITECTURE.md — 统一目标架构与硬约束
  R0_REBASELINE.md          — 当前架构残留、迁移顺序与静态边界
  archive/UI_REPLICATION_PLAN.md — 历史 UI 功能库存，不是活跃重构主线

流程层（怎么做）
  DEVELOPMENT_PROCESS.md    — 开发流程、质量门禁、分支/测试/发布

设计层（某 Phase 怎么做）
  superpowers/specs/        — 设计规格（已批准）
  superpowers/plans/        — 分步实施计划

专题层（某一主题的细则）
  JS_COMPAT.md              — JS 兼容测试
  RELEASE.md                — 多平台发布
  LEGADO_ARCH_REFERENCE.md  — 架构参考

外部参考
  legado-main/              — 唯一只读 Kotlin 行为、数据、UI 与错误语义基线
  Jingshiro/legado          — 上游来源；reference/ 仅为历史离线副本
  语雀 Wiki                 — 用户向功能与交互（布局仍以 Jingshiro 源码为准）
```

## Phase 与文档对应

| Phase | 主题 | 规格 | 计划 | 进度记录 |
|-------|------|------|------|----------|
| E | Jsoup / 正文引擎 | `superpowers/specs/2026-07-11-phase-e-*` | `superpowers/plans/2026-07-11-phase-e-*` | `.superpowers/sdd/progress.md` |
| F | 历史 UI 功能库存 | `superpowers/specs/2026-07-11-phase-f-ui-design.md` | `superpowers/plans/2026-07-11-phase-f-ui-implementation.md` | `archive/UI_REPLICATION_PLAN.md` |
| — | JS 兼容 / 引擎 | — | `REFACTOR_PLAN.md` § 三 | `JS_COMPAT.md` |

## 待补齐的流程资产

见 [DEVELOPMENT_PROCESS.md § 八](./DEVELOPMENT_PROCESS.md#八待补齐清单)：

- `CONTRIBUTING.md`
- GitHub Issue / PR 模板
- 全平台 CI（目前仅有 Apple Build）
- 版本号与引擎版本联动规范
