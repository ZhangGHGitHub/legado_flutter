# Phase E-A Jsoup 正文兼容 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增强 Jsoup 兼容层 `#id` / `[attr]` 选择器，使 7565 等社区 `<js>` 正文书源在 Rust 引擎中可读。

**Architecture:** 在 `jsoup.js` 扩展 `_parseSelectorPart` / `_matchStep`，保持 Jsoup API facade 不变；Rust `include_str` 注入；Dart polyfill 镜像同步。正文仍走 `run_html_js()` 单路径。

**Tech Stack:** Rust (rquickjs), JavaScript (QuickJS 兼容 ES5), Dart (flutter_quickjs polyfill)

## Global Constraints

- 不修改 `html_content.rs` 主路径，不用 scraper 兜底 JS 失败
- 不支持 `:nth-child`、`>`、`+`、`~`、`:not()`（见 spec §4.2）
- Rust 与 Dart polyfill 逻辑必须同步
- 7565 E2E 正文 `> 500` 字符；7497 保持 `> 20` 且无 `<p>`
- 引擎版本升至 **0.4.1**

**Spec:** `docs/superpowers/specs/2026-07-11-phase-e-jsoup-content-design.md`

---

### Task 1: Jsoup 选择器解析与匹配（Rust 侧主文件）

**Files:**
- Modify: `rust/legado_engine/src/rule/js_assets/jsoup.js:151-206`
- Test: `rust/legado_engine/src/rule/js_engine.rs:113-133`

**Interfaces:**
- Consumes: 无（底层增强）
- Produces: `_parseSelectorPart(part) → step`、` _matchStep(node, step) → bool`（内部函数，行为通过 `select`/`selectFirst` 暴露）

- [ ] **Step 1: 写失败测试 — `#nr`**

在 `js_engine.rs` 的 `mod tests` 中追加：

```rust
#[test]
fn run_jsoup_select_id() {
    let script = r#"
var doc = Packages.org.jsoup.Jsoup.parse(String(result));
var el = doc.selectFirst('#nr');
el ? el.text() : '';
"#;
    let html = r#"<article id="nr">正文内容</article>"#;
    let out = run_html_js(script, html, "", "").unwrap();
    assert_eq!(out, "正文内容");
}
```

- [ ] **Step 2: 运行确认失败**

```bash
cd rust/legado_engine && cargo test run_jsoup_select_id -- --nocapture
```

Expected: FAIL（输出为空字符串）

- [ ] **Step 3: 实现 `_parseSelectorPart` 与增强 `_matchStep`**

替换 `jsoup.js` 中 `_matchStep`、`_parseSelector` 及相关逻辑：

```javascript
function _parseAttrSelector(raw) {
  var m = raw.match(/^([^\]=]+)(\*=|=)(.+)$/);
  if (!m) return null;
  var val = m[3].trim();
  if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
    val = val.substring(1, val.length - 1);
  }
  return { name: m[1].trim(), op: m[2], value: val };
}

function _parseSelectorPart(part) {
  part = part.trim();
  if (!part) return null;
  var step = { tag: '*', id: null, cls: null, attrs: [] };
  var attrRe = /\[([^\]]+)\]/g;
  var am;
  while ((am = attrRe.exec(part)) !== null) {
    var attr = _parseAttrSelector(am[1]);
    if (attr) step.attrs.push(attr);
  }
  part = part.replace(/\[([^\]]+)\]/g, '');
  var hash = part.indexOf('#');
  if (hash >= 0) {
    var after = part.substring(hash + 1);
    var cut = after.search(/[.\[]/);
    step.id = cut >= 0 ? after.substring(0, cut) : after;
    part = part.substring(0, hash) + (cut >= 0 ? after.substring(cut) : '');
  }
  var dot = part.indexOf('.');
  if (dot >= 0) {
    var afterCls = part.substring(dot + 1);
    var cutCls = afterCls.search(/[.\[]/);
    step.cls = cutCls >= 0 ? afterCls.substring(0, cutCls) : afterCls;
    part = part.substring(0, dot);
  }
  part = part.trim();
  if (part && part !== '*') step.tag = part.toLowerCase();
  return step;
}

function _parseSelector(sel) {
  return sel.trim().split(/\s+/).map(_parseSelectorPart).filter(Boolean);
}

function _attrValue(node, name) {
  if (!node || !node.attrs) return '';
  return node.attrs[name] || node.attrs[name.toLowerCase()] || '';
}

function _matchStep(node, step) {
  if (!node || node.tag === '#root') {
    return step.tag === '*';
  }
  if (step.tag !== '*' && node.tag !== step.tag) return false;
  if (step.id && _attrValue(node, 'id') !== step.id) return false;
  if (step.cls) {
    var cls = (_attrValue(node, 'class') || '').split(/\s+/);
    if (cls.indexOf(step.cls) < 0) return false;
  }
  for (var i = 0; i < step.attrs.length; i++) {
    var a = step.attrs[i];
    var val = _attrValue(node, a.name);
    if (a.op === '=' && val !== a.value) return false;
    if (a.op === '*=' && val.indexOf(a.value) < 0) return false;
  }
  return true;
}
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd rust/legado_engine && cargo test run_jsoup_select_id -- --nocapture
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add rust/legado_engine/src/rule/js_assets/jsoup.js rust/legado_engine/src/rule/js_engine.rs
git commit -m "feat(engine): support #id and [attr] in Jsoup selector polyfill"
```

---

### Task 2: 复合选择器与 html() 单元测试

**Files:**
- Modify: `rust/legado_engine/src/rule/js_engine.rs`（追加测试）
- Test: 同上

**Interfaces:**
- Consumes: Task 1 的 `selectFirst` / `html()` / `text()`
- Produces: 测试覆盖 `article#nr`、`[id=nr]`、`.html()`

- [ ] **Step 1: 写失败测试 — `article#nr` 与 `html()`**

```rust
#[test]
fn run_jsoup_select_tag_id() {
    let script = r#"
var doc = Packages.org.jsoup.Jsoup.parse(String(result));
var el = doc.selectFirst('article#nr');
el ? el.text() : '';
"#;
    let html = r#"<div><article id="nr">第一章</article></div>"#;
    let out = run_html_js(script, html, "", "").unwrap();
    assert_eq!(out, "第一章");
}

#[test]
fn run_jsoup_select_attr_equals() {
    let script = r#"
var doc = Packages.org.jsoup.Jsoup.parse(String(result));
var el = doc.selectFirst('[id=nr]');
el ? el.text() : '';
"#;
    let html = r#"<article id="nr">属性选择</article>"#;
    let out = run_html_js(script, html, "", "").unwrap();
    assert_eq!(out, "属性选择");
}

#[test]
fn run_jsoup_html_method() {
    let script = r#"
var doc = Packages.org.jsoup.Jsoup.parse(String(result));
var el = doc.selectFirst('article#nr');
el ? el.html() : '';
"#;
    let html = r#"<article id="nr"><p>段落</p></article>"#;
    let out = run_html_js(script, html, "", "").unwrap();
    assert!(out.contains("<p>段落</p>"), "html() 应含 inner HTML: {out}");
}
```

- [ ] **Step 2: 运行确认全部通过**

```bash
cd rust/legado_engine && cargo test run_jsoup_select_tag_id run_jsoup_select_attr_equals run_jsoup_html_method -- --nocapture
```

Expected: 全部 PASS（Task 1 实现应已覆盖）

- [ ] **Step 3: Commit**

```bash
git add rust/legado_engine/src/rule/js_engine.rs
git commit -m "test(engine): cover tag#id, attr selector, and html() in Jsoup tests"
```

---

### Task 3: 7565 正文脚本 fixture 测试

**Files:**
- Modify: `rust/legado_engine/src/rule/js_engine.rs`（追加测试）
- Reference: `assets/builtin_sources/7565.json` → `ruleContent.content`

**Interfaces:**
- Consumes: `run_html_js(script, html, "", "")`
- Produces: `run_jsoup_7565_content_script` 测试通过

- [ ] **Step 1: 写失败测试 — 7565 完整清洗脚本**

从 `7565.json` 复制 `<js>...</js>` 内脚本（不含标签），写入测试：

```rust
#[test]
fn run_jsoup_7565_content_script() {
    let script = r#"
var html = String(result);
var doc = Packages.org.jsoup.Jsoup.parse(html);
var nr = doc.selectFirst('article#nr');
var lines = [];
if (nr) {
    var rawHtml = String(nr.html());
    rawHtml = rawHtml.replace(/<br\s*\/?>/gi, '\n');
    var parts = rawHtml.split('\n');
    for (var i = 0; i < parts.length; i++) {
        var line = parts[i].replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ').replace(/\u00a0/g, ' ').trim();
        if (line) {
            lines.push(line);
        }
    }
}
lines.join('\n');
"#;
    let html = r#"
<html><body>
<article id="nr">
<p>第一章 开端</p><br/>
<p>这是测试正文段落，字数需要足够多以验证清洗逻辑正常工作。</p>
<p>第二段继续补充内容，确保 join 后超过一百个字符。</p>
</article>
</body></html>
"#;
    let out = run_html_js(script, html, "", "").unwrap();
    assert!(out.len() > 100, "7565 脚本输出过短: {} chars", out.len());
    assert!(out.contains("测试正文"), "应含正文: {out}");
}
```

- [ ] **Step 2: 运行测试**

```bash
cd rust/legado_engine && cargo test run_jsoup_7565_content_script -- --nocapture
```

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add rust/legado_engine/src/rule/js_engine.rs
git commit -m "test(engine): add 7565 content script fixture test"
```

---

### Task 4: Dart jsoup_polyfill 同步

**Files:**
- Modify: `lib/services/jsoup_polyfill.dart:36-186`

**Interfaces:**
- Consumes: `jsoup.js` 中 `_parseSelectorPart`、`_matchStep`、`_nodeHtml`、`html()` prototype
- Produces: Dart QuickJS 环境与 Rust 行为一致的 polyfill

- [ ] **Step 1: 在 Dart polyfill 添加 `.html()` 与 `_nodeHtml`**

在 `_JsoupElement.prototype.attr` 之后插入（与 `jsoup.js` 一致）：

```javascript
_JsoupElement.prototype.html = function() {
  return _nodeHtml(this._node);
};

function _nodeHtml(node) {
  if (!node) return '';
  if (node.tag === '#root') {
    var sb = '';
    for (var i = 0; i < (node.children || []).length; i++) {
      sb += _nodeHtml(node.children[i]);
    }
    return sb;
  }
  var attrs = node.attrs || {};
  var attrStr = '';
  for (var k in attrs) attrStr += ' ' + k + '="' + attrs[k] + '"';
  var inner = node.text || '';
  for (var j = 0; j < (node.children || []).length; j++) {
    inner += _nodeHtml(node.children[j]);
  }
  return '<' + node.tag + attrStr + '>' + inner + '</' + node.tag + '>';
}
```

- [ ] **Step 2: 替换 `_matchStep` / `_parseSelector` 为 Task 1 同款实现**

将 `jsoup_polyfill.dart` 中 `_matchStep`、`_parseSelector` 整段替换为 Task 1 Step 3 的 `_parseAttrSelector`、`_parseSelectorPart`、`_parseSelector`、`_attrValue`、`_matchStep` 代码。

在文件顶部注释追加：

```dart
/// 与 rust/legado_engine/src/rule/js_assets/jsoup.js 保持同步
```

- [ ] **Step 3: 验证 Dart 测试（如有）或 analyzer**

```bash
cd d:\OH-WorkSpace\Projects\legado_flutter && flutter analyze lib/services/jsoup_polyfill.dart
```

Expected: No issues found

- [ ] **Step 4: Commit**

```bash
git add lib/services/jsoup_polyfill.dart
git commit -m "feat(dart): sync Jsoup polyfill with Rust #id and html() support"
```

---

### Task 5: E2E 断言升级与全量验证

**Files:**
- Modify: `rust/legado_engine/tests/e2e_builtin.rs:63-67`
- Modify: `rust/legado_engine/Cargo.toml`（version → 0.4.1，若 `lib.rs` 有版本常量一并更新）

**Interfaces:**
- Consumes: Task 1–3 的 Jsoup 增强
- Produces: `pipeline_bishu` 断言 `content.len() > 500`

- [ ] **Step 1: 升级 7565 E2E 断言**

将 `e2e_builtin.rs` 中：

```rust
assert!(
    !content.is_empty(),
    "笔书网正文为空: {:?}",
    &content[..content.len().min(80)]
);
```

替换为：

```rust
assert!(
    content.len() > 500,
    "笔书网正文过短 ({} 字符): {:?}",
    content.len(),
    &content[..content.len().min(80)]
);
```

- [ ] **Step 2: 更新引擎版本至 0.4.1**

```bash
# 检查并更新
grep -r "0.4.0" rust/legado_engine/
```

更新 `Cargo.toml` 的 `version = "0.4.1"` 及任何 `LEGADO_ENGINE_VERSION` 常量。

- [ ] **Step 3: 运行单元测试**

```bash
cd rust/legado_engine && cargo test
```

Expected: 全部 PASS（含新增 Jsoup 测试）

- [ ] **Step 4: 运行 E2E（需网络）**

```bash
cd rust/legado_engine && cargo test --test e2e_builtin -- --ignored --nocapture
```

Expected: `e2e_bishu_full_pipeline` 正文 > 500；`e2e_tomato_full_pipeline` 仍通过

- [ ] **Step 5: Commit**

```bash
git add rust/legado_engine/tests/e2e_builtin.rs rust/legado_engine/Cargo.toml
git commit -m "feat(engine): v0.4.1 — Jsoup #id content fix, E2E >500 chars for 7565"
```

---

## Self-Review Checklist

| Spec 要求 | 对应 Task |
|-----------|-----------|
| `#id`、`[attr]` 选择器 | Task 1 |
| `article#nr`、`.html()` | Task 2 |
| 7565 脚本 fixture | Task 3 |
| Dart 同步 | Task 4 |
| E2E > 500 / 7497 不变 | Task 5 |
| 不改 html_content 主路径 | Global Constraints |
| 引擎 0.4.1 | Task 5 |

无 TBD / TODO 占位符。

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-07-11-phase-e-jsoup-content.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — 每个 Task 派生子 agent，任务间 review
2. **Inline Execution** — 本会话按 Task 顺序直接实现，checkpoint 验证

**Which approach?**
