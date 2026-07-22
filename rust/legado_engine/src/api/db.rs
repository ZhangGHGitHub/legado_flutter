use crate::db;

/// 初始化数据库（与 Flutter `legado.db` 同路径）
#[flutter_rust_bridge::frb(sync)]
pub fn db_init(path: String) -> Result<(), String> {
    db::db_init(path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_schema_version() -> Result<i32, String> {
    db::db_schema_version()
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_insert_book(book_json: String) -> Result<(), String> {
    db::db_insert_book(book_json)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_books() -> Result<Vec<String>, String> {
    db::db_get_books()
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_delete_book(book_id: String) -> Result<(), String> {
    db::db_delete_book(book_id)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_update_book_progress(
    book_id: String,
    progress: f64,
    chapter: Option<String>,
    page_index: i32,
) -> Result<(), String> {
    db::db_update_book_progress(book_id, progress, chapter, page_index)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_update_book_cover(book_id: String, cover_url: String) -> Result<(), String> {
    db::db_update_book_cover(book_id, cover_url)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_update_book_group(book_id: String, group: String) -> Result<(), String> {
    db::db_update_book_group(book_id, group)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_upsert_source(source_json: String) -> Result<(), String> {
    db::db_upsert_source(source_json)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_sources(enabled_only: bool) -> Result<Vec<String>, String> {
    db::db_get_sources(enabled_only)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_toggle_source(url: String, enabled: bool) -> Result<(), String> {
    db::db_toggle_source(url, enabled)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_delete_source(url: String) -> Result<(), String> {
    db::db_delete_source(url)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_insert_chapters(chapters_json: String) -> Result<(), String> {
    db::db_insert_chapters(chapters_json)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_chapters(book_id: String) -> Result<Vec<String>, String> {
    db::db_get_chapters(book_id)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_chapter_content(chapter_id: String) -> Result<Option<String>, String> {
    db::db_get_chapter_content(chapter_id)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_save_chapter_content(chapter_id: String, content: String) -> Result<(), String> {
    db::db_save_chapter_content(chapter_id, content)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_upsert_replace_rule(rule_json: String) -> Result<(), String> {
    db::db_upsert_replace_rule(rule_json)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_replace_rules() -> Result<Vec<String>, String> {
    db::db_get_replace_rules()
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_toggle_replace_rule(id: String, enabled: bool) -> Result<(), String> {
    db::db_toggle_replace_rule(id, enabled)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_delete_replace_rule(id: String) -> Result<(), String> {
    db::db_delete_replace_rule(id)
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_clear_replace_rules() -> Result<(), String> {
    db::db_clear_replace_rules()
}
