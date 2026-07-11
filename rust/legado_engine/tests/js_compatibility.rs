//! <js> 书源兼容性 — 离线测试（REFACTOR_PLAN #2）
//! 运行: cargo test --test js_compatibility

use legado_engine::http::analyze_url::resolve_search_request;
use legado_engine::model::book_source::BookSource;
use legado_engine::rule::{html_search, js_engine};
use std::fs;
use std::path::PathBuf;

fn fixture(name: &str) -> String {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../test/fixtures/js");
    path.push(name);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("读取 fixture {name} 失败: {e}"))
}

fn builtin_source(name: &str) -> BookSource {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../assets/builtin_sources");
    path.push(name);
    let raw = fs::read_to_string(&path).expect("builtin source");
    let trimmed = raw.trim_start_matches('\u{feff}');
    let json = if trimmed.starts_with('[') {
        let arr: Vec<serde_json::Value> = serde_json::from_str(trimmed).unwrap();
        arr[0].to_string()
    } else {
        trimmed.to_string()
    };
    BookSource::from_json(&json).expect("parse source")
}

#[test]
fn js_7497_jslib_clean_strips_html() {
    let source = builtin_source("7497.json");
    let raw = r#"{"data":{"content":"<p>段落一</p><br/><p>段落二</p>"}}"#;
    let out = js_engine::run_with_result("Clean(result)", raw, &source.js_lib, &source.book_source_url)
        .expect("Clean");
    assert!(out.contains("段落一"));
    assert!(!out.contains("<p>"));
}

#[test]
fn js_7497_jslib_cover_builds_url() {
    let source = builtin_source("7497.json");
    let out = js_engine::run_with_result("Cover('12345')", "", &source.js_lib, &source.book_source_url)
        .expect("Cover");
    assert_eq!(out, "https://pic.cooks.tw/12/12345/12345s.jpg");
}

#[test]
fn js_7497_jslib_base_returns_origin() {
    let source = builtin_source("7497.json");
    let out = js_engine::run_with_result("Base()", "", &source.js_lib, &source.book_source_url)
        .expect("Base");
    assert_eq!(out, "https://novel.cooks.tw");
}

#[test]
fn js_7497_jslib_cache_roundtrip() {
    let source = builtin_source("7497.json");
    let script = r#"
cache.putMemory('articleid', '999');
cache.getFromMemory('articleid');
"#;
    let out = js_engine::run_with_result(script, "", &source.js_lib, &source.book_source_url)
        .expect("cache");
    assert_eq!(out, "999");
}

#[test]
fn js_7565_search_booklist_preprocess() {
    let source = builtin_source("7565.json");
    let html = fixture("7565_search.html");
    let results = html_search::parse_html_search(&html, &source).expect("search parse");
    assert_eq!(results.len(), 2);
    assert_eq!(results[0].name, "斗破苍穹");
    assert!(results[0].author.contains("天蚕土豆"));
    assert_eq!(results[0].kind, "玄幻");
}

#[test]
fn js_7565_explore_booklist_preprocess() {
    let source = builtin_source("7565.json");
    let html = fixture("7565_explore.html");
    let processed = html_search::preprocess_book_list_html(
        &html,
        &source.rule_explore_list,
        &source.js_lib,
        &source.book_source_url,
    );
    assert!(processed.contains("bk-name"));
    assert!(processed.contains("斗破苍穹"));
}

#[test]
fn js_7565_content_script_fixture() {
    let source = builtin_source("7565.json");
    let script = js_engine::extract_js_block(&source.rule_content).expect("content js");
    let html = r#"<html><body><article id="nr"><p>第一章</p><br/><p>正文内容超过一百字用于验证清洗逻辑是否正常工作继续补充文字。</p></article></body></html>"#;
    let out = js_engine::run_html_js(&script, html, &source.js_lib, &source.book_source_url)
        .expect("content js");
    assert!(out.len() > 50);
    assert!(out.contains("正文内容"));
}

#[test]
fn js_at_prefix_search_url() {
    let source = BookSource::from_json(
        r##"{"bookSourceUrl":"http://test.com/","searchUrl":"@js:Base()+'/s?q='+key","ruleSearch":{"bookList":"a","name":"a@text"}}"##,
    )
    .unwrap();
    let mut s = source;
    s.js_lib = "function Base(){return 'https://novel.cooks.tw';}".to_string();
    let cfg = resolve_search_request(&s, "斗破", 1).unwrap();
    assert_eq!(cfg.url, "https://novel.cooks.tw/s?q=斗破");
}

#[test]
fn js_bracket_url_template() {
    let source = BookSource::from_json(
        r##"{"bookSourceUrl":"http://test.com/","searchUrl":"<js>'http://test.com/search?k='+key</js>"}"##,
    )
    .unwrap();
    let cfg = resolve_search_request(&source, "abc", 1).unwrap();
    assert_eq!(cfg.url, "http://test.com/search?k=abc");
}

#[test]
fn js_builtin_sources_have_js_rules() {
    let bishu = builtin_source("7565.json");
    let tomato = builtin_source("7497.json");
    assert!(bishu.rule_content.contains("<js>"));
    assert!(bishu.rule_search_list.contains("<js>"));
    assert!(!tomato.js_lib.is_empty());
    assert!(tomato.rule_content.contains("<js>"));
}

#[test]
fn js_scan_reports_jsoup_usage() {
    let raw = fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../assets/builtin_sources/7565.json"),
    )
    .unwrap();
    assert!(raw.contains("Packages.org.jsoup.Jsoup"));
}
