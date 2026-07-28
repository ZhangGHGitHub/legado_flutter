# R0 工作树可追溯分组

状态：规划记录，不执行暂存、提交、推送或回滚。日期：2026-07-27。

当前工作树同时包含历史 R1-R6 迁移、测试、文档、生成绑定、供应商依赖和本地探针。后续提交必须按
实际 diff 归属分组，不能按文件创建日期或未跟踪状态整体加入。

## 分组顺序

| 顺序 | 拟提交主题 | 主要范围 | 不得混入 |
|---|---|---|---|
| 1 | `docs(R0): rebaseline migration evidence and archive legacy UI plan` | R0 文档、归档索引、边界脚本、忽略规则 | Flutter/Rust 业务代码、探针、生成产物 |
| 2 | `refactor(R1): isolate domain ports and FRB infrastructure` | `lib/application`、`lib/domain`、`lib/infrastructure`、数据库 port/DAO 和其契约测试 | Feature 目录移动、正文/同步行为变更 |
| 3 | `refactor(R3): preserve reader content and pagination boundaries` | `ReadBook`、正文/缓存、Reader Feature、分页快照和断行测试 | 目录、WebDAV、主题/设置无关改动 |
| 4 | `refactor(R4-R5): isolate sync backup and WebDAV boundaries` | 同步、书签、备份、WebDAV、Rust WebDAV crate、R5 集成测试 | 本地 Web server 迁移、外部凭证、探针数据 |
| 5 | `refactor(R6): converge feature UI boundaries` | `lib/features/**` 与对应旧 `lib/pages/**` 删除、Widget/Provider 调整和定向测试 | shared DTO、导航注册、FRB 生成代码 |
| 6 | `build: update generated bindings and vendored engine dependencies` | `lib/src/rust/**`、Rust `frb_generated.rs`、`Cargo.lock`、`rust/vendor`、构建脚本 | 无关联业务行为或文档 |
| 7 | `docs(trace): synchronize plan baseline and changelog` | 阶段完成后新增的证据文档 | 未验证业务代码 |

## 暂不提交的本地内容

- 只读原版基线：`legado-main/`、`reference/`。
- 本地数据库和截图探针：`original_legado.db*`、`tools/*.db`、`tools/*.png`、`tools/*.txt`。
- 本地 WebDAV 运行目录：`.local-webdav/`。
- 任何真实 WebDAV URL、账号、密码、代理认证或模拟器产物。

## 每组固定操作

1. 先运行 `git status --short` 并确认该组文件没有覆盖其他未提交工作。
2. 用 `git add -p` 或精确路径暂存单一分组；不得使用全仓 `git add .`。
3. 执行 `git diff --cached --check`，再运行本组的定向测试和必要构建。
4. 将实际命令、结果、跳过项和外部限制写入 `CHANGELOG.md` 与架构基线。
5. 仅在获得明确授权后执行 `git commit`；不自动 push。

本文件不证明任一历史改动已经通过测试或可提交。其用途是防止后续 R1-R6 将当前大工作树误报为
一个完成边界。
