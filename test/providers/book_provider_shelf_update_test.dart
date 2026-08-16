import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/services/app_paths.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ShelfDao extends BookDao {
  _ShelfDao(this.books);

  final List<Book> books;
  final Map<String, List<Chapter>> chaptersByBook = {};

  @override
  Future<void> insert(Book book) async {
    final index = books.indexWhere((item) => item.id == book.id);
    if (index < 0) {
      books.add(book);
    } else {
      books[index] = book;
    }
  }

  @override
  Future<List<Book>> getAll() async => List<Book>.from(books);

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {
    if (chapters.isEmpty) return;
    chaptersByBook[chapters.first.bookId] = List<Chapter>.from(chapters);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async =>
      List<Chapter>.from(chaptersByBook[bookId] ?? const []);
}

class _ShelfTocService extends TestBookSourceService {
  final Map<String, Future<List<Chapter>> Function(Book book)> handlers = {};
  final List<String> calls = [];

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    calls.add(book.id);
    final handler = handlers[book.id];
    if (handler == null) return const [];
    return handler(book);
  }
}

Book _book(String id, {String type = 'online', String source = 'source-a'}) =>
    Book(
      id: id,
      name: id,
      type: type,
      sourceUrl: '$id-url',
      bookSourceUrl: source,
    );

BookSource _source() =>
    BookSource(bookSourceUrl: 'source-a', bookSourceName: '测试书源');

List<Chapter> _toc(String bookId) => [
  Chapter(
    id: '$bookId-chapter',
    bookId: bookId,
    title: '第一章',
    index: 0,
    url: '$bookId-chapter-url',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('legado_shelf_update_');
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('批量更新返回成功失败统计并在失败后恢复状态', () async {
    final books = <Book>[
      _book('ok'),
      _book('failed'),
      _book('local', type: 'local'),
      _book('missing-source', source: 'source-missing'),
    ];
    final dao = _ShelfDao(books);
    final service = _ShelfTocService();
    service.handlers['ok'] = (_) async => _toc('ok');
    service.handlers['failed'] = (_) async => throw StateError('网络失败');
    final provider = BookProvider(
      repository: dao,
      contentCache: const FileChapterContentCache(),
      sourceService: service,
    );

    await provider.loadBooks();
    final result = await provider.refreshShelfToc(
      provider.books,
      resolveSource: (book) =>
          book.bookSourceUrl == 'source-a' ? _source() : null,
      concurrency: 1,
    );

    expect(result.requested, 4);
    expect(result.eligible, 2);
    expect(result.updated, 1);
    expect(result.failed, 1);
    expect(result.skipped, 2);
    expect(result.failures.keys, contains('failed'));
    expect(service.calls, ['ok', 'failed']);
    expect(dao.chaptersByBook['ok'], hasLength(1));
    expect(provider.isShelfUpdateRunning, isFalse);
    expect(provider.shelfUpdateActiveCount, 0);
    expect(provider.isBookShelfUpdating('ok'), isFalse);
  });

  test('同一批次重复触发只执行一次并最终可再次更新', () async {
    final books = <Book>[_book('one')];
    final dao = _ShelfDao(books);
    final service = _ShelfTocService();
    final pending = Completer<List<Chapter>>();
    service.handlers['one'] = (_) => pending.future;
    final provider = BookProvider(
      repository: dao,
      contentCache: const FileChapterContentCache(),
      sourceService: service,
    );
    await provider.loadBooks();

    final first = provider.refreshShelfToc(
      provider.books,
      resolveSource: (_) => _source(),
    );
    final second = provider.refreshShelfToc(
      provider.books,
      resolveSource: (_) => _source(),
    );
    expect(provider.isShelfUpdateRunning, isTrue);
    pending.complete(_toc('one'));

    final results = await Future.wait([first, second]);
    expect(results[0].updated, 1);
    expect(results[1].updated, 1);
    expect(service.calls, ['one']);
    expect(provider.isShelfUpdateRunning, isFalse);
  });
}
