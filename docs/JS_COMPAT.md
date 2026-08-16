# <js> 书源兼容性测试（REFACTOR_PLAN #2）

离线回归 + 书源规则扫描，验证 rquickjs 对内置书源的 JS 规则支持。

## 快速运行

```powershell
.\scripts\run_js_compat.ps1
```

或分步：

```powershell
# Rust 离线测试（18 项）
cd rust\legado_engine
cargo test --locked --offline --test js_compatibility

# Flutter 扫描器 + 集成测试
flutter test --no-pub test/services/js_compat_analyzer_test.dart test/integration/js_compatibility_test.dart
```

## 覆盖范围

| 书源 | 类型 | 测试点 |
|------|------|--------|
| `7565.json` 笔书网 | HTML + Jsoup `<js>` | 搜索/发现列表预处理、正文清洗 |
| `7497.json` 番茄 | JSON API + `jsLib` + `<js>` | Clean/Cover/Base/cache、多字段 JS 规则 |

额外用例：`@js:` 搜索 URL、`<js>` URL 模板。

## 目录

```
test/fixtures/js/          # 离线 HTML 样本
rust/legado_engine/tests/js_compatibility.rs
lib/services/js_compat_analyzer.dart
test/services/js_compat_analyzer_test.dart
test/integration/js_compatibility_test.dart
```

## 在线端到端

需网络的完整流水线见 `rust/legado_engine/tests/e2e_builtin.rs`：

```powershell
cd rust\legado_engine
cargo test --test e2e_builtin -- --ignored --nocapture
```

在线探测不属于离线兼容门禁；网络不可用或书源返回 HTTP 错误时，测试按现有契约记录为可选路径，不得据此宣称在线链路已验收。

`scripts/run_js_compat.ps1` 会在 Cargo 或 Flutter 缺失时直接失败，不会跳过对应门禁；Rust 固定使用 `--locked --offline`，Flutter 固定使用 `--no-pub`。

## 后续（2a–2d）

- **2a** 扩充 `assets/builtin_sources/` 至 50+ 书源
- **2b** 批量 search→toc→content 通过率报表
- **2c** 按失败案例补充 rquickjs API（`java.headerMap` 等）
- **2d** CI 中加入 `cargo test --test js_compatibility`
