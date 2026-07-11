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

    let resolved_raw = if raw.starts_with("@js:") || raw.starts_with("@Js:") {
        let script = raw[4..].trim();
        js_engine::run_search_js(script, keyword, js_lib, base, page)?
    } else if js_engine::contains_js_block(raw) {
        let template = raw
            .replace("{{key}}", keyword)
            .replace("{{page}}", &page.to_string());
        js_engine::run_url_template_js(&template, keyword, js_lib, base, page)?
    } else {
        return Ok(parse_url_config_with_page(raw, keyword, page));
    };

    if resolved_raw.trim().is_empty() {
        return Ok(empty_config());
    }
    Ok(parse_url_config_with_page(&resolved_raw, keyword, page))
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
}
