use crate::api::{AppError, BookmarkDto};
use crate::db;
use serde_json::Value;

fn map_database_error<T>(result: Result<T, String>) -> Result<T, AppError> {
    result.map_err(AppError::Database)
}

fn parse_bookmark_json(raw: &str) -> Result<BookmarkDto, AppError> {
    let v: Value = serde_json::from_str(raw).map_err(|e| AppError::Parse(e.to_string()))?;
    Ok(BookmarkDto {
        time: v.get("time").and_then(|x| x.as_i64()).unwrap_or(0),
        book_id: v
            .get("bookId")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_name: v
            .get("bookName")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_author: v
            .get("bookAuthor")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        chapter_index: v.get("chapterIndex").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
        chapter_pos: v.get("chapterPos").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
        chapter_name: v
            .get("chapterName")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_text: v
            .get("bookText")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        content: v
            .get("content")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
    })
}

pub fn upsert_bookmark(
    time: i64,
    book_id: &str,
    book_name: &str,
    book_author: &str,
    chapter_index: i32,
    chapter_pos: i32,
    chapter_name: &str,
    book_text: &str,
    content: &str,
) -> Result<(), AppError> {
    map_database_error(db::db_upsert_bookmark(
        time,
        book_id.to_string(),
        book_name.to_string(),
        book_author.to_string(),
        chapter_index,
        chapter_pos,
        chapter_name.to_string(),
        book_text.to_string(),
        content.to_string(),
    ))
}

pub fn delete_bookmark(time: i64) -> Result<(), AppError> {
    map_database_error(db::db_delete_bookmark(time))
}

pub fn list_bookmarks(book_id: String) -> Result<Vec<BookmarkDto>, AppError> {
    let filter = if book_id.is_empty() {
        None
    } else {
        Some(book_id)
    };
    map_database_error(db::db_list_bookmarks(filter))
        .and_then(|rows| rows.iter().map(|s| parse_bookmark_json(s)).collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bookmark_json_mapping_preserves_position_fields() {
        let bookmark = parse_bookmark_json(
            r#"{"time":123,"bookId":"b1","bookName":"测试书","bookAuthor":"作者","chapterIndex":7,"chapterPos":89,"chapterName":"第八章","bookText":"正文","content":"备注"}"#,
        )
        .unwrap();

        assert_eq!(bookmark.time, 123);
        assert_eq!(bookmark.book_id, "b1");
        assert_eq!(bookmark.chapter_index, 7);
        assert_eq!(bookmark.chapter_pos, 89);
        assert_eq!(bookmark.book_text, "正文");
        assert_eq!(bookmark.content, "备注");
    }

    #[test]
    fn bookmark_storage_error_is_database_and_preserves_text() {
        let message = "数据库锁失败".to_string();
        let error = map_database_error::<()>(Err(message.clone())).expect_err("must fail");

        assert!(matches!(error, AppError::Database(ref value) if value == &message));
        assert_eq!(error.to_string(), format!("database: {message}"));
    }

    #[test]
    fn invalid_bookmark_json_is_parse_error() {
        let raw = "not json";
        let expected = serde_json::from_str::<Value>(raw).unwrap_err().to_string();

        let error = parse_bookmark_json(raw).unwrap_err();

        assert!(matches!(error, AppError::Parse(value) if value == expected));
    }
}
