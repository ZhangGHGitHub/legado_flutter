import 'dart:convert';

import '../bridge/legado_db_bridge.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../models/replace_rule.dart';
import '../src/rust/api/db.dart' as rust_db;

/// 数据库管理器 — 委托 Rust rusqlite（Phase C）
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  void _requireReady() => LegadoDbBridge.requireReady();

  // ═══════════════════ 书籍操作 ═══════════════════

  Future<void> insertBook(Book book) async {
    _requireReady();
    rust_db.dbInsertBook(bookJson: jsonEncode(book.toJson()));
  }

  Future<List<Book>> getBooks() async {
    _requireReady();
    return rust_db
        .dbGetBooks()
        .map((s) => Book.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateBookProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {
    _requireReady();
    rust_db.dbUpdateBookProgress(
      bookId: bookId,
      progress: progress,
      chapter: chapter,
      pageIndex: pageIndex,
    );
  }

  Future<void> deleteBook(String bookId) async {
    _requireReady();
    rust_db.dbDeleteBook(bookId: bookId);
  }

  Future<void> updateBookCover(String bookId, String coverUrl) async {
    _requireReady();
    rust_db.dbUpdateBookCover(bookId: bookId, coverUrl: coverUrl);
  }

  Future<void> updateBookGroup(String bookId, String group) async {
    _requireReady();
    rust_db.dbUpdateBookGroup(bookId: bookId, group: group);
  }

  // ═══════════════════ 书源操作 ═══════════════════

  Future<void> insertBookSource(BookSource source) async {
    _requireReady();
    rust_db.dbUpsertSource(sourceJson: _sourceJson(source));
  }

  Future<void> insertBookSources(List<BookSource> sources) async {
    _requireReady();
    for (final source in sources) {
      rust_db.dbUpsertSource(sourceJson: _sourceJson(source));
    }
  }

  Future<void> updateBookSource(BookSource source) async {
    await insertBookSource(source);
  }

  String _sourceJson(BookSource source) => source.toEngineJson();

  List<BookSource> _parseSources(List<String> rows) {
    return rows.map((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return BookSource.fromJson(map);
    }).toList();
  }

  Future<List<BookSource>> getBookSources() async {
    _requireReady();
    return _parseSources(rust_db.dbGetSources(enabledOnly: false));
  }

  Future<List<BookSource>> getEnabledSources() async {
    _requireReady();
    return _parseSources(rust_db.dbGetSources(enabledOnly: true));
  }

  Future<void> toggleSource(String url, bool enabled) async {
    _requireReady();
    rust_db.dbToggleSource(url: url, enabled: enabled);
  }

  Future<void> deleteSource(String url) async {
    _requireReady();
    rust_db.dbDeleteSource(url: url);
  }

  // ═══════════════════ 章节操作 ═══════════════════

  Future<void> insertChapters(List<Chapter> chapters) async {
    _requireReady();
    rust_db.dbInsertChapters(
      chaptersJson: jsonEncode(chapters.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<Chapter>> getChapters(String bookId) async {
    _requireReady();
    return rust_db
        .dbGetChapters(bookId: bookId)
        .map((s) => Chapter.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveChapterContent(String chapterId, String content) async {
    _requireReady();
    rust_db.dbSaveChapterContent(chapterId: chapterId, content: content);
  }

  // ═══════════════════ 替换规则操作 ═══════════════════

  Future<void> insertReplaceRule(ReplaceRule rule) async {
    _requireReady();
    rust_db.dbUpsertReplaceRule(ruleJson: jsonEncode(rule.toJson()));
  }

  Future<void> insertReplaceRules(List<ReplaceRule> rules) async {
    _requireReady();
    for (final rule in rules) {
      rust_db.dbUpsertReplaceRule(ruleJson: jsonEncode(rule.toJson()));
    }
  }

  Future<List<ReplaceRule>> getReplaceRules() async {
    _requireReady();
    return rust_db
        .dbGetReplaceRules()
        .map(
          (s) => ReplaceRule.fromJson(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> toggleReplaceRule(String id, bool enabled) async {
    _requireReady();
    rust_db.dbToggleReplaceRule(id: id, enabled: enabled);
  }

  Future<void> updateReplaceRule(ReplaceRule rule) async {
    await insertReplaceRule(rule);
  }

  Future<void> deleteReplaceRule(String id) async {
    _requireReady();
    rust_db.dbDeleteReplaceRule(id: id);
  }

  Future<void> clearReplaceRules() async {
    _requireReady();
    rust_db.dbClearReplaceRules();
  }

  /// 清空所有数据（调试用）
  Future<void> clearAll() async {
    _requireReady();
    for (final book in await getBooks()) {
      await deleteBook(book.id);
    }
    for (final source in await getBookSources()) {
      await deleteSource(source.bookSourceUrl);
    }
    await clearReplaceRules();
  }
}
