import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/services/app_paths.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedSourceService extends TestBookSourceService {
  final Map<String, Completer<String>> _pending = {};
  final Map<String, int> calls = {};
  final Map<String, String?> nextChapterUrls = {};

  @override
  Future<String> getChapterContent(String url, {required BookSource source}) {
    calls[url] = (calls[url] ?? 0) + 1;
    return (_pending[url] ??= Completer<String>()).future;
  }

  @override
  Future<String> getChapterContentWithNextChapter(
    String url, {
    required BookSource source,
    String? nextChapterUrl,
  }) {
    nextChapterUrls[url] = nextChapterUrl;
    return getChapterContent(url, source: source);
  }

  void complete(String url, String content) {
    final pending = _pending.remove(url);
    if (pending != null && !pending.isCompleted) pending.complete(content);
  }
}

BookSource _source(String url) =>
    BookSource(bookSourceUrl: url, bookSourceName: url);

Chapter _chapter(String bookId, String id, String url, int index) => Chapter(
  id: id,
  bookId: bookId,
  title: '第${index + 1}章',
  index: index,
  url: url,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;
  late _DelayedSourceService service;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('legado_read_book_async_');
    SharedPreferences.setMockInitialValues({});
    await AppDataPrefs.saveDataDir(tempRoot.path);
    service = _DelayedSourceService();
    ReadBook.instance.reset();
    ReadBook.instance.configureDependencies(
      sourceService: service,
      repository: _FakeBookRepository(),
      contentProcessor: ContentProcessorAdapter(
        processor: ContentProcessor.instance,
      ),
      contentCache: const FileChapterContentCache(),
    );
  });

  tearDown(() async {
    for (
      var i = 0;
      i < 100 && ReadBook.instance.preloadingKeys.isNotEmpty;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    ReadBook.instance.reset();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('old source result cannot write current source cache', () async {
    final book = Book(id: 'book-1', name: '测试书', sourceUrl: 'book-url');
    final oldSource = _source('source-old');
    final newSource = _source('source-new');
    final oldChapter = _chapter(book.id, 'same-chapter', 'old-chapter-url', 0);
    final newChapter = _chapter(book.id, 'same-chapter', 'new-chapter-url', 0);

    ReadBook.instance.open(
      currentBook: book,
      source: oldSource,
      chapterList: [oldChapter],
    );
    final oldLoad = ReadBook.instance.loadChapterContent(
      chapter: oldChapter,
      source: oldSource,
      saveCache: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    ReadBook.instance.open(
      currentBook: book,
      source: newSource,
      chapterList: [newChapter],
    );
    service.complete(oldChapter.url, '旧书源正文');
    await oldLoad;

    final newLoad = ReadBook.instance.loadChapterContent(
      chapter: newChapter,
      source: newSource,
      saveCache: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(service.calls[newChapter.url], 1);
    service.complete(newChapter.url, '新书源正文');

    expect(await newLoad, '新书源正文');
  });

  test('passes the next chapter URL to the paginated content source', () async {
    final book = Book(id: 'book-next', name: '测试书');
    final source = _source('source');
    final first = _chapter(book.id, 'first', 'chapter-1', 0);
    final second = _chapter(book.id, 'second', 'chapter-2', 1);

    ReadBook.instance.open(
      currentBook: book,
      source: source,
      chapterList: [first, second],
    );
    final load = ReadBook.instance.loadChapterContent(
      chapter: first,
      source: source,
      saveCache: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(service.nextChapterUrls[first.url], second.url);
    service.complete(first.url, '第一章正文');
    service.complete(second.url, '第二章正文');
    expect(await load, '第一章正文');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  test(
    'old preload completion does not release current preload token',
    () async {
      final book = Book(id: 'book-2', name: '测试书');
      final source = _source('source');
      final oldChapter = _chapter(book.id, 'old-next', 'old-next-url', 1);
      final newChapter = _chapter(book.id, 'new-next', 'new-next-url', 1);

      ReadBook.instance.open(
        currentBook: book,
        source: source,
        chapterList: [
          _chapter(book.id, 'old-current', 'old-current-url', 0),
          oldChapter,
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(service.calls[oldChapter.url], 1);

      ReadBook.instance.open(
        currentBook: book,
        source: source,
        chapterList: [
          _chapter(book.id, 'new-current', 'new-current-url', 0),
          newChapter,
        ],
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(service.calls[newChapter.url], 1);

      service.complete(oldChapter.url, '旧预加载');
      await Future<void>.delayed(Duration.zero);
      ReadBook.instance.preloadAdjacent();
      expect(service.calls[newChapter.url], 1);

      service.complete(newChapter.url, '新预加载');
    },
  );
}

class _FakeBookRepository extends Fake implements BookRepository {
  @override
  Future<String?> getChapterContent(String chapterId) async => null;

  @override
  Future<void> insertChapters(List<Chapter> chapters) async {}

  @override
  Future<void> saveChapterContent(String chapterId, String content) async {}
}
