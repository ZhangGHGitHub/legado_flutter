use super::AppError;
use crate::db;

fn map_database_error<T>(result: Result<T, String>) -> Result<T, AppError> {
    result.map_err(AppError::Database)
}

/// 初始化应用数据目录下固定的 `legado.db`。
#[flutter_rust_bridge::frb(sync)]
pub fn init(app_dir: String) -> Result<(), AppError> {
    db::init(&app_dir).map_err(|error| AppError::Database(error.to_string()))
}

/// 初始化数据库（与 Flutter `legado.db` 同路径）
#[flutter_rust_bridge::frb(sync)]
pub fn db_init(path: String) -> Result<(), AppError> {
    map_database_error(db::db_init(path))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_schema_version() -> Result<i32, AppError> {
    map_database_error(db::db_schema_version())
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_probe_legacy_room_database(path: String) -> Result<String, AppError> {
    map_database_error(db::db_probe_legacy_room_database(path))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_import_legacy_room_database(
    path: String,
    backup_path: Option<String>,
    replace: bool,
) -> Result<String, AppError> {
    map_database_error(db::db_import_legacy_room_database(
        path,
        backup_path,
        replace,
    ))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_insert_book(book_json: String) -> Result<(), AppError> {
    map_database_error(db::db_insert_book(book_json))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_books() -> Result<Vec<String>, AppError> {
    map_database_error(db::db_get_books())
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_delete_book(book_id: String) -> Result<(), AppError> {
    map_database_error(db::db_delete_book(book_id))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_update_book_progress(
    book_id: String,
    progress: f64,
    chapter: Option<String>,
    page_index: i32,
) -> Result<(), AppError> {
    map_database_error(db::db_update_book_progress(
        book_id, progress, chapter, page_index,
    ))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_update_book_cover(book_id: String, cover_url: String) -> Result<(), AppError> {
    map_database_error(db::db_update_book_cover(book_id, cover_url))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_update_book_details(
    book_id: String,
    name: String,
    author: String,
    description: String,
) -> Result<(), AppError> {
    map_database_error(db::db_update_book_details(
        book_id,
        name,
        author,
        description,
    ))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_update_book_group(book_id: String, group: String) -> Result<(), AppError> {
    map_database_error(db::db_update_book_group(book_id, group))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_upsert_source(source_json: String) -> Result<(), AppError> {
    map_database_error(db::db_upsert_source(source_json))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_sources(enabled_only: bool) -> Result<Vec<String>, AppError> {
    map_database_error(db::db_get_sources(enabled_only))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_toggle_source(url: String, enabled: bool) -> Result<(), AppError> {
    map_database_error(db::db_toggle_source(url, enabled))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_delete_source(url: String) -> Result<(), AppError> {
    map_database_error(db::db_delete_source(url))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_insert_chapters(chapters_json: String) -> Result<(), AppError> {
    map_database_error(db::db_insert_chapters(chapters_json))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_chapters(book_id: String) -> Result<Vec<String>, AppError> {
    map_database_error(db::db_get_chapters(book_id))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_chapter_content(chapter_id: String) -> Result<Option<String>, AppError> {
    map_database_error(db::db_get_chapter_content(chapter_id))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_save_chapter_content(chapter_id: String, content: String) -> Result<(), AppError> {
    map_database_error(db::db_save_chapter_content(chapter_id, content))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_upsert_replace_rule(rule_json: String) -> Result<(), AppError> {
    map_database_error(db::db_upsert_replace_rule(rule_json))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_get_replace_rules() -> Result<Vec<String>, AppError> {
    map_database_error(db::db_get_replace_rules())
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_toggle_replace_rule(id: String, enabled: bool) -> Result<(), AppError> {
    map_database_error(db::db_toggle_replace_rule(id, enabled))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_delete_replace_rule(id: String) -> Result<(), AppError> {
    map_database_error(db::db_delete_replace_rule(id))
}

#[flutter_rust_bridge::frb(sync)]
pub fn db_clear_replace_rules() -> Result<(), AppError> {
    map_database_error(db::db_clear_replace_rules())
}

#[cfg(test)]
mod tests {
    use super::{init, map_database_error, AppError};

    #[test]
    fn init_maps_invalid_app_directory_to_database_error() {
        let error = init("  ".to_string()).expect_err("empty app directory must fail");

        assert!(matches!(error, AppError::Database(message) if message.contains("不能为空")));
    }

    #[test]
    fn preserves_database_error_text_and_classification() {
        let message = "sqlite: UNIQUE constraint failed: books.bookUrl".to_string();

        let error = map_database_error::<()>(Err(message.clone())).expect_err("must fail");

        assert!(matches!(error, AppError::Database(ref value) if value == &message));
        assert_eq!(error.to_string(), format!("database: {message}"));
    }

    #[test]
    fn preserves_database_success_value() {
        let value = vec!["book-1".to_string(), "book-2".to_string()];

        assert_eq!(map_database_error(Ok(value.clone())).unwrap(), value);
    }
}
