use crate::model::book_source::BookSource;
use crate::rule::engine;
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
    let document = Html::parse_document(html);
    let body = document
        .select(&Selector::parse("body").unwrap())
        .next()
        .ok_or("HTML 无 body 元素")?;

    Ok(HtmlBookInfo {
        name: engine::extract_text(&body, &source.rule_book_info_name),
        author: engine::extract_text(&body, &source.rule_book_info_author),
        cover_url: engine::extract_attr(&body, &source.rule_book_info_cover_url, "src"),
        intro: engine::extract_text(&body, &source.rule_book_info_intro),
        kind: engine::extract_text(&body, &source.rule_book_info_kind),
        last_chapter: engine::extract_text(&body, &source.rule_book_info_last_chapter),
        toc_url: {
            let mut url = engine::extract_attr(&body, &source.rule_book_info_toc_url, "href");
            if url.is_empty() {
                url = engine::extract_text(&body, &source.rule_book_info_toc_url);
            }
            url
        },
    })
}
