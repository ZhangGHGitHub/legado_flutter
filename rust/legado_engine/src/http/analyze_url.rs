use super::client::{parse_url_config_with_page, RequestConfig};
use crate::model::book_source::BookSource;
use crate::rule::js_engine;

/// 解析搜索请求 URL（支持 `@js:` 与 `<js>` 模板）
pub fn resolve_search_request(
    source: &BookSource,
    keyword: &str,
    page: i32,
) -> Result<RequestConfig, String> {
    let raw = source.rule_search_url.trim();
    if raw.is_empty() {
        return Ok(empty_config());
    }

    let js_lib = source.js_lib.as_str();
    let base = source.book_source_url.as_str();

    let resolved_raw = if raw
        .get(..4)
        .is_some_and(|prefix| prefix.eq_ignore_ascii_case("@js:"))
    {
        let script = raw[4..].trim();
        js_engine::run_search_js(script, keyword, js_lib, base, page)?
    } else if js_engine::contains_js_block(raw) {
        let template = raw
            .replace("{{key}}", keyword)
            .replace("{{page}}", &page.to_string());
        js_engine::run_url_template_js(&template, keyword, js_lib, base, page)?
    } else {
        // 普通 URL：先展开 `{{cookie.*}}` / `{{source.*}}` 等 JS 表达式
        let expanded = expand_mustache_js(raw, keyword, page, base, js_lib)?;
        return Ok(parse_url_config_with_page(&expanded, keyword, page));
    };

    if resolved_raw.trim().is_empty() {
        return Ok(empty_config());
    }
    Ok(parse_url_config_with_page(&resolved_raw, keyword, page))
}

/// 展开 AnalyzeUrl 中剩余的 `{{jsExpr}}`（`{{key}}`/`{{page}}` 由 parse_url_config 处理）
fn expand_mustache_js(
    raw: &str,
    keyword: &str,
    page: i32,
    base_url: &str,
    js_lib: &str,
) -> Result<String, String> {
    if !raw.contains("{{") {
        return Ok(raw.to_string());
    }
    let mut out = String::with_capacity(raw.len());
    let chars: Vec<char> = raw.chars().collect();
    let mut i = 0;
    while i < chars.len() {
        if chars[i] == '{' && i + 1 < chars.len() && chars[i + 1] == '{' {
            if let Some(end) = find_mustache_end(&chars, i + 2) {
                let expr: String = chars[i + 2..end].iter().collect();
                let expr = expr.trim();
                if expr == "key" || expr == "page" || expr == "limit" {
                    // 留给 parse_url_config 做编码替换
                    out.push_str("{{");
                    out.push_str(expr);
                    out.push_str("}}");
                } else {
                    let replaced = eval_mustache_expr(expr, keyword, page, base_url, js_lib)?;
                    out.push_str(&replaced);
                }
                i = end + 2;
                continue;
            }
        }
        out.push(chars[i]);
        i += 1;
    }
    Ok(out)
}

fn find_mustache_end(chars: &[char], start: usize) -> Option<usize> {
    let mut j = start;
    while j + 1 < chars.len() {
        if chars[j] == '}' && chars[j + 1] == '}' {
            return Some(j);
        }
        j += 1;
    }
    None
}

fn eval_mustache_expr(
    expr: &str,
    keyword: &str,
    page: i32,
    base_url: &str,
    js_lib: &str,
) -> Result<String, String> {
    let code = format!(
        "var key = {};\nvar page = {};\nvar baseUrl = {};\n\
         var source = {{ bookSourceUrl: {}, getKey: function() {{ return this.bookSourceUrl; }} }};\n\
         ({})",
        js_engine_json_escape(keyword),
        page,
        js_engine_json_escape(base_url),
        js_engine_json_escape(base_url),
        expr
    );
    // cookie / java 已在 stdlib 注入
    js_engine::run_eval_script(&code, js_lib, base_url)
}

fn js_engine_json_escape(s: &str) -> String {
    serde_json::to_string(s).unwrap_or_else(|_| "\"\"".to_string())
}

fn empty_config() -> RequestConfig {
    RequestConfig {
        url: String::new(),
        method: "GET".to_string(),
        body: None,
        charset: "UTF-8".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::book_source::BookSource;

    #[test]
    fn resolve_at_js_search_url() {
        let source = BookSource::from_json(
            r##"{
            "bookSourceUrl": "http://test.example.com/",
            "searchUrl": "@js:'http://test.example.com/search?q=' + key",
            "ruleSearch": { "bookList": "a", "name": "a@text" }
        }"##,
        )
        .unwrap();
        let cfg = resolve_search_request(&source, "斗破", 1).unwrap();
        assert_eq!(cfg.url, "http://test.example.com/search?q=斗破");
    }

    #[test]
    fn resolve_at_js_prefix_is_case_insensitive() {
        let source = BookSource::from_json(
            r#"{"bookSourceUrl":"https://example.com","searchUrl":"@JS:'https://example.com/search?q='+key"}"#,
        )
        .unwrap();
        let cfg = resolve_search_request(&source, "book", 1).unwrap();
        assert_eq!(cfg.url, "https://example.com/search?q=book");
    }

    #[test]
    fn resolve_js_block_search_url() {
        let source = BookSource::from_json(
            r##"{
            "bookSourceUrl": "http://test.example.com/",
            "searchUrl": "<js>'http://test.example.com/s?k=' + key</js>",
            "ruleSearch": { "bookList": "a", "name": "a@text" }
        }"##,
        )
        .unwrap();
        let cfg = resolve_search_request(&source, "abc", 1).unwrap();
        assert_eq!(cfg.url, "http://test.example.com/s?k=abc");
    }

    #[test]
    fn resolve_cookie_remove_mustache_prefix() {
        let source = BookSource::from_json(
            r##"{
            "bookSourceUrl": "http://www.kkbiquge.net",
            "searchUrl": "{{cookie.removeCookie(source.getKey())}}http://www.kkbiquge.net/search2c.html?searchkey={{key}}",
            "ruleSearch": { "bookList": "a", "name": "a@text" }
        }"##,
        )
        .unwrap();
        let cfg = resolve_search_request(&source, "斗破", 1).unwrap();
        assert!(
            cfg.url.starts_with("http://www.kkbiquge.net/search2c.html"),
            "got {}",
            cfg.url
        );
        assert!(cfg.url.contains("searchkey="), "got {}", cfg.url);
        assert!(!cfg.url.contains("cookie"), "got {}", cfg.url);
    }
}
