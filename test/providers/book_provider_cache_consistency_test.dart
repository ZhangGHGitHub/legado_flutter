import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/help/book_help.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CacheDao extends BookDao {
  _CacheDao(this.book, List<Chapter> chapters)
    : chaptersByBook = {book.id: List<Chapter>.from(chapters)};

  Book book;
  final Map<String, List<Chapter>> chaptersByBook;
  final List<String> clearedChapterIds = [];

  @override
  Future<void> insert(Book value) async {
    book = value;
  }

  @override
  Future<List<Book>> getAll() async => [book];

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {
    if (chapters.isNotEmpty) {
      chaptersByBook[chapters.first.bookId] = List<Chapter>.from(chapters);
    }
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    return List<Chapter>.from(chaptersByBook[bookId] ?? const []);
  }

  @override
  Future<void> clearChapterContent(Chapter chapter) async {
    clearedChapterIds.add(chapter.id);
    final chapters = chaptersByBook[chapter.bookId] ?? const [];
    chaptersByBook[chapter.bookId] = chapters
        .map(
          (item) => item.id == chapter.id
              ? Chapter(
                  id: item.id,
                  bookId: item.bookId,
                  title: item.title,
                  index: item.index,
                  url: item.url,
                  isDownloaded: false,
                  content: null,
                )
              : item,
        )
        .toList();
  }
}

class _CacheSourceService extends BookSourceService {
  _CacheSourceService(this.chapters);

  final List<Chapter> chapters;

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    return chapters;
  }

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    return '';
  }
}

BookSource _source() =>
    BookSource(bookSourceUrl: 'cache-source', bookSourceName: 'cache-source');

Chapter _chapter({required bool isDownloaded, String? content}) => Chapter(
  id: 'chapter-1',
  bookId: 'book-1',
  title: '第一章',
  index: 0,
  url: '/chapter-1',
  isDownloaded: isDownloaded,
  content: content,
);

Future<void> _settleCacheRepair() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp(
      'legado_cache_consistency_',
    );
    await AppDataPrefs.saveDataDir(tempRoot.path);
    ReadBook.instance.reset();
  });

  tearDown(() async {
    ReadBook.instance.reset();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('file cache repairs a missing database download flag', () async {
    final book = Book(id: 'book-1', name: '缓存书');
    final chapter = _chapter(isDownloaded: false);
    final dao = _CacheDao(book, [chapter]);
    await BookHelp.saveContent(book.id, chapter.id, '文件正文');
    final provider = BookProvider(
      dao: dao,
      sourceService: _CacheSourceService([chapter]),
    );

    await provider.loadBooks();
    await provider.loadChapters(book, source: _source(), forceRefresh: true);
    await _settleCacheRepair();

    expect(provider.currentChapters.single.isDownloaded, isTrue);
    expect(dao.chaptersByBook[book.id]!.single.isDownloaded, isTrue);
    expect(dao.clearedChapterIds, isEmpty);
  });

  test(
    'missing file clears a stale database download flag and content',
    () async {
      final book = Book(id: 'book-1', name: '缓存书');
      final chapter = _chapter(isDownloaded: true, content: '旧正文');
      final dao = _CacheDao(book, [chapter]);
      final provider = BookProvider(
        dao: dao,
        sourceService: _CacheSourceService([chapter]),
      );

      await provider.loadBooks();
      await provider.loadChapters(book, source: _source(), forceRefresh: true);
      await _settleCacheRepair();

      expect(provider.currentChapters.single.isDownloaded, isFalse);
      expect(dao.clearedChapterIds, ['chapter-1']);
      expect(dao.chaptersByBook[book.id]!.single.content, isNull);
    },
  );
}
