//! Phase 3.1 功能对齐验证（离线，无需网络）
//! 对照 REFACTOR_PLAN.md §3.1 矩阵

use legado_engine::http::analyze_url::resolve_search_request;
use legado_engine::model::book_source::BookSource;
use legado_engine::rule::{
    html_book_info, html_content, html_search, html_toc, json_content, replace_regex,
};

const HTML_SOURCE: &str = r###"{
    "bookSourceUrl": "http://test.example.com/",
    "searchUrl": "http://test.example.com/search?key={{key}}",
    "ruleSearch": {
        "bookList": ".item",
        "name": ".name@text",
        "author": ".author@text",
        "bookUrl": "a@href",
        "coverUrl": "img@src"
    },
    "ruleBookInfo": {
        "name": "h1@text",
        "author": ".author@text",
        "coverUrl": "img.cover@src",
        "intro": ".intro@text",
        "lastChapter": ".latest@text",
        "tocUrl": "a.read@href"
    },
    "ruleToc": {
        "chapterList": ".chapter-list li",
        "chapterName": "a@text",
        "chapterUrl": "a@href",
        "nextTocUrl": "a.next@href"
    },
    "ruleContent": {
        "content": "#content@text",
        "nextContentUrl": "a.next@href",
        "replaceRegex": "##广告##\n##\\n{3,}##\\n\\n"
    }
}"###;

const JSON_SOURCE: &str = r##"{
    "bookSourceUrl": "http://api.example.com/",
    "searchUrl": "http://api.example.com/search?q={{key}}",
    "ruleSearchUrl": "http://api.example.com/search?q={{key}}",
    "ruleSearch": {
        "bookList": "$.data[*]",
        "name": "$.title",
        "author": "$.author",
        "bookUrl": "$.url"
    },
    "ruleToc": {
        "chapterList": "$.chapters[*]",
        "chapterName": "$.name",
        "chapterUrl": "$.url"
    },
    "ruleContent": {
        "content": "$.data.content",
        "content": "<js>result.replace(/<[^>]+>/g,'')</js>"
    }
}"##;

fn html_source() -> BookSource {
    BookSource::from_json(HTML_SOURCE).expect("html source")
}

#[test]
fn phase3_html_search() {
    let html = r#"
    <html><body>
      <div class="item">
        <div class="name"><a href="/book/1">斗破苍穹</a></div>
        <div class="author">天蚕土豆</div>
        <img src="/cover/1.jpg"/>
      </div>
    </body></html>
    "#;
    let results = html_search::parse_html_search(html, &html_source()).unwrap();
    assert!(!results.is_empty(), "HTML 搜索应 ≥ 1 条");
    assert_eq!(results[0].name, "斗破苍穹");
}

#[test]
fn phase3_json_search() {
    let source = BookSource::from_json(
        r##"{
        "bookSourceUrl": "http://api.example.com/",
        "ruleSearch": {
            "bookList": "$.data[*]",
            "name": "$.title",
            "author": "$.author",
            "bookUrl": "$.url"
        }
    }"##,
    )
    .unwrap();
    let data: serde_json::Value = serde_json::json!({
        "data": [{ "title": "斗罗大陆", "author": "唐家三少", "url": "/b/1" }]
    });
    let results = legado_engine::rule::json_search::parse_json_search(&data, &source).unwrap();
    assert!(!results.is_empty(), "JSON 搜索应 ≥ 1 条");
}

#[test]
fn phase3_at_js_search_url() {
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
fn phase3_book_info_cover_intro_last_chapter() {
    let html = r#"
    <html><body>
      <h1>斗破苍穹</h1>
      <div class="author">天蚕土豆</div>
      <div class="intro">玄幻巨著</div>
      <div class="latest">第100章</div>
      <img class="cover" src="/cover/1.jpg"/>
      <a class="read" href="/book/1/toc">目录</a>
    </body></html>
    "#;
    let info = html_book_info::parse_html_book_info(html, &html_source()).unwrap();
    assert!(!info.name.is_empty());
    assert!(!info.cover_url.is_empty(), "封面");
    assert!(!info.intro.is_empty(), "简介");
    assert!(!info.last_chapter.is_empty(), "最新章节");
}

#[test]
fn phase3_html_toc_at_least_10() {
    let mut items = String::new();
    for i in 1..=12 {
        items.push_str(&format!(r#"<li><a href="/c/{i}">第{i}章</a></li>"#));
    }
    let html = format!(r#"<html><body><ul class="chapter-list">{items}</ul></body></html>"#);
    let chapters = html_toc::parse_html_toc(&html, &html_source()).unwrap();
    assert!(chapters.len() >= 10, "HTML 目录应 ≥ 10 章");
}

#[test]
fn phase3_json_toc() {
    let source = BookSource::from_json(JSON_SOURCE).unwrap();
    let data: serde_json::Value = serde_json::json!({
        "chapters": [
            { "name": "第一章", "url": "/1" },
            { "name": "第二章", "url": "/2" }
        ]
    });
    let chapters =
        legado_engine::rule::json_toc::parse_json_toc(&data, &source, "http://api.example.com/")
            .unwrap();
    assert_eq!(chapters.len(), 2);
}

#[test]
fn phase3_toc_pagination_next_url() {
    let source = html_source();
    let html = r#"<html><body><a class="next" href="http://test.example.com/toc?page=2">下一页</a></body></html>"#;
    let next = html_toc::extract_next_toc_url(html, &source, "http://test.example.com/toc");
    assert_eq!(next, "http://test.example.com/toc?page=2");
}

#[test]
fn phase3_html_content_non_empty() {
    let html = r#"<html><body><div id="content">正文内容</div></body></html>"#;
    let content = html_content::parse_html_content(html, &html_source()).unwrap();
    assert!(!content.is_empty());
}

#[test]
fn phase3_json_content() {
    let raw = include_str!("../../../assets/builtin_sources/7497.json");
    let json = raw.trim_start_matches('\u{feff}');
    let source = if json.starts_with('[') {
        let arr: Vec<serde_json::Value> = serde_json::from_str(json).unwrap();
        BookSource::from_json(&arr[0].to_string()).unwrap()
    } else {
        BookSource::from_json(json).unwrap()
    };
    let data: serde_json::Value = serde_json::json!({
        "data": { "content": "<p>段落一</p><p>段落二</p>" }
    });
    let content = json_content::parse_json_content(&data, &source).unwrap();
    assert!(content.contains("段落一"));
    assert!(!content.contains("<p>"));
}

#[test]
fn phase3_content_pagination_next_url() {
    let source = html_source();
    let html = r#"<html><body><a class="next" href="http://test.example.com/ch/2">下一页</a></body></html>"#;
    let next = html_content::extract_next_content_url(
        html,
        &source,
        "http://test.example.com/ch/1",
        "http://test.example.com/ch/1",
    );
    assert_eq!(next, "http://test.example.com/ch/2");
}

#[test]
fn phase3_replace_regex_in_content() {
    let source = html_source();
    let html = r#"<html><body><div id="content">正文广告


更多内容</div></body></html>"#;
    let content = html_content::parse_html_content(html, &source).unwrap();
    assert!(!content.contains("广告"));
    assert!(content.contains("更多内容"));
}

#[test]
fn phase3_js_content_clean() {
    let raw = include_str!("../../../assets/builtin_sources/7497.json");
    let json = raw.trim_start_matches('\u{feff}');
    let source = if json.starts_with('[') {
        let arr: Vec<serde_json::Value> = serde_json::from_str(json).unwrap();
        BookSource::from_json(&arr[0].to_string()).unwrap()
    } else {
        BookSource::from_json(json).unwrap()
    };
    let _ = legado_engine::rule::js_engine::reset_cache();
    let data: serde_json::Value = serde_json::json!({
        "data": { "content": "<p>JS清洗测试</p>" }
    });
    let content = json_content::parse_json_content(&data, &source).unwrap();
    assert!(content.contains("JS清洗测试"));
    assert!(!content.contains("<p>"));
}

#[test]
fn phase3_replace_regex_unit() {
    let out = replace_regex::apply_replace_regex("正文广告", "##广告##");
    assert_eq!(out, "正文");
}
