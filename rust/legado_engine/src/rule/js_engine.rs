use rquickjs::{Context, Ctx, Runtime, Value};

const STDLIB: &str = include_str!("js_assets/stdlib.js");
const JSOUP: &str = include_str!("js_assets/jsoup.js");

fn init_context(ctx: &Ctx<'_>, js_lib: &str, base_url: &str) -> Result<(), String> {
    ctx.eval::<(), _>(STDLIB.as_bytes())
        .map_err(|e| format!("JS 标准库加载失败: {e}"))?;
    ctx.eval::<(), _>(JSOUP.as_bytes())
        .map_err(|e| format!("Jsoup 兼容层加载失败: {e}"))?;
    let base_code = format!("baseUrl = {};", json_escape(base_url));
    ctx.eval::<(), _>(base_code.as_bytes())
        .map_err(|e| format!("baseUrl 注入失败: {e}"))?;
    if !js_lib.trim().is_empty() {
        ctx.eval::<(), _>(js_lib.as_bytes())
            .map_err(|e| format!("jsLib 加载失败: {e}"))?;
    }
    Ok(())
}

fn value_to_string<'js>(ctx: &Ctx<'js>, v: Value<'js>) -> Result<String, String> {
    if v.is_null() || v.is_undefined() {
        return Ok(String::new());
    }
    if v.is_string() {
        if let Some(s) = v.as_string() {
            return s
                .to_string()
                .map_err(|e| format!("JS 字符串转换失败: {e}"));
        }
        return Ok(String::new());
    }
    if v.is_number() {
        return Ok(v
            .as_number()
            .map(|n| n.to_string())
            .unwrap_or_default());
    }
    if v.is_bool() {
        return Ok(v
            .as_bool()
            .map(|b| b.to_string())
            .unwrap_or_default());
    }
    match ctx.json_stringify(v).map_err(|e| format!("JS JSON 序列化失败: {e}"))? {
        Some(s) => s
            .to_string()
            .map_err(|e| format!("JS JSON 字符串转换失败: {e}")),
        None => Ok(String::new()),
    }
}

/// 新一轮书源操作前清空 JS 内存缓存（每次新建 Runtime，此处为兼容 API 保留）
pub fn reset_cache() -> Result<(), String> {
    Ok(())
}

/// 执行 Legado `<js>...</js>` 脚本，`result` 为输入数据
pub fn run_with_result(
    script: &str,
    result: &str,
    js_lib: &str,
    base_url: &str,
) -> Result<String, String> {
    let rt = Runtime::new().map_err(|e| format!("JS Runtime 失败: {e}"))?;
    let ctx = Context::full(&rt).map_err(|e| format!("JS Context 失败: {e}"))?;
    ctx.with(|ctx| {
        init_context(&ctx, js_lib, base_url)?;
        let escaped = serde_json::to_string(result).unwrap_or_else(|_| "\"\"".to_string());
        let code = format!(
            "legadoResult = {escaped}; var result = typeof legadoResult === 'string' ? legadoResult : JSON.stringify(legadoResult);\n{script}"
        );
        let v: Value = ctx
            .eval(code.as_bytes())
            .map_err(|e| format!("JS 执行失败: {e}"))?;
        value_to_string(&ctx, v)
    })
}

/// 对 HTML 执行 `<js>` 脚本并返回变换后的 HTML/文本
pub fn run_html_js(script: &str, html: &str, js_lib: &str, base_url: &str) -> Result<String, String> {
    run_with_result(script, html, js_lib, base_url)
}

/// 提取 `<js>...</js>` 内脚本
pub fn extract_js_block(rule: &str) -> Option<String> {
    let start = rule.find("<js>")?;
    let end = rule.find("</js>")?;
    if end <= start {
        return None;
    }
    Some(rule[start + 4..end].to_string())
}

/// 规则是否含 `<js>` 块
pub fn contains_js_block(rule: &str) -> bool {
    rule.contains("<js>") && rule.contains("</js>")
}

/// 提取 `<js>...</js>` 之后的 CSS/链式规则部分
pub fn css_suffix_after_js(rule: &str) -> &str {
    if let Some(end) = rule.find("</js>") {
        rule[end + 5..].trim()
    } else {
        rule.trim()
    }
}

fn json_escape(s: &str) -> String {
    serde_json::to_string(s).unwrap_or_else(|_| "\"\"".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn run_simple_js_transform() {
        let out = run_with_result("result + '!'", "hello", "", "").unwrap();
        assert_eq!(out, "hello!");
    }

    #[test]
    fn run_jsoup_parse() {
        let script = r#"
var html = String(result);
var doc = Packages.org.jsoup.Jsoup.parse(html);
var a = doc.selectFirst('a');
a ? a.text() : '';
"#;
        let out = run_html_js(script, "<a href='/1'>书名</a>", "", "").unwrap();
        assert_eq!(out, "书名");
    }
}
