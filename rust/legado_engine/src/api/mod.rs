pub mod backup;
pub mod book_info;
pub mod content;
pub mod db;
pub mod debug;
pub mod dict;
pub mod error;
pub mod explore;
pub mod local_book;
pub mod network;
pub mod read_record;
pub mod rss;
pub mod search;
pub mod toc;
pub mod validate;
pub mod webdav;

pub use dict::query_dict_rule;

use flutter_rust_bridge::{frb, DartFnFuture};

pub use error::AppError;

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

/// `java.startBrowserAwait` 发往 Flutter 可见 WebView 宿主的请求。
#[derive(Debug, Clone)]
pub struct SourceBrowserRequestDto {
    pub source_key: String,
    pub url: String,
    pub title: String,
    pub html: Option<String>,
    pub headers: std::collections::HashMap<String, String>,
    pub refetch_after_success: bool,
}

/// Flutter WebView 完成验证后返回的最终页面。
#[derive(Debug, Clone)]
pub struct SourceBrowserResponseDto {
    pub final_url: String,
    pub body: String,
}

/// 运行可见 WebView 宿主循环。Flutter 启动后保持此 Future，Rust 后台规则线程按请求等待回调。
pub async fn serve_source_browser_host(
    host: impl Fn(SourceBrowserRequestDto) -> DartFnFuture<anyhow::Result<SourceBrowserResponseDto>>,
) -> Result<(), String> {
    crate::browser_host::serve(host).await
}

/// FRB 回调契约探针；供桥接测试确认 Dart 回调可在 Rust 异步任务等待期间完成。
pub async fn probe_source_browser_host(
    request: SourceBrowserRequestDto,
) -> Result<SourceBrowserResponseDto, String> {
    tokio::task::spawn_blocking(move || crate::browser_host::invoke(request))
        .await
        .map_err(|e| format!("浏览器宿主探针线程失败: {e}"))?
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

/// 远程 ZIP 中可导入的本地书籍文件。
#[derive(Debug, Clone)]
pub struct RemoteArchiveBookFile {
    pub relative_path: String,
    pub bytes: Vec<u8>,
}

/// 正文替换规则 DTO。
#[derive(Debug, Clone)]
pub struct ContentReplaceRuleDto {
    pub id: String,
    pub name: String,
    pub pattern: String,
    pub replacement: String,
    pub is_enabled: bool,
    pub is_regex: bool,
}

/// 书源级正文替换规则 DTO。
#[derive(Debug, Clone)]
pub struct ContentProcessingSourceRulesDto {
    pub content_replace: String,
    pub content_replace_to: String,
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
pub async fn search(source_json: String, keyword: String) -> Result<Vec<SearchItem>, AppError> {
    search::search(&source_json, &keyword)
        .await
        .map_err(AppError::from_legacy)
}

/// 发现页 / 分类页
#[frb]
pub async fn explore(
    source_json: String,
    explore_url: String,
    page: i32,
) -> Result<Vec<SearchItem>, AppError> {
    explore::explore(&source_json, &explore_url, page)
        .await
        .map_err(AppError::from_legacy)
}

/// 获取书籍详情
#[frb]
pub async fn get_book_info(
    source_json: String,
    book_url: String,
) -> Result<BookInfoItem, AppError> {
    book_info::get_book_info(&source_json, &book_url).await
}

/// 获取目录
#[frb]
pub async fn get_toc(source_json: String, book_url: String) -> Result<Vec<ChapterItem>, AppError> {
    toc::get_toc(&source_json, &book_url)
        .await
        .map_err(AppError::from_legacy)
}

/// 获取章节正文
#[frb]
pub async fn get_content(source_json: String, chapter_url: String) -> Result<String, AppError> {
    content::get_content(&source_json, &chapter_url)
        .await
        .map_err(AppError::from_legacy)
}

/// 获取章节正文，并在正文下一页指向下一章时停止。
#[frb]
pub async fn get_content_with_next_chapter(
    source_json: String,
    chapter_url: String,
    next_chapter_url: Option<String>,
) -> Result<String, AppError> {
    content::get_content_with_next_chapter(&source_json, &chapter_url, next_chapter_url.as_deref())
        .await
        .map_err(AppError::from_legacy)
}

/// 书源校验（搜索 / 发现 / 目录 / 正文）
#[frb]
pub async fn validate_source(
    source_json: String,
    keyword: String,
) -> Result<SourceValidation, AppError> {
    validate::validate_source(&source_json, &keyword)
        .await
        .map_err(AppError::from_legacy)
}

/// 分步调试搜索
#[frb]
pub async fn debug_search(source_json: String, keyword: String) -> Result<DebugResult, AppError> {
    debug::debug_search(&source_json, &keyword)
        .await
        .map_err(AppError::from_legacy)
}

/// 分步调试目录
#[frb]
pub async fn debug_toc(source_json: String, book_url: String) -> Result<DebugResult, AppError> {
    debug::debug_toc(&source_json, &book_url)
        .await
        .map_err(AppError::from_legacy)
}

/// TXT 分章
#[frb(sync)]
pub fn parse_txt_chapters(content: String) -> Vec<LocalChapterItem> {
    local_book::parse_txt_chapters(&content)
}

/// EPUB 解析
#[frb(sync)]
pub fn parse_epub(data: Vec<u8>) -> Result<LocalBookInfo, AppError> {
    local_book::parse_epub(&data)
}

/// 安全解析远程 ZIP，并按压缩包顺序返回其中的 TXT/EPUB 文件。
#[frb(sync)]
pub fn parse_remote_archive_book_files(
    data: Vec<u8>,
) -> Result<Vec<RemoteArchiveBookFile>, AppError> {
    local_book::parse_remote_archive_book_files(&data)
}

/// 应用正文替换规则。
#[frb(sync)]
pub fn apply_content_replace_rules(text: String, rules: Vec<ContentReplaceRuleDto>) -> String {
    crate::content_processing::apply_replace_rules(&text, &to_content_rules(rules))
}

/// 应用全局及书源级正文替换规则。
#[frb(sync)]
pub fn process_content(
    text: String,
    rules: Vec<ContentReplaceRuleDto>,
    source_rules: Option<ContentProcessingSourceRulesDto>,
) -> String {
    crate::content_processing::process(
        &text,
        &to_content_rules(rules),
        source_rules
            .as_ref()
            .map(|rules| crate::content_processing::SourceRulesInput {
                content_replace: rules.content_replace.clone(),
                content_replace_to: rules.content_replace_to.clone(),
            })
            .as_ref(),
    )
}

/// 阅读前正文净化处理；不负责分页、断行或章节边界。
#[frb(sync)]
pub fn process_content_for_reading(
    raw: String,
    chapter_title: String,
    book_name: String,
    include_title: bool,
    use_replace: bool,
    paragraph_indent: String,
    re_segment: bool,
    rules: Vec<ContentReplaceRuleDto>,
    source_rules: Option<ContentProcessingSourceRulesDto>,
) -> Result<String, String> {
    crate::content_processing::process_for_reading(crate::content_processing::ReadingProcessInput {
        raw,
        chapter_title,
        book_name,
        include_title,
        use_replace,
        paragraph_indent,
        re_segment,
        rules: to_content_rules(rules),
        source_rules: source_rules.map(|r| crate::content_processing::SourceRulesInput {
            content_replace: r.content_replace,
            content_replace_to: r.content_replace_to,
        }),
    })
}

fn to_content_rules(
    rules: Vec<ContentReplaceRuleDto>,
) -> Vec<crate::content_processing::ReplaceRuleInput> {
    rules
        .into_iter()
        .map(|rule| crate::content_processing::ReplaceRuleInput {
            pattern: rule.pattern,
            replacement: rule.replacement,
            is_enabled: rule.is_enabled,
            is_regex: rule.is_regex,
        })
        .collect()
}

/// 记录阅读（按书 + 日期累加）
#[frb(sync)]
pub fn record_reading(
    book_id: String,
    book_name: String,
    chars: i32,
    duration_seconds: i32,
) -> Result<(), AppError> {
    read_record::record_reading(&book_id, &book_name, chars, duration_seconds)
}

/// 阅读统计（range: week / month / year）
#[frb(sync)]
pub fn get_reading_stats(range: String) -> Result<ReadingStats, AppError> {
    read_record::get_reading_stats(&range)
}

/// 导出阅读记录（csv / json）
#[frb(sync)]
pub fn export_reading_records(format: String) -> Result<String, AppError> {
    read_record::export_reading_records(&format)
}

/// 写入详细阅读会话
#[frb(sync)]
pub fn record_detailed_read_session(
    book_name: String,
    start_time: i64,
    end_time: i64,
    read_iteration: i64,
) -> Result<(), AppError> {
    read_record::record_detailed_read_session(&book_name, start_time, end_time, read_iteration)
}

/// 导出详细阅读会话
#[frb(sync)]
pub fn export_detailed_read_records() -> Result<String, AppError> {
    read_record::export_detailed_read_records()
}

/// 单本书阅读统计（阅读小票）
#[frb(sync)]
pub fn get_book_reading_stats(book_id: String) -> Result<BookReadingStats, AppError> {
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
) -> Result<(), AppError> {
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
pub fn delete_note(id: String) -> Result<(), AppError> {
    crate::notes_store::delete_note(&id)
}

/// 列出想法笔记（book_id 为空则全部）
#[frb(sync)]
pub fn list_notes(book_id: String) -> Result<Vec<NoteDto>, AppError> {
    crate::notes_store::list_notes(book_id)
}

/// 导出 Obsidian 风格 Markdown
#[frb(sync)]
pub fn export_notes_markdown(book_id: String) -> Result<String, AppError> {
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
) -> Result<(), AppError> {
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
pub fn delete_bookmark(time: i64) -> Result<(), AppError> {
    crate::bookmarks_store::delete_bookmark(time)
}

/// 列出独立书签；book_id 为空则全部
#[frb(sync)]
pub fn list_bookmarks(book_id: String) -> Result<Vec<BookmarkDto>, AppError> {
    crate::bookmarks_store::list_bookmarks(book_id)
}

/// 执行裸 JS（登录 UI / loginUrl / 按钮脚本）
#[frb(sync)]
pub fn eval_js(script: String, js_lib: String, base_url: String) -> Result<String, AppError> {
    crate::rule::js_engine::run_eval_script(&script, &js_lib, &base_url)
        .map_err(AppError::JsExecution)
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
) -> Result<RssArticlesResult, AppError> {
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
pub async fn get_rss_content(
    source_json: String,
    article_link: String,
) -> Result<String, AppError> {
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
) -> Result<String, AppError> {
    let source_key = source_url.as_deref().unwrap_or(&url);
    if let Some(rate) = concurrent_rate.as_deref() {
        crate::http::rate_limit::configure(source_key, rate);
    }
    crate::http::rate_limit::wait_if_needed(source_key)
        .await
        .map_err(AppError::Network)?;
    crate::http::client::fetch_text(
        &url,
        &method,
        body.as_deref(),
        &charset,
        referer.as_deref(),
        source_key,
    )
    .await
    .map_err(map_http_fetch_error)
}

fn map_http_fetch_error(message: String) -> AppError {
    if message.starts_with("gzip 解压失败:") || message.starts_with("响应不是 UTF-8:") {
        AppError::Parse(message)
    } else {
        AppError::Network(message)
    }
}

#[cfg(test)]
mod http_fetch_tests {
    use super::{http_fetch, map_http_fetch_error, AppError};

    #[tokio::test]
    async fn http_fetch_maps_ssrf_errors_to_network_without_changing_original_text() {
        let error = http_fetch(
            "file:///private".to_string(),
            "GET".to_string(),
            None,
            "UTF-8".to_string(),
            None,
            None,
            None,
        )
        .await
        .unwrap_err();

        assert!(matches!(
            error,
            AppError::Network(ref message) if message == "仅允许 http/https 请求"
        ));
    }

    #[test]
    fn maps_http_fetch_network_errors_without_changing_original_text() {
        for message in [
            "HTTP 请求失败: 503 Service Unavailable",
            "主机并发闸损坏: example.com:443",
            "SSRF blocked: private address",
        ] {
            let error = map_http_fetch_error(message.to_string());
            assert!(matches!(error, AppError::Network(ref value) if value == message));
        }
    }

    #[test]
    fn maps_http_fetch_decode_errors_to_parse_without_changing_original_text() {
        for message in [
            "gzip 解压失败: unexpected end of file",
            "响应不是 UTF-8: invalid byte",
        ] {
            let error = map_http_fetch_error(message.to_string());
            assert!(matches!(error, AppError::Parse(ref value) if value == message));
        }
    }
}

#[cfg(test)]
mod eval_js_tests {
    use super::{eval_js, AppError};

    #[test]
    fn eval_js_preserves_successful_result() {
        let result = eval_js("'结果:' + (1 + 1)".into(), String::new(), String::new())
            .expect("有效脚本必须返回结果");

        assert_eq!(result, "结果:2");
    }

    #[test]
    fn eval_js_maps_errors_to_js_execution_without_changing_text() {
        let error = eval_js(
            "throw new Error('原始 JS 错误')".into(),
            String::new(),
            String::new(),
        )
        .expect_err("脚本异常必须通过 AppError 返回");

        assert!(matches!(
            error,
            AppError::JsExecution(ref message)
                if message.contains("JS 执行失败") && message.contains("原始 JS 错误")
        ));
    }
}
