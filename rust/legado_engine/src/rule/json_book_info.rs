use crate::model::book_source::BookSource;
use crate::rule::json_rule;
use crate::rule::json_util;
use serde_json::Value;

#[derive(Debug, Clone, Default)]
pub struct JsonBookInfo {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub intro: String,
    pub kind: String,
    pub last_chapter: String,
    pub toc_url: String,
}

pub fn parse_json_book_info(
    data: &Value,
    source: &BookSource,
    book_url: &str,
) -> Result<JsonBookInfo, String> {
    let rule = source
        .rule_book_info_obj
        .as_ref()
        .ok_or("无 ruleBookInfo 对象")?;

    let base = book_url;
    let js_lib = source.js_lib.as_str();

    if let Some(init_rule) = rule.get("init").and_then(|v| v.as_str()) {
        let _ = json_rule::resolve_field(data, init_rule, js_lib, base);
    }

    Ok(JsonBookInfo {
        name: field(rule, "name", data, source, js_lib, base),
        author: field(rule, "author", data, source, js_lib, base),
        cover_url: field(rule, "coverUrl", data, source, js_lib, base),
        intro: field(rule, "intro", data, source, js_lib, base),
        kind: field(rule, "kind", data, source, js_lib, base),
        last_chapter: field(rule, "lastChapter", data, source, js_lib, base),
        toc_url: field(rule, "tocUrl", data, source, js_lib, base),
    })
}

fn field(
    rule: &Value,
    key: &str,
    data: &Value,
    _source: &BookSource,
    js_lib: &str,
    base: &str,
) -> String {
    let Some(raw) = rule.get(key).and_then(|v| v.as_str()) else {
        return String::new();
    };
    let mut val = json_rule::resolve_field(data, raw, js_lib, base);
    if val.contains("{{") {
        val = json_util::resolve_template(&val, data);
    }
    if !val.starts_with("http") && (key == "coverUrl" || key == "tocUrl") {
        return crate::rule::engine::resolve_url(&val, base);
    }
    val
}
