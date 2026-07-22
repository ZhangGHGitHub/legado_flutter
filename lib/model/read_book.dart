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

  /// 阅读会话内是否对正文应用替换净化（对齐 legado enableReplace）
  bool enableReplace = true;

  /// 本书是否重新分段（对齐 Book.getReSegment）
  bool reSegment = false;

  /// 预加载去重必须包含会话代数，避免旧会话完成时移除新会话的同索引任务。
  final Set<String> _preloading = {};
  final Map<String, String> _memoryCache = {};
  final Map<int, int> _activeContentLoads = {};
  int _sessionGeneration = 0;

  @visibleForTesting
  static String contentCacheKey({
    required String bookId,
    required String chapterId,
  }) => '$bookId\u0000$chapterId';

  @visibleForTesting
  int get sessionGeneration => _sessionGeneration;

  @visibleForTesting
  Set<String> get preloadingKeys => Set.unmodifiable(_preloading);

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
    _sessionGeneration++;
    book = currentBook;
    bookSource = source;
    chapters = List<Chapter>.from(chapterList);
    durChapterIndex = startIndex.clamp(
      0,
      chapters.isEmpty ? 0 : chapters.length - 1,
    );
    _memoryCache.clear();
    _preloading.clear();
    _activeContentLoads.clear();
    isLoadingContent = false;
    notifyListeners();
    preloadAdjacent();
  }

  Chapter? get currentChapter {
    if (chapters.isEmpty ||
        durChapterIndex < 0 ||
        durChapterIndex >= chapters.length) {
      return null;
    }
    return chapters[durChapterIndex];
  }

  /// Rust 空解析占位（恰好 9 字）——勿当成功正文缓存 / 勿当可阅读段落
  static bool isEmptyContentPlaceholder(String s) {
    final t = s.trim();
    return t.isEmpty || t == '（此章节暂无内容）' || t == '（阅读引擎未初始化）';
  }

  /// 失败 / 空结果：一律不写文件/DB 缓存
  static bool shouldSkipCache(String s) {
    final t = s.trim();
    return isEmptyContentPlaceholder(t) ||
        t.startsWith('（加载失败') ||
        t.startsWith('⚠️');
  }

  /// 对齐 ContentProcessor：reSegment → replace
  String _processContent(String raw, {String chapterTitle = ''}) {
    final proc = _processor;
    if (proc == null) return raw;
    return proc.processForReading(
      raw,
      chapterTitle: chapterTitle,
      includeTitle: false,
      useReplace: enableReplace,
      reSegment: reSegment,
    );
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
    final memKey = contentCacheKey(bookId: bid, chapterId: chapter.id);
    if (_memoryCache.containsKey(memKey)) {
      final hit = _memoryCache[memKey]!;
      // 坏缓存（空章/失败占位）一律丢弃并重新拉取
      if (!shouldSkipCache(hit)) return hit;
      _memoryCache.remove(memKey);
    }

    final generation = _sessionGeneration;
    _activeContentLoads[generation] =
        (_activeContentLoads[generation] ?? 0) + 1;
    if (generation == _sessionGeneration) {
      isLoadingContent = true;
      notifyListeners();
    }

    try {
      // 1. 文件缓存（跳过空章/失败占位，并清掉坏文件）
      final fileCached = await BookHelp.getCachedContent(bid, chapter.id);
      if (fileCached != null && fileCached.isNotEmpty) {
        if (shouldSkipCache(fileCached)) {
          if (generation == _sessionGeneration) {
            await BookHelp.deleteChapterContent(bid, chapter.id);
          }
        } else {
          final processed = _processContent(
            fileCached,
            chapterTitle: chapter.title,
          );
          if (!shouldSkipCache(processed)) {
            if (generation == _sessionGeneration) {
              _memoryCache[memKey] = processed;
            }
            return processed;
          }
          if (generation == _sessionGeneration) {
            await BookHelp.deleteChapterContent(bid, chapter.id);
          }
        }
      }

      // 2. DB 正文列（目录查询已不再带 content；正文以文件缓存为主）
      // 文件丢失时回落到 DB；数据库未就绪或读取失败则继续走网络。
      try {
        final dbCached = await _db?.getChapterContent(chapter.id);
        if (dbCached != null && dbCached.isNotEmpty) {
          final processed = _processContent(
            dbCached,
            chapterTitle: chapter.title,
          );
          if (!shouldSkipCache(processed)) {
            if (generation == _sessionGeneration) {
              _memoryCache[memKey] = processed;
              if (saveCache) {
                await BookHelp.saveContent(bid, chapter.id, dbCached);
              }
            }
            return processed;
          }
        }
      } catch (e) {
        debugPrint('DB 章节正文回落跳过: $e');
      }

      // 3. 网络拉取（失败转为可展示文案，绝不写缓存；预加载也不会变 unhandled）
      try {
        final raw = await svc.getChapterContent(chapter.url, source: source);
        if (shouldSkipCache(raw)) {
          return _processContent(raw, chapterTitle: chapter.title);
        }
        final processed = _processContent(raw, chapterTitle: chapter.title);
        if (shouldSkipCache(processed)) {
          // 占位 / 失败文案：不进内存、不写库（旧引擎 Ok 占位兼容）
          return processed;
        }
        // 换书/换源后旧请求仍可能完成，但不能把旧源正文写进当前会话缓存。
        if (generation != _sessionGeneration) return processed;
        _memoryCache[memKey] = processed;

        if (saveCache) {
          // 对齐 BookHelp：缓存原文，净化/重分段在读取时应用
          await BookHelp.saveContent(bid, chapter.id, raw);
          if (_db != null) {
            // upsert：UPDATE 在章节行尚未落库时为 0 行，需 insert 才能打上 isDownloaded
            // 搜索预览书未进 books 表时外键会失败——文件缓存仍可用，DB 标记可跳过
            try {
              await _db!.insertChapters([
                Chapter(
                  id: chapter.id,
                  bookId: bid,
                  title: chapter.title,
                  index: chapter.index,
                  url: chapter.url,
                  isDownloaded: true,
                  content: raw,
                ),
              ]);
              await _db!.saveChapterContent(chapter.id, raw);
            } catch (e) {
              debugPrint('正文 DB 落库跳过（常见于未加入书架）: $e');
            }
          }
        }

        return processed;
      } catch (e) {
        return '（加载失败: $e）';
      }
    } finally {
      final active = (_activeContentLoads[generation] ?? 1) - 1;
      if (active <= 0) {
        _activeContentLoads.remove(generation);
      } else {
        _activeContentLoads[generation] = active;
      }
      if (generation == _sessionGeneration) {
        isLoadingContent = active > 0;
        notifyListeners();
      }
    }
  }

  /// 切换到指定章节索引
  Future<String> loadAtIndex(int index, {required BookSource source}) async {
    if (index < 0 || index >= chapters.length) return '';
    final generation = _sessionGeneration;
    durChapterIndex = index;
    notifyListeners();
    final content = await loadChapterContent(
      chapter: chapters[index],
      source: source,
      bookId: book?.id,
    );
    if (generation == _sessionGeneration) preloadAdjacent();
    return content;
  }

  /// 预加载前后章（不阻塞 UI）
  void preloadAdjacent() {
    final source = bookSource;
    if (source == null || chapters.isEmpty) return;

    final generation = _sessionGeneration;
    for (final idx in [durChapterIndex - 1, durChapterIndex + 1]) {
      if (idx < 0 || idx >= chapters.length) continue;
      final ch = chapters[idx];
      final token =
          '$generation:${contentCacheKey(bookId: book?.id ?? ch.bookId, chapterId: ch.id)}';
      if (_preloading.contains(token)) continue;
      _preloading.add(token);
      loadChapterContent(
        chapter: ch,
        source: source,
        bookId: book?.id,
        saveCache: true,
      ).whenComplete(() => _preloading.remove(token));
    }
  }

  /// 使某章缓存失效（内存 + 文件），下次加载将重新拉取
  Future<void> invalidateChapterCache(
    String chapterId, {
    String? bookId,
  }) async {
    final bid = bookId ?? book?.id;
    if (bid != null && bid.isNotEmpty) {
      _memoryCache.remove(contentCacheKey(bookId: bid, chapterId: chapterId));
      await BookHelp.deleteChapterContent(bid, chapterId);
    }
  }

  /// 仅清内存缓存（文件原文保留，供替换/重分段开关切换后重算）
  void invalidateMemoryCache(String? chapterId, {String? bookId}) {
    if (chapterId == null) {
      _memoryCache.clear();
    } else if (bookId != null && bookId.isNotEmpty) {
      _memoryCache.remove(
        contentCacheKey(bookId: bookId, chapterId: chapterId),
      );
    } else {
      final suffix = '\u0000$chapterId';
      _memoryCache.removeWhere((key, _) => key.endsWith(suffix));
    }
  }

  /// 反转当前章缓存原文 — 对齐 ReadBookViewModel.reverseContent
  Future<bool> reverseChapterContent({
    required Chapter chapter,
    String? bookId,
  }) async {
    final bid = bookId ?? book?.id;
    if (bid == null || bid.isEmpty) return false;
    final raw = await BookHelp.getCachedContent(bid, chapter.id);
    if (raw == null || raw.isEmpty || shouldSkipCache(raw)) return false;
    final reversed = String.fromCharCodes(raw.runes.toList().reversed);
    await BookHelp.saveContent(bid, chapter.id, reversed);
    invalidateMemoryCache(chapter.id, bookId: bid);
    return true;
  }

  /// 写入编辑后的原文并清内存
  Future<void> saveEditedContent({
    required Chapter chapter,
    required String content,
    String? bookId,
  }) async {
    final bid = bookId ?? book?.id;
    if (bid == null || bid.isEmpty) return;
    await BookHelp.saveContent(bid, chapter.id, content);
    invalidateMemoryCache(chapter.id, bookId: bid);
  }

  void reset() {
    _sessionGeneration++;
    book = null;
    bookSource = null;
    chapters = [];
    durChapterIndex = 0;
    _memoryCache.clear();
    _preloading.clear();
    _activeContentLoads.clear();
    isLoadingContent = false;
    notifyListeners();
  }
}
