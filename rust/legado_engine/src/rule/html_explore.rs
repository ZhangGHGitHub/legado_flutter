use crate::model::book_source::BookSource;
use crate::rule::html_search::{parse_html_search, preprocess_book_list_html, HtmlSearchResult};
use crate::rule::js_engine;

/// 发现页结果解析 — 复用搜索列表逻辑，字段来自 ruleExplore
pub fn parse_html_explore(
    html: &str,
    source: &BookSource,
) -> Result<Vec<HtmlSearchResult>, String> {
    let base = source.book_source_url.as_str();
    let js_lib = source.js_lib.as_str();
    let html = preprocess_book_list_html(html, &source.rule_explore_list, js_lib, base);

    let explore_source = BookSource {
        rule_search_list: js_engine::css_suffix_after_js(&source.rule_explore_list).to_string(),
        rule_search_name: source.rule_explore_name.clone(),
        rule_search_author: source.rule_explore_author.clone(),
        rule_search_cover_url: source.rule_explore_cover_url.clone(),
        rule_search_kind: source.rule_explore_kind.clone(),
        rule_search_note: if source.rule_explore_note.is_empty() {
            source.rule_explore_intro.clone()
        } else {
            source.rule_explore_note.clone()
        },
        rule_search_book_url: source.rule_explore_book_url.clone(),
        ..source.clone()
    };
    parse_html_search(&html, &explore_source)
}
