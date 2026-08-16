# 原 Android 模块迁移映射

状态：Phase 0 第一版，后续按原版源码核对持续补充；`legado-main/` 只读。

| 原版模块 | 目标归属 | 当前仓库实现 | 状态/差距 |
|---|---|---|---|
| `model/` Book、Chapter、BookSource、Rule | Rust core + Flutter 镜像模型 | Rust `model/`、Flutter `domain/`、`models/` | 核心字段已映射；freezed 镜像未完成 |
| `help/` 规则、JS、替换净化 | Rust core | `rust/legado_engine/src/rule/` | 主要能力已迁移；JS 超时门禁未完成 |
| `network/` HTTP、Cookie、重试 | Rust core | `rust/legado_engine/src/http/` | 主链路已迁移；平台 Cookie 宿主保留桥接 |
| `database/` Room、DAO、迁移 | Rust core + infrastructure | Rust `db/`、Flutter database ports | Room v99 -> Rust v17 已完成；非核心表暂归档 |
| `ui/` Activity、Adapter、View | Flutter features/widgets | `lib/features/`、`lib/widgets/` | 主要页面已迁移；状态管理仍是 Provider |
| `service/` 下载、同步、后台任务 | application + 平台 adapter | `lib/application/`、`lib/infrastructure/` | 端口化进行中；后台原生服务仍有平台差异 |
| `widget/` 阅读器控件 | Flutter widgets | `lib/features/reader/`、`lib/widgets/` | 已有阅读器链路；保持正文/分页契约 |
| 本地文件读写 | Flutter 文件端口 + Rust 解析 | `LocalBookService`、`LocalBookParserPort` | Rust parser 已接入；TXT Dart fallback 仍存在 |
| 分享、Intent、剪贴板 | Flutter plugin + Platform Channel | application ports + infrastructure adapters | 已按功能逐步端口化 |

## Rust 公开 API 清单（首批）

| 原能力 | Rust 函数 | Flutter 暴露方式 |
|---|---|---|
| 引擎初始化 | `init_engine` | `RealCoreApi`/基础设施 adapter |
| 数据库初始化 | `db_init(path)` | `init(app_dir)` 适配层内部调用 |
| 书架读取 | `db_get_books` | `CoreApi.getBookshelf` |
| 书源搜索 | `search(source_json, keyword)` | `CoreApi.searchBooks` |
| 详情/目录/正文 | `get_book_info` / `get_toc` / `get_content` | application ports |
| JS 执行 | `eval_js` 及规则内部执行器 | 禁止页面直接调用，须经规则端口 |

## Android 强依赖清单

| 能力 | 替代方案 | 当前状态 |
|---|---|---|
| Room/SQLite | Rust `rusqlite` | 已完成迁移门禁 |
| WebView Cookie | Flutter WebView + 平台定域清理 | 已有端口；iOS/macOS 实机构建待验收 |
| Android TTS | Flutter TTS/原生 adapter | 真实 Android 引擎验收暂停 |
| 后台下载/通知 | application 任务 + 平台服务 | 平台差异登记，未宣称等价 |
| 文件选择/分享 | Flutter 插件 | 由 infrastructure adapter 负责 |
| Intent/剪贴板 | Platform Channel/插件 | 按端口逐步收口 |
