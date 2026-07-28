pub mod backup;
pub mod book_info;
pub mod content;
pub mod db;
pub mod debug;
pub mod explore;
pub mod local_book;
pub mod network;
pub mod read_record;
pub mod rss;
pub mod search;
pub mod toc;
pub mod validate;
pub mod webdav;

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

/// 书源校验结果
#[derive(Debug, Clone)]
pub struct SourceValidation {
    pub search_ok: bool,
    pub discovery_ok: bool,
    pub toc_ok: bool,
    pub content_ok: bool,
    pub search_time_ms: u64,
    pub errors: Vec<String>,
}

/// 本地书籍章节（含正文）
#[derive(Debug, Clone)]
pub struct LocalChapterItem {
    pub title: String,
    pub content: String,
}

/// EPUB 解析结果
#[derive(Debug, Clone)]
pub struct LocalBookInfo {
    pub title: String,
    pub author: String,
    pub chapters: Vec<LocalChapterItem>,
}

/// 单日阅读统计
#[derive(Debug, Clone)]
pub struct DailyReadingStat {
    pub date: String,
    pub chars: i32,
    pub duration_seconds: i32,
}

/// 阅读统计汇总
#[derive(Debug, Clone)]
pub struct ReadingStats {
    pub total_chars: i32,
    pub total_duration_seconds: i32,
    pub today_chars: i32,
    pub today_duration_seconds: i32,
    pub week_chars: i32,
    pub daily: Vec<DailyReadingStat>,
}

/// 单本书阅读统计
#[derive(Debug, Clone)]
pub struct BookReadingStats {
    pub duration_seconds: i32,
    pub read_chars: i32,
    pub start_date: Option<String>,
    pub last_date: Option<String>,
    pub reading_days: i32,
}

/// 想法笔记
#[derive(Debug, Clone)]
pub struct NoteDto {
    pub id: String,
    pub book_id: String,
    pub chapter_title: String,
    pub selected_text: String,
    pub note_content: String,
    pub position: i32,
    /// 章内字符偏移（对齐 Jingshiro Bookmark.chapterPos）；-1=未知
    pub chapter_pos: i32,
    pub created_at: String,
}

/// 独立书签实体；字段对齐 Jingshiro Bookmark
#[derive(Debug, Clone)]
pub struct BookmarkDto {
    pub time: i64,
    pub book_id: String,
    pub book_name: String,
    pub book_author: String,
    pub chapter_index: i32,
    pub chapter_pos: i32,
    pub chapter_name: String,
    pub book_text: String,
    pub content: String,
}

/// 引擎版本号
#[frb(sync)]
pub fn engine_version() -> String {
    "0.5.6".to_string()
}

/// Web API 运行状态
#[derive(Debug, Clone)]
pub struct WebApiStatus {
    pub running: bool,
    pub port: i32,
    pub token: String,
    pub base_url: String,
}

/// 规则调试步骤
#[derive(Debug, Clone)]
pub struct RuleDebugStep {
    pub step: String,
    pub rule: String,
    pub result: String,
    pub ok: bool,
}

/// 调试结果条目（搜索书 / 目录章）
#[derive(Debug, Clone)]
pub struct DebugItem {
    pub name: String,
    pub author: String,
    pub cover_url: String,
    pub book_url: String,
    pub kind: String,
    pub note: String,
}

/// 书源调试结果
#[derive(Debug, Clone)]
pub struct DebugResult {
    pub request_url: String,
    pub request_method: String,
    pub response_status: String,
    pub response_charset: String,
    pub response_size: i32,
    pub response_body_preview: String,
    pub rule_steps: Vec<RuleDebugStep>,
    pub results: Vec<DebugItem>,
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
    pub is_volume: bool,
    pub is_vip: bool,
    pub is_pay: bool,
    pub tag: String,
    pub base_url: String,
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

/// 书源校验（搜索 / 发现 / 目录 / 正文）
#[frb]
pub async fn validate_source(
    source_json: String,
    keyword: String,
) -> Result<SourceValidation, String> {
    validate::validate_source(&source_json, &keyword).await
}

/// 分步调试搜索
#[frb]
pub async fn debug_search(source_json: String, keyword: String) -> Result<DebugResult, String> {
    debug::debug_search(&source_json, &keyword).await
}

/// 分步调试目录
#[frb]
pub async fn debug_toc(source_json: String, book_url: String) -> Result<DebugResult, String> {
    debug::debug_toc(&source_json, &book_url).await
}

/// 启动 Web API 服务
#[frb]
pub async fn start_web_api(port: i32, token: String) -> Result<WebApiStatus, String> {
    crate::web_server::start_web_api(port, token).await
}

/// 停止 Web API 服务
#[frb]
pub async fn stop_web_api() -> Result<(), String> {
    crate::web_server::stop_web_api().await
}

/// Web API 运行状态
#[frb(sync)]
pub fn web_api_status() -> WebApiStatus {
    crate::web_server::web_api_status()
}

/// TXT 分章
#[frb(sync)]
pub fn parse_txt_chapters(content: String) -> Vec<LocalChapterItem> {
    local_book::parse_txt_chapters(&content)
}

/// EPUB 解析
#[frb(sync)]
pub fn parse_epub(data: Vec<u8>) -> Result<LocalBookInfo, String> {
    local_book::parse_epub(&data)
}

/// 记录阅读（按书 + 日期累加）
#[frb(sync)]
pub fn record_reading(
    book_id: String,
    book_name: String,
    chars: i32,
    duration_seconds: i32,
) -> Result<(), String> {
    read_record::record_reading(&book_id, &book_name, chars, duration_seconds)
}

/// 阅读统计（range: week / month / year）
#[frb(sync)]
pub fn get_reading_stats(range: String) -> Result<ReadingStats, String> {
    read_record::get_reading_stats(&range)
}

/// 导出阅读记录（csv / json）
#[frb(sync)]
pub fn export_reading_records(format: String) -> Result<String, String> {
    read_record::export_reading_records(&format)
}

/// 写入详细阅读会话
#[frb(sync)]
pub fn record_detailed_read_session(
    book_name: String,
    start_time: i64,
    end_time: i64,
    read_iteration: i64,
) -> Result<(), String> {
    read_record::record_detailed_read_session(&book_name, start_time, end_time, read_iteration)
}

/// 导出详细阅读会话
#[frb(sync)]
pub fn export_detailed_read_records() -> Result<String, String> {
    read_record::export_detailed_read_records()
}

/// 单本书阅读统计（阅读小票）
#[frb(sync)]
pub fn get_book_reading_stats(book_id: String) -> Result<BookReadingStats, String> {
    read_record::get_book_reading_stats(&book_id)
}

/// 保存想法笔记
#[frb(sync)]
pub fn upsert_note(
    id: String,
    book_id: String,
    chapter_title: String,
    selected_text: String,
    note_content: String,
    position: i32,
    chapter_pos: i32,
) -> Result<(), String> {
    crate::notes_store::upsert_note(
        &id,
        &book_id,
        &chapter_title,
        &selected_text,
        &note_content,
        position,
        chapter_pos,
    )
}

/// 删除想法笔记
#[frb(sync)]
pub fn delete_note(id: String) -> Result<(), String> {
    crate::notes_store::delete_note(&id)
}

/// 列出想法笔记（book_id 为空则全部）
#[frb(sync)]
pub fn list_notes(book_id: String) -> Result<Vec<NoteDto>, String> {
    crate::notes_store::list_notes(book_id)
}

/// 导出 Obsidian 风格 Markdown
#[frb(sync)]
pub fn export_notes_markdown(book_id: String) -> Result<String, String> {
    crate::notes_store::export_notes_markdown(book_id)
}

/// 保存独立书签；time 对齐原版 Bookmark 主键
#[frb(sync)]
pub fn upsert_bookmark(
    time: i64,
    book_id: String,
    book_name: String,
    book_author: String,
    chapter_index: i32,
    chapter_pos: i32,
    chapter_name: String,
    book_text: String,
    content: String,
) -> Result<(), String> {
    crate::bookmarks_store::upsert_bookmark(
        time,
        &book_id,
        &book_name,
        &book_author,
        chapter_index,
        chapter_pos,
        &chapter_name,
        &book_text,
        &content,
    )
}

/// 删除独立书签
#[frb(sync)]
pub fn delete_bookmark(time: i64) -> Result<(), String> {
    crate::bookmarks_store::delete_bookmark(time)
}

/// 列出独立书签；book_id 为空则全部
#[frb(sync)]
pub fn list_bookmarks(book_id: String) -> Result<Vec<BookmarkDto>, String> {
    crate::bookmarks_store::list_bookmarks(book_id)
}

/// 执行裸 JS（登录 UI / loginUrl / 按钮脚本）
#[frb(sync)]
pub fn eval_js(script: String, js_lib: String, base_url: String) -> Result<String, String> {
    crate::rule::js_engine::run_eval_script(&script, &js_lib, &base_url)
}

/// 预热 Rust 登录头缓存（Dart SharedPreferences → 引擎）
#[frb(sync)]
pub fn seed_login_header(source_url: String, header: String) -> Result<(), String> {
    crate::http::login_header_store::seed(&source_url, &header);
    Ok(())
}

/// 取出 loginCheckJs 新写入的登录头（JSON: url → header），供 Dart 回写 prefs
#[frb(sync)]
pub fn drain_login_header_updates() -> String {
    crate::http::login_header_store::drain_dirty_json()
}

/// RSS 文章 DTO
#[derive(Debug, Clone)]
pub struct RssArticleDto {
    pub title: String,
    pub link: String,
    pub pub_date: String,
    pub description: String,
    pub content: String,
    pub image: String,
    pub origin: String,
    pub sort: String,
}

/// RSS 列表结果
#[derive(Debug, Clone)]
pub struct RssArticlesResult {
    pub articles: Vec<RssArticleDto>,
    pub next_url: Option<String>,
}

/// 获取 RSS 文章列表 — 对齐 Jingshiro Rss.getArticlesAwait
#[frb]
pub async fn get_rss_articles(
    source_json: String,
    sort_url: String,
    sort_name: String,
    page: i32,
) -> Result<RssArticlesResult, String> {
    let (articles, next_url) =
        rss::get_rss_articles(&source_json, &sort_url, &sort_name, page).await?;
    Ok(RssArticlesResult {
        articles: articles
            .into_iter()
            .map(|a| RssArticleDto {
                title: a.title,
                link: a.link,
                pub_date: a.pub_date,
                description: a.description,
                content: a.content,
                image: a.image,
                origin: a.origin,
                sort: a.sort,
            })
            .collect(),
        next_url,
    })
}

/// 获取 RSS 正文 — 对齐 Jingshiro Rss.getContentAwait
#[frb]
pub async fn get_rss_content(source_json: String, article_link: String) -> Result<String, String> {
    rss::get_rss_content(&source_json, &article_link).await
}

pub use db::{
    db_clear_replace_rules, db_delete_book, db_delete_replace_rule, db_delete_source, db_get_books,
    db_get_chapters, db_get_replace_rules, db_get_sources, db_init, db_insert_book,
    db_insert_chapters, db_probe_legacy_room_database, db_save_chapter_content, db_schema_version,
    db_toggle_replace_rule, db_toggle_source, db_update_book_cover, db_update_book_group,
    db_update_book_progress, db_upsert_replace_rule, db_upsert_source,
};

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
