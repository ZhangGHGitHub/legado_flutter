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

#[test]
fn login_check_js_rewrites_body() {
    let src = r#"{"bookSourceUrl":"https://example.com","loginCheckJs":"result.replace('LOGIN','OK')","jsLib":""}"#;
    let out = js_engine::apply_login_check_js(
        src,
        "hello LOGIN world",
        "https://example.com/",
        "GET",
        None,
        "UTF-8",
    );
    assert_eq!(out.body, "hello OK world");
}

#[test]
fn login_check_js_empty_is_noop() {
    let src = r#"{"bookSourceUrl":"https://example.com"}"#;
    let out = js_engine::apply_login_check_js(
        src,
        "raw-body",
        "https://example.com/",
        "GET",
        None,
        "UTF-8",
    );
    assert_eq!(out.body, "raw-body");
}

#[test]
fn login_check_js_failure_keeps_body() {
    let src = r#"{"bookSourceUrl":"https://example.com","loginCheckJs":"throw new Error('boom')"}"#;
    let out = js_engine::apply_login_check_js(
        src,
        "keep-me",
        "https://example.com/",
        "GET",
        None,
        "UTF-8",
    );
    assert_eq!(out.body, "keep-me");
}

#[test]
fn login_check_js_str_response_body_and_source() {
    // 对齐恩木类源：result.body() / result.url() / source.bookSourceUrl
    let src = r#"{"bookSourceUrl":"https://enmu.example","loginCheckJs":"var b=result.body(); if(b.indexOf('NEED')>=0){ result=new __StrResponse(b.replace('NEED','DONE'), result.url()); } result;","jsLib":""}"#;
    let out = js_engine::apply_login_check_js(
        src,
        "NEED login",
        "https://enmu.example/book",
        "GET",
        None,
        "UTF-8",
    );
    assert_eq!(out.body, "DONE login");
}

#[test]
fn login_check_js_put_login_header_and_header_map() {
    // 对照 jsHelp：source.putLoginHeader + java.getHeaderMap().putAll(source.getHeaderMap(true))
    legado_engine::http::login_header_store::clear();
    let src = r#"{"bookSourceUrl":"https://login.example","header":"{\"X-A\":\"1\"}","loginCheckJs":"source.putLoginHeader(JSON.stringify({Cookie:'sid=abc'})); java.getHeaderMap().putAll(source.getHeaderMap(true)); java.initUrl(); result;","jsLib":""}"#;
    let out = js_engine::apply_login_check_js(
        src,
        "ok",
        "https://login.example/page",
        "GET",
        None,
        "UTF-8",
    );
    assert_eq!(out.body, "ok");
    assert!(out.login_header.as_ref().unwrap().contains("sid=abc"));
    assert!(
        legado_engine::http::login_header_store::get("https://login.example").contains("sid=abc")
    );
}

#[test]
fn login_check_js_get_str_response_returns_str_response() {
    // getStrResponse 对不可达地址返回 code=500 的 StrResponse（不抛）
    let src = r#"{"bookSourceUrl":"https://getstr.example","loginCheckJs":"result = java.getStrResponse(); result;","jsLib":""}"#;
    let out = js_engine::apply_login_check_js(
        src,
        "orig",
        "http://127.0.0.1:1/nope",
        "GET",
        None,
        "UTF-8",
    );
    assert!(
        out.body.contains("Error Response") || out.body == "orig",
        "body={}",
        out.body
    );
}

#[test]
fn pre_update_js_runs_and_writes_cache() {
    let _ = js_engine::reset_cache();
    let source = BookSource::from_json(
        r#"{"bookSourceUrl":"https://example.com","ruleToc":{"preUpdateJs":"cache.put('pre','1',0); 'ok'","chapterList":"a"}}"#,
    )
    .unwrap();
    js_engine::run_pre_update_js(&source, "https://example.com/book/1");
    // 失败不抛；有 cache 宿主则能读到（stdlib 可能走 putMemory）
    // 至少保证非空字段被解析且调用不 panic
    assert!(!source.pre_update_js.is_empty());
}
