# Phase E-A：通用 Jsoup 正文兼容 — 设计规格

> **状态：** 已批准（2026-07-11）  
> **阶段：** Phase E 主线 A — 正文可读  
> **完成标准：** 通用 Jsoup 兼容（选项 B）

---

## 1. 背景与问题

### 1.1 现状

- Rust 引擎通过 `rquickjs` 注入 `js_assets/jsoup.js`，为 Legado 书源 `<js>` 脚本提供 `Packages.org.jsoup.Jsoup` API。
- 内置书源 **7565（笔书网）** 正文规则使用：

```javascript
var doc = Packages.org.jsoup.Jsoup.parse(html);
var nr = doc.selectFirst('article#nr');
var rawHtml = String(nr.html());
// ... 按行清洗 ...
lines.join('\n');
```

- E2E 实测正文约 **27 字符**（应为数千字），断言仅检查非空。

### 1.2 根因

`jsoup.js` 的 `_parseSelector` / `_matchStep` **仅支持** `tag`、`.class`、`tag.class` 后代选择器，**不支持 `#id`**。

`article#nr` 被解析为标签名 `article#nr`，永远无法匹配 `id="nr"` 的 `<article>` 节点 → `nr` 为 `null` → `lines` 为空 → 正文极短。

### 1.3 关联缺口

| 位置 | 缺口 |
|------|------|
| `rust/.../jsoup.js` | 无 `#id`、`[attr]` 选择器 |
| `lib/services/jsoup_polyfill.dart` | 同上；且缺少 `.html()` 方法（Rust 版已有） |
| `e2e_builtin.rs` | 7565 正文断言过弱（仅 `!is_empty()`） |

**不在本阶段范围：** 7497 番茄正文走 `jsLib` 的 `Clean()`，不依赖 Jsoup；保持现有行为即可。

---

## 2. 目标与非目标

### 2.1 目标

1. 增强 Jsoup 兼容层，覆盖 Legado 社区 `<js>` 正文中 **高频 CSS 选择器**。
2. **7565 首章正文 E2E > 500 字符**。
3. **7497 番茄正文**保持可用（`> 20` 字符、无裸 `<p>`）。
4. Rust 与 Dart 两份 Jsoup polyfill **逻辑同步**（单一真相源：先改 `jsoup.js`，再镜像到 Dart）。

### 2.2 非目标（Phase E+）

- 完整 CSS3（`:nth-child`、`:not()`、`>` / `+` / `~` 组合符、伪元素）
- 内嵌第三方选择器库（sizzle 等）
- `html_content.rs` 用 scraper 兜底 JS 失败（双轨方案已否决）
- Dart 规则引擎退役（Phase E-B）

---

## 3. 方案决策

### 3.1 候选方案

| 方案 | 描述 | 结论 |
|------|------|------|
| 1. 渐进增强 jsoup.js | 扩展 `_parseSelector` / `_matchStep` | **采用** |
| 2. 内嵌第三方选择器库 | bundle sizzle/css-select | 否决（体积与 QuickJS 风险） |
| 3. Jsoup + scraper 双轨 | JS 失败时 Rust 兜底 | 否决（维护两套逻辑） |

### 3.2 架构原则

- 正文主路径不变：`<js>` → `js_engine::run_html_js()` → 脚本返回值 → `clean_content()`。
- **不修改** `html_content.rs` 主流程；不靠 scraper 偷跑。
- 选择器增强集中在 `jsoup.js` 一个文件，边界清晰、可单测。

---

## 4. 选择器支持矩阵

### 4.1 Phase E-A 必支持

| 类别 | 语法示例 | 解析规则 |
|------|----------|----------|
| ID | `#nr`、`article#nr` | `#` 后至 `.`/`[`/结尾为 id；前缀为 tag（缺省 `*`） |
| Class | `.content`、`div.chapter` | 现有逻辑保留 |
| 复合 | `article#nr.content` | tag + id + class 同时匹配 |
| 属性等于 | `[id=nr]`、`[class=content]` | 属性名 + `=` + 值（引号可选） |
| 属性包含 | `[class*=content]` | 属性值 `indexOf` 子串 |
| 后代空格 | `div.content p` | 现有 walk 逻辑，与上述组合联调 |

### 4.2 明确不支持

`:nth-child`、`:first-child`、`:not()`、`>`、`+`、`~`、`::before`、`::after`

### 4.3 Jsoup API（保持/补齐）

| 方法 | Document | Element | 说明 |
|------|----------|---------|------|
| `select(sel)` | ✓ | ✓ | 已有 |
| `selectFirst(sel)` | ✓ | ✓ | 已有 |
| `text()` | — | ✓ | 已有 |
| `html()` | — | ✓ | Rust 已有；**Dart 需补齐** |
| `attr(name)` | — | ✓ | 已有 |

---

## 5. 实现设计

### 5.1 选择器解析（`_parseSelectorPart`）

将每个空格分隔的片段解析为 step 对象：

```javascript
{ tag: 'article' | '*', id: 'nr' | null, cls: 'content' | null, attrs: [{ name, op, value }] }
```

解析顺序（单片段内）：

1. 提取并移除 `[...]` 属性子句 → `attrs[]`
2. 提取 `#id`（`#` 至 `.`/`[`/结尾）
3. 提取 `.class`（`.` 至 `[`/结尾）
4. 剩余部分为 `tag`（空则 `*`）

### 5.2 匹配（`_matchStep`）

在现有 tag/class 判断后追加：

- `step.id`：`(node.attrs.id || '') === step.id`
- `step.attrs[]`：按 `op` 判断（`=` 全等，`*=` 包含）

### 5.3 文件职责

```
rust/legado_engine/src/rule/js_assets/jsoup.js   ← 主实现（include_str 注入）
lib/services/jsoup_polyfill.dart                 ← 镜像同步 + const 包装
rust/legado_engine/src/rule/js_engine.rs         ← 单元测试
rust/legado_engine/tests/e2e_builtin.rs          ← E2E 断言升级
```

### 5.4 数据流

```
HTTP 响应 HTML
  → html_content::parse_html_content()
  → js_engine::run_html_js(script, html, js_lib, base)
      → init: stdlib.js + jsoup.js + jsLib
      → eval: legadoResult=html; script
      → Jsoup.parse → selectFirst('article#nr') → html() → 清洗
  → clean_content()
  → 返回正文
```

---

## 6. 测试策略

### 6.1 Rust 单元测试（`js_engine.rs` `#[cfg(test)]`）

| 测试名 | 输入选择器 | 断言 |
|--------|------------|------|
| `run_jsoup_parse` | `a` | 已有，保持 |
| `run_jsoup_select_id` | `#nr` | 命中 `id="nr"` |
| `run_jsoup_select_tag_id` | `article#nr` | 命中 `<article id="nr">` |
| `run_jsoup_select_attr` | `[id=nr]` | 同上 |
| `run_jsoup_html` | `article#nr` + `.html()` | 输出含子节点 HTML |
| `run_jsoup_7565_content_script` | 7565 完整脚本 + fixture HTML | 输出 > 100 字符 |

Fixture HTML 最小示例：

```html
<html><body><article id="nr"><p>第一章 测试</p><br/>正文段落内容超过二十个字。</article></body></html>
```

### 6.2 E2E（需 `--ignored`）

| 书源 | 断言 |
|------|------|
| 7565 | `content.len() > 500` |
| 7497 | `content.len() > 20` 且 `!content.contains("<p>")`（不变） |

### 6.3 验收命令

```bash
cd rust/legado_engine && cargo test
cd rust/legado_engine && cargo test --test e2e_builtin -- --ignored --nocapture
```

---

## 7. 风险与缓解

| 风险 | 缓解 |
|------|------|
| 简易 HTML 解析器对畸形 HTML 不准 | 与现状一致；Legado 书源 HTML 通常规整 |
| Rust/Dart 两份 polyfill 漂移 | 以 `jsoup.js` 为源，Dart 手工同步（注释标明来源） |
| 选择器边界 case（`tag#id.class[attr]`） | 单元测试矩阵覆盖 |
| E2E 网络不稳定 | 单元测试为主；E2E 为最终验收 |

---

## 8. 交付清单

- [ ] `jsoup.js` 选择器增强
- [ ] `jsoup_polyfill.dart` 同步 + `.html()`
- [ ] `js_engine.rs` 单元测试（≥ 5 个新用例）
- [ ] `e2e_builtin.rs` 7565 断言 `> 500`
- [ ] `cargo test` 全绿
- [ ] （可选收尾）社区书源 5–10 条 fixture 回归

---

## 9. 版本与文档

- 引擎版本：**0.4.1**（patch：Jsoup 正文修复）
- 关联文档：`docs/REFACTOR_PLAN.md` Phase 3 正文验证表
