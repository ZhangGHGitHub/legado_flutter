# 历史计划归档

本目录存放不再定义当前重构执行顺序的历史计划和功能库存。

- 当前唯一阶段顺序、模块边界和退出条件见 `../REFACTOR_PLAN.md` 的 R0-R6。
- 原版行为验收见 `../LEGADO_COMPATIBILITY_DEVELOPMENT_PLAN.md`；原版源码只读基线为
  根目录 `legado-main/`。
- `UI_REPLICATION_PLAN.md` 保留历史 UI/功能追溯信息，不可用于声明 R6 或产品重构完成。
- `docs/superpowers/` 中含有当前未提交修改的 Phase/Wave 历史资料，暂保留原路径并在
  `R0_REBASELINE.md` 中标记为原位归档候选；待这些既有改动完成可追溯拆分后再物理归档。

归档文件不得作为新功能或重构迁移的入口。新迁移单元必须先记录在 R0-R6 主计划、架构基线和
变更日志中。
