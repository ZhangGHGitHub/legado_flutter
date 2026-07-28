use crate::model::book_source::BookSource;
use crate::rule::json_rule;
use crate::rule::json_search::JsonSearchResult;
use crate::rule::json_util;
use serde_json::Value;

pub fn parse_json_explore(
    data: &Value,
    source: &BookSource,
) -> Result<Vec<JsonSearchResult>, String> {
    let rule_explore = source
        .rule_explore_obj
        .as_ref()
        .ok_or("无 ruleExplore 对象")?;

    let list_path = rule_explore
        .get("bookList")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    if list_path.is_empty() {
        return Ok(vec![]);
    }

    let base = source.book_source_url.as_str();
    let js_lib = source.js_lib.as_str();
    let items = json_util::collect_array(data, list_path);

    let mut results = Vec::new();
    for item in items {
        let name = json_rule::resolve_field(
            &item,
            rule_explore
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
            rule_explore
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
                rule_explore
                    .get("author")
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
            cover_url: json_rule::resolve_field(
                &item,
                rule_explore
                    .get("coverUrl")
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
            book_url,
            kind: json_rule::resolve_field(
                &item,
                rule_explore
                    .get("kind")
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
            note: json_rule::resolve_field(
                &item,
                rule_explore
                    .get("intro")
                    .or_else(|| rule_explore.get("note"))
                    .and_then(|v| v.as_str())
                    .unwrap_or(""),
                js_lib,
                base,
            ),
        });
    }
    Ok(results)
}
