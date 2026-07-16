//! RSS API — 对齐 Jingshiro model/rss/Rss.kt

use crate::rule::rss_parser::{self, RssArticleItem};

pub(crate) async fn get_rss_articles(
    source_json: &str,
    sort_url: &str,
    sort_name: &str,
    page: i32,
) -> Result<(Vec<RssArticleItem>, Option<String>), String> {
    rss_parser::get_articles(source_json, sort_url, sort_name, page).await
}

pub(crate) async fn get_rss_content(
    source_json: &str,
    article_link: &str,
) -> Result<String, String> {
    rss_parser::get_content(source_json, article_link).await
}
