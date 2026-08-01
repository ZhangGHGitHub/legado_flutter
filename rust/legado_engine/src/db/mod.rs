//! Rust 本地数据库 — 与 Flutter `legado.db` schema v7 对齐（Phase C）

use once_cell::sync::OnceCell;
use rusqlite::{params, Connection, OptionalExtension};
use serde_json::{json, Value};
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use thiserror::Error;

pub(crate) mod room_import;

const SCHEMA_VERSION: i32 = 17;

static DB: OnceCell<Mutex<EngineDb>> = OnceCell::new();
static DB_INIT_LOCK: Mutex<()> = Mutex::new(());

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
    path: PathBuf,
}

impl EngineDb {
    pub fn open(path: &str) -> Result<Self, DbError> {
        let conn = Connection::open(path)?;
        let normalized_path = normalize_db_path(path);
        Self::init_schema(&conn)?;
        Ok(Self {
            conn,
            path: normalized_path,
        })
    }

    pub fn open_in_memory() -> Result<Self, DbError> {
        Self::open(":memory:")
    }

    fn init_schema(conn: &Connection) -> Result<(), DbError> {
        // foreign_keys must be enabled before opening the transaction; SQLite ignores
        // changes to this pragma while a transaction is active.
        conn.execute_batch("PRAGMA foreign_keys = ON;")?;
        let transaction = conn.unchecked_transaction()?;
        let conn = &transaction;

        conn.execute_batch(
            "CREATE TABLE IF NOT EXISTS books (
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
            add_column_if_missing(
                conn,
                "books",
                "readIteration",
                "ALTER TABLE books ADD COLUMN readIteration INTEGER DEFAULT 0",
            )?;
        }
        if current < 11 {
            add_column_if_missing(
                conn,
                "books",
                "simReadEnabled",
                "ALTER TABLE books ADD COLUMN simReadEnabled INTEGER DEFAULT 0",
            )?;
            add_column_if_missing(
                conn,
                "books",
                "simReadStartDate",
                "ALTER TABLE books ADD COLUMN simReadStartDate TEXT DEFAULT ''",
            )?;
            add_column_if_missing(
                conn,
                "books",
                "simReadStartChapter",
                "ALTER TABLE books ADD COLUMN simReadStartChapter INTEGER DEFAULT 0",
            )?;
            add_column_if_missing(
                conn,
                "books",
                "simReadDailyChapters",
                "ALTER TABLE books ADD COLUMN simReadDailyChapters INTEGER DEFAULT 3",
            )?;
        }
        if current < 12 {
            // 书架未读角标：总章数 / 当前章索引（旧库 ALTER；新库 CREATE 已含）
            add_column_if_missing(
                conn,
                "books",
                "totalChapterNum",
                "ALTER TABLE books ADD COLUMN totalChapterNum INTEGER DEFAULT 0",
            )?;
            add_column_if_missing(
                conn,
                "books",
                "durChapterIndex",
                "ALTER TABLE books ADD COLUMN durChapterIndex INTEGER DEFAULT 0",
            )?;
        }
        if current < 13 {
            // 书签章内字符偏移（对齐 Jingshiro Bookmark.chapterPos）
            add_column_if_missing(
                conn,
                "notes",
                "chapter_pos",
                "ALTER TABLE notes ADD COLUMN chapter_pos INTEGER NOT NULL DEFAULT -1",
            )?;
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
            add_column_if_missing(
                conn,
                "books",
                "readConfig",
                "ALTER TABLE books ADD COLUMN readConfig TEXT DEFAULT '{}'",
            )?;
        }
        if current < 17 {
            add_column_if_missing(
                conn,
                "books",
                "tocUrl",
                "ALTER TABLE books ADD COLUMN tocUrl TEXT DEFAULT ''",
            )?;
        }
        if current < SCHEMA_VERSION {
            conn.execute_batch(&format!("PRAGMA user_version = {SCHEMA_VERSION};"))?;
        }
        transaction.commit()?;
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
            self.restore_backup_json_inner(&mapping.backup_json, false)?;
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
        let rule_search_list = nested_or_flat_str(&v, "ruleSearch", "bookList", "ruleSearchList");
        let rule_search_name = nested_or_flat_str(&v, "ruleSearch", "name", "ruleSearchName");
        let rule_search_author = nested_or_flat_str(&v, "ruleSearch", "author", "ruleSearchAuthor");
        let rule_search_cover_url =
            nested_or_flat_str(&v, "ruleSearch", "coverUrl", "ruleSearchCoverUrl");
        let rule_search_kind = nested_or_flat_str(&v, "ruleSearch", "kind", "ruleSearchKind");
        let rule_search_note = nested_or_flat_str(&v, "ruleSearch", "note", "ruleSearchNote");
        let rule_book_url_pattern =
            nested_or_flat_str(&v, "ruleBookInfo", "bookUrl", "ruleBookUrlPattern");
        let rule_book_name = nested_or_flat_str(&v, "ruleBookInfo", "name", "ruleBookName");
        let rule_book_author = nested_or_flat_str(&v, "ruleBookInfo", "author", "ruleBookAuthor");
        let rule_book_cover_url =
            nested_or_flat_str(&v, "ruleBookInfo", "coverUrl", "ruleBookCoverUrl");
        let rule_book_kind = nested_or_flat_str(&v, "ruleBookInfo", "kind", "ruleBookKind");
        let rule_book_note = nested_or_flat_str(&v, "ruleBookInfo", "intro", "ruleBookNote");
        let rule_book_last_chapter =
            nested_or_flat_str(&v, "ruleBookInfo", "lastChapter", "ruleBookLastChapter");
        let rule_chapter_list = nested_or_flat_str(&v, "ruleToc", "chapterList", "ruleChapterList");
        let rule_chapter_name = nested_or_flat_str(&v, "ruleToc", "chapterName", "ruleChapterName");
        let rule_chapter_url = nested_or_flat_str(&v, "ruleToc", "chapterUrl", "ruleChapterUrl");
        let rule_chapter_url_is_full =
            nested_or_flat_str(&v, "ruleToc", "chapterUrlIsFull", "ruleChapterUrlIsFull");
        let rule_page_next = {
            let flat = str_field(&v, "rulePageNext").unwrap_or_default();
            if !flat.is_empty() {
                flat
            } else {
                let toc = nested_or_flat_str(&v, "ruleToc", "nextTocUrl", "");
                if !toc.is_empty() {
                    toc
                } else {
                    nested_or_flat_str(&v, "ruleContent", "nextContentUrl", "")
                }
            }
        };
        let rule_content = nested_or_flat_str(&v, "ruleContent", "content", "ruleContent");
        let rule_content_remove =
            nested_or_flat_str(&v, "ruleContent", "removeHtml", "ruleContentRemove");
        let rule_page_url = nested_or_flat_str(&v, "ruleContent", "nextPageUrl", "rulePageUrl");
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
                rule_search_list,
                rule_search_name,
                rule_search_author,
                rule_search_cover_url,
                rule_search_kind,
                rule_search_note,
                rule_book_url_pattern,
                rule_book_name,
                rule_book_author,
                rule_book_cover_url,
                rule_book_kind,
                rule_book_note,
                rule_book_last_chapter,
                rule_chapter_list,
                rule_chapter_name,
                rule_chapter_url,
                rule_chapter_url_is_full,
                nested_or_flat_str(&v, "ruleContent", "url", "ruleContentUrl"),
                rule_content,
                rule_content_remove,
                rule_page_url,
                rule_page_next,
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
        self.conn.execute_batch("BEGIN IMMEDIATE")?;
        let result = self.restore_backup_json_inner(&v, replace);
        match result {
            Ok(()) => match self.conn.execute_batch("COMMIT") {
                Ok(()) => Ok(()),
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

    fn restore_backup_json_inner(&self, v: &Value, replace: bool) -> Result<(), DbError> {
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
    if let Err(error) = fs::write(&temporary, backup_json) {
        let _ = fs::remove_file(&temporary);
        return Err(DbError::Message(format!("写入导入前备份失败: {error}")));
    }
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

fn add_column_if_missing(
    conn: &Connection,
    table: &str,
    column: &str,
    alter_sql: &str,
) -> Result<(), DbError> {
    let exists: i64 = conn.query_row(
        &format!("SELECT COUNT(*) FROM pragma_table_info('{table}') WHERE name = '{column}'"),
        [],
        |row| row.get(0),
    )?;
    if exists == 0 {
        conn.execute(alter_sql, [])?;
    }
    Ok(())
}

fn normalize_db_path(path: &str) -> PathBuf {
    if path == ":memory:" {
        return PathBuf::from(path);
    }
    fs::canonicalize(path).unwrap_or_else(|_| PathBuf::from(path))
}

fn app_database_path(app_dir: &str) -> Result<PathBuf, DbError> {
    let trimmed = app_dir.trim();
    if trimmed.is_empty() {
        return Err(DbError::Message("应用数据目录不能为空".into()));
    }

    let directory = Path::new(trimmed);
    let metadata = fs::metadata(directory)
        .map_err(|error| DbError::Message(format!("应用数据目录不可用: {trimmed}: {error}")))?;
    if !metadata.is_dir() {
        return Err(DbError::Message(format!(
            "应用数据路径必须是目录: {trimmed}"
        )));
    }

    let directory = fs::canonicalize(directory)
        .map_err(|error| DbError::Message(format!("应用数据目录无法规范化: {trimmed}: {error}")))?;
    Ok(directory.join("legado.db"))
}

fn same_published_database(path: &Path) -> Result<bool, DbError> {
    let cell = DB
        .get()
        .ok_or_else(|| DbError::Message("数据库尚未初始化".into()))?;
    let guard = cell
        .lock()
        .map_err(|_| DbError::Message("数据库锁失败".into()))?;
    Ok(guard.path == path)
}

/// 初始化应用数据目录下固定的 `legado.db`，成功完成 schema 后才发布全局实例。
pub fn init(app_dir: &str) -> Result<(), DbError> {
    let _init_guard = DB_INIT_LOCK
        .lock()
        .map_err(|_| DbError::Message("数据库初始化锁失败".into()))?;
    let database_path = app_database_path(app_dir)?;

    if DB.get().is_some() {
        return if same_published_database(&database_path)? {
            Ok(())
        } else {
            Err(DbError::Message("数据库已初始化，禁止切换数据目录".into()))
        };
    }

    let path = database_path.to_string_lossy().into_owned();
    let db = EngineDb::open(&path)?;

    match DB.set(Mutex::new(db)) {
        Ok(()) => Ok(()),
        Err(_) => {
            // Another initializer may have won the race while this database was opening.
            // The failed candidate is dropped and can never replace the published instance.
            if same_published_database(&database_path)? {
                Ok(())
            } else {
                Err(DbError::Message("数据库已初始化，禁止切换数据目录".into()))
            }
        }
    }
}

pub fn init_global(path: &str) -> Result<(), DbError> {
    let _init_guard = DB_INIT_LOCK
        .lock()
        .map_err(|_| DbError::Message("数据库初始化锁失败".into()))?;
    let db = EngineDb::open(path)?;
    DB.set(Mutex::new(db))
        .map_err(|_| DbError::Message("数据库已初始化".into()))?;
    Ok(())
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

fn nested_or_flat_str(v: &Value, outer: &str, inner: &str, flat: &str) -> String {
    if let Some(value) = v.get(flat).and_then(Value::as_str) {
        if !value.is_empty() {
            return value.to_string();
        }
    }
    v.get(outer)
        .and_then(|value| value.get(inner))
        .and_then(Value::as_str)
        .unwrap_or_default()
        .to_string()
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

    fn test_directory(label: &str) -> PathBuf {
        let path = std::env::temp_dir().join(format!(
            "legado-db-{label}-{}-{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        fs::create_dir_all(&path).unwrap();
        path
    }

    #[test]
    fn init_rejects_empty_and_file_app_paths() {
        assert!(matches!(
            init("   "),
            Err(DbError::Message(message)) if message.contains("不能为空")
        ));

        let directory = test_directory("invalid-file");
        let file = directory.join("not-a-directory");
        fs::write(&file, b"not a directory").unwrap();
        let file_path = file.to_string_lossy().into_owned();
        assert!(matches!(
            init(&file_path),
            Err(DbError::Message(message)) if message.contains("必须是目录")
        ));
    }

    #[test]
    fn schema_failure_rolls_back_all_ddl_and_version_changes() {
        let directory = test_directory("rollback");
        let path = directory.join("legado.db");
        let path_string = path.to_string_lossy().into_owned();

        {
            let conn = Connection::open(&path_string).unwrap();
            conn.execute_batch(
                "CREATE TABLE notes (id TEXT PRIMARY KEY);
                 PRAGMA user_version = 7;",
            )
            .unwrap();
        }

        assert!(EngineDb::open(&path_string).is_err());

        let conn = Connection::open(&path_string).unwrap();
        let version: i32 = conn
            .query_row("PRAGMA user_version", [], |row| row.get(0))
            .unwrap();
        assert_eq!(version, 7);
        for table in [
            "books",
            "book_sources",
            "chapters",
            "replace_rules",
            "legacy_room_imports",
            "reading_records",
        ] {
            let exists: i64 = conn
                .query_row(
                    "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?1",
                    [table],
                    |row| row.get(0),
                )
                .unwrap();
            assert_eq!(exists, 0, "table {table} must be rolled back");
        }
    }

    #[test]
    fn import_backup_write_failure_does_not_remove_preexisting_temp_path() {
        let directory = test_directory("backup-write-failure");
        let destination = directory.join("before.json");
        let temporary = PathBuf::from(format!(
            "{}.tmp-{}",
            destination.display(),
            std::process::id()
        ));
        fs::create_dir(&temporary).unwrap();

        let error =
            write_import_backup(&destination.to_string_lossy(), "{\"books\":[]}").unwrap_err();

        assert!(error.to_string().contains("写入导入前备份失败"));
        assert!(temporary.is_dir());
        assert!(!destination.exists());
        fs::remove_dir_all(&temporary).unwrap();
        fs::remove_dir_all(directory).unwrap();
    }

    fn write_minimal_room_import_source(path: &Path) {
        let conn = Connection::open(path).unwrap();
        conn.execute_batch(
            "CREATE TABLE room_master_table (id INTEGER PRIMARY KEY, identity_hash TEXT);
             INSERT INTO room_master_table (id, identity_hash)
               VALUES (42, '90980f1d0da029cf3254f354b227a2fe');
             CREATE TABLE books (
               bookUrl TEXT PRIMARY KEY,
               tocUrl TEXT NOT NULL DEFAULT '',
               origin TEXT NOT NULL DEFAULT '',
               originName TEXT NOT NULL DEFAULT '',
               name TEXT NOT NULL,
               author TEXT NOT NULL DEFAULT '',
               durChapterTitle TEXT,
               durChapterIndex INTEGER NOT NULL DEFAULT 0,
               durChapterPos INTEGER NOT NULL DEFAULT 0,
               readConfig TEXT
             );
             CREATE TABLE book_sources (
               bookSourceUrl TEXT PRIMARY KEY,
               bookSourceName TEXT NOT NULL,
               bookSourceGroup TEXT,
               enabled INTEGER NOT NULL DEFAULT 1,
               customOrder INTEGER NOT NULL DEFAULT 0
             );
             CREATE TABLE chapters (
               url TEXT NOT NULL,
               bookUrl TEXT NOT NULL,
               title TEXT NOT NULL,
               \"index\" INTEGER NOT NULL,
               baseUrl TEXT NOT NULL DEFAULT '',
               wordCount INTEGER NOT NULL DEFAULT 0,
               PRIMARY KEY(url, bookUrl)
             );
             CREATE TABLE replace_rules (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name TEXT NOT NULL,
               pattern TEXT NOT NULL,
               replacement TEXT NOT NULL,
               isEnabled INTEGER NOT NULL DEFAULT 1,
               isRegex INTEGER NOT NULL DEFAULT 1,
               sortOrder INTEGER NOT NULL DEFAULT 0,
               scope TEXT NOT NULL DEFAULT '',
               [group] TEXT NOT NULL DEFAULT ''
             );
             CREATE TABLE searchBooks (bookUrl TEXT);
             CREATE TABLE search_keywords (word TEXT);
             CREATE TABLE cookies (url TEXT, cookie TEXT);
             CREATE TABLE rssSources (sourceUrl TEXT);
             CREATE TABLE bookmarks (
               time INTEGER PRIMARY KEY,
               bookName TEXT NOT NULL,
               bookAuthor TEXT NOT NULL,
               chapterIndex INTEGER NOT NULL,
               chapterPos INTEGER NOT NULL,
               chapterName TEXT NOT NULL,
               bookText TEXT NOT NULL DEFAULT '',
               content TEXT NOT NULL DEFAULT ''
             );
             CREATE TABLE rssArticles (origin TEXT);
             CREATE TABLE rssReadRecords (record TEXT);
             CREATE TABLE rssStars (origin TEXT);
             CREATE TABLE txtTocRules (id INTEGER);
             CREATE TABLE readRecord (
               deviceId TEXT NOT NULL,
               bookName TEXT NOT NULL,
               readTime INTEGER NOT NULL,
               lastRead INTEGER NOT NULL DEFAULT 0,
               PRIMARY KEY(deviceId, bookName)
             );
             CREATE TABLE detailedReadRecord (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               bookName TEXT NOT NULL,
               startTime INTEGER NOT NULL,
               endTime INTEGER NOT NULL,
               readIteration INTEGER NOT NULL DEFAULT 0
             );
             CREATE TABLE httpTTS (id INTEGER);
             CREATE TABLE caches (key TEXT, value TEXT);
             CREATE TABLE ruleSubs (id INTEGER);
             CREATE TABLE dictRules (name TEXT);
             CREATE TABLE keyboardAssists (type TEXT);
             CREATE TABLE book_thoughts (id INTEGER);
             CREATE TABLE servers (id INTEGER);
             CREATE TABLE book_groups (groupId TEXT, groupName TEXT);
             INSERT INTO books
               (bookUrl, tocUrl, origin, originName, name, author,
                durChapterTitle, durChapterIndex, durChapterPos, readConfig)
               VALUES ('book-1', 'toc', 'source', '源', '重复导入书', '作者',
                       '第一章', 0, 7, '{}');
             INSERT INTO book_sources
               (bookSourceUrl, bookSourceName, bookSourceGroup, enabled, customOrder)
               VALUES ('source', '测试书源', '测试组', 1, 3);
             INSERT INTO chapters (url, bookUrl, title, [index], baseUrl, wordCount)
               VALUES ('chapter-1', 'book-1', '第一章', 0, 'https://example.test/', 1234);
             INSERT INTO readRecord (deviceId, bookName, readTime, lastRead)
               VALUES ('device-a', '重复导入书', 600, 1700000000);
             INSERT INTO detailedReadRecord (bookName, startTime, endTime, readIteration)
               VALUES ('重复导入书', 1000000, 1120001, 1);
             INSERT INTO replace_rules
               (name, pattern, replacement, isEnabled, isRegex, sortOrder, scope, [group])
               VALUES ('净化', '广告', '', 1, 1, 3, 'book-1', '正文');
             PRAGMA user_version = 99;",
        )
        .unwrap();
    }

    #[test]
    fn duplicate_import_with_new_backup_path_is_a_true_noop() {
        let directory = test_directory("duplicate-new-backup");
        let source_path = directory.join("room.db");
        let first_backup_path = directory.join("first-backup.json");
        let second_backup_path = directory.join("second-backup.json");
        write_minimal_room_import_source(&source_path);
        let db = EngineDb::open_in_memory().unwrap();

        let first = db
            .import_legacy_room_database(
                &source_path.to_string_lossy(),
                Some(&first_backup_path.to_string_lossy()),
                false,
            )
            .unwrap();
        assert!(!first.skipped_duplicate);
        assert!(first.backup_written);
        let first_database = db.export_backup_json().unwrap();
        let first_backup = fs::read(&first_backup_path).unwrap();

        let duplicate = db
            .import_legacy_room_database(
                &source_path.to_string_lossy(),
                Some(&second_backup_path.to_string_lossy()),
                false,
            )
            .unwrap();

        assert!(duplicate.skipped_duplicate);
        assert!(!duplicate.backup_written);
        assert_eq!(
            duplicate.backup_path.as_deref(),
            Some(second_backup_path.to_string_lossy().as_ref())
        );
        assert!(!second_backup_path.exists());
        assert_eq!(db.export_backup_json().unwrap(), first_database);
        assert_eq!(fs::read(&first_backup_path).unwrap(), first_backup);
        assert_eq!(db.legacy_room_import_count().unwrap(), 1);

        fs::remove_dir_all(directory).unwrap();
    }

    #[test]
    fn room_import_persists_mapped_rows_and_keeps_archive_only_fields() {
        let directory = test_directory("persistence-boundary");
        let source_path = directory.join("room.db");
        let backup_path = directory.join("backup.json");
        write_minimal_room_import_source(&source_path);
        let db = EngineDb::open_in_memory().unwrap();

        let report = db
            .import_legacy_room_database(
                &source_path.to_string_lossy(),
                Some(&backup_path.to_string_lossy()),
                false,
            )
            .unwrap();

        assert_eq!(report.counts.get("books"), Some(&1));
        assert_eq!(report.counts.get("sources"), Some(&1));
        assert_eq!(report.counts.get("chapters"), Some(&1));
        assert_eq!(report.counts.get("readRecord"), Some(&1));
        assert!(report
            .archive_only_tables
            .contains(&"readRecord".to_string()));

        let books: Vec<Value> = db
            .get_books_json()
            .unwrap()
            .into_iter()
            .map(|raw| serde_json::from_str(&raw).unwrap())
            .collect();
        assert_eq!(books.len(), 1);
        assert_eq!(books[0]["id"], "book-1");
        assert_eq!(books[0]["bookSourceUrl"], "source");
        assert_eq!(books[0]["tocUrl"], "toc");
        assert_eq!(books[0]["currentPageIndex"], 7);

        let chapters: Vec<Value> = db
            .get_chapters_json("book-1")
            .unwrap()
            .into_iter()
            .map(|raw| serde_json::from_str(&raw).unwrap())
            .collect();
        assert_eq!(chapters.len(), 1);
        assert_eq!(chapters[0]["bookId"], "book-1");
        assert_eq!(chapters[0]["title"], "第一章");
        assert_eq!(chapters[0]["index"], 0);
        assert_eq!(chapters[0]["url"], "chapter-1");
        assert!(chapters[0].get("wordCount").is_none());

        let sources: Vec<Value> = db
            .get_sources_json(false)
            .unwrap()
            .into_iter()
            .map(|raw| serde_json::from_str(&raw).unwrap())
            .collect();
        assert_eq!(sources.len(), 1);
        assert_eq!(sources[0]["bookSourceUrl"], "source");
        assert_eq!(sources[0]["bookSourceName"], "测试书源");
        assert_eq!(sources[0]["bookSourceGroup"], "测试组");
        assert_eq!(sources[0]["enabled"], true);

        let replace_rule: (String, String, String, String, i64, i64) = db
            .conn
            .query_row(
                "SELECT id, name, pattern, replacement, isEnabled, isRegex
                 FROM replace_rules WHERE name=?1",
                params!["净化"],
                |row| {
                    Ok((
                        row.get(0)?,
                        row.get(1)?,
                        row.get(2)?,
                        row.get(3)?,
                        row.get(4)?,
                        row.get(5)?,
                    ))
                },
            )
            .unwrap();
        assert_eq!(
            replace_rule,
            (
                "1".to_string(),
                "净化".to_string(),
                "广告".to_string(),
                String::new(),
                1,
                1,
            )
        );

        let raw_snapshot: String = db
            .conn
            .query_row(
                "SELECT raw_snapshot_json FROM legacy_room_imports WHERE fingerprint=?1",
                params![report.fingerprint],
                |row| row.get(0),
            )
            .unwrap();
        let raw_snapshot: Value = serde_json::from_str(&raw_snapshot).unwrap();
        assert_eq!(raw_snapshot["tables"]["chapters"][0]["wordCount"], 1234);
        assert_eq!(raw_snapshot["tables"]["detailedReadRecord"][0]["id"], 1);
        assert_eq!(raw_snapshot["tables"]["replace_rules"][0]["sortOrder"], 3);
        assert_eq!(
            raw_snapshot["tables"]["replace_rules"][0]["scope"],
            "book-1"
        );
        assert_eq!(raw_snapshot["tables"]["replace_rules"][0]["group"], "正文");

        let mapped_backup: String = db
            .conn
            .query_row(
                "SELECT mapped_backup_json FROM legacy_room_imports WHERE fingerprint=?1",
                params![report.fingerprint],
                |row| row.get(0),
            )
            .unwrap();
        let mapped_backup: Value = serde_json::from_str(&mapped_backup).unwrap();
        assert_eq!(mapped_backup["books"][0]["currentPageIndex"], 7);
        assert_eq!(mapped_backup["chapters"][0]["url"], "chapter-1");
        assert!(mapped_backup["chapters"][0].get("wordCount").is_none());
        assert_eq!(mapped_backup["sources"][0]["bookSourceName"], "测试书源");
        assert_eq!(mapped_backup["replaceRules"][0]["name"], "净化");
        assert_eq!(mapped_backup["replaceRules"][0]["isRegex"], true);
        assert!(mapped_backup["replaceRules"][0].get("sortOrder").is_none());
        assert!(mapped_backup["replaceRules"][0].get("scope").is_none());
        assert!(mapped_backup["replaceRules"][0].get("group").is_none());

        fs::remove_dir_all(directory).unwrap();
    }

    #[test]
    fn init_is_idempotent_for_same_directory_and_rejects_switching_directory() {
        let failed_directory = test_directory("init-failure");
        let failed_path = failed_directory.join("legado.db");
        let failed_path_string = failed_path.to_string_lossy().into_owned();
        let conn = Connection::open(&failed_path_string).unwrap();
        conn.execute_batch(
            "CREATE TABLE notes (id TEXT PRIMARY KEY);
             PRAGMA user_version = 7;",
        )
        .unwrap();
        drop(conn);
        assert!(init(&failed_directory.to_string_lossy()).is_err());
        assert!(DB.get().is_none(), "失败初始化不得发布全局实例");

        let first_directory = test_directory("init-first");
        let first_path = first_directory.to_string_lossy().into_owned();
        let handles = (0..4)
            .map(|_| {
                let path = first_path.clone();
                std::thread::spawn(move || init(&path))
            })
            .collect::<Vec<_>>();
        for handle in handles {
            handle
                .join()
                .expect("concurrent initialization thread must not panic")
                .expect("concurrent initialization of one directory must be idempotent");
        }

        let published_path = DB.get().unwrap().lock().unwrap().path.clone();
        assert_eq!(
            published_path,
            fs::canonicalize(first_directory.join("legado.db")).unwrap()
        );

        init(&first_path).unwrap();

        let second_directory = test_directory("init-second");
        let second_path = second_directory.to_string_lossy().into_owned();
        assert!(matches!(
            init(&second_path),
            Err(DbError::Message(message)) if message.contains("禁止切换数据目录")
        ));
        assert_eq!(
            DB.get().unwrap().lock().unwrap().path,
            published_path,
            "a rejected path must not replace the published database"
        );
    }

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
    fn restore_backup_rolls_back_existing_rows_when_a_later_row_is_invalid() {
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(
            r#"{"id":"existing","name":"原有书籍","author":"原作者","bookSourceUrl":"source"}"#,
        )
        .unwrap();

        let invalid_backup = r#"{
            "books": [
                {"id":"new","name":"先写入的书籍","author":"作者"},
                {"name":"缺少主键的书籍","author":"作者"}
            ]
        }"#;
        let error = db.restore_backup_json(invalid_backup, true).unwrap_err();
        assert!(error.to_string().contains("缺少字段 id"));

        let books = db.get_books_json().unwrap();
        assert_eq!(books.len(), 1);
        assert!(books[0].contains("原有书籍"));
        assert!(!books[0].contains("先写入的书籍"));
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

    #[test]
    fn import_reports_conflicts_for_each_mapped_identity() {
        let db = EngineDb::open_in_memory().unwrap();
        let backup = json!({
            "books": [{
                "id": "book-1",
                "name": "冲突书",
                "author": "作者",
                "bookSourceUrl": "source-1"
            }],
            "sources": [{
                "bookSourceUrl": "source-1",
                "bookSourceName": "冲突书源"
            }],
            "chapters": [{
                "id": "chapter-1",
                "bookId": "book-1",
                "title": "第一章",
                "index": 0,
                "url": "chapter-1"
            }],
            "replaceRules": [{
                "id": "rule-1",
                "name": "规则",
                "pattern": "旧",
                "replacement": "新",
                "isEnabled": true,
                "isRegex": false
            }],
            "bookmarks": [{
                "time": 100,
                "bookId": "book-1",
                "bookName": "冲突书",
                "bookAuthor": "作者",
                "chapterIndex": 0,
                "chapterPos": 10,
                "chapterName": "第一章",
                "bookText": "片段",
                "content": "备注"
            }],
            "readingRecords": [{
                "bookId": "book-1",
                "bookName": "冲突书",
                "date": "2026-08-01",
                "readChars": 10,
                "durationSeconds": 2
            }],
            "detailedReadRecords": [{
                "bookName": "冲突书",
                "sessions": [{
                    "startTime": 1_000_000,
                    "endTime": 1_120_001,
                    "readIteration": 1
                }]
            }]
        });

        // 先导入一遍，建立与待导入数据相同的五类主键。
        db.restore_backup_json(&backup.to_string(), true).unwrap();
        let conflicts = import_conflict_counts(&db.conn, &backup).unwrap();
        assert_eq!(conflicts.get("books"), Some(&1));
        assert_eq!(conflicts.get("sources"), Some(&1));
        assert_eq!(conflicts.get("chapters"), Some(&1));
        assert_eq!(conflicts.get("replaceRules"), Some(&1));
        assert_eq!(conflicts.get("bookmarks"), Some(&1));
        assert!(!conflicts.contains_key("readingRecords"));
        assert!(!conflicts.contains_key("detailedReadRecords"));

        // 再次恢复必须成功，且每个映射实体仍只有一行。
        db.restore_backup_json(&backup.to_string(), false).unwrap();
        for (table, expected) in [
            ("books", 1_i64),
            ("book_sources", 1_i64),
            ("chapters", 1_i64),
            ("replace_rules", 1_i64),
            ("bookmarks", 1_i64),
            ("reading_records", 1_i64),
            // 详细阅读会话不参与主键冲突统计，重复恢复按现有语义追加。
            ("detailed_read_records", 2_i64),
        ] {
            let actual: i64 = db
                .conn
                .query_row(&format!("SELECT COUNT(*) FROM {table}"), [], |row| {
                    row.get(0)
                })
                .unwrap();
            assert_eq!(actual, expected, "unexpected row count in {table}");
        }
    }
}
