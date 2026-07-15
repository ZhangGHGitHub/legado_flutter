# Legado Flutter — 文档索引

> 最后更新：2026-07-15  
> **UI 对标项目：** [Jingshiro/legado](https://github.com/Jingshiro/legado)（原 gedoor 仓库已下架，此 fork 为权威参照）

## 怎么用这些文档

| 你想… | 先看 |
|--------|------|
| 了解项目怎么协作、提交流程 | **[DEVELOPMENT_PROCESS.md](./DEVELOPMENT_PROCESS.md)** |
| 看引擎/功能总进度与后续计划 | [REFACTOR_PLAN.md](./REFACTOR_PLAN.md) |
| 做 UI 1:1 复刻、查 Task ID | [UI_REPLICATION_PLAN.md](./UI_REPLICATION_PLAN.md) |
| 查 Jingshiro 架构对照 | [LEGADO_ARCH_REFERENCE.md](./LEGADO_ARCH_REFERENCE.md) |
| 发布到各平台 | [RELEASE.md](./RELEASE.md) |
| `<js>` 书源兼容性 | [JS_COMPAT.md](./JS_COMPAT.md) |
| 查官方用户功能说明（截图/交互） | [语雀 Wiki](https://www.yuque.com/legado/wiki) |

## 文档分层

```
战略层（做什么、做到哪了）
  REFACTOR_PLAN.md          — 引擎 + 功能路线图
  UI_REPLICATION_PLAN.md    — UI 复刻路线图 + Task 清单

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
  Jingshiro/legado          — UI 布局 1:1 对标（权威；见 reference/Jingshiro-legado/ 或 GitHub）
  语雀 Wiki                 — 用户向功能与交互（布局仍以 Jingshiro 源码为准）
```

## Phase 与文档对应

| Phase | 主题 | 规格 | 计划 | 进度记录 |
|-------|------|------|------|----------|
| E | Jsoup / 正文引擎 | `superpowers/specs/2026-07-11-phase-e-*` | `superpowers/plans/2026-07-11-phase-e-*` | `.superpowers/sdd/progress.md` |
| F | UI 复刻 | `superpowers/specs/2026-07-11-phase-f-ui-design.md` | `superpowers/plans/2026-07-11-phase-f-ui-implementation.md` | `UI_REPLICATION_PLAN.md` § 四 |
| — | JS 兼容 / 引擎 | — | `REFACTOR_PLAN.md` § 三 | `JS_COMPAT.md` |

## 待补齐的流程资产

见 [DEVELOPMENT_PROCESS.md § 八](./DEVELOPMENT_PROCESS.md#八待补齐清单)：

- `CONTRIBUTING.md`
- `CHANGELOG.md`
- GitHub Issue / PR 模板
- 全平台 CI（目前仅有 Apple Build）
- 版本号与引擎版本联动规范
