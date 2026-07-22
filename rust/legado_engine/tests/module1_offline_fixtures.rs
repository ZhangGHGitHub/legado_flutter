//! 模块 1 完整离线 fixture：HTML/JSON 四类页面和 JS 宿主返回语义。

use legado_engine::model::book_source::BookSource;
use legado_engine::rule::{
    css, engine, html_book_info, html_content, html_search, html_toc, js_engine, json_book_info,
    json_content, json_search, json_toc, regex_rule, xpath,
};
use scraper::{Html, Selector};
use serde_json::Value;
use serial_test::serial;
use std::fs;
use std::path::PathBuf;

fn fixture(name: &str) -> String {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.push("../../test/fixtures/rules/module1");
    path.push(name);
    fs::read_to_string(&path).unwrap_or_else(|e| panic!("读取 fixture {name} 失败: {e}"))
}

fn source(name: &str) -> BookSource {
    BookSource::from_json(&fixture(name)).expect("书源 fixture")
}

fn json_fixture(name: &str) -> Value {
    serde_json::from_str(&fixture(name)).expect("JSON fixture")
}

#[test]
fn html_fixture_covers_search_info_toc_and_content() {
    let source = source("html_source.json");

    let search = html_search::parse_html_search(&fixture("search.html"), &source).unwrap();
    assert_eq!(search.len(), 2);
    assert_eq!(search[0].name, "HTML 书籍");
    assert_eq!(search[0].author, "甲作者");
    assert_eq!(search[0].book_url, "/book/html-1");
    assert_eq!(search[0].cover_url, "/covers/html-1.jpg");
    assert_eq!(search[1].kind, "历史");

    let info = html_book_info::parse_html_book_info_at(
        &fixture("info.html"),
        &source,
        "https://fixture.example/book/html-1",
    )
    .unwrap();
    assert_eq!(info.name, "HTML 书籍");
    assert_eq!(info.author, "甲作者");
    assert_eq!(info.intro, "这是 HTML 简介。");
    assert_eq!(info.cover_url, "/covers/html-1.jpg");
    assert_eq!(info.toc_url, "/book/html-1/chapters");

    let toc = html_toc::parse_html_toc(&fixture("toc.html"), &source).unwrap();
    assert_eq!(toc.len(), 2);
    assert_eq!(toc[0].title, "第一章 开始");
    assert_eq!(toc[1].url, "/book/html-1/2");

    let content = html_content::parse_html_content(&fixture("content.html"), &source).unwrap();
    assert!(content.contains("第一段。"));
    assert!(content.contains("第三段。"));
    assert!(!content.contains("广告内容"));
}

#[test]
fn json_fixture_covers_search_info_toc_and_content() {
    let source = source("json_source.json");

    let search = json_search::parse_json_search(&json_fixture("search.json"), &source).unwrap();
    assert_eq!(search.len(), 2);
    assert_eq!(search[0].name, "JSON 书籍");
    assert_eq!(search[0].author, "丙作者");
    assert_eq!(search[1].book_url, "https://fixture.example/api/book/2");

    let info = json_book_info::parse_json_book_info(
        &json_fixture("info.json"),
        &source,
        "https://fixture.example/api/book/1",
    )
    .unwrap();
    assert_eq!(info.name, "JSON 书籍");
    assert_eq!(info.cover_url, "https://cdn.example/json-1.jpg");
    assert_eq!(info.toc_url, "https://fixture.example/api/book/1/chapters");

    let toc = json_toc::parse_json_toc(
        &json_fixture("toc.json"),
        &source,
        "https://fixture.example/api/book/1/chapters",
    )
    .unwrap();
    assert_eq!(toc.len(), 2);
    assert_eq!(toc[0].title, "第一章 JSON");
    assert_eq!(toc[1].url, "https://fixture.example/read/2");

    let content = json_content::parse_json_content(&json_fixture("content.json"), &source).unwrap();
    assert_eq!(content, "JSON 第一段\nJSON 第二段");
}

#[test]
fn offline_rule_matrix_covers_multivalue_empty_xpath_and_regex() {
    let html = Html::parse_fragment(
        r#"<div class="value">一</div><div class="value">二</div><p class="empty"></p>"#,
    );
    let root = html.root_element();
    assert_eq!(css::extract_text(&root, ".value@text"), "一\n二");
    assert_eq!(
        engine::extract_text(&root, "//div[@class='value']/text()"),
        "一\n二"
    );
    assert_eq!(engine::extract_text(&root, ".missing@text"), "");
    assert_eq!(xpath::extract_text(&root, "//p[@class='empty']/text()"), "");

    let json = serde_json::json!({"items": [{"name":"一"}, {"name":"二"}], "none": null});
    assert_eq!(
        legado_engine::rule::json_rule::resolve_field(&json, "$.items[*].name", "", ""),
        "一\n二"
    );
    assert_eq!(
        legado_engine::rule::json_rule::resolve_field(&json, "$.none", "", ""),
        ""
    );

    assert_eq!(
        regex_rule::get_element("第一章12 第二章34", &[r"(第一章)(\d+)"]).unwrap(),
        vec!["第一章12", "第一章", "12"]
    );
    assert_eq!(
        regex_rule::get_elements("a1 b2", &[r"([a-z])(\d)"]),
        vec![vec!["a1", "a", "1"], vec!["b2", "b", "2"]]
    );
    assert!(regex_rule::get_elements("无匹配", &[r"(\d+)"]).is_empty());
}

#[test]
#[serial(js_cache)]
fn offline_js_values_cache_base64_and_aes_are_stable() {
    js_engine::reset_cache().unwrap();
    assert_eq!(
        js_engine::run_with_result_as_string("['甲', '乙']", "", "", "https://fixture.example/")
            .unwrap(),
        "甲,乙"
    );
    assert_eq!(
        js_engine::run_with_result_as_string("({name:'书'})", "", "", "https://fixture.example/")
            .unwrap(),
        "[object Object]"
    );
    assert_eq!(
        js_engine::run_with_result("null", "", "", "https://fixture.example/").unwrap(),
        ""
    );
    assert_eq!(
        js_engine::run_with_result("undefined", "", "", "https://fixture.example/").unwrap(),
        ""
    );
    assert_eq!(
        js_engine::run_with_result("base64Decode('SGk=')", "", "", "https://fixture.example/")
            .unwrap(),
        "Hi"
    );
    assert_eq!(
        js_engine::run_with_result(
            "cache.putMemory('fixture-key','fixture-value'); cache.getFromMemory('fixture-key')",
            "",
            "",
            "https://fixture.example/",
        )
        .unwrap(),
        "fixture-value"
    );
    let encrypted = js_engine::run_with_result(
        "var c=java.createSymmetricCrypto('AES/CBC/PKCS5Padding','12345678901234567890123456789012','1234567890123456'); c.encryptBase64('fixture')",
        "",
        "",
        "https://fixture.example/",
    )
    .unwrap();
    assert_eq!(
        js_engine::run_with_result(
            &format!("var c=java.createSymmetricCrypto('AES/CBC/PKCS5Padding','12345678901234567890123456789012','1234567890123456'); c.decryptStr('{}')", encrypted),
            "",
            "",
            "https://fixture.example/",
        )
        .unwrap(),
        "fixture"
    );
}
