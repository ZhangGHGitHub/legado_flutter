use crate::model::book_source::BookSource;
use crate::rule::{json_rule, json_util};
use serde_json::Value;

/// JSON 搜索结果（内部）
#[derive(Debug, Clone)]
pub struct JsonSearchResult {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub book_url: String,
    pub kind: String,
    pub note: String,
}

pub fn parse_json_search(
    data: &Value,
    source: &BookSource,
) -> Result<Vec<JsonSearchResult>, String> {
    let rule_search = source
        .rule_search_obj
        .as_ref()
        .ok_or("无 ruleSearch 对象")?;

    let book_list_path = rule_search
        .get("bookList")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if book_list_path.is_empty() {
        return Ok(vec![]);
    }

    let base = source.book_source_url.as_str();
    let js_lib = source.js_lib.as_str();
    let items = json_util::collect_array(data, book_list_path);

    let mut results = Vec::new();
    for item in items {
        let name = json_rule::resolve_field(
            &item,
            rule_search
                .get("name")
                .and_then(|v| v.as_str())
                .unwrap_or(""),
            js_lib,
            base,
        );
        if name.is_empty() {
            continue;
        }

        let mut book_url = json_rule::resolve_field(
            &item,
            rule_search
                .get("bookUrl")
                .and_then(|v| v.as_str())
                .unwrap_or(""),
            js_lib,
            base,
        );
        if book_url.contains("{{") {
            book_url = json_util::resolve_template(&book_url, &item);
        }

        results.push(JsonSearchResult {
            name,
            author: json_rule::resolve_field(
                &item,
                rule_search
                    .get("author")
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
            cover_url: json_rule::resolve_field(
                &item,
                rule_search
                    .get("coverUrl")
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
            book_url,
            kind: json_rule::resolve_field(
                &item,
                rule_search
                    .get("kind")
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
            note: json_rule::resolve_field(
                &item,
                rule_search
                    .get("intro")
                    .or_else(|| rule_search.get("note"))
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
        });
    }

    Ok(results)
}
