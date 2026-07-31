use crate::api::{AppError, NoteDto};
use crate::db;
use serde_json::Value;

fn map_database_error<T>(result: Result<T, String>) -> Result<T, AppError> {
    result.map_err(AppError::Database)
}

fn parse_note_json(raw: &str) -> Result<NoteDto, AppError> {
    let v: Value = serde_json::from_str(raw).map_err(|e| AppError::Parse(e.to_string()))?;
    Ok(NoteDto {
        id: v
            .get("id")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        book_id: v
            .get("bookId")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        chapter_title: v
            .get("chapterTitle")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        selected_text: v
            .get("selectedText")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        note_content: v
            .get("noteContent")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
        position: v.get("position").and_then(|x| x.as_i64()).unwrap_or(0) as i32,
        chapter_pos: v.get("chapterPos").and_then(|x| x.as_i64()).unwrap_or(-1) as i32,
        created_at: v
            .get("createdAt")
            .and_then(|x| x.as_str())
            .unwrap_or_default()
            .to_string(),
    })
}

pub fn upsert_note(
    id: &str,
    book_id: &str,
    chapter_title: &str,
    selected_text: &str,
    note_content: &str,
    position: i32,
    chapter_pos: i32,
) -> Result<(), AppError> {
    map_database_error(db::db_upsert_note(
        id.to_string(),
        book_id.to_string(),
        chapter_title.to_string(),
        selected_text.to_string(),
        note_content.to_string(),
        position,
        chapter_pos,
    ))
}

pub fn delete_note(id: &str) -> Result<(), AppError> {
    map_database_error(db::db_delete_note(id.to_string()))
}

pub fn list_notes(book_id: String) -> Result<Vec<NoteDto>, AppError> {
    let filter = if book_id.is_empty() {
        None
    } else {
        Some(book_id)
    };
    let rows = map_database_error(db::db_list_notes(filter))?;
    rows.iter().map(|s| parse_note_json(s)).collect()
}

pub fn export_notes_markdown(book_id: String) -> Result<String, AppError> {
    let filter = if book_id.is_empty() {
        None
    } else {
        Some(book_id)
    };
    map_database_error(db::db_export_notes_markdown(filter))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn note_json_mapping_preserves_utf16_positions() {
        let note = parse_note_json(
            r#"{"id":"n1","bookId":"b1","chapterTitle":"第一章","selectedText":"选中","noteContent":"想法","position":12,"chapterPos":34,"createdAt":"2026-08-01"}"#,
        )
        .unwrap();

        assert_eq!(note.id, "n1");
        assert_eq!(note.book_id, "b1");
        assert_eq!(note.position, 12);
        assert_eq!(note.chapter_pos, 34);
    }

    #[test]
    fn note_storage_error_is_database_and_preserves_text() {
        let message = "数据库未初始化".to_string();
        let error = map_database_error::<()>(Err(message.clone())).expect_err("must fail");

        assert!(matches!(error, AppError::Database(ref value) if value == &message));
        assert_eq!(error.to_string(), format!("database: {message}"));
    }

    #[test]
    fn invalid_note_json_is_parse_error() {
        let raw = "not json";
        let expected = serde_json::from_str::<Value>(raw).unwrap_err().to_string();

        let error = parse_note_json(raw).unwrap_err();

        assert!(matches!(error, AppError::Parse(value) if value == expected));
    }
}
