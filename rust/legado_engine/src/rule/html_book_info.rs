use crate::model::book_source::BookSource;
use crate::rule::{engine, js_engine};
use scraper::{Html, Selector};

/// 书籍详情（内部）
#[derive(Debug, Clone, Default)]
pub struct HtmlBookInfo {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub intro: String,
    pub kind: String,
    pub last_chapter: String,
    pub toc_url: String,
}

pub fn parse_html_book_info(html: &str, source: &BookSource) -> Result<HtmlBookInfo, String> {
    parse_html_book_info_at(html, source, "")
}

/// `book_url` 供 tocUrl 等 `<js>` 使用（注入 `baseUrl` / `book.bookUrl`）
pub fn parse_html_book_info_at(
    html: &str,
    source: &BookSource,
    book_url: &str,
) -> Result<HtmlBookInfo, String> {
    let document = Html::parse_document(html);
    let body = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body 元素")?;

    let base = if book_url.is_empty() {
        source.book_source_url.as_str()
    } else {
        book_url
    };
    let js_lib = source.js_lib.as_str();

    Ok(HtmlBookInfo {
        name: engine::extract_text(&body, &source.rule_book_info_name),
        author: engine::extract_text(&body, &source.rule_book_info_author),
        cover_url: engine::extract_attr(&body, &source.rule_book_info_cover_url, "src"),
        intro: engine::extract_text(&body, &source.rule_book_info_intro),
        kind: engine::extract_text(&body, &source.rule_book_info_kind),
        last_chapter: engine::extract_text(&body, &source.rule_book_info_last_chapter),
        toc_url: resolve_toc_url_field(
            html,
            &body,
            &source.rule_book_info_toc_url,
            js_lib,
            base,
            book_url,
        ),
    })
}

fn resolve_toc_url_field(
    html: &str,
    body: &scraper::ElementRef<'_>,
    rule: &str,
    js_lib: &str,
    base_url: &str,
    book_url: &str,
) -> String {
    let rule = rule.trim();
    if rule.is_empty() {
        return String::new();
    }
    if js_engine::contains_js_block(rule) {
        if let Some(script) = js_engine::extract_js_block(rule) {
            let bu = if book_url.is_empty() {
                base_url
            } else {
                book_url
            };
            if let Ok(out) =
                js_engine::run_with_result_opts(&script, html, js_lib, bu, Some(bu))
            {
                let out = out.trim().to_string();
                if !out.is_empty() && out != "null" && out != "undefined" {
                    return out;
                }
            }
        }
        return String::new();
    }
    let mut url = engine::extract_attr(body, rule, "href");
    if url.is_empty() {
        url = engine::extract_text(body, rule);
    }
    url
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn toc_url_js_replaces_book_with_chapter() {
        let source_json = r##"{
            "bookSourceUrl": "https://www.rrssk.com/",
            "ruleBookInfo": {
                "name": "meta[property=og:novel:book_name]@content",
                "tocUrl": "<js>var tocUrl=baseUrl.replace('/book/','/chapter/');tocUrl</js>"
            }
        }"##;
        let html = r#"<html><head>
<meta property="og:novel:book_name" content="测试书"/>
</head><body></body></html>"#;
        let source = BookSource::from_json(source_json).unwrap();
        let info = parse_html_book_info_at(
            html,
            &source,
            "https://www.kelexs.com/book/AIJGIFF.html",
        )
        .unwrap();
        assert_eq!(info.toc_url, "https://www.kelexs.com/chapter/AIJGIFF.html");
    }
}
