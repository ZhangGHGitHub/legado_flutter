import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../help/book_help.dart';
import '../help/content_processor.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../services/book_source_service.dart';

/// 阅读会话 — 对齐 Legado `ReadBook.kt`
///
/// 管理当前书/章节、正文加载、相邻章预加载。
class ReadBook extends ChangeNotifier {
  ReadBook._();

  static final ReadBook instance = ReadBook._();

  BookSourceService? _sourceService;
  DatabaseHelper? _db;
  ContentProcessor? _processor;

  Book? book;
  BookSource? bookSource;
  List<Chapter> chapters = [];
  int durChapterIndex = 0;
  bool isLoadingContent = false;

  final Set<int> _preloading = {};
  final Map<int, String> _memoryCache = {};

  void configure({
    required BookSourceService sourceService,
    DatabaseHelper? db,
    ContentProcessor? processor,
  }) {
    _sourceService = sourceService;
    _db = db ?? DatabaseHelper();
    _processor = processor ?? ContentProcessor.instance;
  }

  /// 打开阅读会话
  void open({
    required Book currentBook,
    required BookSource source,
    required List<Chapter> chapterList,
    int startIndex = 0,
  }) {
    book = currentBook;
    bookSource = source;
    chapters = List<Chapter>.from(chapterList);
    durChapterIndex = startIndex.clamp(0, chapters.isEmpty ? 0 : chapters.length - 1);
    _memoryCache.clear();
    notifyListeners();
    preloadAdjacent();
  }

  Chapter? get currentChapter {
    if (chapters.isEmpty || durChapterIndex < 0 || durChapterIndex >= chapters.length) {
      return null;
    }
    return chapters[durChapterIndex];
  }

  /// 加载章节正文（文件缓存 → DB → 网络 → 净化 → 写缓存）
  Future<String> loadChapterContent({
    required Chapter chapter,
    required BookSource source,
    String? bookId,
    bool saveCache = true,
  }) async {
    final svc = _sourceService;
    final proc = _processor;
    if (svc == null || proc == null) {
      return '（阅读引擎未初始化）';
    }

    final bid = bookId ?? book?.id ?? chapter.bookId;
    final memKey = chapter.id.hashCode;
    if (_memoryCache.containsKey(memKey)) {
      return _memoryCache[memKey]!;
    }

    isLoadingContent = true;
    notifyListeners();

    try {
      // 1. 内存/文件缓存
      final fileCached = await BookHelp.getCachedContent(bid, chapter.id);
      if (fileCached != null && fileCached.isNotEmpty) {
        final processed = proc.getContent(fileCached);
        _memoryCache[memKey] = processed;
        return processed;
      }

      // 2. DB 缓存
      if (_db != null) {
        final localChapters = await _db!.getChapters(bid);
        final hit = localChapters.where((c) => c.id == chapter.id).firstOrNull;
        if (hit != null &&
            hit.isDownloaded &&
            hit.content != null &&
            hit.content!.isNotEmpty) {
          final processed = proc.getContent(hit.content!);
          _memoryCache[memKey] = processed;
          if (saveCache) {
            await BookHelp.saveContent(bid, chapter.id, processed);
          }
          return processed;
        }
      }

      // 3. 网络拉取
      final raw = await svc.getChapterContent(chapter.url, source: source);
      final processed = proc.getContent(raw);
      _memoryCache[memKey] = processed;

      if (saveCache &&
          processed.isNotEmpty &&
          !processed.startsWith('（加载失败') &&
          !processed.startsWith('⚠️')) {
        await BookHelp.saveContent(bid, chapter.id, processed);
        if (_db != null) {
          await _db!.saveChapterContent(chapter.id, processed);
        }
      }

      return processed;
    } finally {
      isLoadingContent = false;
      notifyListeners();
    }
  }

  /// 切换到指定章节索引
  Future<String> loadAtIndex(int index, {required BookSource source}) async {
    if (index < 0 || index >= chapters.length) return '';
    durChapterIndex = index;
    notifyListeners();
    final content = await loadChapterContent(
      chapter: chapters[index],
      source: source,
      bookId: book?.id,
    );
    preloadAdjacent();
    return content;
  }

  /// 预加载前后章（不阻塞 UI）
  void preloadAdjacent() {
    final source = bookSource;
    if (source == null || chapters.isEmpty) return;

    for (final idx in [durChapterIndex - 1, durChapterIndex + 1]) {
      if (idx < 0 || idx >= chapters.length) continue;
      if (_preloading.contains(idx)) continue;
      _preloading.add(idx);
      final ch = chapters[idx];
      loadChapterContent(
        chapter: ch,
        source: source,
        bookId: book?.id,
        saveCache: true,
      ).whenComplete(() => _preloading.remove(idx));
    }
  }

  void reset() {
    book = null;
    bookSource = null;
    chapters = [];
    durChapterIndex = 0;
    _memoryCache.clear();
    _preloading.clear();
    notifyListeners();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
