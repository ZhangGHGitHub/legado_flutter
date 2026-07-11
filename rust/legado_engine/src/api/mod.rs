pub mod book_info;
pub mod content;
pub mod explore;
pub mod search;
pub mod toc;

use flutter_rust_bridge::frb;

/// FRB 默认初始化（日志等）
#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

/// 初始化 Rust 书源引擎
#[frb(sync)]
pub fn init_engine() -> Result<(), String> {
    Ok(())
}

/// 引擎版本号
#[frb(sync)]
pub fn engine_version() -> String {
    "0.4.2".to_string()
}

/// 搜索结果条目
#[derive(Debug, Clone)]
pub struct SearchItem {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub book_url: String,
    pub kind: String,
    pub note: String,
}

/// 目录章节条目
#[derive(Debug, Clone)]
pub struct ChapterItem {
    pub title: String,
    pub url: String,
}

/// 书籍详情
#[derive(Debug, Clone)]
pub struct BookInfoItem {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub intro: String,
    pub kind: String,
    pub last_chapter: String,
    pub toc_url: String,
}

/// 搜索书籍
#[frb]
pub async fn search(source_json: String, keyword: String) -> Result<Vec<SearchItem>, String> {
    search::search(&source_json, &keyword).await
}

/// 发现页 / 分类页
#[frb]
pub async fn explore(
    source_json: String,
    explore_url: String,
    page: i32,
) -> Result<Vec<SearchItem>, String> {
    explore::explore(&source_json, &explore_url, page).await
}

/// 获取书籍详情
#[frb]
pub async fn get_book_info(source_json: String, book_url: String) -> Result<BookInfoItem, String> {
    book_info::get_book_info(&source_json, &book_url).await
}

/// 获取目录
#[frb]
pub async fn get_toc(source_json: String, book_url: String) -> Result<Vec<ChapterItem>, String> {
    toc::get_toc(&source_json, &book_url).await
}

/// 获取章节正文
#[frb]
pub async fn get_content(source_json: String, chapter_url: String) -> Result<String, String> {
    content::get_content(&source_json, &chapter_url).await
}

/// HTTP 请求并返回解码后的文本（调试用）
#[frb]
pub async fn http_fetch(
    url: String,
    method: String,
    body: Option<String>,
    charset: String,
    referer: Option<String>,
    source_url: Option<String>,
    concurrent_rate: Option<String>,
) -> Result<String, String> {
    let source_key = source_url.as_deref().unwrap_or(&url);
    if let Some(rate) = concurrent_rate.as_deref() {
        crate::http::rate_limit::configure(source_key, rate);
    }
    crate::http::rate_limit::wait_if_needed(source_key).await?;
    crate::http::client::fetch_text(
        &url,
        &method,
        body.as_deref(),
        &charset,
        referer.as_deref(),
        source_key,
    )
    .await
}
