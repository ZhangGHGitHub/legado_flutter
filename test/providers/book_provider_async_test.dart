import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/services/app_paths.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryBookDao extends BookDao {
  final Map<String, List<Chapter>> chaptersByBook = {};

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {
    if (chapters.isEmpty) return;
    chaptersByBook[chapters.first.bookId] = List<Chapter>.from(chapters);
  }

  @override
  Future<List<Chapter>> getChapters(String bookId) async {
    return List<Chapter>.from(chaptersByBook[bookId] ?? const []);
  }

  @override
  Future<List<Book>> getAll() async => const [];
}

class _DelayedTocService extends TestBookSourceService {
  final Map<String, Completer<List<Chapter>>> _pending = {};
  int calls = 0;

  bool hasPending(String sourceUrl) => _pending[sourceUrl] != null;

  Future<void> waitFor(String sourceUrl) async {
    for (var i = 0; i < 100; i++) {
      if (hasPending(sourceUrl)) return;
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    fail('timeout waiting for $sourceUrl request');
  }

  @override
  Future<List<Chapter>> getChapters(Book book, {required BookSource source}) {
    calls++;
    return (_pending[source.bookSourceUrl] ??= Completer<List<Chapter>>())
        .future;
  }

  void complete(String sourceUrl, List<Chapter> chapters) {
    final pending = _pending.remove(sourceUrl);
    if (pending != null && !pending.isCompleted) pending.complete(chapters);
  }
}

Book _book() => Book(id: 'book-1', name: '测试书', sourceUrl: 'book-url');

BookSource _source(String url) =>
    BookSource(bookSourceUrl: url, bookSourceName: url);

List<Chapter> _chapters(String bookId, String prefix) => [
  Chapter(
    id: '$prefix-chapter',
    bookId: bookId,
    title: '$prefix 章节',
    index: 0,
    url: '$prefix-url',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp(
      'legado_book_provider_async_',
    );
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('same source concurrent directory loads share one request', () async {
    final service = _DelayedTocService();
    final provider = BookProvider(
      repository: _MemoryBookDao(),
      contentCache: const FileChapterContentCache(),
      sourceService: service,
    );
    final book = _book();
    final source = _source('source-a');

    final first = provider.loadChapters(book, source: source);
    await service.waitFor(source.bookSourceUrl);
    final second = provider.loadChapters(book, source: source);
    expect(service.calls, 1);

    service.complete(source.bookSourceUrl, _chapters(book.id, 'a'));
    await Future.wait([first, second]);
    expect(provider.currentChapters.single.title, 'a 章节');
  });

  test('stale source directory result cannot replace current source', () async {
    final service = _DelayedTocService();
    final provider = BookProvider(
      repository: _MemoryBookDao(),
      contentCache: const FileChapterContentCache(),
      sourceService: service,
    );
    final book = _book();
    final oldSource = _source('source-old');
    final newSource = _source('source-new');

    final oldLoad = provider.loadChapters(book, source: oldSource);
    await service.waitFor(oldSource.bookSourceUrl);
    final newLoad = provider.loadChapters(book, source: newSource);
    await service.waitFor(newSource.bookSourceUrl);
    expect(service.calls, 2);

    service.complete(oldSource.bookSourceUrl, _chapters(book.id, 'old'));
    await oldLoad;
    expect(provider.currentChapters, isEmpty);

    service.complete(newSource.bookSourceUrl, _chapters(book.id, 'new'));
    await newLoad;
    expect(provider.currentChapters.single.title, 'new 章节');
  });
}
