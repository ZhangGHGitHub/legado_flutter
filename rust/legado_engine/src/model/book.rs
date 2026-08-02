use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Flutter/domain-facing projection of one persisted Legado book.
///
/// The JSON field names, nullable `currentChapter`, and empty `updatedAt`
/// fallback remain compatible with the existing `db_get_books` FFI result.
#[derive(Debug, Clone, Deserialize, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct BookDto {
    pub id: String,
    pub name: String,
    pub author: String,
    pub cover_url: String,
    #[serde(rename = "type")]
    pub book_type: String,
    pub progress: f64,
    pub current_chapter: Option<String>,
    pub last_chapter: String,
    pub total_chapter_num: i64,
    pub dur_chapter_index: i64,
    pub current_page_index: i64,
    pub read_config: Value,
    pub is_favorite: bool,
    pub source_url: String,
    pub toc_url: String,
    pub description: String,
    pub book_source_url: String,
    pub group: String,
    pub read_iteration: i64,
    pub sim_read_enabled: bool,
    pub sim_read_start_date: String,
    pub sim_read_start_chapter: i64,
    pub sim_read_daily_chapters: i64,
    pub updated_at: String,
}

#[cfg(test)]
mod tests {
    use super::BookDto;
    use serde_json::json;

    #[test]
    fn book_dto_serializes_flutter_database_contract() {
        let dto = BookDto {
            id: "book-1".to_string(),
            name: "测试书".to_string(),
            author: "作者".to_string(),
            cover_url: "https://example.test/cover.jpg".to_string(),
            book_type: "online".to_string(),
            progress: 0.5,
            current_chapter: Some("第十章".to_string()),
            last_chapter: "第二十章".to_string(),
            total_chapter_num: 20,
            dur_chapter_index: 9,
            current_page_index: 123,
            read_config: json!({"reverseToc": true, "pageAnim": 2}),
            is_favorite: true,
            source_url: "https://example.test/book".to_string(),
            toc_url: "https://example.test/toc".to_string(),
            description: "简介".to_string(),
            book_source_url: "https://example.test/source".to_string(),
            group: "收藏".to_string(),
            read_iteration: 2,
            sim_read_enabled: true,
            sim_read_start_date: "2026-08-02".to_string(),
            sim_read_start_chapter: 3,
            sim_read_daily_chapters: 5,
            updated_at: "2026-08-02 12:00:00".to_string(),
        };

        let encoded = serde_json::to_value(dto).unwrap();

        assert_eq!(encoded["coverUrl"], "https://example.test/cover.jpg");
        assert_eq!(encoded["type"], "online");
        assert_eq!(encoded["currentChapter"], "第十章");
        assert_eq!(encoded["durChapterIndex"], 9);
        assert_eq!(encoded["currentPageIndex"], 123);
        assert_eq!(encoded["readConfig"]["reverseToc"], true);
        assert_eq!(encoded["readConfig"]["pageAnim"], 2);
        assert_eq!(encoded["simReadDailyChapters"], 5);
        assert_eq!(encoded["updatedAt"], "2026-08-02 12:00:00");
    }
}
