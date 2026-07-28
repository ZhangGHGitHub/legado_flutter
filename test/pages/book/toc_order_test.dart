import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/features/book/toc_sheet.dart';
import 'package:legado_flutter/services/book_source_service.dart';

class _MemoryDao extends BookDao {
  _MemoryDao(this.chapters, {this.books = const []});

  List<Chapter> chapters;
  List<Book> books;

  @override
  Future<List<Book>> getAll() async => List<Book>.from(books);

  @override
  Future<void> insert(Book value) async => books = [value];

  @override
  Future<List<Chapter>> getChapters(String bookId) async =>
      List<Chapter>.from(chapters);

  @override
  Future<void> insertChapters(List<Chapter> value) async {
    chapters = List<Chapter>.from(value);
  }
}

class _RemoteTocService extends BookSourceService {
  _RemoteTocService(this.remote);

  final List<Chapter> remote;

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async => remote;
}

List<Chapter> _chapters(String bookId) => [
  Chapter(
    id: 'chapter-a',
    bookId: bookId,
    title: '第一章',
    index: 0,
    url: 'https://example.test/a',
  ),
  Chapter(
    id: 'chapter-b',
    bookId: bookId,
    title: '第二章',
    index: 1,
    url: 'https://example.test/b',
  ),
  Chapter(
    id: 'chapter-c',
    bookId: bookId,
    title: '第三章',
    index: 2,
    url: 'https://example.test/c',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(ReadBook.instance.reset);

  testWidgets('directory defaults to source order', (tester) async {
    final chapters = _chapters('book-1');
    await tester.pumpWidget(
      MaterialApp(
        home: TocSheet(
          chapters: chapters,
          onChapterTap: (_, {pageIndex, chapterPos}) {},
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('第一章')).dy,
      lessThan(tester.getTopLeft(find.text('第二章')).dy),
    );
    expect(
      tester.getTopLeft(find.text('第二章')).dy,
      lessThan(tester.getTopLeft(find.text('第三章')).dy),
    );
  });

  testWidgets('directory reverse action changes presentation order', (
    tester,
  ) async {
    final chapters = _chapters('book-1');
    await tester.pumpWidget(
      MaterialApp(
        home: TocSheet(
          chapters: chapters,
          onChapterTap: (_, {pageIndex, chapterPos}) {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('倒序'));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('第三章')).dy,
      lessThan(tester.getTopLeft(find.text('第二章')).dy),
    );
    expect(
      tester.getTopLeft(find.text('第二章')).dy,
      lessThan(tester.getTopLeft(find.text('第一章')).dy),
    );
  });

  testWidgets('reverseToc persists the reversed TOC with fresh indexes', (
    tester,
  ) async {
    final chapters = _chapters('book-1');
    final book = Book(id: 'book-1', name: '测试书');
    final dao = _MemoryDao(chapters, books: [book]);
    await tester.pumpWidget(
      MaterialApp(
        home: TocSheet(
          chapters: chapters,
          book: book,
          bookRepository: dao,
          onChapterTap: (_, {pageIndex, chapterPos}) {},
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('倒序'));
    await tester.pump();
    await tester.pump();

    expect(dao.chapters.map((chapter) => chapter.title), ['第三章', '第二章', '第一章']);
    expect(dao.chapters.map((chapter) => chapter.index), [0, 1, 2]);
    expect(dao.books.single.readConfig.reverseToc, isTrue);
  });

  test(
    'remote directory contract normalizes chapter indexes to 0-based order',
    () async {
      final book = Book(id: 'book-1', name: '测试书');
      final remote = _chapters(book.id)
          .asMap()
          .entries
          .map(
            (entry) => Chapter(
              id: entry.value.id,
              bookId: book.id,
              title: entry.value.title,
              index: entry.key + 10,
              url: entry.value.url,
            ),
          )
          .toList();
      final provider = BookProvider(
        repository: _MemoryDao(const []),
        contentCache: const FileChapterContentCache(),
        sourceService: _RemoteTocService(remote),
      );

      await provider.loadChapters(
        book,
        source: BookSource(bookSourceUrl: 'source', bookSourceName: '测试'),
      );

      expect(provider.currentChapters.map((chapter) => chapter.index), [
        0,
        1,
        2,
      ]);
    },
  );

  test('book reverseToc contract is explicit and persistent', () {
    final json = Book(id: 'book-1', name: '测试书').toJson();
    expect(
      json,
      containsPair('readConfig', containsPair('reverseToc', isFalse)),
    );
    expect(json, isNot(contains('reverseToc')));
    final restored = Book.fromJson({
      ...json,
      'readConfig': {'reverseToc': true},
    });
    expect(restored.readConfig.reverseToc, isTrue);
  });
}
