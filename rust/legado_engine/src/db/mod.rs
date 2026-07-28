//! Rust 本地数据库 — 与 Flutter `legado.db` schema v7 对齐（Phase C）

use once_cell::sync::OnceCell;
use rusqlite::{params, Connection, OptionalExtension};
use serde_json::{json, Value};
use std::collections::BTreeMap;
use std::fs;
use std::path::Path;
use std::sync::Mutex;
use thiserror::Error;

pub(crate) mod room_import;

const SCHEMA_VERSION: i32 = 17;

static DB: OnceCell<Mutex<EngineDb>> = OnceCell::new();

#[derive(Error, Debug)]
pub enum DbError {
    #[error("sqlite: {0}")]
    Sqlite(#[from] rusqlite::Error),
    #[error("{0}")]
    Message(String),
}

/// 引擎本地 SQLite
pub struct EngineDb {
    conn: Connection,
}

impl EngineDb {
    pub fn open(path: &str) -> Result<Self, DbError> {
        let conn = Connection::open(path)?;
        Self::init_schema(&conn)?;
        Ok(Self { conn })
    }

    pub fn open_in_memory() -> Result<Self, DbError> {
        Self::open(":memory:")
    }

    fn init_schema(conn: &Connection) -> Result<(), DbError> {
        conn.execute_batch(
            "PRAGMA foreign_keys = ON;
             CREATE TABLE IF NOT EXISTS books (
               id TEXT PRIMARY KEY,
               name TEXT NOT NULL,
               author TEXT DEFAULT '未知作者',
               coverUrl TEXT DEFAULT '',
               type TEXT DEFAULT 'online',
               progress REAL DEFAULT 0.0,
               currentChapter TEXT,
               lastChapter TEXT DEFAULT '',
               totalChapterNum INTEGER DEFAULT 0,
               durChapterIndex INTEGER DEFAULT 0,
               currentPageIndex INTEGER DEFAULT 0,
               isFavorite INTEGER DEFAULT 0,
               sourceUrl TEXT DEFAULT '',
               description TEXT DEFAULT '',
               bookSourceUrl TEXT DEFAULT '',
               tocUrl TEXT DEFAULT '',
               bookGroup TEXT DEFAULT '',
               readIteration INTEGER DEFAULT 0,
               simReadEnabled INTEGER DEFAULT 0,
               simReadStartDate TEXT DEFAULT '',
               simReadStartChapter INTEGER DEFAULT 0,
               simReadDailyChapters INTEGER DEFAULT 3,
               readConfig TEXT DEFAULT '{}',
               updatedAt TEXT DEFAULT (datetime('now'))
             );
             CREATE TABLE IF NOT EXISTS book_sources (
               bookSourceUrl TEXT PRIMARY KEY,
               bookSourceName TEXT NOT NULL,
               enabled INTEGER DEFAULT 1,
               bookSourceType TEXT DEFAULT '0',
               bookSourceGroup TEXT DEFAULT '',
               ruleSearchUrl TEXT DEFAULT '',
               ruleSearchList TEXT DEFAULT '',
               ruleSearchName TEXT DEFAULT '',
               ruleSearchAuthor TEXT DEFAULT '',
               ruleSearchCoverUrl TEXT DEFAULT '',
               ruleSearchKind TEXT DEFAULT '',
               ruleSearchNote TEXT DEFAULT '',
               ruleBookUrlPattern TEXT DEFAULT '',
               ruleBookName TEXT DEFAULT '',
               ruleBookAuthor TEXT DEFAULT '',
               ruleBookCoverUrl TEXT DEFAULT '',
               ruleBookKind TEXT DEFAULT '',
               ruleBookNote TEXT DEFAULT '',
               ruleBookLastChapter TEXT DEFAULT '',
               ruleChapterList TEXT DEFAULT '',
               ruleChapterName TEXT DEFAULT '',
               ruleChapterUrl TEXT DEFAULT '',
               ruleChapterUrlIsFull TEXT DEFAULT '',
               ruleContentUrl TEXT DEFAULT '',
               ruleContent TEXT DEFAULT '',
               ruleContentRemove TEXT DEFAULT '',
               rulePageUrl TEXT DEFAULT '',
               rulePageNext TEXT DEFAULT '',
               rawSourceJson TEXT DEFAULT '',
               createdAt TEXT DEFAULT (datetime('now'))
             );
             CREATE TABLE IF NOT EXISTS chapters (
               id TEXT PRIMARY KEY,
               bookId TEXT NOT NULL,
               title TEXT NOT NULL,
               idx INTEGER NOT NULL,
               url TEXT DEFAULT '',
               isDownloaded INTEGER DEFAULT 0,
               content TEXT,
               FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
             );
             CREATE TABLE IF NOT EXISTS replace_rules (
               id TEXT PRIMARY KEY,
               name TEXT DEFAULT '',
               pattern TEXT NOT NULL,
               replacement TEXT DEFAULT '',
               isEnabled INTEGER DEFAULT 1,
               isRegex INTEGER DEFAULT 1
             );
             CREATE TABLE IF NOT EXISTS legacy_room_imports (
               fingerprint TEXT PRIMARY KEY,
               room_version INTEGER NOT NULL,
               room_identity_hash TEXT,
               raw_snapshot_json TEXT NOT NULL,
               mapped_backup_json TEXT NOT NULL,
               imported_at TEXT NOT NULL DEFAULT (datetime('now'))
             );",
        )?;
        let current: i32 = conn.query_row("PRAGMA user_version", [], |r| r.get(0))?;
        if current < 8 {
            conn.execute_batch(
                "CREATE TABLE IF NOT EXISTS reading_records (
                   id TEXT PRIMARY KEY,
                   book_id TEXT NOT NULL,
                   book_name TEXT DEFAULT '',
                   date TEXT NOT NULL,
                   duration_seconds INTEGER DEFAULT 0,
                   read_chars INTEGER DEFAULT 0,
                   UNIQUE(book_id, date)
                 );
                 CREATE INDEX IF NOT EXISTS idx_reading_records_date ON reading_records(date);",
            )?;
        }
        if current < 9 {
            conn.execute_batch(
                "CREATE TABLE IF NOT EXISTS notes (
                  id TEXT PRIMARY KEY,
                  book_id TEXT NOT NULL,
                  chapter_title TEXT DEFAULT '',
                  selected_text TEXT NOT NULL,
                  note_content TEXT DEFAULT '',
                  position INTEGER DEFAULT 0,
                  chapter_pos INTEGER NOT NULL DEFAULT -1,
                  created_at TEXT DEFAULT (datetime('now')),
                  FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
                );
                 CREATE INDEX IF NOT EXISTS idx_notes_book_id ON notes(book_id);",
            )?;
        }
        if current < 10 {
            // 已有 v10 CREATE 的新库可能已含该列；重复添加忽略错误
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN readIteration INTEGER DEFAULT 0",
                [],
            );
        }
        if current < 11 {
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN simReadEnabled INTEGER DEFAULT 0",
                [],
            );
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN simReadStartDate TEXT DEFAULT ''",
                [],
            );
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN simReadStartChapter INTEGER DEFAULT 0",
                [],
            );
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN simReadDailyChapters INTEGER DEFAULT 3",
                [],
            );
        }
        if current < 12 {
            // 书架未读角标：总章数 / 当前章索引（旧库 ALTER；新库 CREATE 已含）
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN totalChapterNum INTEGER DEFAULT 0",
                [],
            );
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN durChapterIndex INTEGER DEFAULT 0",
                [],
            );
        }
        if current < 13 {
            // 书签章内字符偏移（对齐 Jingshiro Bookmark.chapterPos）
            let _ = conn.execute(
                "ALTER TABLE notes ADD COLUMN chapter_pos INTEGER NOT NULL DEFAULT -1",
                [],
            );
        }
        if current < 14 {
            conn.execute_batch(
                "CREATE TABLE IF NOT EXISTS detailed_read_records (
                   id INTEGER PRIMARY KEY AUTOINCREMENT,
                   book_name TEXT NOT NULL,
                   start_time INTEGER NOT NULL,
                   end_time INTEGER NOT NULL,
                   read_iteration INTEGER DEFAULT 0
                 );
                 CREATE INDEX IF NOT EXISTS idx_detailed_read_records_book
                   ON detailed_read_records(book_name, end_time);",
            )?;
        }
        if current < 15 {
            // 独立书签实体；旧 notes 表继续保存想法和历史兼容数据
            conn.execute_batch(
                "CREATE TABLE IF NOT EXISTS bookmarks (
                   time INTEGER PRIMARY KEY,
                   book_id TEXT NOT NULL DEFAULT '',
                   book_name TEXT NOT NULL DEFAULT '',
                   book_author TEXT NOT NULL DEFAULT '',
                   chapter_index INTEGER NOT NULL DEFAULT 0,
                   chapter_pos INTEGER NOT NULL DEFAULT 0,
                   chapter_name TEXT NOT NULL DEFAULT '',
                   book_text TEXT NOT NULL DEFAULT '',
                   content TEXT NOT NULL DEFAULT ''
                 );
                 CREATE INDEX IF NOT EXISTS idx_bookmarks_book
                   ON bookmarks(book_name, book_author, chapter_index, chapter_pos);",
            )?;
        }
        if current < 16 {
            // Per-book reader settings are stored as the same nested JSON
            // object used by the original app's Book.readConfig.
            let _ = conn.execute(
                "ALTER TABLE books ADD COLUMN readConfig TEXT DEFAULT '{}'",
                [],
            );
        }
        if current < 17 {
            let _ = conn.execute("ALTER TABLE books ADD COLUMN tocUrl TEXT DEFAULT ''", []);
        }
        if current < SCHEMA_VERSION {
            conn.execute_batch(&format!("PRAGMA user_version = {SCHEMA_VERSION};"))?;
        }
        Ok(())
    }

    pub fn schema_version(&self) -> Result<i32, DbError> {
        Ok(self
            .conn
            .query_row("PRAGMA user_version", [], |r| r.get(0))?)
    }

    #[cfg(test)]
    fn legacy_room_import_count(&self) -> Result<i64, DbError> {
        Ok(self
            .conn
            .query_row("SELECT COUNT(*) FROM legacy_room_imports", [], |row| {
                row.get(0)
            })?)
    }

    pub fn import_legacy_room_database(
        &self,
        source_path: &str,
        backup_path: Option<&str>,
        replace: bool,
    ) -> Result<room_import::LegacyRoomImportReport, DbError> {
        let snapshot = room_import::extract_legacy_room_database(source_path)?;
        let mapping = room_import::map_legacy_room_snapshot(&snapshot)?;
        let fingerprint = room_import::snapshot_fingerprint(&snapshot);
        let already_imported = self.conn.query_row(
            "SELECT EXISTS(SELECT 1 FROM legacy_room_imports WHERE fingerprint=?1)",
            params![fingerprint],
            |row| row.get::<_, i64>(0),
        )? == 1;

        let normalized_backup_path = backup_path
            .filter(|path| !path.trim().is_empty())
            .map(str::to_string);
        if already_imported && !replace {
            let archive_only_tables = mapping.archive_only_tables.clone();
            let mut warnings = mapping.warnings;
            warnings.push(format!(
                "legacy Room snapshot already imported; skipped duplicate: {fingerprint}"
            ));
            return Ok(room_import::LegacyRoomImportReport {
                source_room_version: snapshot.user_version,
                source_room_identity_hash: snapshot.room_identity_hash,
                fingerprint,
                replaced: false,
                skipped_duplicate: true,
                backup_path: normalized_backup_path,
                backup_written: false,
                counts: mapping.counts,
                conflict_counts: BTreeMap::new(),
                preserved_rows: snapshot
                    .tables
                    .iter()
                    .map(|(table, rows)| (table.clone(), rows.len()))
                    .collect(),
                archive_only_tables,
                warnings,
                unmapped_columns: mapping.unmapped_columns,
            });
        }

        let backup_path = normalized_backup_path
            .as_deref()
            .ok_or_else(|| DbError::Message("首次 Room 导入必须提供导入前备份路径".to_string()))?;
        let backup_json = self.export_backup_json()?;
        write_import_backup(backup_path, &backup_json)?;
        let conflict_counts = if replace {
            BTreeMap::new()
        } else {
            import_conflict_counts(&self.conn, &mapping.backup_json)?
        };

        self.conn.execute_batch("BEGIN IMMEDIATE")?;
        let result = (|| {
            if replace {
                self.clear_all_for_restore()?;
            }
            self.restore_backup_json(&mapping.backup_json.to_string(), false)?;
            self.conn.execute(
                "INSERT INTO legacy_room_imports
                 (fingerprint, room_version, room_identity_hash, raw_snapshot_json, mapped_backup_json)
                 VALUES (?1, ?2, ?3, ?4, ?5)
                 ON CONFLICT(fingerprint) DO UPDATE SET
                   room_version=excluded.room_version,
                   room_identity_hash=excluded.room_identity_hash,
                   raw_snapshot_json=excluded.raw_snapshot_json,
                   mapped_backup_json=excluded.mapped_backup_json,
                   imported_at=datetime('now')",
                params![
                    fingerprint,
                    snapshot.user_version,
                    snapshot.room_identity_hash,
                    room_import::snapshot_json(&snapshot).to_string(),
                    mapping.backup_json.to_string(),
                ],
            )?;
            Ok::<(), DbError>(())
        })();

        match result {
            Ok(()) => match self.conn.execute_batch("COMMIT") {
                Ok(()) => Ok(room_import::LegacyRoomImportReport {
                    source_room_version: snapshot.user_version,
                    source_room_identity_hash: snapshot.room_identity_hash,
                    fingerprint,
                    replaced: replace,
                    skipped_duplicate: false,
                    backup_path: normalized_backup_path,
                    backup_written: true,
                    counts: mapping.counts,
                    conflict_counts,
                    preserved_rows: snapshot
                        .tables
                        .iter()
                        .map(|(table, rows)| (table.clone(), rows.len()))
                        .collect(),
                    archive_only_tables: mapping.archive_only_tables,
                    warnings: mapping.warnings,
                    unmapped_columns: mapping.unmapped_columns,
                }),
                Err(error) => {
                    let _ = self.conn.execute_batch("ROLLBACK");
                    Err(DbError::Sqlite(error))
                }
            },
            Err(error) => {
                let _ = self.conn.execute_batch("ROLLBACK");
                Err(error)
            }
        }
    }

    pub fn insert_book_json(&self, book_json: &str) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(book_json)
            .map_err(|e| DbError::Message(format!("book JSON 无效: {e}")))?;
        let id = str_field(&v, "id")?;
        self.conn.execute(
            "INSERT INTO books (id, name, author, coverUrl, type, progress, currentChapter,
              lastChapter, totalChapterNum, durChapterIndex, currentPageIndex, isFavorite,
              sourceUrl, description, bookSourceUrl, tocUrl, bookGroup, readIteration, simReadEnabled,
              simReadStartDate, simReadStartChapter, simReadDailyChapters, readConfig)
             VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,?23)
             ON CONFLICT(id) DO UPDATE SET
               name=excluded.name, author=excluded.author, coverUrl=excluded.coverUrl,
               type=excluded.type, progress=excluded.progress, currentChapter=excluded.currentChapter,
               lastChapter=excluded.lastChapter, totalChapterNum=excluded.totalChapterNum,
               durChapterIndex=excluded.durChapterIndex, currentPageIndex=excluded.currentPageIndex,
               isFavorite=excluded.isFavorite, sourceUrl=excluded.sourceUrl,
               description=excluded.description, bookSourceUrl=excluded.bookSourceUrl,
               tocUrl=excluded.tocUrl, bookGroup=excluded.bookGroup, readIteration=excluded.readIteration,
               simReadEnabled=excluded.simReadEnabled, simReadStartDate=excluded.simReadStartDate,
               simReadStartChapter=excluded.simReadStartChapter,
               simReadDailyChapters=excluded.simReadDailyChapters,
               readConfig=excluded.readConfig,
               updatedAt=datetime('now')",
            params![
                id,
                str_field(&v, "name").unwrap_or_else(|_| "未知".into()),
                str_field(&v, "author").unwrap_or_default(),
                str_field(&v, "coverUrl").unwrap_or_default(),
                str_field(&v, "type").unwrap_or_else(|_| "online".into()),
                f64_field(&v, "progress"),
                opt_str_field(&v, "currentChapter"),
                str_field(&v, "lastChapter").unwrap_or_default(),
                i64_field(&v, "totalChapterNum").max(0),
                i64_field(&v, "durChapterIndex").max(0),
                i64_field(&v, "currentPageIndex"),
                bool_field(&v, "isFavorite") as i64,
                str_field(&v, "sourceUrl").unwrap_or_default(),
                str_field(&v, "description").unwrap_or_default(),
                str_field(&v, "bookSourceUrl").unwrap_or_default(),
                str_field(&v, "tocUrl").unwrap_or_default(),
                str_field(&v, "group").or_else(|_| str_field(&v, "bookGroup")).unwrap_or_default(),
                i64_field(&v, "readIteration"),
                // 缺省 false / 3，避免 bool_field 缺键时默认 true、日更被 clamp 成 1
                v.get("simReadEnabled")
                    .map(|_| bool_field(&v, "simReadEnabled"))
                    .unwrap_or(false) as i64,
                str_field(&v, "simReadStartDate").unwrap_or_default(),
                i64_field(&v, "simReadStartChapter").max(0),
                v.get("simReadDailyChapters")
                    .map(|_| {
                        let d = i64_field(&v, "simReadDailyChapters");
                        if d < 1 {
                            3
                        } else {
                            d.min(999)
                        }
                    })
                    .unwrap_or(3),
                read_config_json(&v),
            ],
        )?;
        Ok(())
    }

    pub fn get_books_json(&self) -> Result<Vec<String>, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, name, author, coverUrl, type, progress, currentChapter, lastChapter,
                    totalChapterNum, durChapterIndex, currentPageIndex, isFavorite, sourceUrl,
                    description, bookSourceUrl, tocUrl, bookGroup, readIteration, simReadEnabled,
                    simReadStartDate, simReadStartChapter, simReadDailyChapters, readConfig,
                    updatedAt
             FROM books ORDER BY updatedAt DESC",
        )?;
        let rows = stmt.query_map([], |row| {
            let daily_raw = row.get::<_, Option<i64>>(21)?.unwrap_or(3);
            let daily = if daily_raw < 1 { 3 } else { daily_raw.min(999) };
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "name": row.get::<_, String>(1)?,
                "author": row.get::<_, String>(2)?,
                "coverUrl": row.get::<_, String>(3)?,
                "type": row.get::<_, String>(4)?,
                "progress": row.get::<_, f64>(5)?,
                "currentChapter": row.get::<_, Option<String>>(6)?,
                "lastChapter": row.get::<_, String>(7)?,
                "totalChapterNum": row.get::<_, Option<i64>>(8)?.unwrap_or(0).max(0),
                "durChapterIndex": row.get::<_, Option<i64>>(9)?.unwrap_or(0).max(0),
                "currentPageIndex": row.get::<_, i64>(10)?,
                "isFavorite": row.get::<_, i64>(11)? == 1,
                "sourceUrl": row.get::<_, String>(12)?,
                "description": row.get::<_, String>(13)?,
                "bookSourceUrl": row.get::<_, String>(14)?,
                "tocUrl": row.get::<_, Option<String>>(15)?.unwrap_or_default(),
                "group": row.get::<_, String>(16)?,
                "readIteration": row.get::<_, Option<i64>>(17)?.unwrap_or(0),
                "simReadEnabled": row.get::<_, Option<i64>>(18)?.unwrap_or(0) == 1,
                "simReadStartDate": row.get::<_, Option<String>>(19)?.unwrap_or_default(),
                "simReadStartChapter": row.get::<_, Option<i64>>(20)?.unwrap_or(0).max(0),
                "simReadDailyChapters": daily,
                "readConfig": parse_read_config(row.get::<_, Option<String>>(22)?),
                "updatedAt": row.get::<_, Option<String>>(23)?.unwrap_or_default(),
            }))
        })?;
        rows.map(|r| {
            r.map(|v| v.to_string())
                .map_err(|e| DbError::Message(e.to_string()))
        })
        .collect()
    }

    pub fn update_book_progress(
        &self,
        book_id: &str,
        progress: f64,
        chapter: Option<&str>,
        page_index: i64,
        dur_chapter_index: Option<i64>,
    ) -> Result<(), DbError> {
        if let Some(dur) = dur_chapter_index {
            self.conn.execute(
                "UPDATE books SET progress=?1, currentChapter=?2, currentPageIndex=?3,
                 durChapterIndex=?4, updatedAt=datetime('now') WHERE id=?5",
                params![progress, chapter, page_index, dur.max(0), book_id],
            )?;
        } else {
            self.conn.execute(
                "UPDATE books SET progress=?1, currentChapter=?2, currentPageIndex=?3,
                 updatedAt=datetime('now') WHERE id=?4",
                params![progress, chapter, page_index, book_id],
            )?;
        }
        Ok(())
    }

    pub fn update_book_cover(&self, book_id: &str, cover_url: &str) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE books SET coverUrl=?1 WHERE id=?2",
            params![cover_url, book_id],
        )?;
        Ok(())
    }

    pub fn update_book_group(&self, book_id: &str, group: &str) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE books SET bookGroup=?1 WHERE id=?2",
            params![group, book_id],
        )?;
        Ok(())
    }

    pub fn delete_book(&self, book_id: &str) -> Result<(), DbError> {
        self.conn
            .execute("DELETE FROM chapters WHERE bookId=?1", params![book_id])?;
        self.conn
            .execute("DELETE FROM books WHERE id=?1", params![book_id])?;
        Ok(())
    }

    pub fn upsert_source_json(&self, source_json: &str) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(source_json)
            .map_err(|e| DbError::Message(format!("书源 JSON 无效: {e}")))?;
        let url = str_field(&v, "bookSourceUrl")?;
        self.conn.execute(
            "INSERT INTO book_sources (
               bookSourceUrl, bookSourceName, enabled, bookSourceType, bookSourceGroup,
               ruleSearchUrl, ruleSearchList, ruleSearchName, ruleSearchAuthor,
               ruleSearchCoverUrl, ruleSearchKind, ruleSearchNote, ruleBookUrlPattern,
               ruleBookName, ruleBookAuthor, ruleBookCoverUrl, ruleBookKind, ruleBookNote,
               ruleBookLastChapter, ruleChapterList, ruleChapterName, ruleChapterUrl,
               ruleChapterUrlIsFull, ruleContentUrl, ruleContent, ruleContentRemove,
               rulePageUrl, rulePageNext, rawSourceJson)
             VALUES (?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,?23,?24,?25,?26,?27,?28,?29)
             ON CONFLICT(bookSourceUrl) DO UPDATE SET
               bookSourceName=excluded.bookSourceName,
               enabled=book_sources.enabled,
               bookSourceType=excluded.bookSourceType, bookSourceGroup=excluded.bookSourceGroup,
               ruleSearchUrl=excluded.ruleSearchUrl, rawSourceJson=excluded.rawSourceJson",
            params![
                url,
                str_field(&v, "bookSourceName").unwrap_or_else(|_| "未命名书源".into()),
                bool_field(&v, "enabled") as i64,
                str_field(&v, "bookSourceType").unwrap_or_else(|_| "0".into()),
                str_field(&v, "bookSourceGroup").unwrap_or_default(),
                str_field(&v, "ruleSearchUrl").unwrap_or_default(),
                str_field(&v, "ruleSearchList").unwrap_or_default(),
                str_field(&v, "ruleSearchName").unwrap_or_default(),
                str_field(&v, "ruleSearchAuthor").unwrap_or_default(),
                str_field(&v, "ruleSearchCoverUrl").unwrap_or_default(),
                str_field(&v, "ruleSearchKind").unwrap_or_default(),
                str_field(&v, "ruleSearchNote").unwrap_or_default(),
                str_field(&v, "ruleBookUrlPattern").unwrap_or_default(),
                str_field(&v, "ruleBookName").unwrap_or_default(),
                str_field(&v, "ruleBookAuthor").unwrap_or_default(),
                str_field(&v, "ruleBookCoverUrl").unwrap_or_default(),
                str_field(&v, "ruleBookKind").unwrap_or_default(),
                str_field(&v, "ruleBookNote").unwrap_or_default(),
                str_field(&v, "ruleBookLastChapter").unwrap_or_default(),
                str_field(&v, "ruleChapterList").unwrap_or_default(),
                str_field(&v, "ruleChapterName").unwrap_or_default(),
                str_field(&v, "ruleChapterUrl").unwrap_or_default(),
                str_field(&v, "ruleChapterUrlIsFull").unwrap_or_default(),
                str_field(&v, "ruleContentUrl").unwrap_or_default(),
                str_field(&v, "ruleContent").unwrap_or_default(),
                str_field(&v, "ruleContentRemove").unwrap_or_default(),
                str_field(&v, "rulePageUrl").unwrap_or_default(),
                str_field(&v, "rulePageNext").unwrap_or_default(),
                str_field(&v, "rawSourceJson").unwrap_or(source_json.to_string()),
            ],
        )?;
        Ok(())
    }

    pub fn get_sources_json(&self, enabled_only: bool) -> Result<Vec<String>, DbError> {
        let sql = if enabled_only {
            "SELECT rawSourceJson, bookSourceUrl, bookSourceName, enabled, bookSourceGroup,
                    ruleSearchUrl FROM book_sources WHERE enabled=1 ORDER BY createdAt DESC"
        } else {
            "SELECT rawSourceJson, bookSourceUrl, bookSourceName, enabled, bookSourceGroup,
                    ruleSearchUrl FROM book_sources ORDER BY createdAt DESC"
        };
        let mut stmt = self.conn.prepare(sql)?;
        let rows = stmt.query_map([], |row| Ok(source_row_to_json(row)?))?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    pub fn toggle_source(&self, url: &str, enabled: bool) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE book_sources SET enabled=?1 WHERE bookSourceUrl=?2",
            params![enabled as i64, url],
        )?;
        Ok(())
    }

    pub fn delete_source(&self, url: &str) -> Result<(), DbError> {
        self.conn.execute(
            "DELETE FROM book_sources WHERE bookSourceUrl=?1",
            params![url],
        )?;
        Ok(())
    }

    pub fn insert_chapters_json(&self, chapters_json: &str) -> Result<(), DbError> {
        let arr: Vec<Value> = serde_json::from_str(chapters_json)
            .map_err(|e| DbError::Message(format!("chapters JSON 无效: {e}")))?;
        for ch in arr {
            let id = str_field(&ch, "id")?;
            // TOC 刷新时常见 content=null / isDownloaded=0；勿覆盖已缓存正文。
            // clearDownloaded 只由文件缓存一致性修复流程显式传入。
            let clear_downloaded = ch
                .get("clearDownloaded")
                .and_then(Value::as_bool)
                .unwrap_or(false);
            self.conn.execute(
                "INSERT INTO chapters (id, bookId, title, idx, url, isDownloaded, content)
                 VALUES (?1,?2,?3,?4,?5,?6,?7)
                 ON CONFLICT(id) DO UPDATE SET
                   title=excluded.title,
                   idx=excluded.idx,
                   url=excluded.url,
                   isDownloaded=CASE
                     WHEN ?8 != 0 THEN 0
                     WHEN excluded.isDownloaded != 0 THEN 1
                     ELSE chapters.isDownloaded
                   END,
                   content=CASE
                     WHEN ?8 != 0 THEN NULL
                     WHEN excluded.content IS NOT NULL AND excluded.content != ''
                       THEN excluded.content
                     ELSE chapters.content
                   END",
                params![
                    id,
                    str_field(&ch, "bookId")?,
                    str_field(&ch, "title").unwrap_or_default(),
                    i64_field_idx(&ch, "index"),
                    str_field(&ch, "url").unwrap_or_default(),
                    bool_field(&ch, "isDownloaded") as i64,
                    opt_str_field(&ch, "content"),
                    clear_downloaded as i64,
                ],
            )?;
        }
        Ok(())
    }

    pub fn get_chapters_json(&self, book_id: &str) -> Result<Vec<String>, DbError> {
        // 目录展示不带 content：对齐 Legado ChapterList 只查元数据，避免千章×正文撑爆/拖慢
        let mut stmt = self.conn.prepare(
            "SELECT id, bookId, title, idx, url, isDownloaded
             FROM chapters WHERE bookId=?1 ORDER BY idx ASC",
        )?;
        let rows = stmt.query_map(params![book_id], |row| {
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "bookId": row.get::<_, String>(1)?,
                "title": row.get::<_, String>(2)?,
                "index": row.get::<_, i64>(3)?,
                "url": row.get::<_, String>(4)?,
                "isDownloaded": row.get::<_, i64>(5)? == 1,
                "content": null,
            })
            .to_string())
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    /// 单章正文（文件缓存未命中时的 DB 回落）
    pub fn get_chapter_content(&self, chapter_id: &str) -> Result<Option<String>, DbError> {
        let mut stmt = self
            .conn
            .prepare("SELECT content FROM chapters WHERE id=?1 AND isDownloaded=1")?;
        let mut rows = stmt.query(params![chapter_id])?;
        if let Some(row) = rows.next()? {
            Ok(row.get::<_, Option<String>>(0)?)
        } else {
            Ok(None)
        }
    }

    pub fn save_chapter_content(&self, chapter_id: &str, content: &str) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE chapters SET content=?1, isDownloaded=1 WHERE id=?2",
            params![content, chapter_id],
        )?;
        Ok(())
    }

    pub fn book_count(&self) -> Result<i64, DbError> {
        Ok(self
            .conn
            .query_row("SELECT COUNT(*) FROM books", [], |r| r.get(0))?)
    }

    pub fn upsert_replace_rule_json(&self, rule_json: &str) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(rule_json)
            .map_err(|e| DbError::Message(format!("replace rule JSON 无效: {e}")))?;
        self.conn.execute(
            "INSERT INTO replace_rules (id, name, pattern, replacement, isEnabled, isRegex)
             VALUES (?1,?2,?3,?4,?5,?6)
             ON CONFLICT(id) DO UPDATE SET
               name=excluded.name, pattern=excluded.pattern,
               replacement=excluded.replacement, isEnabled=excluded.isEnabled,
               isRegex=excluded.isRegex",
            params![
                str_field(&v, "id")?,
                str_field(&v, "name").unwrap_or_default(),
                str_field(&v, "pattern")?,
                str_field(&v, "replacement").unwrap_or_default(),
                bool_field(&v, "isEnabled") as i64,
                bool_field(&v, "isRegex") as i64,
            ],
        )?;
        Ok(())
    }

    pub fn get_replace_rules_json(&self) -> Result<Vec<String>, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, name, pattern, replacement, isEnabled, isRegex
             FROM replace_rules ORDER BY name ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "name": row.get::<_, String>(1)?,
                "pattern": row.get::<_, String>(2)?,
                "replacement": row.get::<_, String>(3)?,
                "isEnabled": row.get::<_, i64>(4)? == 1,
                "isRegex": row.get::<_, i64>(5)? == 1,
            })
            .to_string())
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    pub fn toggle_replace_rule(&self, id: &str, enabled: bool) -> Result<(), DbError> {
        self.conn.execute(
            "UPDATE replace_rules SET isEnabled=?1 WHERE id=?2",
            params![enabled as i64, id],
        )?;
        Ok(())
    }

    pub fn delete_replace_rule(&self, id: &str) -> Result<(), DbError> {
        self.conn
            .execute("DELETE FROM replace_rules WHERE id=?1", params![id])?;
        Ok(())
    }

    pub fn clear_replace_rules(&self) -> Result<(), DbError> {
        self.conn.execute("DELETE FROM replace_rules", [])?;
        Ok(())
    }

    pub fn record_reading(
        &self,
        book_id: &str,
        book_name: &str,
        chars: i64,
        duration_seconds: i64,
    ) -> Result<(), DbError> {
        let date: String = self
            .conn
            .query_row("SELECT date('now', 'localtime')", [], |r| r.get(0))?;
        let id = format!("{book_id}_{date}");
        self.conn.execute(
            "INSERT INTO reading_records (id, book_id, book_name, date, duration_seconds, read_chars)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(book_id, date) DO UPDATE SET
               read_chars = read_chars + excluded.read_chars,
               duration_seconds = duration_seconds + excluded.duration_seconds,
               book_name = excluded.book_name",
            params![id, book_id, book_name, date, duration_seconds, chars],
        )?;
        Ok(())
    }

    fn reading_days_filter(&self, range: &str) -> &'static str {
        match range {
            "week" => "-7 days",
            "month" => "-30 days",
            "year" => "-365 days",
            _ => "-30 days",
        }
    }

    pub fn get_reading_stats_json(&self, range: &str) -> Result<String, DbError> {
        let (total_chars, total_duration): (i64, i64) = self.conn.query_row(
            "SELECT COALESCE(SUM(read_chars),0), COALESCE(SUM(duration_seconds),0) FROM reading_records",
            [],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )?;

        let (today_chars, today_duration): (i64, i64) = self.conn.query_row(
            "SELECT COALESCE(SUM(read_chars),0), COALESCE(SUM(duration_seconds),0)
             FROM reading_records WHERE date = date('now', 'localtime')",
            [],
            |r| Ok((r.get(0)?, r.get(1)?)),
        )?;

        let week_chars: i64 = self.conn.query_row(
            "SELECT COALESCE(SUM(read_chars),0) FROM reading_records
             WHERE date >= date('now', 'localtime', '-7 days')",
            [],
            |r| r.get(0),
        )?;

        let days = self.reading_days_filter(range);
        let sql = format!(
            "SELECT date, COALESCE(SUM(read_chars),0), COALESCE(SUM(duration_seconds),0)
             FROM reading_records
             WHERE date >= date('now', 'localtime', '{days}')
             GROUP BY date ORDER BY date ASC"
        );

        let mut stmt = self.conn.prepare(&sql)?;
        let daily = stmt
            .query_map([], |row| {
                Ok(json!({
                    "date": row.get::<_, String>(0)?,
                    "chars": row.get::<_, i64>(1)?,
                    "durationSeconds": row.get::<_, i64>(2)?,
                }))
            })?
            .map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect::<Result<Vec<_>, _>>()?;

        Ok(json!({
            "totalChars": total_chars,
            "totalDurationSeconds": total_duration,
            "todayChars": today_chars,
            "todayDurationSeconds": today_duration,
            "weekChars": week_chars,
            "daily": daily,
        })
        .to_string())
    }

    pub fn get_book_reading_stats_json(&self, book_id: &str) -> Result<String, DbError> {
        let (duration, chars, start_date, last_date, days): (
            i64,
            i64,
            Option<String>,
            Option<String>,
            i64,
        ) = self.conn.query_row(
            "SELECT COALESCE(SUM(duration_seconds),0), COALESCE(SUM(read_chars),0),
                        MIN(date), MAX(date), COUNT(DISTINCT date)
                 FROM reading_records WHERE book_id = ?1",
            params![book_id],
            |r| Ok((r.get(0)?, r.get(1)?, r.get(2)?, r.get(3)?, r.get(4)?)),
        )?;

        Ok(json!({
            "durationSeconds": duration,
            "readChars": chars,
            "startDate": start_date,
            "lastDate": last_date,
            "readingDays": days,
        })
        .to_string())
    }

    pub fn upsert_note(
        &self,
        id: &str,
        book_id: &str,
        chapter_title: &str,
        selected_text: &str,
        note_content: &str,
        position: i64,
        chapter_pos: i64,
    ) -> Result<(), DbError> {
        self.conn.execute(
            "INSERT INTO notes (id, book_id, chapter_title, selected_text, note_content, position, chapter_pos)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(id) DO UPDATE SET
               chapter_title = excluded.chapter_title,
               selected_text = excluded.selected_text,
               note_content = excluded.note_content,
               position = excluded.position,
               chapter_pos = excluded.chapter_pos",
            params![
                id,
                book_id,
                chapter_title,
                selected_text,
                note_content,
                position,
                chapter_pos
            ],
        )?;
        Ok(())
    }

    pub fn delete_note(&self, id: &str) -> Result<(), DbError> {
        self.conn
            .execute("DELETE FROM notes WHERE id = ?1", params![id])?;
        Ok(())
    }

    pub fn list_notes_json(&self, book_id: Option<&str>) -> Result<Vec<String>, DbError> {
        let mut out = Vec::new();
        if let Some(bid) = book_id.filter(|s| !s.is_empty()) {
            let mut stmt = self.conn.prepare(
                "SELECT id, book_id, chapter_title, selected_text, note_content, position, created_at, chapter_pos
                 FROM notes WHERE book_id = ?1 ORDER BY created_at DESC",
            )?;
            let rows = stmt.query_map(params![bid], |row| Self::map_note_row(row))?;
            for row in rows {
                out.push(row.map_err(|e| DbError::Message(e.to_string()))?);
            }
        } else {
            let mut stmt = self.conn.prepare(
                "SELECT id, book_id, chapter_title, selected_text, note_content, position, created_at, chapter_pos
                 FROM notes ORDER BY created_at DESC",
            )?;
            let rows = stmt.query_map([], |row| Self::map_note_row(row))?;
            for row in rows {
                out.push(row.map_err(|e| DbError::Message(e.to_string()))?);
            }
        }
        Ok(out)
    }

    fn map_note_row(row: &rusqlite::Row<'_>) -> Result<String, rusqlite::Error> {
        Ok(json!({
            "id": row.get::<_, String>(0)?,
            "bookId": row.get::<_, String>(1)?,
            "chapterTitle": row.get::<_, String>(2)?,
            "selectedText": row.get::<_, String>(3)?,
            "noteContent": row.get::<_, String>(4)?,
            "position": row.get::<_, i64>(5)?,
            "createdAt": row.get::<_, String>(6)?,
            "chapterPos": row.get::<_, i64>(7).unwrap_or(-1),
        })
        .to_string())
    }

    pub fn export_notes_markdown(&self, book_id: Option<&str>) -> Result<String, DbError> {
        let notes = self.list_notes_json(book_id)?;
        let mut out = String::new();
        for raw in notes {
            let v: Value = serde_json::from_str(&raw)
                .map_err(|e| DbError::Message(format!("笔记 JSON 无效: {e}")))?;
            let chapter = str_field(&v, "chapterTitle").unwrap_or_default();
            let selected = str_field(&v, "selectedText")?;
            let content = str_field(&v, "noteContent").unwrap_or_default();
            let created = str_field(&v, "createdAt").unwrap_or_default();
            out.push_str(&format!("## {chapter}\n\n"));
            if !selected.is_empty() {
                out.push_str("> ");
                out.push_str(&selected.replace('\n', "\n> "));
                out.push_str("\n\n");
            }
            if !content.is_empty() {
                out.push_str(&content);
                out.push('\n');
            }
            out.push_str(&format!("\n---\ncreated: {created}\n\n"));
        }
        Ok(out)
    }

    pub fn upsert_bookmark(
        &self,
        time: i64,
        book_id: &str,
        book_name: &str,
        book_author: &str,
        chapter_index: i64,
        chapter_pos: i64,
        chapter_name: &str,
        book_text: &str,
        content: &str,
    ) -> Result<(), DbError> {
        self.conn.execute(
            "INSERT INTO bookmarks
             (time, book_id, book_name, book_author, chapter_index, chapter_pos,
              chapter_name, book_text, content)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
             ON CONFLICT(time) DO UPDATE SET
               book_id = excluded.book_id,
               book_name = excluded.book_name,
               book_author = excluded.book_author,
               chapter_index = excluded.chapter_index,
               chapter_pos = excluded.chapter_pos,
               chapter_name = excluded.chapter_name,
               book_text = excluded.book_text,
               content = excluded.content",
            params![
                time,
                book_id,
                book_name,
                book_author,
                chapter_index,
                chapter_pos,
                chapter_name,
                book_text,
                content,
            ],
        )?;
        Ok(())
    }

    pub fn delete_bookmark(&self, time: i64) -> Result<(), DbError> {
        self.conn
            .execute("DELETE FROM bookmarks WHERE time = ?1", params![time])?;
        Ok(())
    }

    pub fn list_bookmarks_json(&self, book_id: Option<&str>) -> Result<Vec<String>, DbError> {
        let sql = "SELECT time, book_id, book_name, book_author, chapter_index,
                          chapter_pos, chapter_name, book_text, content
                   FROM bookmarks";
        let order = " ORDER BY book_name COLLATE NOCASE, book_author COLLATE NOCASE,
                               chapter_index, chapter_pos, time";
        let mut out = Vec::new();
        if let Some(book_id) = book_id.filter(|s| !s.is_empty()) {
            let mut stmt = self
                .conn
                .prepare(&format!("{sql} WHERE book_id = ?1{order}"))?;
            let rows = stmt.query_map(params![book_id], |row| Self::map_bookmark_row(row))?;
            for row in rows {
                out.push(row.map_err(|e| DbError::Message(e.to_string()))?);
            }
        } else {
            let mut stmt = self.conn.prepare(&format!("{sql}{order}"))?;
            let rows = stmt.query_map([], |row| Self::map_bookmark_row(row))?;
            for row in rows {
                out.push(row.map_err(|e| DbError::Message(e.to_string()))?);
            }
        }
        Ok(out)
    }

    fn map_bookmark_row(row: &rusqlite::Row<'_>) -> Result<String, rusqlite::Error> {
        Ok(json!({
            "time": row.get::<_, i64>(0)?,
            "bookId": row.get::<_, String>(1)?,
            "bookName": row.get::<_, String>(2)?,
            "bookAuthor": row.get::<_, String>(3)?,
            "chapterIndex": row.get::<_, i64>(4)?,
            "chapterPos": row.get::<_, i64>(5)?,
            "chapterName": row.get::<_, String>(6)?,
            "bookText": row.get::<_, String>(7)?,
            "content": row.get::<_, String>(8)?,
        })
        .to_string())
    }

    pub fn export_reading_records(&self, format: &str) -> Result<String, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT date, book_id, book_name, read_chars, duration_seconds
             FROM reading_records ORDER BY date DESC, book_name ASC",
        )?;
        let rows = stmt
            .query_map([], |row| {
                Ok((
                    row.get::<_, String>(0)?,
                    row.get::<_, String>(1)?,
                    row.get::<_, String>(2)?,
                    row.get::<_, i64>(3)?,
                    row.get::<_, i64>(4)?,
                ))
            })?
            .map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect::<Result<Vec<_>, _>>()?;

        if format.eq_ignore_ascii_case("csv") {
            let mut out = String::from("date,book_id,book_name,read_chars,duration_seconds\n");
            for (date, book_id, book_name, chars, duration) in rows {
                let name = book_name.replace('"', "\"\"");
                out.push_str(&format!(
                    "{date},\"{book_id}\",\"{name}\",{chars},{duration}\n"
                ));
            }
            return Ok(out);
        }

        let list: Vec<Value> = rows
            .into_iter()
            .map(|(date, book_id, book_name, chars, duration)| {
                json!({
                    "date": date,
                    "bookId": book_id,
                    "bookName": book_name,
                    "readChars": chars,
                    "durationSeconds": duration,
                })
            })
            .collect();
        Ok(serde_json::to_string_pretty(&list).map_err(|e| DbError::Message(e.to_string()))?)
    }

    /// 写入详细阅读会话；短于等于两分钟的会话不计入记录。
    pub fn insert_detailed_read_session(
        &self,
        book_name: &str,
        start_time: i64,
        end_time: i64,
        read_iteration: i64,
    ) -> Result<(), DbError> {
        let book_name = book_name.trim();
        if book_name.is_empty() || end_time - start_time <= 120_000 {
            return Ok(());
        }

        let last: Option<(i64, i64)> = self
            .conn
            .query_row(
                "SELECT start_time, end_time FROM detailed_read_records
                 WHERE book_name = ?1 ORDER BY end_time DESC LIMIT 1",
                params![book_name],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .optional()?;
        if let Some((_, last_end)) = last {
            if (start_time - last_end) >= 0 && (start_time - last_end) <= 180_000 {
                self.conn.execute(
                    "UPDATE detailed_read_records SET end_time = MAX(end_time, ?1),
                     read_iteration = ?2 WHERE book_name = ?3 AND end_time = ?4",
                    params![end_time, read_iteration, book_name, last_end],
                )?;
                return Ok(());
            }
        }

        self.conn.execute(
            "INSERT INTO detailed_read_records
             (book_name, start_time, end_time, read_iteration)
             VALUES (?1, ?2, ?3, ?4)",
            params![book_name, start_time, end_time, read_iteration],
        )?;
        Ok(())
    }

    /// 导出按书分组、按开始时间排序的详细阅读会话。
    pub fn export_detailed_read_records(&self) -> Result<String, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT book_name, start_time, end_time, read_iteration
             FROM detailed_read_records ORDER BY book_name ASC, start_time ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok((
                row.get::<_, String>(0)?,
                json!({
                    "startTime": row.get::<_, i64>(1)?,
                    "endTime": row.get::<_, i64>(2)?,
                    "readIteration": row.get::<_, i64>(3)?,
                }),
            ))
        })?;
        let mut grouped = BTreeMap::<String, Vec<Value>>::new();
        for row in rows {
            let (book_name, session) = row.map_err(|e| DbError::Message(e.to_string()))?;
            grouped.entry(book_name).or_default().push(session);
        }
        let export: Vec<Value> = grouped
            .into_iter()
            .map(|(book_name, sessions)| json!({"bookName": book_name, "sessions": sessions}))
            .collect();
        serde_json::to_string_pretty(&export).map_err(|e| DbError::Message(e.to_string()))
    }

    pub fn get_all_chapters_json(&self) -> Result<Vec<String>, DbError> {
        let mut stmt = self.conn.prepare(
            "SELECT id, bookId, title, idx, url, isDownloaded, content
             FROM chapters ORDER BY bookId ASC, idx ASC",
        )?;
        let rows = stmt.query_map([], |row| {
            Ok(json!({
                "id": row.get::<_, String>(0)?,
                "bookId": row.get::<_, String>(1)?,
                "title": row.get::<_, String>(2)?,
                "index": row.get::<_, i64>(3)?,
                "url": row.get::<_, String>(4)?,
                "isDownloaded": row.get::<_, i64>(5)? == 1,
                "content": row.get::<_, Option<String>>(6)?,
            })
            .to_string())
        })?;
        rows.map(|r| r.map_err(|e| DbError::Message(e.to_string())))
            .collect()
    }

    pub fn export_backup_json(&self) -> Result<String, DbError> {
        let books: Vec<Value> = self
            .get_books_json()?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let sources: Vec<Value> = self
            .get_sources_json(false)?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let chapters: Vec<Value> = self
            .get_all_chapters_json()?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let replace_rules: Vec<Value> = self
            .get_replace_rules_json()?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let reading_records: Vec<Value> =
            serde_json::from_str(&self.export_reading_records("json")?).unwrap_or_default();
        let detailed_read_records: Vec<Value> =
            serde_json::from_str(&self.export_detailed_read_records()?).unwrap_or_default();
        let notes: Vec<Value> = self
            .list_notes_json(None)?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let bookmarks: Vec<Value> = self
            .list_bookmarks_json(None)?
            .into_iter()
            .filter_map(|s| serde_json::from_str(&s).ok())
            .collect();
        let mut legacy_stmt = self.conn.prepare(
            "SELECT fingerprint, room_version, room_identity_hash,
                    raw_snapshot_json, mapped_backup_json
             FROM legacy_room_imports ORDER BY fingerprint ASC",
        )?;
        let legacy_room_imports: Vec<Value> = legacy_stmt
            .query_map([], |row| {
                Ok(json!({
                    "fingerprint": row.get::<_, String>(0)?,
                    "roomVersion": row.get::<_, i64>(1)?,
                    "roomIdentityHash": row.get::<_, Option<String>>(2)?,
                    "rawSnapshotJson": row.get::<_, String>(3)?,
                    "mappedBackupJson": row.get::<_, String>(4)?,
                }))
            })?
            .collect::<Result<Vec<_>, _>>()?;

        Ok(json!({
            "version": 1,
            "schemaVersion": SCHEMA_VERSION,
            "books": books,
            "sources": sources,
            "chapters": chapters,
            "replaceRules": replace_rules,
            "readingRecords": reading_records,
            "detailedReadRecords": detailed_read_records,
            "notes": notes,
            "bookmarks": bookmarks,
            "legacyRoomImports": legacy_room_imports,
        })
        .to_string())
    }

    fn clear_all_for_restore(&self) -> Result<(), DbError> {
        self.conn.execute_batch(
            "DELETE FROM chapters;
             DELETE FROM books;
             DELETE FROM book_sources;
             DELETE FROM replace_rules;
             DELETE FROM reading_records;
             DELETE FROM detailed_read_records;
             DELETE FROM notes;
             DELETE FROM bookmarks;
             DELETE FROM legacy_room_imports;",
        )?;
        Ok(())
    }

    fn restore_reading_record(&self, entry: &Value) -> Result<(), DbError> {
        let book_id = str_field(entry, "bookId")?;
        let book_name = str_field(entry, "bookName").unwrap_or_default();
        let date = str_field(entry, "date")?;
        let chars = entry.get("readChars").and_then(|v| v.as_i64()).unwrap_or(0);
        let duration = entry
            .get("durationSeconds")
            .and_then(|v| v.as_i64())
            .unwrap_or(0);
        let id = format!("{book_id}_{date}");
        self.conn.execute(
            "INSERT INTO reading_records (id, book_id, book_name, date, duration_seconds, read_chars)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)
             ON CONFLICT(book_id, date) DO UPDATE SET
               read_chars = excluded.read_chars,
               duration_seconds = excluded.duration_seconds,
               book_name = excluded.book_name",
            params![id, book_id, book_name, date, duration, chars],
        )?;
        Ok(())
    }

    fn restore_note(&self, entry: &Value) -> Result<(), DbError> {
        let id = str_field(entry, "id")?;
        let book_id = str_field(entry, "bookId")?;
        let chapter_title = str_field(entry, "chapterTitle").unwrap_or_default();
        let selected_text = str_field(entry, "selectedText")?;
        let note_content = str_field(entry, "noteContent").unwrap_or_default();
        let position = entry.get("position").and_then(|v| v.as_i64()).unwrap_or(0);
        let chapter_pos = entry
            .get("chapterPos")
            .and_then(|v| v.as_i64())
            .unwrap_or(-1);
        let created_at = str_field(entry, "createdAt").unwrap_or_default();
        self.conn.execute(
            "INSERT INTO notes (id, book_id, chapter_title, selected_text, note_content, position, chapter_pos, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)
             ON CONFLICT(id) DO UPDATE SET
               chapter_title = excluded.chapter_title,
               selected_text = excluded.selected_text,
               note_content = excluded.note_content,
               position = excluded.position,
               chapter_pos = excluded.chapter_pos,
               created_at = excluded.created_at",
            params![
                id,
                book_id,
                chapter_title,
                selected_text,
                note_content,
                position,
                chapter_pos,
                created_at
            ],
        )?;
        Ok(())
    }

    fn restore_bookmark(&self, entry: &Value) -> Result<(), DbError> {
        let time = entry
            .get("time")
            .and_then(|v| v.as_i64())
            .ok_or_else(|| DbError::Message("书签缺少 time 字段".to_string()))?;
        let book_id = str_field(entry, "bookId").unwrap_or_default();
        let book_name = str_field(entry, "bookName").unwrap_or_default();
        let book_author = str_field(entry, "bookAuthor").unwrap_or_default();
        let chapter_index = entry
            .get("chapterIndex")
            .and_then(|v| v.as_i64())
            .unwrap_or(0);
        let chapter_pos = entry
            .get("chapterPos")
            .and_then(|v| v.as_i64())
            .unwrap_or(0);
        let chapter_name = str_field(entry, "chapterName").unwrap_or_default();
        let book_text = str_field(entry, "bookText").unwrap_or_default();
        let content = str_field(entry, "content").unwrap_or_default();
        self.upsert_bookmark(
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

    fn restore_legacy_room_import(&self, entry: &Value) -> Result<(), DbError> {
        self.conn.execute(
            "INSERT INTO legacy_room_imports
             (fingerprint, room_version, room_identity_hash, raw_snapshot_json, mapped_backup_json)
             VALUES (?1, ?2, ?3, ?4, ?5)
             ON CONFLICT(fingerprint) DO UPDATE SET
               room_version=excluded.room_version,
               room_identity_hash=excluded.room_identity_hash,
               raw_snapshot_json=excluded.raw_snapshot_json,
               mapped_backup_json=excluded.mapped_backup_json,
               imported_at=datetime('now')",
            params![
                str_field(entry, "fingerprint")?,
                i64_field(entry, "roomVersion"),
                opt_str_field(entry, "roomIdentityHash"),
                str_field(entry, "rawSnapshotJson")?,
                str_field(entry, "mappedBackupJson")?,
            ],
        )?;
        Ok(())
    }

    pub fn restore_backup_json(&self, raw: &str, replace: bool) -> Result<(), DbError> {
        let v: Value = serde_json::from_str(raw)
            .map_err(|e| DbError::Message(format!("备份 JSON 无效: {e}")))?;
        if replace {
            self.clear_all_for_restore()?;
        }

        if let Some(arr) = v.get("sources").and_then(|x| x.as_array()) {
            for item in arr {
                self.upsert_source_json(&item.to_string())?;
            }
        }
        if let Some(arr) = v.get("books").and_then(|x| x.as_array()) {
            for item in arr {
                self.insert_book_json(&item.to_string())?;
            }
        }
        if let Some(arr) = v.get("chapters").and_then(|x| x.as_array()) {
            if !arr.is_empty() {
                self.insert_chapters_json(&serde_json::to_string(arr).unwrap())?;
            }
        }
        if let Some(arr) = v.get("replaceRules").and_then(|x| x.as_array()) {
            for item in arr {
                self.upsert_replace_rule_json(&item.to_string())?;
            }
        }
        if let Some(arr) = v.get("readingRecords").and_then(|x| x.as_array()) {
            for item in arr {
                self.restore_reading_record(item)?;
            }
        }
        if let Some(groups) = v.get("detailedReadRecords").and_then(|x| x.as_array()) {
            for group in groups {
                let book_name = str_field(group, "bookName").unwrap_or_default();
                if let Some(sessions) = group.get("sessions").and_then(|x| x.as_array()) {
                    for session in sessions {
                        self.insert_detailed_read_session(
                            &book_name,
                            session
                                .get("startTime")
                                .and_then(|x| x.as_i64())
                                .unwrap_or(0),
                            session.get("endTime").and_then(|x| x.as_i64()).unwrap_or(0),
                            session
                                .get("readIteration")
                                .and_then(|x| x.as_i64())
                                .unwrap_or(0),
                        )?;
                    }
                }
            }
        }
        if let Some(arr) = v.get("notes").and_then(|x| x.as_array()) {
            for item in arr {
                self.restore_note(item)?;
            }
        }
        if let Some(arr) = v
            .get("bookmarks")
            .or_else(|| v.get("bookmark"))
            .and_then(|x| x.as_array())
        {
            for item in arr {
                self.restore_bookmark(item)?;
            }
        }
        if let Some(arr) = v.get("legacyRoomImports").and_then(|x| x.as_array()) {
            for item in arr {
                self.restore_legacy_room_import(item)?;
            }
        }
        Ok(())
    }
}

fn write_import_backup(path: &str, backup_json: &str) -> Result<(), DbError> {
    let destination = Path::new(path);
    if destination.exists() {
        return Err(DbError::Message(format!(
            "导入前备份路径已存在，为避免覆盖拒绝写入: {path}"
        )));
    }
    let parent = destination
        .parent()
        .filter(|path| !path.as_os_str().is_empty());
    if let Some(parent) = parent {
        if !parent.exists() {
            return Err(DbError::Message(format!(
                "导入前备份目录不存在: {}",
                parent.display()
            )));
        }
    }
    let temporary = format!("{path}.tmp-{}", std::process::id());
    fs::write(&temporary, backup_json)
        .map_err(|error| DbError::Message(format!("写入导入前备份失败: {error}")))?;
    if let Err(error) = fs::rename(&temporary, destination) {
        let _ = fs::remove_file(&temporary);
        return Err(DbError::Message(format!("完成导入前备份失败: {error}")));
    }
    Ok(())
}

fn import_conflict_counts(
    conn: &Connection,
    backup: &Value,
) -> Result<BTreeMap<String, usize>, DbError> {
    let mappings = [
        ("books", "books", "id"),
        ("sources", "book_sources", "bookSourceUrl"),
        ("chapters", "chapters", "id"),
        ("replaceRules", "replace_rules", "id"),
        ("bookmarks", "bookmarks", "time"),
    ];
    let mut conflicts = BTreeMap::new();
    for (json_key, table, key) in mappings {
        let Some(rows) = backup.get(json_key).and_then(Value::as_array) else {
            continue;
        };
        let mut count = 0usize;
        for row in rows {
            let Some(value) = row.get(key) else {
                continue;
            };
            let exists: i64 = conn.query_row(
                &format!("SELECT EXISTS(SELECT 1 FROM {table} WHERE {key}=?1)"),
                [sqlite_param(value)],
                |result| result.get(0),
            )?;
            count += usize::from(exists == 1);
        }
        if count > 0 {
            conflicts.insert(json_key.to_string(), count);
        }
    }
    Ok(conflicts)
}

fn sqlite_param(value: &Value) -> String {
    match value {
        Value::String(value) => value.clone(),
        Value::Number(value) => value.to_string(),
        Value::Bool(value) => value.to_string(),
        Value::Null => String::new(),
        other => other.to_string(),
    }
}

pub fn init_global(path: &str) -> Result<(), DbError> {
    let db = EngineDb::open(path)?;
    DB.set(Mutex::new(db))
        .map_err(|_| DbError::Message("数据库已初始化".into()))?;
    Ok(())
}

pub fn is_initialized() -> bool {
    DB.get().is_some()
}

fn with_db<F, T>(f: F) -> Result<T, String>
where
    F: FnOnce(&EngineDb) -> Result<T, DbError>,
{
    let cell = DB.get().ok_or_else(|| "数据库未初始化".to_string())?;
    let guard = cell.lock().map_err(|_| "数据库锁失败".to_string())?;
    f(&guard).map_err(|e| e.to_string())
}

pub fn db_init(path: String) -> Result<(), String> {
    init_global(&path).map_err(|e| e.to_string())
}

pub fn db_schema_version() -> Result<i32, String> {
    with_db(|db| db.schema_version())
}

pub fn db_probe_legacy_room_database(path: String) -> Result<String, String> {
    room_import::probe_legacy_room_database(&path)
        .map(|probe| {
            json!({
                "userVersion": probe.user_version,
                "currentRoomVersion": room_import::KOTLIN_ROOM_CURRENT_VERSION,
                "roomIdentityHash": probe.room_identity_hash,
                "hasRequiredCoreShape": probe.has_required_core_shape(),
                "needsKotlinRoomMigration": probe.needs_kotlin_room_migration(),
                "missingTables": probe.missing_tables,
                "missingColumns": probe.missing_columns,
            })
            .to_string()
        })
        .map_err(|e| e.to_string())
}

pub fn db_import_legacy_room_database(
    path: String,
    backup_path: Option<String>,
    replace: bool,
) -> Result<String, String> {
    with_db(|db| {
        let report = db.import_legacy_room_database(&path, backup_path.as_deref(), replace)?;
        serde_json::to_string(&report).map_err(|e| DbError::Message(e.to_string()))
    })
}

pub fn db_insert_book(book_json: String) -> Result<(), String> {
    with_db(|db| db.insert_book_json(&book_json))
}

pub fn db_get_books() -> Result<Vec<String>, String> {
    with_db(|db| db.get_books_json())
}

pub fn db_delete_book(book_id: String) -> Result<(), String> {
    with_db(|db| db.delete_book(&book_id))
}

pub fn db_upsert_source(source_json: String) -> Result<(), String> {
    with_db(|db| db.upsert_source_json(&source_json))
}

pub fn db_get_sources(enabled_only: bool) -> Result<Vec<String>, String> {
    with_db(|db| db.get_sources_json(enabled_only))
}

pub fn db_insert_chapters(chapters_json: String) -> Result<(), String> {
    with_db(|db| db.insert_chapters_json(&chapters_json))
}

pub fn db_get_chapters(book_id: String) -> Result<Vec<String>, String> {
    with_db(|db| db.get_chapters_json(&book_id))
}

pub fn db_get_chapter_content(chapter_id: String) -> Result<Option<String>, String> {
    with_db(|db| db.get_chapter_content(&chapter_id))
}

pub fn db_update_book_progress(
    book_id: String,
    progress: f64,
    chapter: Option<String>,
    page_index: i32,
) -> Result<(), String> {
    with_db(|db| {
        db.update_book_progress(
            &book_id,
            progress,
            chapter.as_deref(),
            page_index as i64,
            None,
        )
    })
}

pub fn db_update_book_cover(book_id: String, cover_url: String) -> Result<(), String> {
    with_db(|db| db.update_book_cover(&book_id, &cover_url))
}

pub fn db_update_book_group(book_id: String, group: String) -> Result<(), String> {
    with_db(|db| db.update_book_group(&book_id, &group))
}

pub fn db_save_chapter_content(chapter_id: String, content: String) -> Result<(), String> {
    with_db(|db| db.save_chapter_content(&chapter_id, &content))
}

pub fn db_toggle_source(url: String, enabled: bool) -> Result<(), String> {
    with_db(|db| db.toggle_source(&url, enabled))
}

pub fn db_delete_source(url: String) -> Result<(), String> {
    with_db(|db| db.delete_source(&url))
}

pub fn db_upsert_replace_rule(rule_json: String) -> Result<(), String> {
    with_db(|db| db.upsert_replace_rule_json(&rule_json))
}

pub fn db_get_replace_rules() -> Result<Vec<String>, String> {
    with_db(|db| db.get_replace_rules_json())
}

pub fn db_toggle_replace_rule(id: String, enabled: bool) -> Result<(), String> {
    with_db(|db| db.toggle_replace_rule(&id, enabled))
}

pub fn db_delete_replace_rule(id: String) -> Result<(), String> {
    with_db(|db| db.delete_replace_rule(&id))
}

pub fn db_clear_replace_rules() -> Result<(), String> {
    with_db(|db| db.clear_replace_rules())
}

pub fn db_record_reading(
    book_id: String,
    book_name: String,
    chars: i32,
    duration_seconds: i32,
) -> Result<(), String> {
    with_db(|db| db.record_reading(&book_id, &book_name, chars as i64, duration_seconds as i64))
}

pub fn db_get_reading_stats(range: String) -> Result<String, String> {
    with_db(|db| db.get_reading_stats_json(&range))
}

pub fn db_get_book_reading_stats(book_id: String) -> Result<String, String> {
    with_db(|db| db.get_book_reading_stats_json(&book_id))
}

pub fn db_upsert_note(
    id: String,
    book_id: String,
    chapter_title: String,
    selected_text: String,
    note_content: String,
    position: i32,
    chapter_pos: i32,
) -> Result<(), String> {
    with_db(|db| {
        db.upsert_note(
            &id,
            &book_id,
            &chapter_title,
            &selected_text,
            &note_content,
            position as i64,
            chapter_pos as i64,
        )
    })
}

pub fn db_delete_note(id: String) -> Result<(), String> {
    with_db(|db| db.delete_note(&id))
}

pub fn db_list_notes(book_id: Option<String>) -> Result<Vec<String>, String> {
    with_db(|db| db.list_notes_json(book_id.as_deref().filter(|s| !s.is_empty())))
}

pub fn db_export_notes_markdown(book_id: Option<String>) -> Result<String, String> {
    with_db(|db| db.export_notes_markdown(book_id.as_deref().filter(|s| !s.is_empty())))
}

pub fn db_upsert_bookmark(
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
    with_db(|db| {
        db.upsert_bookmark(
            time,
            &book_id,
            &book_name,
            &book_author,
            chapter_index as i64,
            chapter_pos as i64,
            &chapter_name,
            &book_text,
            &content,
        )
    })
}

pub fn db_delete_bookmark(time: i64) -> Result<(), String> {
    with_db(|db| db.delete_bookmark(time))
}

pub fn db_list_bookmarks(book_id: Option<String>) -> Result<Vec<String>, String> {
    with_db(|db| db.list_bookmarks_json(book_id.as_deref().filter(|s| !s.is_empty())))
}

pub fn db_export_reading_records(format: String) -> Result<String, String> {
    with_db(|db| db.export_reading_records(&format))
}

pub fn db_record_detailed_read_session(
    book_name: String,
    start_time: i64,
    end_time: i64,
    read_iteration: i64,
) -> Result<(), String> {
    with_db(|db| db.insert_detailed_read_session(&book_name, start_time, end_time, read_iteration))
}

pub fn db_export_detailed_read_records() -> Result<String, String> {
    with_db(|db| db.export_detailed_read_records())
}

pub fn db_export_backup() -> Result<String, String> {
    with_db(|db| db.export_backup_json())
}

pub fn db_restore_backup(json: String, replace: bool) -> Result<(), String> {
    with_db(|db| db.restore_backup_json(&json, replace))
}

fn str_field(v: &Value, key: &str) -> Result<String, DbError> {
    v.get(key)
        .and_then(|x| {
            if x.is_null() {
                None
            } else {
                Some(x.as_str().unwrap_or(&x.to_string()).to_string())
            }
        })
        .ok_or_else(|| DbError::Message(format!("缺少字段 {key}")))
}

fn opt_str_field(v: &Value, key: &str) -> Option<String> {
    v.get(key).and_then(|x| {
        if x.is_null() {
            None
        } else {
            Some(x.as_str().unwrap_or(&x.to_string()).to_string())
        }
    })
}

fn bool_field(v: &Value, key: &str) -> bool {
    v.get(key)
        .and_then(|x| x.as_bool())
        .unwrap_or_else(|| v.get(key).and_then(|x| x.as_i64()).unwrap_or(1) == 1)
}

/// 将 DB 行合并为书源 JSON：`rawSourceJson` 保留规则，但 `enabled` 等以列为准。
fn source_row_to_json(row: &rusqlite::Row<'_>) -> Result<String, rusqlite::Error> {
    let raw: String = row.get(0)?;
    let url: String = row.get(1)?;
    let name: String = row.get(2)?;
    let enabled: i64 = row.get(3)?;
    let group: String = row.get(4)?;
    let search_url: String = row.get(5)?;

    if !raw.is_empty() {
        if let Ok(mut v) = serde_json::from_str::<Value>(&raw) {
            if let Some(obj) = v.as_object_mut() {
                obj.insert("enabled".to_string(), json!(enabled == 1));
                if !group.is_empty() {
                    obj.insert("bookSourceGroup".to_string(), json!(group));
                }
            }
            return Ok(v.to_string());
        }
    }

    Ok(json!({
        "bookSourceUrl": url,
        "bookSourceName": name,
        "enabled": enabled == 1,
        "bookSourceGroup": group,
        "ruleSearchUrl": search_url,
    })
    .to_string())
}

fn f64_field(v: &Value, key: &str) -> f64 {
    v.get(key).and_then(|x| x.as_f64()).unwrap_or(0.0)
}

fn i64_field(v: &Value, key: &str) -> i64 {
    v.get(key)
        .and_then(|x| x.as_i64())
        .unwrap_or_else(|| v.get(key).and_then(|x| x.as_f64()).unwrap_or(0.0) as i64)
}

fn i64_field_idx(v: &Value, key: &str) -> i64 {
    v.get(key)
        .or_else(|| v.get("idx"))
        .and_then(|x| x.as_i64())
        .unwrap_or(0)
}

fn read_config_json(v: &Value) -> String {
    let mut config = match v.get("readConfig") {
        Some(Value::Object(map)) => Value::Object(map.clone()),
        _ => json!({}),
    };
    if let Value::Object(map) = &mut config {
        if !map.contains_key("reverseToc") {
            let reverse = v
                .get("reverseToc")
                .and_then(Value::as_bool)
                .unwrap_or(false);
            map.insert("reverseToc".to_string(), json!(reverse));
        }
    }
    config.to_string()
}

fn parse_read_config(raw: Option<String>) -> Value {
    let mut config = raw
        .and_then(|value| serde_json::from_str::<Value>(&value).ok())
        .filter(Value::is_object)
        .unwrap_or_else(|| json!({}));
    if let Value::Object(map) = &mut config {
        map.entry("reverseToc").or_insert_with(|| json!(false));
    }
    config
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn in_memory_db_schema_and_book_roundtrip() {
        let db = EngineDb::open_in_memory().unwrap();
        assert_eq!(db.schema_version().unwrap(), SCHEMA_VERSION);
        db.insert_book_json(
            r#"{"id":"b1","name":"斗破","author":"土豆","sourceUrl":"http://x/1"}"#,
        )
        .unwrap();
        assert_eq!(db.book_count().unwrap(), 1);
        let books = db.get_books_json().unwrap();
        assert_eq!(books.len(), 1);
        assert!(books[0].contains("斗破"));
        let book: Value = serde_json::from_str(&books[0]).unwrap();
        assert_eq!(
            book.get("simReadEnabled").and_then(|x| x.as_bool()),
            Some(false)
        );
        assert_eq!(
            book.get("simReadDailyChapters").and_then(|x| x.as_i64()),
            Some(3)
        );
        assert_eq!(
            book.get("readConfig")
                .and_then(|x| x.get("reverseToc"))
                .and_then(|x| x.as_bool()),
            Some(false)
        );

        db.insert_book_json(
            r#"{"id":"b1","name":"斗破","author":"土豆","sourceUrl":"http://x/1",
                "simReadEnabled":true,"simReadStartDate":"2026-07-01",
                "simReadStartChapter":2,"simReadDailyChapters":5}"#,
        )
        .unwrap();
        let books2 = db.get_books_json().unwrap();
        let book2: Value = serde_json::from_str(&books2[0]).unwrap();
        assert_eq!(
            book2.get("simReadEnabled").and_then(|x| x.as_bool()),
            Some(true)
        );
        assert_eq!(
            book2.get("simReadStartDate").and_then(|x| x.as_str()),
            Some("2026-07-01")
        );
        assert_eq!(
            book2.get("simReadStartChapter").and_then(|x| x.as_i64()),
            Some(2)
        );
        assert_eq!(
            book2.get("simReadDailyChapters").and_then(|x| x.as_i64()),
            Some(5)
        );

        db.insert_book_json(
            r#"{"id":"b1","name":"斗破","readConfig":{"reverseToc":true,"pageAnim":2}}"#,
        )
        .unwrap();
        let books3 = db.get_books_json().unwrap();
        let book3: Value = serde_json::from_str(&books3[0]).unwrap();
        assert_eq!(
            book3
                .get("readConfig")
                .and_then(|x| x.get("reverseToc"))
                .and_then(|x| x.as_bool()),
            Some(true)
        );
        assert_eq!(
            book3
                .get("readConfig")
                .and_then(|x| x.get("pageAnim"))
                .and_then(|x| x.as_i64()),
            Some(2)
        );
    }

    #[test]
    fn read_config_survives_database_reopen() {
        let path = std::env::temp_dir().join(format!(
            "legado-read-config-{}-{}.db",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let path_str = path.to_string_lossy().to_string();
        {
            let db = EngineDb::open(&path_str).unwrap();
            db.insert_book_json(
                r#"{"id":"reopen-book","name":"重启测试","readConfig":{"reverseToc":true}}"#,
            )
            .unwrap();
        }
        {
            let db = EngineDb::open(&path_str).unwrap();
            let books = db.get_books_json().unwrap();
            let book: Value = serde_json::from_str(&books[0]).unwrap();
            assert_eq!(
                book.get("readConfig")
                    .and_then(|x| x.get("reverseToc"))
                    .and_then(|x| x.as_bool()),
                Some(true)
            );
        }
        let _ = std::fs::remove_file(path);
    }

    #[test]
    fn legacy_v7_schema_migrates_to_current_without_losing_book_rows() {
        let conn = Connection::open_in_memory().unwrap();
        conn.execute_batch(
            "CREATE TABLE books (
               id TEXT PRIMARY KEY,
               name TEXT NOT NULL,
               author TEXT DEFAULT '',
               sourceUrl TEXT DEFAULT ''
             );
             CREATE TABLE book_sources (
               bookSourceUrl TEXT PRIMARY KEY,
               bookSourceName TEXT NOT NULL
             );
             CREATE TABLE chapters (
               id TEXT PRIMARY KEY,
               bookId TEXT NOT NULL,
               title TEXT NOT NULL,
               idx INTEGER NOT NULL,
               url TEXT DEFAULT ''
             );
             CREATE TABLE replace_rules (
               id TEXT PRIMARY KEY,
               pattern TEXT NOT NULL
             );
             CREATE TABLE notes (
               id TEXT PRIMARY KEY,
               book_id TEXT NOT NULL,
               selected_text TEXT NOT NULL
             );
             INSERT INTO books (id, name, author, sourceUrl)
               VALUES ('legacy-book', '旧书', '旧作者', 'https://example.test/book');
             PRAGMA user_version = 7;",
        )
        .unwrap();

        EngineDb::init_schema(&conn).unwrap();

        let version: i32 = conn
            .query_row("PRAGMA user_version", [], |row| row.get(0))
            .unwrap();
        assert_eq!(version, SCHEMA_VERSION);
        let book: (String, String, String) = conn
            .query_row(
                "SELECT id, name, author FROM books WHERE id = 'legacy-book'",
                [],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
            )
            .unwrap();
        assert_eq!(book, ("legacy-book".into(), "旧书".into(), "旧作者".into()));

        for (table, column) in [
            ("books", "readIteration"),
            ("books", "simReadEnabled"),
            ("books", "totalChapterNum"),
            ("books", "durChapterIndex"),
            ("books", "readConfig"),
            ("books", "tocUrl"),
            ("notes", "chapter_pos"),
        ] {
            let exists: i32 = conn
                .query_row(
                    &format!(
                        "SELECT COUNT(*) FROM pragma_table_info('{table}') WHERE name = '{column}'"
                    ),
                    [],
                    |row| row.get(0),
                )
                .unwrap();
            assert_eq!(exists, 1, "missing migrated column {table}.{column}");
        }

        conn.execute(
            "UPDATE books SET tocUrl = ?1 WHERE id = 'legacy-book'",
            params!["https://example.test/book/toc"],
        )
        .unwrap();
        let toc_url: String = conn
            .query_row(
                "SELECT tocUrl FROM books WHERE id = 'legacy-book'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(toc_url, "https://example.test/book/toc");
    }

    #[test]
    fn book_toc_url_json_roundtrip() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(
            r#"{"id":"toc-book","name":"目录书","tocUrl":"https://example.test/toc"}"#,
        )
        .unwrap();

        let books = db.get_books_json().unwrap();
        let book: Value = serde_json::from_str(&books[0]).unwrap();
        assert_eq!(
            book.get("tocUrl").and_then(|value| value.as_str()),
            Some("https://example.test/toc")
        );

        db.insert_book_json(
            r#"{"id":"toc-book","name":"目录书","tocUrl":"https://example.test/toc?page=2"}"#,
        )
        .unwrap();
        let updated: Value = serde_json::from_str(&db.get_books_json().unwrap()[0]).unwrap();
        assert_eq!(
            updated.get("tocUrl").and_then(|value| value.as_str()),
            Some("https://example.test/toc?page=2")
        );
    }

    #[test]
    fn book_total_and_dur_chapter_roundtrip() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(
            r#"{"id":"b2","name":"角标","totalChapterNum":120,"durChapterIndex":49,
                "currentChapter":"第50章","lastChapter":"第120章"}"#,
        )
        .unwrap();
        let books = db.get_books_json().unwrap();
        let book: Value = serde_json::from_str(&books[0]).unwrap();
        assert_eq!(
            book.get("totalChapterNum").and_then(|x| x.as_i64()),
            Some(120)
        );
        assert_eq!(
            book.get("durChapterIndex").and_then(|x| x.as_i64()),
            Some(49)
        );

        db.update_book_progress("b2", 0.5, Some("第60章"), 0, Some(59))
            .unwrap();
        let books2 = db.get_books_json().unwrap();
        let book2: Value = serde_json::from_str(&books2[0]).unwrap();
        assert_eq!(
            book2.get("durChapterIndex").and_then(|x| x.as_i64()),
            Some(59)
        );
        assert_eq!(
            book2.get("currentChapter").and_then(|x| x.as_str()),
            Some("第60章")
        );
    }

    #[test]
    fn chapter_cache_metadata_can_be_explicitly_cleared() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(r#"{"id":"cache-book","name":"缓存书"}"#)
            .unwrap();
        db.insert_chapters_json(
            r#"[{"id":"cache-chapter","bookId":"cache-book","title":"第一章",
                "index":0,"url":"/1","isDownloaded":true,"content":"正文"}]"#,
        )
        .unwrap();
        assert_eq!(
            db.get_chapter_content("cache-chapter").unwrap(),
            Some("正文".to_string())
        );

        db.insert_chapters_json(
            r#"[{"id":"cache-chapter","bookId":"cache-book","title":"第一章",
                "index":0,"url":"/1","isDownloaded":false,"content":null,
                "clearDownloaded":true}]"#,
        )
        .unwrap();
        let chapters = db.get_chapters_json("cache-book").unwrap();
        let chapter: Value = serde_json::from_str(&chapters[0]).unwrap();
        assert_eq!(
            chapter.get("isDownloaded").and_then(|v| v.as_bool()),
            Some(false)
        );
        assert_eq!(db.get_chapter_content("cache-chapter").unwrap(), None);
    }

    #[test]
    fn source_toggle_persists_over_raw_json() {
        let db = EngineDb::open_in_memory().unwrap();
        db.upsert_source_json(
            r#"{"bookSourceUrl":"https://a.test","bookSourceName":"A","enabled":true,"rawSourceJson":"{\"bookSourceUrl\":\"https://a.test\",\"enabled\":true}"}"#,
        )
        .unwrap();
        db.toggle_source("https://a.test", false).unwrap();

        let all = db.get_sources_json(false).unwrap();
        assert_eq!(all.len(), 1);
        let v: Value = serde_json::from_str(&all[0]).unwrap();
        assert_eq!(v.get("enabled").and_then(|x| x.as_bool()), Some(false));

        let enabled_only = db.get_sources_json(true).unwrap();
        assert!(enabled_only.is_empty());
    }

    #[test]
    fn backup_export_restore_roundtrip() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(
            r#"{"id":"b1","name":"测试书","author":"作者","bookSourceUrl":"https://x.com"}"#,
        )
        .unwrap();
        db.upsert_source_json(
            r#"{"bookSourceUrl":"https://x.com","bookSourceName":"测试源","enabled":true}"#,
        )
        .unwrap();
        db.insert_chapters_json(
            r#"[{"id":"c1","bookId":"b1","title":"第一章","index":0,"url":"/1"}]"#,
        )
        .unwrap();
        db.insert_detailed_read_session("测试书", 1_000_000, 1_120_001, 1)
            .unwrap();

        let backup = db.export_backup_json().unwrap();
        assert!(backup.contains("测试书"));
        assert!(backup.contains("测试源"));
        assert!(backup.contains("detailedReadRecords"));

        let db2 = EngineDb::open_in_memory().unwrap();
        db2.restore_backup_json(&backup, true).unwrap();
        assert_eq!(db2.get_books_json().unwrap().len(), 1);
        assert_eq!(db2.get_sources_json(false).unwrap().len(), 1);
        assert_eq!(db2.get_chapters_json("b1").unwrap().len(), 1);
        let detailed: Vec<Value> =
            serde_json::from_str(&db2.export_detailed_read_records().unwrap()).unwrap();
        assert_eq!(detailed.len(), 1);
    }

    #[test]
    fn reading_records_accumulate_and_export() {
        let db = EngineDb::open_in_memory().unwrap();
        db.record_reading("b1", "斗破", 1000, 300).unwrap();
        db.record_reading("b1", "斗破", 500, 120).unwrap();
        db.record_reading("b2", "遮天", 800, 200).unwrap();

        let stats_json = db.get_reading_stats_json("month").unwrap();
        let stats: Value = serde_json::from_str(&stats_json).unwrap();
        assert_eq!(stats.get("totalChars").and_then(|x| x.as_i64()), Some(2300));
        assert_eq!(stats.get("todayChars").and_then(|x| x.as_i64()), Some(2300));

        let csv = db.export_reading_records("csv").unwrap();
        assert!(csv.starts_with("date,book_id,book_name,read_chars,duration_seconds"));
        assert!(csv.contains("斗破"));
        assert!(csv.contains("1500"));

        let json = db.export_reading_records("json").unwrap();
        let rows: Vec<Value> = serde_json::from_str(&json).unwrap();
        assert_eq!(rows.len(), 2);

        let book_stats_json = db.get_book_reading_stats_json("b1").unwrap();
        let book_stats: Value = serde_json::from_str(&book_stats_json).unwrap();
        assert_eq!(
            book_stats.get("readChars").and_then(|x| x.as_i64()),
            Some(1500)
        );
        assert_eq!(
            book_stats.get("durationSeconds").and_then(|x| x.as_i64()),
            Some(420)
        );
        assert_eq!(
            book_stats.get("readingDays").and_then(|x| x.as_i64()),
            Some(1)
        );
    }

    #[test]
    fn detailed_read_sessions_filter_and_merge() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_detailed_read_session("斗破", 1_000_000, 1_120_000, 1)
            .unwrap();
        db.insert_detailed_read_session("斗破", 1_000_000, 1_120_001, 1)
            .unwrap();
        db.insert_detailed_read_session("斗破", 1_300_001, 1_420_002, 2)
            .unwrap();
        db.insert_detailed_read_session("遮天", 2_000_000, 2_120_001, 0)
            .unwrap();

        let value: Value =
            serde_json::from_str(&db.export_detailed_read_records().unwrap()).unwrap();
        assert_eq!(value.as_array().unwrap().len(), 2);
        let doupo = &value.as_array().unwrap()[0];
        assert_eq!(doupo["bookName"], "斗破");
        assert_eq!(doupo["sessions"].as_array().unwrap().len(), 1);
        assert_eq!(doupo["sessions"][0]["startTime"], 1_000_000);
        assert_eq!(doupo["sessions"][0]["endTime"], 1_420_002);
        assert_eq!(doupo["sessions"][0]["readIteration"], 2);
    }

    #[test]
    fn notes_crud_and_markdown_export() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(
            r#"{"id":"b1","name":"测试书","author":"作者","bookSourceUrl":"https://x.com"}"#,
        )
        .unwrap();

        db.upsert_note("n1", "b1", "第一章", "选中片段", "我的想法", 120, 42)
            .unwrap();

        let notes = db.list_notes_json(Some("b1")).unwrap();
        assert_eq!(notes.len(), 1);
        assert!(notes[0].contains("我的想法"));
        assert!(notes[0].contains("\"chapterPos\":42"));

        db.upsert_note("n1", "b1", "第一章", "选中片段", "更新内容", 120, 42)
            .unwrap();
        let notes2 = db.list_notes_json(None).unwrap();
        assert!(notes2[0].contains("更新内容"));

        let md = db.export_notes_markdown(Some("b1")).unwrap();
        assert!(md.contains("> 选中片段"));
        assert!(md.contains("更新内容"));

        db.delete_note("n1").unwrap();
        assert!(db.list_notes_json(Some("b1")).unwrap().is_empty());
    }

    #[test]
    fn bookmarks_roundtrip_fields_and_original_order() {
        let db = EngineDb::open_in_memory().unwrap();
        assert_eq!(db.schema_version().unwrap(), SCHEMA_VERSION);
        db.upsert_bookmark(
            200,
            "b1",
            "测试书",
            "作者乙",
            2,
            80,
            "第三章",
            "正文片段",
            "",
        )
        .unwrap();
        db.upsert_bookmark(
            100,
            "b1",
            "测试书",
            "作者乙",
            1,
            20,
            "第二章",
            "较早片段",
            "备注",
        )
        .unwrap();

        let rows = db.list_bookmarks_json(Some("b1")).unwrap();
        assert_eq!(rows.len(), 2);
        assert!(rows[0].contains("\"time\":100"));
        assert!(rows[0].contains("\"bookAuthor\":\"作者乙\""));
        assert!(rows[0].contains("\"chapterName\":\"第二章\""));
        assert!(rows[0].contains("\"bookText\":\"较早片段\""));

        db.upsert_bookmark(
            100,
            "b1",
            "测试书",
            "作者乙",
            1,
            20,
            "第二章",
            "更新片段",
            "备注",
        )
        .unwrap();
        let updated = db.list_bookmarks_json(Some("b1")).unwrap();
        assert_eq!(updated.len(), 2);
        assert!(updated[0].contains("更新片段"));

        db.delete_bookmark(100).unwrap();
        assert_eq!(db.list_bookmarks_json(Some("b1")).unwrap().len(), 1);
    }

    #[test]
    fn bookmarks_backup_export_restore_roundtrip() {
        let db = EngineDb::open_in_memory().unwrap();
        db.upsert_bookmark(
            123456,
            "b1",
            "备份书",
            "备份作者",
            7,
            99,
            "第八章",
            "书签正文",
            "书签备注",
        )
        .unwrap();
        let backup = db.export_backup_json().unwrap();
        assert!(backup.contains("\"bookmarks\""));
        assert!(backup.contains("备份作者"));

        let restored = EngineDb::open_in_memory().unwrap();
        restored.restore_backup_json(&backup, true).unwrap();
        let rows = restored.list_bookmarks_json(None).unwrap();
        assert_eq!(rows.len(), 1);
        assert!(rows[0].contains("\"chapterPos\":99"));
        assert!(rows[0].contains("\"content\":\"书签备注\""));
    }
}
