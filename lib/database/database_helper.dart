import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../models/replace_rule.dart';

/// 数据库管理器 - 管理书籍、书源、章节的持久化
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'legado.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _createTables,
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          try {
            await db.execute("ALTER TABLE book_sources ADD COLUMN rawSourceJson TEXT DEFAULT ''");
          } catch (_) {}
        }
        if (oldV < 3) {
          try {
            await db.execute("ALTER TABLE book_sources ADD COLUMN rawSourceJson TEXT DEFAULT ''");
          } catch (_) {}
          // 清理旧的列名数据
          try {
            await db.execute("UPDATE book_sources SET rawSourceJson = ruleSearchJson");
          } catch (_) {}
        }
        if (oldV < 4) {
          try {
            await db.execute("ALTER TABLE books ADD COLUMN bookSourceUrl TEXT DEFAULT ''");
          } catch (_) {}
        }
        if (oldV < 5) {
          try {
            await db.execute("ALTER TABLE books ADD COLUMN lastChapter TEXT DEFAULT ''");
          } catch (_) {}
        }
        if (oldV < 6) {
          try {
            await db.execute("ALTER TABLE books ADD COLUMN currentPageIndex INTEGER DEFAULT 0");
          } catch (_) {}
        }
        if (oldV < 7) {
          try {
            await db.execute("ALTER TABLE books ADD COLUMN bookGroup TEXT DEFAULT ''");
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // 书籍表
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        author TEXT DEFAULT '未知作者',
        coverUrl TEXT DEFAULT '',
        type TEXT DEFAULT 'online',
        progress REAL DEFAULT 0.0,
        currentChapter TEXT,
        lastChapter TEXT DEFAULT '',
        currentPageIndex INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        sourceUrl TEXT DEFAULT '',
        description TEXT DEFAULT '',
        bookSourceUrl TEXT DEFAULT '',
        bookGroup TEXT DEFAULT '',
        updatedAt TEXT DEFAULT (datetime('now'))
      )
    ''');

    // 书源表
    await db.execute('''
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
      )
    ''');

    // 章节表
    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        title TEXT NOT NULL,
        idx INTEGER NOT NULL,
        url TEXT DEFAULT '',
        isDownloaded INTEGER DEFAULT 0,
        content TEXT,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    // 替换规则表
    await db.execute('''
      CREATE TABLE replace_rules (
        id TEXT PRIMARY KEY,
        name TEXT DEFAULT '',
        pattern TEXT NOT NULL,
        replacement TEXT DEFAULT '',
        isEnabled INTEGER DEFAULT 1,
        isRegex INTEGER DEFAULT 1
      )
    ''');
  }

  // ═══════════════════ 书籍操作 ═══════════════════

  Future<void> insertBook(Book book) async {
    final db = await database;
    await db.insert('books', {
      'id': book.id,
      'name': book.name,
      'author': book.author,
      'coverUrl': book.coverUrl,
      'type': book.type,
      'progress': book.progress,
      'currentChapter': book.currentChapter,
      'lastChapter': book.lastChapter,
      'currentPageIndex': book.currentPageIndex,
      'isFavorite': book.isFavorite ? 1 : 0,
      'sourceUrl': book.sourceUrl,
      'description': book.description,
      'bookSourceUrl': book.bookSourceUrl,
      'bookGroup': book.group,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Book>> getBooks() async {
    final db = await database;
    final maps = await db.query('books', orderBy: 'updatedAt DESC');
    return maps.map((m) => Book.fromJson({
      ...m,
      'isFavorite': m['isFavorite'] == 1,
      'group': m['bookGroup'] ?? '',
    })).toList();
  }

  Future<void> updateBookProgress(String bookId, double progress, String? chapter, {int pageIndex = 0}) async {
    final db = await database;
    await db.update(
      'books',
      {'progress': progress, 'currentChapter': chapter, 'currentPageIndex': pageIndex, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> deleteBook(String bookId) async {
    final db = await database;
    await db.delete('chapters', where: 'bookId = ?', whereArgs: [bookId]);
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> updateBookCover(String bookId, String coverUrl) async {
    final db = await database;
    await db.update('books', {'coverUrl': coverUrl},
        where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> updateBookGroup(String bookId, String group) async {
    final db = await database;
    await db.update('books', {'bookGroup': group},
        where: 'id = ?', whereArgs: [bookId]);
  }

  // ═══════════════════ 书源操作 ═══════════════════

  /// 将数据库行转换为 BookSource（兼容旧表结构 + Legado 嵌套格式）
  BookSource _sourceFromMap(Map<String, dynamic> m) {
    // 从 rawSourceJson 中提取嵌套规则的辅助函数
    String rawField(String dbField, String outerKey, String innerKey) {
      final dbVal = m[dbField] as String? ?? '';
      if (dbVal.isNotEmpty) return dbVal;
      // 数据库字段为空 → 从 rawSourceJson 嵌套对象提取
      final raw = m['rawSourceJson'] as String? ?? '';
      if (raw.isEmpty) return '';
      try {
        final obj = jsonDecode(raw) as Map<String, dynamic>;
        final outer = obj[outerKey];
        if (outer is Map) {
          final val = outer[innerKey];
          if (val is String && val.isNotEmpty) return val;
        }
      } catch (_) {}
      return '';
    }

    return BookSource(
      bookSourceUrl: m['bookSourceUrl'] as String? ?? '',
      bookSourceName: m['bookSourceName'] as String? ?? '未命名书源',
      enabled: m['enabled'] == 1,
      bookSourceType: (m['bookSourceType'] as String?) ?? '0',
      bookSourceGroup: (m['bookSourceGroup'] as String?) ?? '',
      ruleSearchUrl: (m['ruleSearchUrl'] as String?) ?? '',
      ruleSearchList: rawField('ruleSearchList', 'ruleSearch', 'bookList'),
      ruleSearchName: rawField('ruleSearchName', 'ruleSearch', 'name'),
      ruleSearchAuthor: rawField('ruleSearchAuthor', 'ruleSearch', 'author'),
      ruleSearchCoverUrl: rawField('ruleSearchCoverUrl', 'ruleSearch', 'coverUrl'),
      ruleSearchKind: rawField('ruleSearchKind', 'ruleSearch', 'kind'),
      ruleSearchNote: rawField('ruleSearchNote', 'ruleSearch', 'note'),
      ruleBookUrlPattern: (m['ruleBookUrlPattern'] as String?) ?? '',
      ruleBookName: rawField('ruleBookName', 'ruleBookInfo', 'name'),
      ruleBookAuthor: rawField('ruleBookAuthor', 'ruleBookInfo', 'author'),
      ruleBookCoverUrl: rawField('ruleBookCoverUrl', 'ruleBookInfo', 'coverUrl'),
      ruleBookKind: (m['ruleBookKind'] as String?) ?? '',
      ruleBookNote: (m['ruleBookNote'] as String?) ?? '',
      ruleBookLastChapter: (m['ruleBookLastChapter'] as String?) ?? '',
      ruleChapterList: rawField('ruleChapterList', 'ruleToc', 'chapterList'),
      ruleChapterName: rawField('ruleChapterName', 'ruleToc', 'chapterName'),
      ruleChapterUrl: rawField('ruleChapterUrl', 'ruleToc', 'chapterUrl'),
      ruleChapterUrlIsFull: (m['ruleChapterUrlIsFull'] as String?) ?? '',
      ruleContentUrl: (m['ruleContentUrl'] as String?) ?? '',
      ruleContent: (m['ruleContent'] as String?) ?? '',
      ruleContentRemove: (m['ruleContentRemove'] as String?) ?? '',
      rulePageUrl: (m['rulePageUrl'] as String?) ?? '',
      rulePageNext: (m['rulePageNext'] as String?) ?? '',
      rawSourceJson: (m['rawSourceJson'] as String?) ?? '',
    );
  }

  Future<void> insertBookSource(BookSource source) async {
    final db = await database;
    await db.insert('book_sources', _sourceToMap(source),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertBookSources(List<BookSource> sources) async {
    final db = await database;
    final batch = db.batch();
    for (final source in sources) {
      batch.insert('book_sources', _sourceToMap(source),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateBookSource(BookSource source) async {
    final db = await database;
    await db.update(
      'book_sources',
      _sourceToMap(source),
      where: 'bookSourceUrl = ?',
      whereArgs: [source.bookSourceUrl],
    );
  }

  Map<String, dynamic> _sourceToMap(BookSource s) => {
    'bookSourceUrl': s.bookSourceUrl,
    'bookSourceName': s.bookSourceName,
    'enabled': s.enabled ? 1 : 0,
    'bookSourceType': s.bookSourceType,
    'bookSourceGroup': s.bookSourceGroup,
    'ruleSearchUrl': s.ruleSearchUrl,
    'ruleSearchList': s.ruleSearchList,
    'ruleSearchName': s.ruleSearchName,
    'ruleSearchAuthor': s.ruleSearchAuthor,
    'ruleSearchCoverUrl': s.ruleSearchCoverUrl,
    'ruleSearchKind': s.ruleSearchKind,
    'ruleSearchNote': s.ruleSearchNote,
    'ruleBookUrlPattern': s.ruleBookUrlPattern,
    'ruleBookName': s.ruleBookName,
    'ruleBookAuthor': s.ruleBookAuthor,
    'ruleBookCoverUrl': s.ruleBookCoverUrl,
    'ruleBookKind': s.ruleBookKind,
    'ruleBookNote': s.ruleBookNote,
    'ruleBookLastChapter': s.ruleBookLastChapter,
    'ruleChapterList': s.ruleChapterList,
    'ruleChapterName': s.ruleChapterName,
    'ruleChapterUrl': s.ruleChapterUrl,
    'ruleChapterUrlIsFull': s.ruleChapterUrlIsFull,
    'ruleContentUrl': s.ruleContentUrl,
    'ruleContent': s.ruleContent,
    'ruleContentRemove': s.ruleContentRemove,
    'rulePageUrl': s.rulePageUrl,
    'rulePageNext': s.rulePageNext,
    'rawSourceJson': s.rawSourceJson,
  };

  Future<List<BookSource>> getBookSources() async {
    final db = await database;
    final maps = await db.query('book_sources', orderBy: 'createdAt DESC');
    return maps.map((m) => _sourceFromMap(m)).toList();
  }

  Future<List<BookSource>> getEnabledSources() async {
    final db = await database;
    final maps = await db.query('book_sources',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => _sourceFromMap(m)).toList();
  }

  Future<void> toggleSource(String url, bool enabled) async {
    final db = await database;
    await db.update('book_sources',
      {'enabled': enabled ? 1 : 0},
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
    );
  }

  Future<void> deleteSource(String url) async {
    final db = await database;
    await db.delete('book_sources', where: 'bookSourceUrl = ?', whereArgs: [url]);
  }

  // ═══════════════════ 章节操作 ═══════════════════

  Future<void> insertChapters(List<Chapter> chapters) async {
    final db = await database;
    final batch = db.batch();
    for (final ch in chapters) {
      batch.insert('chapters', {
        'id': ch.id,
        'bookId': ch.bookId,
        'title': ch.title,
        'idx': ch.index,
        'url': ch.url,
        'isDownloaded': ch.isDownloaded ? 1 : 0,
        'content': ch.content,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Chapter>> getChapters(String bookId) async {
    final db = await database;
    final maps = await db.query('chapters',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'idx ASC',
    );
    return maps.map((m) => Chapter.fromJson({
      ...m,
      'isDownloaded': m['isDownloaded'] == 1,
    })).toList();
  }

  Future<void> saveChapterContent(String chapterId, String content) async {
    final db = await database;
    await db.update('chapters',
      {'content': content, 'isDownloaded': 1},
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  // ═══════════════════ 替换规则操作 ═══════════════════

  Future<void> insertReplaceRule(ReplaceRule rule) async {
    final db = await database;
    await db.insert('replace_rules', {
      'id': rule.id,
      'name': rule.name,
      'pattern': rule.pattern,
      'replacement': rule.replacement,
      'isEnabled': rule.isEnabled ? 1 : 0,
      'isRegex': rule.isRegex ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertReplaceRules(List<ReplaceRule> rules) async {
    final db = await database;
    final batch = db.batch();
    for (final rule in rules) {
      batch.insert('replace_rules', {
        'id': rule.id,
        'name': rule.name,
        'pattern': rule.pattern,
        'replacement': rule.replacement,
        'isEnabled': rule.isEnabled ? 1 : 0,
        'isRegex': rule.isRegex ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<ReplaceRule>> getReplaceRules() async {
    final db = await database;
    final maps = await db.query('replace_rules', orderBy: 'name ASC');
    return maps.map((m) => ReplaceRule.fromJson({
      ...m,
      'isEnabled': m['isEnabled'] == 1,
      'isRegex': m['isRegex'] == 1,
    })).toList();
  }

  Future<void> toggleReplaceRule(String id, bool enabled) async {
    final db = await database;
    await db.update('replace_rules',
      {'isEnabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReplaceRule(ReplaceRule rule) async {
    final db = await database;
    await db.update('replace_rules', {
      'name': rule.name,
      'pattern': rule.pattern,
      'replacement': rule.replacement,
      'isEnabled': rule.isEnabled ? 1 : 0,
      'isRegex': rule.isRegex ? 1 : 0,
    }, where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<void> deleteReplaceRule(String id) async {
    final db = await database;
    await db.delete('replace_rules', where: 'id = ?', whereArgs: [id]);
  }

  /// 清空所有数据（调试用）
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('chapters');
    await db.delete('books');
    await db.delete('book_sources');
  }
}
