use super::DbError;
use rusqlite::{types::ValueRef, Connection, OpenFlags, OptionalExtension};
use serde::Serialize;
use serde_json::{json, Map, Value};
use std::collections::BTreeMap;

/// Current Room database version from the read-only Kotlin baseline.
pub const KOTLIN_ROOM_CURRENT_VERSION: i32 = 99;
pub const KOTLIN_ROOM_IDENTITY_HASH: &str = "90980f1d0da029cf3254f354b227a2fe";

const REQUIRED_TABLE_COLUMNS: &[(&str, &[&str])] = &[
    (
        "books",
        &[
            "bookUrl",
            "tocUrl",
            "origin",
            "originName",
            "name",
            "author",
            "durChapterTitle",
            "durChapterIndex",
            "durChapterPos",
            "readConfig",
        ],
    ),
    (
        "book_sources",
        &[
            "bookSourceUrl",
            "bookSourceName",
            "bookSourceGroup",
            "enabled",
            "customOrder",
        ],
    ),
    ("chapters", &["url", "bookUrl", "title", "index", "baseUrl"]),
    (
        "bookmarks",
        &[
            "time",
            "bookName",
            "bookAuthor",
            "chapterIndex",
            "chapterPos",
            "chapterName",
            "bookText",
            "content",
        ],
    ),
    (
        "readRecord",
        &["deviceId", "bookName", "readTime", "lastRead"],
    ),
    (
        "detailedReadRecord",
        &["id", "bookName", "startTime", "endTime", "readIteration"],
    ),
    (
        "replace_rules",
        &[
            "id",
            "name",
            "pattern",
            "replacement",
            "isEnabled",
            "isRegex",
            "sortOrder",
        ],
    ),
];

/// Room v99 entities from the read-only Kotlin schema baseline.
///
/// The seven tables above have a Rust v17 business mapping. The remaining
/// entities are archived verbatim until their product-level ports exist.
const ROOM_ENTITY_TABLES: &[&str] = &[
    "books",
    "book_groups",
    "book_sources",
    "chapters",
    "replace_rules",
    "searchBooks",
    "search_keywords",
    "cookies",
    "rssSources",
    "bookmarks",
    "rssArticles",
    "rssReadRecords",
    "rssStars",
    "txtTocRules",
    "readRecord",
    "detailedReadRecord",
    "httpTTS",
    "caches",
    "ruleSubs",
    "dictRules",
    "keyboardAssists",
    "book_thoughts",
    "servers",
];

const CORE_MAPPED_TABLES: &[&str] = &[
    "books",
    "book_sources",
    "chapters",
    "bookmarks",
    "readRecord",
    "detailedReadRecord",
    "replace_rules",
];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LegacyRoomProbe {
    pub user_version: i32,
    pub room_identity_hash: Option<String>,
    pub missing_tables: Vec<String>,
    pub missing_columns: BTreeMap<String, Vec<String>>,
}

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct LegacyRoomSnapshot {
    pub user_version: i32,
    pub room_identity_hash: Option<String>,
    pub columns: BTreeMap<String, Vec<String>>,
    pub tables: BTreeMap<String, Vec<Value>>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct LegacyRoomMapping {
    pub backup_json: Value,
    pub counts: BTreeMap<String, usize>,
    pub archive_only_tables: Vec<String>,
    pub warnings: Vec<String>,
    pub unmapped_columns: BTreeMap<String, Vec<String>>,
}

#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct LegacyRoomImportReport {
    #[serde(rename = "sourceRoomVersion")]
    pub source_room_version: i32,
    #[serde(rename = "sourceRoomIdentityHash")]
    pub source_room_identity_hash: Option<String>,
    pub fingerprint: String,
    pub replaced: bool,
    #[serde(rename = "skippedDuplicate")]
    pub skipped_duplicate: bool,
    #[serde(rename = "backupPath")]
    pub backup_path: Option<String>,
    #[serde(rename = "backupWritten")]
    pub backup_written: bool,
    pub counts: BTreeMap<String, usize>,
    #[serde(rename = "conflictCounts")]
    pub conflict_counts: BTreeMap<String, usize>,
    #[serde(rename = "preservedRows")]
    pub preserved_rows: BTreeMap<String, usize>,
    #[serde(rename = "archiveOnlyTables")]
    pub archive_only_tables: Vec<String>,
    pub warnings: Vec<String>,
    #[serde(rename = "unmappedColumns")]
    pub unmapped_columns: BTreeMap<String, Vec<String>>,
}

impl LegacyRoomProbe {
    pub fn has_required_core_shape(&self) -> bool {
        self.missing_tables.is_empty() && self.missing_columns.is_empty()
    }

    pub fn needs_kotlin_room_migration(&self) -> bool {
        self.user_version < KOTLIN_ROOM_CURRENT_VERSION
    }
}

pub fn validate_kotlin_room_version(user_version: i32) -> Result<(), DbError> {
    if user_version != KOTLIN_ROOM_CURRENT_VERSION {
        return Err(DbError::Message(format!(
            "不支持的 Kotlin Room 数据库版本: v{user_version}，仅支持 v{KOTLIN_ROOM_CURRENT_VERSION}"
        )));
    }
    Ok(())
}

/// Read-only probe for an original Kotlin Room database.
///
/// This deliberately does not import or modify data. It only establishes whether
/// the file has the minimum Legado Room shape required by the later mapping step.
pub fn probe_legacy_room_database(path: &str) -> Result<LegacyRoomProbe, DbError> {
    let conn = Connection::open_with_flags(
        path,
        OpenFlags::SQLITE_OPEN_READ_ONLY | OpenFlags::SQLITE_OPEN_NO_MUTEX,
    )?;
    probe_legacy_room_connection(&conn)
}

pub fn probe_legacy_room_connection(conn: &Connection) -> Result<LegacyRoomProbe, DbError> {
    let user_version: i32 = conn.query_row("PRAGMA user_version", [], |row| row.get(0))?;
    let room_identity_hash = read_room_identity_hash(conn)?;

    let mut missing_tables = Vec::new();
    let mut missing_columns = BTreeMap::new();
    for (table, required_columns) in REQUIRED_TABLE_COLUMNS {
        if !table_exists(conn, table)? {
            missing_tables.push((*table).to_string());
            continue;
        }
        let columns = table_columns(conn, table)?;
        let missing = required_columns
            .iter()
            .filter(|column| !columns.iter().any(|existing| existing == **column))
            .map(|column| (*column).to_string())
            .collect::<Vec<_>>();
        if !missing.is_empty() {
            missing_columns.insert((*table).to_string(), missing);
        }
    }

    Ok(LegacyRoomProbe {
        user_version,
        room_identity_hash,
        missing_tables,
        missing_columns,
    })
}

/// Extracts every Room entity table without modifying the source database.
///
/// The snapshot is deliberately separate from target-schema mapping. Core
/// rows are mapped to Rust v17 later; all entity rows and columns remain in
/// the raw archive so unsupported fields can be recovered without data loss.
pub fn extract_legacy_room_database(path: &str) -> Result<LegacyRoomSnapshot, DbError> {
    let conn = Connection::open_with_flags(
        path,
        OpenFlags::SQLITE_OPEN_READ_ONLY | OpenFlags::SQLITE_OPEN_NO_MUTEX,
    )?;
    extract_legacy_room_connection(&conn)
}

pub fn extract_legacy_room_connection(conn: &Connection) -> Result<LegacyRoomSnapshot, DbError> {
    let probe = probe_legacy_room_connection(conn)?;
    if !probe.has_required_core_shape() {
        return Err(DbError::Message(format!(
            "旧 Room 数据库缺少迁移所需结构: tables={:?}, columns={:?}",
            probe.missing_tables, probe.missing_columns
        )));
    }
    validate_kotlin_room_version(probe.user_version)?;
    if probe.room_identity_hash.as_deref() != Some(KOTLIN_ROOM_IDENTITY_HASH) {
        return Err(DbError::Message(format!(
            "不支持的 Kotlin Room identity hash: {:?}，期望 {KOTLIN_ROOM_IDENTITY_HASH}",
            probe.room_identity_hash
        )));
    }

    let mut columns = BTreeMap::new();
    let mut tables = BTreeMap::new();
    let mut missing_tables = Vec::new();
    for table in ROOM_ENTITY_TABLES {
        if !table_exists(conn, table)? {
            missing_tables.push((*table).to_string());
            continue;
        }
        columns.insert((*table).to_string(), table_columns(conn, table)?);
        tables.insert((*table).to_string(), read_table_rows(conn, table)?);
    }
    if !missing_tables.is_empty() {
        return Err(DbError::Message(format!(
            "Room v99 数据库缺少实体表: {missing_tables:?}"
        )));
    }

    Ok(LegacyRoomSnapshot {
        user_version: probe.user_version,
        room_identity_hash: probe.room_identity_hash,
        columns,
        tables,
    })
}

pub fn map_legacy_room_database(path: &str) -> Result<LegacyRoomMapping, DbError> {
    let snapshot = extract_legacy_room_database(path)?;
    map_legacy_room_snapshot(&snapshot)
}

pub fn map_legacy_room_snapshot(
    snapshot: &LegacyRoomSnapshot,
) -> Result<LegacyRoomMapping, DbError> {
    let mut warnings = Vec::new();
    let unmapped_columns = detect_unmapped_columns(snapshot);

    let books = map_books(table(snapshot, "books")?);
    let book_index = BookIdentityIndex::new(&books, &mut warnings);
    let sources = map_sources(table(snapshot, "book_sources")?);
    let chapters = map_chapters(table(snapshot, "chapters")?);
    let bookmarks = map_bookmarks(table(snapshot, "bookmarks")?, &book_index, &mut warnings);
    let detailed_read_records = map_detailed_read_records(table(snapshot, "detailedReadRecord")?);
    let replace_rules = map_replace_rules(table(snapshot, "replace_rules")?);
    let archive_only_tables = snapshot
        .tables
        .keys()
        .filter(|table| !CORE_MAPPED_TABLES.contains(&table.as_str()))
        .cloned()
        .collect::<Vec<_>>();

    for table_name in &archive_only_tables {
        if !table(snapshot, table_name)?.is_empty() {
            warnings.push(format!(
                "Room table {table_name} is preserved verbatim in legacy_room_imports; no Rust v17 business mapping exists yet"
            ));
        }
    }

    if !table(snapshot, "readRecord")?.is_empty() {
        warnings.push(
            "readRecord contains aggregate readTime/lastRead without stable bookUrl/date; deferred to detailedReadRecord or a later statistics migration"
                .to_string(),
        );
    }

    let mut counts = BTreeMap::new();
    counts.insert("books".to_string(), books.len());
    counts.insert("sources".to_string(), sources.len());
    counts.insert("chapters".to_string(), chapters.len());
    counts.insert("bookmarks".to_string(), bookmarks.len());
    counts.insert(
        "detailedReadRecords".to_string(),
        detailed_read_records.len(),
    );
    counts.insert("replaceRules".to_string(), replace_rules.len());

    Ok(LegacyRoomMapping {
        backup_json: json!({
            "version": 1,
            "source": {
                "kind": "kotlin-room",
                "roomVersion": snapshot.user_version,
                "roomIdentityHash": snapshot.room_identity_hash,
            },
            "books": books,
            "sources": sources,
            "chapters": chapters,
            "replaceRules": replace_rules,
            "readingRecords": [],
            "detailedReadRecords": detailed_read_records,
            "notes": [],
            "bookmarks": bookmarks,
        }),
        counts,
        archive_only_tables,
        warnings,
        unmapped_columns,
    })
}

pub(crate) fn snapshot_json(snapshot: &LegacyRoomSnapshot) -> Value {
    json!({
        "userVersion": snapshot.user_version,
        "roomIdentityHash": snapshot.room_identity_hash,
        "columns": snapshot.columns,
        "tables": snapshot.tables,
    })
}

pub(crate) fn snapshot_fingerprint(snapshot: &LegacyRoomSnapshot) -> String {
    let mut hash = 14695981039346656037u64;
    for byte in snapshot_json(snapshot).to_string().bytes() {
        hash ^= u64::from(byte);
        hash = hash.wrapping_mul(1099511628211);
    }
    format!("room-{hash:016x}")
}

fn map_books(rows: &[Value]) -> Vec<Value> {
    rows.iter()
        .map(|row| {
            let id = str_value(row, "bookUrl");
            let name = str_value(row, "name");
            let author = str_value(row, "author");
            let dur_index = i64_value(row, "durChapterIndex").max(0);
            let dur_pos = i64_value(row, "durChapterPos").max(0);
            let total = i64_value(row, "totalChapterNum").max(0);
            let progress = if total > 0 {
                ((dur_index + 1) as f64 / total as f64).clamp(0.0, 1.0)
            } else {
                0.0
            };
            json!({
                "id": id,
                "name": name,
                "author": author,
                "coverUrl": first_non_empty(&[
                    str_value(row, "customCoverUrl"),
                    str_value(row, "coverUrl"),
                ]),
                "type": if str_value(row, "origin") == "loc_book" { "local" } else { "online" },
                "progress": progress,
                "currentChapter": str_opt(row, "durChapterTitle"),
                "lastChapter": str_opt(row, "latestChapterTitle"),
                "totalChapterNum": total,
                "durChapterIndex": dur_index,
                "currentPageIndex": dur_pos,
                "isFavorite": true,
                "sourceUrl": id,
                "description": first_non_empty(&[
                    str_value(row, "customIntro"),
                    str_value(row, "intro"),
                ]),
                "bookSourceUrl": str_value(row, "origin"),
                "tocUrl": str_value(row, "tocUrl"),
                "group": string_or_i64(row, "group"),
                "readIteration": i64_value(row, "readIteration").max(0),
                "readConfig": parse_json_object(row, "readConfig"),
            })
        })
        .collect()
}

fn map_sources(rows: &[Value]) -> Vec<Value> {
    rows.iter()
        .map(|row| {
            let mut source = row.as_object().cloned().unwrap_or_default();
            source.insert(
                "ruleSearchUrl".to_string(),
                Value::String(str_value(row, "searchUrl")),
            );
            source.insert(
                "bookSourceType".to_string(),
                Value::String(string_or_i64(row, "bookSourceType")),
            );
            for key in [
                "ruleSearch",
                "ruleBookInfo",
                "ruleToc",
                "ruleContent",
                "ruleExplore",
            ] {
                if let Some(value) = parse_json_maybe_string(row, key) {
                    source.insert(key.to_string(), value);
                }
            }
            let raw = Value::Object(source.clone()).to_string();
            source.insert("rawSourceJson".to_string(), Value::String(raw));
            Value::Object(source)
        })
        .collect()
}

fn map_chapters(rows: &[Value]) -> Vec<Value> {
    rows.iter()
        .map(|row| {
            let book_id = str_value(row, "bookUrl");
            let url = str_value(row, "url");
            let index = i64_value(row, "index").max(0);
            json!({
                "id": chapter_id_for(&book_id, &url, index),
                "bookId": book_id,
                "title": str_value(row, "title"),
                "index": index,
                "url": url,
                "isVolume": bool_value(row, "isVolume"),
                "isVip": bool_value(row, "isVip"),
                "isPay": bool_value(row, "isPay"),
                "tag": str_value(row, "tag"),
                "baseUrl": str_value(row, "baseUrl"),
                "isDownloaded": false,
                "content": Value::Null,
            })
        })
        .collect()
}

fn map_bookmarks(
    rows: &[Value],
    book_index: &BookIdentityIndex,
    warnings: &mut Vec<String>,
) -> Vec<Value> {
    rows.iter()
        .map(|row| {
            let book_name = str_value(row, "bookName");
            let book_author = str_value(row, "bookAuthor");
            let book_id = book_index.lookup(&book_name, &book_author, warnings);
            json!({
                "time": i64_value(row, "time"),
                "bookId": book_id,
                "bookName": book_name,
                "bookAuthor": book_author,
                "chapterIndex": i64_value(row, "chapterIndex").max(0),
                "chapterPos": i64_value(row, "chapterPos").max(0),
                "chapterName": str_value(row, "chapterName"),
                "bookText": str_value(row, "bookText"),
                "content": str_value(row, "content"),
            })
        })
        .collect()
}

fn map_detailed_read_records(rows: &[Value]) -> Vec<Value> {
    let mut grouped = BTreeMap::<String, Vec<Value>>::new();
    for row in rows {
        grouped
            .entry(str_value(row, "bookName"))
            .or_default()
            .push(json!({
                "startTime": i64_value(row, "startTime"),
                "endTime": i64_value(row, "endTime"),
                "readIteration": i64_value(row, "readIteration").max(0),
            }));
    }
    grouped
        .into_iter()
        .map(|(book_name, sessions)| json!({"bookName": book_name, "sessions": sessions}))
        .collect()
}

fn map_replace_rules(rows: &[Value]) -> Vec<Value> {
    rows.iter()
        .map(|row| {
            json!({
                "id": string_or_i64(row, "id"),
                "name": str_value(row, "name"),
                "pattern": str_value(row, "pattern"),
                "replacement": str_value(row, "replacement"),
                "isEnabled": bool_value(row, "isEnabled"),
                "isRegex": bool_value(row, "isRegex"),
            })
        })
        .collect()
}

struct BookIdentityIndex {
    by_name_author: BTreeMap<String, Option<String>>,
}

impl BookIdentityIndex {
    fn new(books: &[Value], warnings: &mut Vec<String>) -> Self {
        let mut by_name_author = BTreeMap::<String, Option<String>>::new();
        for book in books {
            let key = book_key(&str_value(book, "name"), &str_value(book, "author"));
            let id = str_value(book, "id");
            if let Some(existing) = by_name_author.get_mut(&key) {
                if existing.as_ref() != Some(&id) {
                    *existing = None;
                    warnings.push(format!(
                        "book identity is ambiguous for bookmark/read-record matching: {key}"
                    ));
                }
            } else {
                by_name_author.insert(key, Some(id));
            }
        }
        Self { by_name_author }
    }

    fn lookup(&self, name: &str, author: &str, warnings: &mut Vec<String>) -> String {
        let key = book_key(name, author);
        match self.by_name_author.get(&key) {
            Some(Some(id)) => id.clone(),
            Some(None) => {
                warnings.push(format!(
                    "bookmark bookId left empty because book identity is ambiguous: {key}"
                ));
                String::new()
            }
            None => {
                warnings.push(format!(
                    "bookmark bookId left empty because no book matched: {key}"
                ));
                String::new()
            }
        }
    }
}

fn detect_unmapped_columns(snapshot: &LegacyRoomSnapshot) -> BTreeMap<String, Vec<String>> {
    const MAPPED: &[(&str, &[&str])] = &[
        (
            "books",
            &[
                "bookUrl",
                "tocUrl",
                "origin",
                "originName",
                "name",
                "author",
                "coverUrl",
                "customCoverUrl",
                "intro",
                "customIntro",
                "type",
                "group",
                "latestChapterTitle",
                "totalChapterNum",
                "durChapterTitle",
                "durChapterIndex",
                "durChapterPos",
                "readConfig",
                "readIteration",
            ],
        ),
        (
            "book_sources",
            &[
                "bookSourceUrl",
                "bookSourceName",
                "bookSourceGroup",
                "bookSourceType",
                "customOrder",
                "enabled",
                "searchUrl",
                "ruleSearch",
                "ruleBookInfo",
                "ruleToc",
                "ruleContent",
                "ruleExplore",
            ],
        ),
        (
            "chapters",
            &[
                "url", "bookUrl", "title", "index", "baseUrl", "isVolume", "isVip", "isPay", "tag",
            ],
        ),
        (
            "bookmarks",
            &[
                "time",
                "bookName",
                "bookAuthor",
                "chapterIndex",
                "chapterPos",
                "chapterName",
                "bookText",
                "content",
            ],
        ),
        ("readRecord", &[]),
        (
            "detailedReadRecord",
            &["bookName", "startTime", "endTime", "readIteration"],
        ),
        (
            "replace_rules",
            &[
                "id",
                "name",
                "pattern",
                "replacement",
                "isEnabled",
                "isRegex",
            ],
        ),
    ];

    let mapped = MAPPED
        .iter()
        .map(|(table, columns)| (*table, columns.iter().copied().collect::<Vec<_>>()))
        .collect::<BTreeMap<_, _>>();

    let mut result = BTreeMap::new();
    for (table, rows) in &snapshot.tables {
        let mut columns = snapshot.columns.get(table).cloned().unwrap_or_default();
        if columns.is_empty() {
            columns = rows
                .iter()
                .filter_map(Value::as_object)
                .flat_map(|object| object.keys().cloned())
                .collect::<Vec<_>>();
        }
        columns.sort();
        columns.dedup();
        let allowed = mapped.get(table.as_str()).cloned().unwrap_or_default();
        let unmapped = columns
            .into_iter()
            .filter(|column| !allowed.iter().any(|allowed| allowed == column))
            .collect::<Vec<_>>();
        if !unmapped.is_empty() {
            result.insert(table.clone(), unmapped);
        }
    }
    result
}

fn table<'a>(snapshot: &'a LegacyRoomSnapshot, table: &str) -> Result<&'a [Value], DbError> {
    snapshot
        .tables
        .get(table)
        .map(Vec::as_slice)
        .ok_or_else(|| DbError::Message(format!("旧 Room 快照缺少表 {table}")))
}

fn first_non_empty(values: &[String]) -> String {
    values
        .iter()
        .find(|value| !value.is_empty())
        .cloned()
        .unwrap_or_default()
}

fn str_value(row: &Value, key: &str) -> String {
    str_opt(row, key).unwrap_or_default()
}

fn str_opt(row: &Value, key: &str) -> Option<String> {
    row.get(key).and_then(|value| match value {
        Value::Null => None,
        Value::String(value) => Some(value.clone()),
        Value::Number(value) => Some(value.to_string()),
        Value::Bool(value) => Some(value.to_string()),
        other => Some(other.to_string()),
    })
}

fn string_or_i64(row: &Value, key: &str) -> String {
    str_opt(row, key).unwrap_or_default()
}

fn i64_value(row: &Value, key: &str) -> i64 {
    row.get(key)
        .and_then(|value| match value {
            Value::Number(value) => value.as_i64(),
            Value::String(value) => value.parse::<i64>().ok(),
            Value::Bool(value) => Some(if *value { 1 } else { 0 }),
            _ => None,
        })
        .unwrap_or(0)
}

fn bool_value(row: &Value, key: &str) -> bool {
    row.get(key)
        .and_then(|value| match value {
            Value::Bool(value) => Some(*value),
            Value::Number(value) => Some(value.as_i64().unwrap_or(0) != 0),
            Value::String(value) => Some(value == "true" || value == "1"),
            _ => None,
        })
        .unwrap_or(false)
}

fn parse_json_object(row: &Value, key: &str) -> Value {
    parse_json_maybe_string(row, key)
        .filter(Value::is_object)
        .unwrap_or_else(|| json!({}))
}

fn parse_json_maybe_string(row: &Value, key: &str) -> Option<Value> {
    match row.get(key)? {
        Value::String(value) if !value.is_empty() => serde_json::from_str::<Value>(value)
            .ok()
            .or_else(|| Some(Value::String(value.clone()))),
        Value::Object(_) | Value::Array(_) => row.get(key).cloned(),
        _ => None,
    }
}

fn book_key(name: &str, author: &str) -> String {
    format!("{name}\u{0}{author}")
}

fn chapter_id_for(book_id: &str, url: &str, index: i64) -> String {
    if url.is_empty() {
        return format!("{book_id}_ch_{}", index.max(0));
    }
    let mut hash = 2166136261u32;
    for unit in url.encode_utf16() {
        hash ^= u32::from(unit);
        hash = hash.wrapping_mul(16777619);
    }
    format!("{book_id}_url_{hash:08x}")
}

fn read_table_rows(conn: &Connection, table: &str) -> Result<Vec<Value>, DbError> {
    let column_names = table_columns(conn, table)?;
    let sql = format!(
        "SELECT * FROM {} ORDER BY {}",
        quote_identifier(table),
        snapshot_order_by(table, &column_names)
    );
    let mut stmt = conn.prepare(&sql)?;
    let mut rows = stmt.query([])?;
    let mut values = Vec::new();
    while let Some(row) = rows.next()? {
        let mut object = Map::new();
        for (index, column) in column_names.iter().enumerate() {
            let value = sqlite_value_to_json(row.get_ref(index)?).map_err(|error| match error {
                DbError::Message(message) => {
                    DbError::Message(format!("Room 表 {table} 列 {column}: {message}"))
                }
                error => error,
            })?;
            object.insert(column.clone(), value);
        }
        values.push(Value::Object(object));
    }
    Ok(values)
}

fn snapshot_order_by(table: &str, columns: &[String]) -> String {
    match table {
        "books" => "\"bookUrl\"".to_string(),
        "book_sources" => "\"customOrder\", \"bookSourceUrl\"".to_string(),
        "chapters" => "\"bookUrl\", \"index\", \"url\"".to_string(),
        "bookmarks" => "\"time\"".to_string(),
        "readRecord" => "\"deviceId\", \"bookName\"".to_string(),
        "detailedReadRecord" => "\"id\"".to_string(),
        "replace_rules" => "\"sortOrder\", \"id\"".to_string(),
        _ => columns
            .iter()
            .map(|column| quote_identifier(column))
            .collect::<Vec<_>>()
            .join(", "),
    }
}

fn sqlite_value_to_json(value: ValueRef<'_>) -> Result<Value, DbError> {
    match value {
        ValueRef::Null => Ok(Value::Null),
        ValueRef::Integer(value) => Ok(json!(value)),
        ValueRef::Real(value) => Ok(json!(value)),
        ValueRef::Text(value) => std::str::from_utf8(value)
            .map(|value| Value::String(value.to_string()))
            .map_err(|_| DbError::Message("SQLite TEXT 包含非法 UTF-8，无法无损归档".to_string())),
        ValueRef::Blob(value) => Ok(json!({"$blob": value})),
    }
}

fn read_room_identity_hash(conn: &Connection) -> Result<Option<String>, DbError> {
    if !table_exists(conn, "room_master_table")? {
        return Ok(None);
    }
    Ok(conn
        .query_row(
            "SELECT identity_hash FROM room_master_table WHERE id = 42",
            [],
            |row| row.get(0),
        )
        .optional()?)
}

fn table_exists(conn: &Connection, table: &str) -> Result<bool, DbError> {
    let count: i32 = conn.query_row(
        "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?1",
        [table],
        |row| row.get(0),
    )?;
    Ok(count > 0)
}

fn table_columns(conn: &Connection, table: &str) -> Result<Vec<String>, DbError> {
    let mut stmt = conn.prepare(&format!("PRAGMA table_info({})", quote_identifier(table)))?;
    let rows = stmt.query_map([], |row| row.get::<_, String>(1))?;
    rows.collect::<Result<Vec<_>, _>>().map_err(DbError::from)
}

fn quote_identifier(value: &str) -> String {
    format!("\"{}\"", value.replace('"', "\"\""))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::EngineDb;

    #[test]
    fn probe_accepts_current_room_core_shape() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);

        let probe = probe_legacy_room_connection(&conn).unwrap();

        assert_eq!(probe.user_version, KOTLIN_ROOM_CURRENT_VERSION);
        assert_eq!(
            probe.room_identity_hash.as_deref(),
            Some(KOTLIN_ROOM_IDENTITY_HASH)
        );
        assert!(probe.has_required_core_shape());
        assert!(!probe.needs_kotlin_room_migration());
    }

    #[test]
    fn probe_reports_missing_columns_and_old_room_version() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, 42);
        conn.execute("ALTER TABLE books RENAME TO books_old", [])
            .unwrap();
        conn.execute(
            "CREATE TABLE books (bookUrl TEXT PRIMARY KEY, name TEXT NOT NULL)",
            [],
        )
        .unwrap();

        let probe = probe_legacy_room_connection(&conn).unwrap();

        assert!(probe.needs_kotlin_room_migration());
        assert!(!probe.has_required_core_shape());
        assert!(probe
            .missing_columns
            .get("books")
            .unwrap()
            .contains(&"durChapterPos".to_string()));
    }

    #[test]
    fn probe_rejects_non_legado_sqlite_shape() {
        let conn = Connection::open_in_memory().unwrap();
        conn.execute("CREATE TABLE unrelated (id INTEGER PRIMARY KEY)", [])
            .unwrap();

        let probe = probe_legacy_room_connection(&conn).unwrap();

        assert!(!probe.has_required_core_shape());
        assert!(probe.missing_tables.contains(&"books".to_string()));
        assert!(probe.missing_tables.contains(&"book_sources".to_string()));
    }

    #[test]
    fn extract_rejects_missing_room_entity_tables_after_core_shape_passes() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute("DROP TABLE book_groups", []).unwrap();
        conn.execute("DROP TABLE servers", []).unwrap();

        let probe = probe_legacy_room_connection(&conn).unwrap();
        assert!(probe.has_required_core_shape());
        assert!(probe.missing_tables.is_empty());

        let error = extract_legacy_room_connection(&conn).unwrap_err();
        let message = error.to_string();
        assert!(message.contains("Room v99 数据库缺少实体表"));
        assert!(message.contains("book_groups"));
        assert!(message.contains("servers"));
    }

    #[test]
    fn extract_rejects_view_that_uses_a_room_entity_name() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute("DROP TABLE book_groups", []).unwrap();
        conn.execute(
            "CREATE VIEW book_groups AS SELECT 'g1' AS groupId, '收藏' AS groupName",
            [],
        )
        .unwrap();

        let error = extract_legacy_room_connection(&conn).unwrap_err();
        let message = error.to_string();
        assert!(message.contains("Room v99 数据库缺少实体表"));
        assert!(message.contains("book_groups"));
    }

    #[test]
    fn invalid_utf8_text_rejects_snapshot_and_import_without_writes() {
        let source_path = test_path("invalid-utf8-source");
        let backup_path = test_path("invalid-utf8-backup");
        write_room_fixture(&source_path, false);
        {
            let conn = Connection::open(&source_path).unwrap();
            conn.execute(
                "UPDATE books SET name=CAST(X'80' AS TEXT) WHERE bookUrl='book-1'",
                [],
            )
            .unwrap();
        }
        let source_before = std::fs::read(&source_path).unwrap();
        let source_size_before = std::fs::metadata(&source_path).unwrap().len();

        let snapshot_error = extract_legacy_room_database(&source_path).unwrap_err();
        assert!(snapshot_error.to_string().contains("非法 UTF-8"));

        let db = EngineDb::open_in_memory().unwrap();
        let import_error = db
            .import_legacy_room_database(&source_path, Some(&backup_path), false)
            .unwrap_err();
        assert!(import_error.to_string().contains("非法 UTF-8"));
        assert_eq!(db.book_count().unwrap(), 0);
        assert_eq!(db.legacy_room_import_count().unwrap(), 0);
        let fingerprint_count: i64 = db
            .conn
            .query_row("SELECT COUNT(*) FROM legacy_room_imports", [], |row| {
                row.get(0)
            })
            .unwrap();
        assert_eq!(fingerprint_count, 0);
        assert!(!std::fs::metadata(&backup_path).is_ok());
        assert!(!std::fs::metadata(format!("{backup_path}.tmp-{}", std::process::id())).is_ok());
        assert_eq!(
            std::fs::metadata(&source_path).unwrap().len(),
            source_size_before
        );
        assert_eq!(std::fs::read(&source_path).unwrap(), source_before);

        cleanup_test_paths(&source_path, &backup_path);
    }

    #[test]
    fn snapshot_extracts_core_rows_in_stable_order_without_writes() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute(
            "INSERT INTO books
             (bookUrl, tocUrl, origin, originName, name, author, durChapterTitle,
              durChapterIndex, durChapterPos, readConfig)
             VALUES ('book-b', '', 'source', '源', '乙书', '作者', '第二章', 1, 12, '{}'),
                    ('book-a', '', 'source', '源', '甲书', '作者', '第一章', 0, 4, '{}')",
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO chapters (url, bookUrl, title, \"index\", baseUrl)
             VALUES ('chapter-2', 'book-a', '第二章', 1, ''),
                    ('chapter-1', 'book-a', '第一章', 0, '')",
            [],
        )
        .unwrap();
        let changes_before = conn.total_changes();

        let snapshot = extract_legacy_room_connection(&conn).unwrap();

        assert_eq!(snapshot.user_version, KOTLIN_ROOM_CURRENT_VERSION);
        assert_eq!(
            snapshot.room_identity_hash.as_deref(),
            Some(KOTLIN_ROOM_IDENTITY_HASH)
        );
        assert_eq!(snapshot.tables["books"][0]["bookUrl"], "book-a");
        assert_eq!(snapshot.tables["chapters"][0]["url"], "chapter-1");
        assert_eq!(snapshot.tables["chapters"][1]["url"], "chapter-2");
        assert_eq!(conn.total_changes(), changes_before);
    }

    #[test]
    fn snapshot_archives_all_room_entities_and_marks_non_core_tables() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute(
            "INSERT INTO book_groups (groupId, groupName) VALUES ('g1', '收藏')",
            [],
        )
        .unwrap();

        let snapshot = extract_legacy_room_connection(&conn).unwrap();
        assert_eq!(snapshot.tables.len(), ROOM_ENTITY_TABLES.len());
        assert_eq!(
            snapshot.columns["book_groups"],
            vec!["groupId".to_string(), "groupName".to_string()]
        );
        assert_eq!(snapshot.tables["book_groups"][0]["groupId"], "g1");

        let mapping = map_legacy_room_snapshot(&snapshot).unwrap();
        assert!(mapping
            .archive_only_tables
            .contains(&"book_groups".to_string()));
        assert!(mapping
            .unmapped_columns
            .get("book_groups")
            .unwrap()
            .contains(&"groupName".to_string()));
        assert!(mapping
            .warnings
            .iter()
            .any(|warning| warning.contains("book_groups") && warning.contains("verbatim")));
    }

    #[test]
    fn archive_only_room_entities_survive_mapping_import_export_and_restore() {
        let source_path = test_path("archive-only-complete-source");
        let backup_path = test_path("archive-only-complete-backup");
        write_room_fixture(&source_path, false);
        {
            let conn = Connection::open(&source_path).unwrap();
            conn.execute(
                "INSERT INTO book_groups (groupId, groupName)
                 VALUES ('g1', CAST(X'00FF10' AS BLOB))",
                [],
            )
            .unwrap();
        }

        let expected_tables = ROOM_ENTITY_TABLES
            .iter()
            .map(|table| (*table).to_string())
            .collect::<std::collections::BTreeSet<_>>();
        let snapshot = extract_legacy_room_database(&source_path).unwrap();
        assert_eq!(
            snapshot
                .tables
                .keys()
                .cloned()
                .collect::<std::collections::BTreeSet<_>>(),
            expected_tables
        );
        assert_eq!(snapshot.columns["book_groups"], ["groupId", "groupName"]);
        assert_eq!(snapshot.tables["book_groups"][0]["groupId"], "g1");
        assert_eq!(
            snapshot.tables["book_groups"][0]["groupName"],
            json!({"$blob": [0, 255, 16]})
        );

        let mapping = map_legacy_room_snapshot(&snapshot).unwrap();
        let represented_tables = mapping
            .archive_only_tables
            .iter()
            .cloned()
            .chain(CORE_MAPPED_TABLES.iter().map(|table| (*table).to_string()))
            .collect::<std::collections::BTreeSet<_>>();
        assert_eq!(represented_tables, expected_tables);
        assert!(mapping
            .archive_only_tables
            .contains(&"book_groups".to_string()));

        let db = EngineDb::open_in_memory().unwrap();
        let report = db
            .import_legacy_room_database(&source_path, Some(&backup_path), false)
            .unwrap();
        let exported = db.export_backup_json().unwrap();
        let exported_value: Value = serde_json::from_str(&exported).unwrap();
        let raw_snapshot = exported_value["legacyRoomImports"][0]["rawSnapshotJson"]
            .as_str()
            .unwrap();
        let raw_value: Value = serde_json::from_str(raw_snapshot).unwrap();
        assert_eq!(
            raw_value["tables"]
                .as_object()
                .unwrap()
                .keys()
                .cloned()
                .collect::<std::collections::BTreeSet<_>>(),
            expected_tables
        );
        assert_eq!(
            raw_value["tables"]["book_groups"][0]["groupName"],
            json!({"$blob": [0, 255, 16]})
        );

        let restored = EngineDb::open_in_memory().unwrap();
        restored.restore_backup_json(&exported, true).unwrap();
        let restored_raw: String = restored
            .conn
            .query_row(
                "SELECT raw_snapshot_json FROM legacy_room_imports WHERE fingerprint=?1",
                [report.fingerprint.as_str()],
                |row| row.get(0),
            )
            .unwrap();
        let restored_value: Value = serde_json::from_str(&restored_raw).unwrap();
        assert_eq!(restored_raw, raw_snapshot);
        assert_eq!(
            restored_value["tables"]
                .as_object()
                .unwrap()
                .keys()
                .cloned()
                .collect::<std::collections::BTreeSet<_>>(),
            expected_tables
        );
        assert_eq!(
            restored_value["tables"]["book_groups"][0]["groupName"],
            json!({"$blob": [0, 255, 16]})
        );

        cleanup_test_paths(&source_path, &backup_path);
    }

    #[test]
    fn non_core_room_rows_are_stable_across_insert_order() {
        let first_path = test_path("stable-order-first");
        let second_path = test_path("stable-order-second");
        write_non_core_order_fixture(&first_path, false);
        write_non_core_order_fixture(&second_path, true);

        let first = extract_legacy_room_database(&first_path).unwrap();
        let second = extract_legacy_room_database(&second_path).unwrap();
        let expected_rows = vec![
            json!({"groupId": "group-a", "groupName": "甲"}),
            json!({"groupId": "group-b", "groupName": "乙"}),
        ];

        assert_eq!(first.tables["book_groups"], expected_rows);
        assert_eq!(first.tables["book_groups"], second.tables["book_groups"]);
        assert_eq!(
            snapshot_json(&first).to_string(),
            snapshot_json(&second).to_string()
        );
        assert_eq!(snapshot_fingerprint(&first), snapshot_fingerprint(&second));

        cleanup_test_paths(&first_path, &second_path);
    }

    #[test]
    fn snapshot_rejects_incomplete_room_shape_before_reading_rows() {
        let conn = Connection::open_in_memory().unwrap();
        conn.execute("CREATE TABLE books (bookUrl TEXT PRIMARY KEY)", [])
            .unwrap();

        let error = extract_legacy_room_connection(&conn).unwrap_err();

        assert!(error.to_string().contains("缺少迁移所需结构"));
    }

    #[test]
    fn mapping_converts_core_room_rows_to_backup_shape_and_reports_unmapped_fields() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute("ALTER TABLE chapters ADD COLUMN wordCount TEXT", [])
            .unwrap();
        conn.execute("ALTER TABLE replace_rules ADD COLUMN scope TEXT", [])
            .unwrap();
        conn.execute(
            r#"INSERT INTO books
             (bookUrl, tocUrl, origin, originName, name, author, coverUrl,
              customCoverUrl, intro, customIntro, latestChapterTitle,
              totalChapterNum, durChapterTitle, durChapterIndex,
              durChapterPos, readConfig, readIteration)
             VALUES
             ('book-1', 'https://toc.test', 'https://source.test', '源名',
              '迁移书', '作者', 'https://cover.old', 'https://cover.new',
              '简介旧', '简介新', '最新章', 10, '第二章', 1, 42,
              '{"reverseToc":true,"fontSize":20}', 2)"#,
            [],
        )
        .unwrap();
        conn.execute(
            r#"INSERT INTO book_sources
             (bookSourceUrl, bookSourceName, bookSourceGroup, bookSourceType,
              enabled, customOrder, searchUrl, ruleSearch, ruleToc, ruleContent)
             VALUES
             ('https://source.test', '测试源', '分组', 0, 1, 7,
              'https://search.test?q={{key}}',
              '{"bookList":"$.list","name":"$.name"}',
              '{"chapterList":"$.toc","chapterName":"$.title"}',
              '{"content":"$.content"}')"#,
            [],
        )
        .unwrap();
        conn.execute(
            r#"INSERT INTO chapters
             (url, bookUrl, title, "index", baseUrl, isVolume, isVip, isPay,
              tag, wordCount)
             VALUES
             ('https://chapter.test/1', 'book-1', '第一章', 0,
              'https://toc.test', 0, 1, 0, 'tag-a', '1234')"#,
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO bookmarks
             (time, bookName, bookAuthor, chapterIndex, chapterPos,
              chapterName, bookText, content)
             VALUES
             (100, '迁移书', '作者', 1, 42, '第二章', '原文', '备注')",
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO detailedReadRecord
             (bookName, startTime, endTime, readIteration)
             VALUES ('迁移书', 10, 20, 2)",
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO replace_rules
             (name, pattern, replacement, isEnabled, isRegex, sortOrder, scope)
             VALUES ('净化', '广告', '', 1, 1, 3, 'book-1')",
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO readRecord (deviceId, bookName, readTime)
             VALUES ('device-a', '迁移书', 60)",
            [],
        )
        .unwrap();

        let snapshot = extract_legacy_room_connection(&conn).unwrap();
        let mapping = map_legacy_room_snapshot(&snapshot).unwrap();

        assert_eq!(mapping.counts["books"], 1);
        assert_eq!(mapping.counts["chapters"], 1);
        assert_eq!(mapping.backup_json["books"][0]["id"], "book-1");
        assert_eq!(
            mapping.backup_json["books"][0]["coverUrl"],
            "https://cover.new"
        );
        assert_eq!(mapping.backup_json["books"][0]["currentPageIndex"], 42);
        assert_eq!(mapping.backup_json["books"][0]["durChapterIndex"], 1);
        assert_eq!(
            mapping.backup_json["books"][0]["readConfig"]["reverseToc"],
            true
        );
        assert_eq!(
            mapping.backup_json["chapters"][0]["id"],
            chapter_id_for("book-1", "https://chapter.test/1", 0)
        );
        assert_eq!(mapping.backup_json["chapters"][0]["isVip"], true);
        assert_eq!(mapping.backup_json["bookmarks"][0]["bookId"], "book-1");
        assert_eq!(
            mapping.backup_json["sources"][0]["ruleSearch"]["bookList"],
            "$.list"
        );
        assert_eq!(
            mapping.backup_json["detailedReadRecords"][0]["sessions"][0]["readIteration"],
            2
        );
        assert!(mapping
            .warnings
            .iter()
            .any(|warning| warning.contains("readRecord contains aggregate")));
        assert!(mapping
            .unmapped_columns
            .get("chapters")
            .unwrap()
            .contains(&"wordCount".to_string()));
        assert!(mapping
            .unmapped_columns
            .get("replace_rules")
            .unwrap()
            .contains(&"scope".to_string()));
    }

    #[test]
    fn mapping_warns_and_keeps_bookmark_unbound_when_book_identity_is_ambiguous() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute(
            "INSERT INTO books
             (bookUrl, tocUrl, origin, originName, name, author,
              durChapterTitle, durChapterIndex, durChapterPos, readConfig)
             VALUES
             ('book-a', '', 'source-a', '源A', '同名书', '作者', '一', 0, 0, '{}'),
             ('book-b', '', 'source-b', '源B', '同名书', '作者', '一', 0, 0, '{}')",
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO bookmarks
             (time, bookName, bookAuthor, chapterIndex, chapterPos, chapterName)
             VALUES (200, '同名书', '作者', 0, 0, '一')",
            [],
        )
        .unwrap();

        let snapshot = extract_legacy_room_connection(&conn).unwrap();
        let mapping = map_legacy_room_snapshot(&snapshot).unwrap();

        assert_eq!(mapping.backup_json["bookmarks"][0]["bookId"], "");
        assert!(mapping
            .warnings
            .iter()
            .any(|warning| warning.contains("ambiguous")));
    }

    #[test]
    fn import_rejects_non_v99_room_database() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION - 1);

        let error = extract_legacy_room_connection(&conn).unwrap_err();

        assert!(error.to_string().contains("仅支持 v99"));
    }

    #[test]
    fn import_rejects_mismatched_room_identity_hash() {
        let conn = Connection::open_in_memory().unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute(
            "UPDATE room_master_table SET identity_hash='wrong-hash' WHERE id=42",
            [],
        )
        .unwrap();

        let error = extract_legacy_room_connection(&conn).unwrap_err();

        assert!(error.to_string().contains("identity hash"));
        assert!(error.to_string().contains(KOTLIN_ROOM_IDENTITY_HASH));
    }

    #[test]
    fn import_is_transactional_preserves_raw_rows_and_skips_duplicate_merge() {
        let source_path = test_path("source");
        let backup_path = test_path("backup");
        write_room_fixture(&source_path, false);
        let source_before = std::fs::read(&source_path).unwrap();
        let source_size_before = std::fs::metadata(&source_path).unwrap().len();
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(r#"{"id":"existing","name":"保留书","author":"作者"}"#)
            .unwrap();

        let report = db
            .import_legacy_room_database(&source_path, Some(&backup_path), false)
            .unwrap();

        assert!(!report.replaced);
        assert!(!report.skipped_duplicate);
        assert!(report.backup_written);
        assert_eq!(report.conflict_counts.get("books").copied(), None);
        assert_eq!(db.book_count().unwrap(), 2);
        assert_eq!(db.legacy_room_import_count().unwrap(), 1);
        assert!(std::fs::metadata(&backup_path).unwrap().len() > 0);
        assert_eq!(
            std::fs::metadata(&source_path).unwrap().len(),
            source_size_before
        );
        assert_eq!(std::fs::read(&source_path).unwrap(), source_before);

        let raw_snapshot: String = db
            .conn
            .query_row(
                "SELECT raw_snapshot_json FROM legacy_room_imports WHERE fingerprint=?1",
                [report.fingerprint.as_str()],
                |row| row.get(0),
            )
            .unwrap();
        assert!(raw_snapshot.contains("wordCount"));

        let duplicate = db
            .import_legacy_room_database(&source_path, None, false)
            .unwrap();
        assert!(duplicate.skipped_duplicate);
        assert_eq!(db.book_count().unwrap(), 2);
        assert_eq!(db.legacy_room_import_count().unwrap(), 1);
        assert_eq!(
            std::fs::metadata(&source_path).unwrap().len(),
            source_size_before
        );
        assert_eq!(std::fs::read(&source_path).unwrap(), source_before);

        cleanup_test_paths(&source_path, &backup_path);
    }

    #[test]
    fn import_backup_round_trip_preserves_raw_room_snapshot() {
        let source_path = test_path("round-trip-source");
        let backup_path = test_path("round-trip-backup");
        write_room_fixture(&source_path, false);
        {
            let conn = Connection::open(&source_path).unwrap();
            conn.execute("ALTER TABLE replace_rules ADD COLUMN scope TEXT", [])
                .unwrap();
            conn.execute(
                "INSERT INTO replace_rules
                 (name, pattern, replacement, isEnabled, isRegex, sortOrder, scope)
                 VALUES ('净化', '广告', '', 1, 1, 3, 'book-1')",
                [],
            )
            .unwrap();
            conn.execute("UPDATE detailedReadRecord SET endTime=200000", [])
                .unwrap();
        }

        let snapshot = extract_legacy_room_database(&source_path).unwrap();
        assert_eq!(
            snapshot.tables["readRecord"][0],
            json!({
                "deviceId": "device-a",
                "bookName": "迁移书",
                "readTime": 600,
                "lastRead": 1700000000
            })
        );
        let mapping = map_legacy_room_snapshot(&snapshot).unwrap();
        assert!(mapping
            .warnings
            .iter()
            .any(|warning| warning.contains("readRecord contains aggregate")));
        assert_eq!(mapping.backup_json["readingRecords"], json!([]));

        let db = EngineDb::open_in_memory().unwrap();
        let report = db
            .import_legacy_room_database(&source_path, Some(&backup_path), false)
            .unwrap();
        let reading_record_count: i64 = db
            .conn
            .query_row("SELECT COUNT(*) FROM reading_records", [], |row| row.get(0))
            .unwrap();
        assert_eq!(reading_record_count, 0);
        let exported = db.export_backup_json().unwrap();
        let exported_value: Value = serde_json::from_str(&exported).unwrap();
        let legacy = &exported_value["legacyRoomImports"][0];
        let raw_snapshot = legacy["rawSnapshotJson"].as_str().unwrap();
        let mapped_backup = legacy["mappedBackupJson"].as_str().unwrap();
        let raw_value: Value = serde_json::from_str(raw_snapshot).unwrap();
        let mapped_value: Value = serde_json::from_str(mapped_backup).unwrap();

        assert_eq!(
            raw_value["tables"]["readRecord"][0],
            snapshot.tables["readRecord"][0]
        );
        assert_eq!(
            raw_value["tables"]["chapters"][0]["wordCount"],
            "preserve-me"
        );
        assert_eq!(raw_value["tables"]["replace_rules"][0]["scope"], "book-1");
        assert_eq!(mapped_value["readingRecords"], json!([]));
        assert_eq!(mapped_value["books"][0]["id"], "book-1");
        assert_eq!(mapped_value["chapters"][0]["bookId"], "book-1");
        assert_eq!(
            mapped_value["detailedReadRecords"][0]["sessions"][0]["readIteration"],
            1
        );

        let restored = EngineDb::open_in_memory().unwrap();
        restored.restore_backup_json(&exported, true).unwrap();

        let (restored_raw, restored_mapped): (String, String) = restored
            .conn
            .query_row(
                "SELECT raw_snapshot_json, mapped_backup_json
                 FROM legacy_room_imports WHERE fingerprint=?1",
                [report.fingerprint.as_str()],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .unwrap();
        assert_eq!(restored_raw, raw_snapshot);
        assert_eq!(restored_mapped, mapped_backup);
        let restored_raw_value: Value = serde_json::from_str(&restored_raw).unwrap();
        assert_eq!(
            restored_raw_value["tables"]["readRecord"][0],
            json!({
                "deviceId": "device-a",
                "bookName": "迁移书",
                "readTime": 600,
                "lastRead": 1700000000
            })
        );
        assert_eq!(restored.book_count().unwrap(), 1);
        let restored_chapter_count: i64 = restored
            .conn
            .query_row("SELECT COUNT(*) FROM chapters", [], |row| row.get(0))
            .unwrap();
        assert_eq!(restored_chapter_count, 1);
        let restored_detailed_record_count: i64 = restored
            .conn
            .query_row("SELECT COUNT(*) FROM detailed_read_records", [], |row| {
                row.get(0)
            })
            .unwrap();
        assert_eq!(restored_detailed_record_count, 1);

        cleanup_test_paths(&source_path, &backup_path);
    }

    #[test]
    fn import_requires_backup_path_for_first_import_without_writing_target() {
        let source_path = test_path("missing-backup-source");
        let backup_path = test_path("missing-backup");
        write_room_fixture(&source_path, false);
        let db = EngineDb::open_in_memory().unwrap();

        let error = db
            .import_legacy_room_database(&source_path, None, false)
            .unwrap_err();

        assert!(error
            .to_string()
            .contains("首次 Room 导入必须提供导入前备份路径"));
        assert_eq!(db.book_count().unwrap(), 0);
        assert_eq!(db.legacy_room_import_count().unwrap(), 0);
        assert!(!std::fs::metadata(&backup_path).is_ok());
        assert!(!std::fs::metadata(format!("{backup_path}.tmp-{}", std::process::id())).is_ok());

        cleanup_test_paths(&source_path, &backup_path);
    }

    #[test]
    fn import_refuses_existing_backup_path_without_writing_target() {
        let source_path = test_path("existing-backup-source");
        let backup_path = test_path("existing-backup");
        let original_backup = "existing-backup-content";
        write_room_fixture(&source_path, false);
        std::fs::write(&backup_path, original_backup).unwrap();
        let db = EngineDb::open_in_memory().unwrap();

        let error = db
            .import_legacy_room_database(&source_path, Some(&backup_path), false)
            .unwrap_err();

        assert!(error.to_string().contains("导入前备份路径已存在"));
        assert_eq!(db.book_count().unwrap(), 0);
        assert_eq!(db.legacy_room_import_count().unwrap(), 0);
        assert_eq!(
            std::fs::read_to_string(&backup_path).unwrap(),
            original_backup
        );
        assert!(!std::fs::metadata(format!("{backup_path}.tmp-{}", std::process::id())).is_ok());

        cleanup_test_paths(&source_path, &backup_path);
    }

    #[test]
    fn import_reports_positive_conflicts_for_existing_mapped_rows() {
        let source_path = test_path("conflict-source");
        let backup_path = test_path("conflict-backup");
        write_room_fixture(&source_path, false);
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(r#"{"id":"book-1","name":"目标旧书","author":"作者"}"#)
            .unwrap();

        let report = db
            .import_legacy_room_database(&source_path, Some(&backup_path), false)
            .unwrap();

        assert_eq!(report.conflict_counts.get("books"), Some(&1));
        assert_eq!(db.book_count().unwrap(), 1);
        cleanup_test_paths(&source_path, &backup_path);
    }

    #[test]
    fn import_rolls_back_target_rows_and_archive_when_mapping_write_fails() {
        let source_path = test_path("orphan-source");
        let backup_path = test_path("orphan-backup");
        write_room_fixture(&source_path, true);
        let db = EngineDb::open_in_memory().unwrap();
        db.insert_book_json(r#"{"id":"existing","name":"原有书籍","author":"原作者"}"#)
            .unwrap();
        db.conn
            .execute(
                "INSERT INTO legacy_room_imports
                 (fingerprint, room_version, room_identity_hash, raw_snapshot_json, mapped_backup_json)
                 VALUES ('existing-fingerprint', 99, 'existing-hash', '{}', '{}')",
                [],
            )
            .unwrap();

        let error = db
            .import_legacy_room_database(&source_path, Some(&backup_path), true)
            .unwrap_err();

        assert!(error.to_string().contains("FOREIGN KEY"));
        assert_eq!(db.book_count().unwrap(), 1);
        assert_eq!(db.legacy_room_import_count().unwrap(), 1);
        assert!(db.get_books_json().unwrap()[0].contains("原有书籍"));
        let existing_archive: String = db
            .conn
            .query_row(
                "SELECT raw_snapshot_json FROM legacy_room_imports
                 WHERE fingerprint='existing-fingerprint'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(existing_archive, "{}");
        assert!(std::fs::metadata(&backup_path).is_ok());

        cleanup_test_paths(&source_path, &backup_path);
    }

    fn write_room_fixture(path: &str, include_orphan_chapter: bool) {
        let conn = Connection::open(path).unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        conn.execute("ALTER TABLE chapters ADD COLUMN wordCount TEXT", [])
            .unwrap();
        conn.execute(
            "INSERT INTO books
             (bookUrl, tocUrl, origin, originName, name, author,
              durChapterTitle, durChapterIndex, durChapterPos, readConfig)
             VALUES ('book-1', 'toc', 'source', '源', '迁移书', '作者', '第一章', 0, 7, '{}')",
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO chapters
             (url, bookUrl, title, \"index\", baseUrl, wordCount)
             VALUES ('chapter-1', ?1, '第一章', 0, '', 'preserve-me')",
            [if include_orphan_chapter {
                "missing-book"
            } else {
                "book-1"
            }],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO detailedReadRecord
             (bookName, startTime, endTime, readIteration)
             VALUES ('迁移书', 10, 20, 1)",
            [],
        )
        .unwrap();
        conn.execute(
            "INSERT INTO readRecord (deviceId, bookName, readTime, lastRead)
             VALUES ('device-a', '迁移书', 600, 1700000000)",
            [],
        )
        .unwrap();
    }

    fn write_non_core_order_fixture(path: &str, reverse_insert_order: bool) {
        let conn = Connection::open(path).unwrap();
        create_minimal_room_schema(&conn, KOTLIN_ROOM_CURRENT_VERSION);
        if reverse_insert_order {
            conn.execute(
                "INSERT INTO book_groups (groupId, groupName) VALUES (?1, ?2)",
                ["group-b", "乙"],
            )
            .unwrap();
            conn.execute(
                "INSERT INTO book_groups (groupId, groupName) VALUES (?1, ?2)",
                ["group-a", "甲"],
            )
            .unwrap();
        } else {
            conn.execute(
                "INSERT INTO book_groups (groupId, groupName) VALUES (?1, ?2)",
                ["group-a", "甲"],
            )
            .unwrap();
            conn.execute(
                "INSERT INTO book_groups (groupId, groupName) VALUES (?1, ?2)",
                ["group-b", "乙"],
            )
            .unwrap();
        }
    }

    fn test_path(label: &str) -> String {
        let nonce = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        std::env::temp_dir()
            .join(format!(
                "legado-room-import-{label}-{}-{nonce}.db",
                std::process::id()
            ))
            .to_string_lossy()
            .into_owned()
    }

    fn cleanup_test_paths(source_path: &str, backup_path: &str) {
        let _ = std::fs::remove_file(source_path);
        let _ = std::fs::remove_file(backup_path);
    }

    fn create_minimal_room_schema(conn: &Connection, user_version: i32) {
        conn.execute_batch(
            "CREATE TABLE room_master_table (id INTEGER PRIMARY KEY, identity_hash TEXT);
             INSERT INTO room_master_table (id, identity_hash) VALUES (42, '90980f1d0da029cf3254f354b227a2fe');
             CREATE TABLE books (
               bookUrl TEXT PRIMARY KEY,
               tocUrl TEXT NOT NULL DEFAULT '',
               origin TEXT NOT NULL DEFAULT '',
               originName TEXT NOT NULL DEFAULT '',
               name TEXT NOT NULL,
               author TEXT NOT NULL DEFAULT '',
               coverUrl TEXT,
               customCoverUrl TEXT,
               intro TEXT,
               customIntro TEXT,
               type INTEGER NOT NULL DEFAULT 0,
               \"group\" INTEGER NOT NULL DEFAULT 0,
               latestChapterTitle TEXT,
               totalChapterNum INTEGER NOT NULL DEFAULT 0,
               durChapterTitle TEXT,
               durChapterIndex INTEGER NOT NULL DEFAULT 0,
               durChapterPos INTEGER NOT NULL DEFAULT 0,
               readConfig TEXT,
               readIteration INTEGER NOT NULL DEFAULT 0
             );
             CREATE TABLE book_sources (
               bookSourceUrl TEXT PRIMARY KEY,
               bookSourceName TEXT NOT NULL,
               bookSourceGroup TEXT,
               bookSourceType INTEGER NOT NULL DEFAULT 0,
               enabled INTEGER NOT NULL DEFAULT 1,
               customOrder INTEGER NOT NULL DEFAULT 0,
               searchUrl TEXT,
               ruleSearch TEXT,
               ruleBookInfo TEXT,
               ruleToc TEXT,
               ruleContent TEXT,
               ruleExplore TEXT
             );
             CREATE TABLE chapters (
               url TEXT NOT NULL,
               bookUrl TEXT NOT NULL,
               title TEXT NOT NULL,
               \"index\" INTEGER NOT NULL,
               baseUrl TEXT NOT NULL DEFAULT '',
               isVolume INTEGER NOT NULL DEFAULT 0,
               isVip INTEGER NOT NULL DEFAULT 0,
               isPay INTEGER NOT NULL DEFAULT 0,
               tag TEXT,
               PRIMARY KEY(url, bookUrl)
             );
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
             CREATE TABLE replace_rules (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name TEXT NOT NULL,
               pattern TEXT NOT NULL,
               replacement TEXT NOT NULL,
               isEnabled INTEGER NOT NULL DEFAULT 1,
               isRegex INTEGER NOT NULL DEFAULT 1,
               sortOrder INTEGER NOT NULL DEFAULT 0
             );
             CREATE TABLE book_groups (groupId TEXT, groupName TEXT);
             CREATE TABLE searchBooks (bookUrl TEXT);
             CREATE TABLE search_keywords (word TEXT);
             CREATE TABLE cookies (url TEXT, cookie TEXT);
             CREATE TABLE rssSources (sourceUrl TEXT);
             CREATE TABLE rssArticles (origin TEXT);
             CREATE TABLE rssReadRecords (record TEXT);
             CREATE TABLE rssStars (origin TEXT);
             CREATE TABLE txtTocRules (id INTEGER);
             CREATE TABLE httpTTS (id INTEGER);
             CREATE TABLE caches (key TEXT, value TEXT);
             CREATE TABLE ruleSubs (id INTEGER);
             CREATE TABLE dictRules (name TEXT);
             CREATE TABLE keyboardAssists (type TEXT);
             CREATE TABLE book_thoughts (id INTEGER);
             CREATE TABLE servers (id INTEGER);",
        )
        .unwrap();
        conn.execute_batch(&format!("PRAGMA user_version = {user_version};"))
            .unwrap();
    }
}
