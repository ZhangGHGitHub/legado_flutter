import 'dart:convert';

import '../infrastructure/database/database_record_codec.dart';
import '../infrastructure/database/frb_rust_database_port.dart';
import '../infrastructure/database/rust_database_port.dart';
import '../domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';

/// 数据库管理器 — 委托 Rust rusqlite（Phase C）
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal() : _port = FrbRustDatabasePort();
  DatabaseHelper.forPort(RustDatabasePort port) : _port = port;

  final RustDatabasePort _port;

  void _requireReady() => _port.requireReady();

  // ═══════════════════ 书籍操作 ═══════════════════

  Future<void> insertBook(Book book) async {
    _requireReady();
    _port.insertBook(bookJson: DatabaseRecordCodec.encodeBook(book));
  }

  Future<List<Book>> getBooks() async {
    _requireReady();
    return _port.getBooks().map(DatabaseRecordCodec.decodeBook).toList();
  }

  Future<void> updateBookProgress(
    String bookId,
    double progress,
    String? chapter, {
    int pageIndex = 0,
  }) async {
    _requireReady();
    _port.updateBookProgress(
      bookId: bookId,
      progress: progress,
      chapter: chapter,
      pageIndex: pageIndex,
    );
  }

  Future<void> deleteBook(String bookId) async {
    _requireReady();
    _port.deleteBook(bookId: bookId);
  }

  Future<void> updateBookCover(String bookId, String coverUrl) async {
    _requireReady();
    _port.updateBookCover(bookId: bookId, coverUrl: coverUrl);
  }

  Future<void> updateBookGroup(String bookId, String group) async {
    _requireReady();
    _port.updateBookGroup(bookId: bookId, group: group);
  }

  // ═══════════════════ 书源操作 ═══════════════════

  Future<void> insertBookSource(BookSource source) async {
    _requireReady();
    _port.upsertSource(sourceJson: _sourceJson(source));
  }

  Future<void> insertBookSources(List<BookSource> sources) async {
    _requireReady();
    for (final source in sources) {
      _port.upsertSource(sourceJson: _sourceJson(source));
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
    return _parseSources(_port.getSources(enabledOnly: false));
  }

  Future<List<BookSource>> getEnabledSources() async {
    _requireReady();
    return _parseSources(_port.getSources(enabledOnly: true));
  }

  Future<void> toggleSource(String url, bool enabled) async {
    _requireReady();
    _port.toggleSource(url: url, enabled: enabled);
  }

  Future<void> deleteSource(String url) async {
    _requireReady();
    _port.deleteSource(url: url);
  }

  // ═══════════════════ 章节操作 ═══════════════════

  Future<void> insertChapters(List<Chapter> chapters) async {
    _requireReady();
    _port.insertChapters(
      chaptersJson: DatabaseRecordCodec.encodeChapters(chapters),
    );
  }

  Future<List<Chapter>> getChapters(String bookId) async {
    _requireReady();
    return _port
        .getChapters(bookId: bookId)
        .map(DatabaseRecordCodec.decodeChapter)
        .toList();
  }

  Future<String?> getChapterContent(String chapterId) async {
    _requireReady();
    return _port.getChapterContent(chapterId: chapterId);
  }

  Future<void> saveChapterContent(String chapterId, String content) async {
    _requireReady();
    _port.saveChapterContent(chapterId: chapterId, content: content);
  }

  /// 清除章节文件缓存对应的数据库正文和下载标记。
  Future<void> clearChapterContent(Chapter chapter) async {
    _requireReady();
    _port.insertChapters(
      chaptersJson: DatabaseRecordCodec.encodeChapter(
        chapter,
        clearDownloaded: true,
      ),
    );
  }

  // ═══════════════════ 替换规则操作 ═══════════════════

  Future<void> insertReplaceRule(ReplaceRule rule) async {
    _requireReady();
    _port.upsertReplaceRule(ruleJson: jsonEncode(rule.toJson()));
  }

  Future<void> insertReplaceRules(List<ReplaceRule> rules) async {
    _requireReady();
    for (final rule in rules) {
      _port.upsertReplaceRule(ruleJson: jsonEncode(rule.toJson()));
    }
  }

  Future<List<ReplaceRule>> getReplaceRules() async {
    _requireReady();
    return _port
        .getReplaceRules()
        .map((s) => ReplaceRule.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleReplaceRule(String id, bool enabled) async {
    _requireReady();
    _port.toggleReplaceRule(id: id, enabled: enabled);
  }

  Future<void> updateReplaceRule(ReplaceRule rule) async {
    await insertReplaceRule(rule);
  }

  Future<void> deleteReplaceRule(String id) async {
    _requireReady();
    _port.deleteReplaceRule(id: id);
  }

  Future<void> clearReplaceRules() async {
    _requireReady();
    _port.clearReplaceRules();
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
