import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/services/app_paths.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryBookDao extends BookDao {
  _MemoryBookDao({this.shelfBook});

  Book? shelfBook;
  final Map<String, List<Chapter>> chaptersByBook = {};

  @override
  Future<void> insert(Book book) async {
    shelfBook = book;
  }

  @override
  Future<List<Book>> getAll() async => [?shelfBook];

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {
    if (chapters.isEmpty) return;
    chaptersByBook[chapters.first.bookId] = List<Chapter>.from(chapters);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    return List<Chapter>.from(chaptersByBook[bookId] ?? const []);
  }
}

class _RefreshSourceService extends TestBookSourceService {
  _RefreshSourceService(this.remoteChapters);

  final List<Chapter> remoteChapters;

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    return remoteChapters;
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
    BookSource(bookSourceUrl: 'source-a', bookSourceName: 'source-a');

Chapter _chapter(String id, String title, String url, int index) =>
    Chapter(id: id, bookId: 'book-1', title: title, index: index, url: url);

List<Chapter> _oldChapters() => [
  _chapter('old-a', '第一章', '/a', 0),
  _chapter('old-b', '第二章', '/b', 1),
  _chapter('old-c', '第三章', '/c', 2),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp(
      'legado_progress_migration_',
    );
    await AppDataPrefs.saveDataDir(tempRoot.path);
    ReadBook.instance.reset();
  });

  tearDown(() async {
    ReadBook.instance.reset();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test(
    'refresh keeps progress on the same URL after chapter reorder',
    () async {
      final oldChapters = _oldChapters();
      final reordered = [oldChapters[2], oldChapters[0], oldChapters[1]];
      final book = Book(
        id: 'book-1',
        name: '测试书',
        durChapterIndex: 1,
        currentPageIndex: 7,
      );
      final dao = _MemoryBookDao(shelfBook: book);
      dao.chaptersByBook[book.id] = oldChapters;
      final provider = BookProvider(
        repository: dao,
        contentCache: const FileChapterContentCache(),
        sourceService: _RefreshSourceService(reordered),
      );
      await provider.loadBooks();

      await provider.loadChapters(book, source: _source(), forceRefresh: true);

      expect(ReadBook.instance.durChapterIndex, 2);
      expect(ReadBook.instance.book?.currentPageIndex, 7);
      expect(dao.shelfBook?.durChapterIndex, 2);
      expect(dao.shelfBook?.currentPageIndex, 7);
      expect(dao.shelfBook?.currentChapter, '第二章');
    },
  );

  test('refresh clips deleted chapter and resets its page position', () async {
    final oldChapters = _oldChapters();
    final remaining = [oldChapters[0], oldChapters[2]];
    final book = Book(
      id: 'book-1',
      name: '测试书',
      durChapterIndex: 1,
      currentPageIndex: 7,
    );
    final dao = _MemoryBookDao(shelfBook: book);
    dao.chaptersByBook[book.id] = oldChapters;
    final provider = BookProvider(
      repository: dao,
      contentCache: const FileChapterContentCache(),
      sourceService: _RefreshSourceService(remaining),
    );
    await provider.loadBooks();

    await provider.loadChapters(book, source: _source(), forceRefresh: true);

    expect(ReadBook.instance.durChapterIndex, 1);
    expect(ReadBook.instance.book?.currentPageIndex, 0);
    expect(dao.shelfBook?.durChapterIndex, 1);
    expect(dao.shelfBook?.currentPageIndex, 0);
    expect(dao.shelfBook?.currentChapter, '第三章');
  });
}
