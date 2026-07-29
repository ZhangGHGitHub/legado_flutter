import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/web_api/repository_web_api_data_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/ports/reading_record_port.dart';
import 'package:legado_flutter/domain/ports/web_api_data_port.dart';
import 'package:legado_flutter/domain/reading_stats.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

void main() {
  test(
    'maps repository entities and reading stats to the Web API contract',
    () async {
      final books = _BookRepositoryFake();
      final sources = _SourceRepositoryFake();
      final port = RepositoryWebApiDataPort(
        bookRepository: books,
        sourceRepository: sources,
        readingRecordPort: _ReadingRecordPortFake(),
        isDatabaseReady: () => true,
      );

      expect((await port.listBooks()).single['name'], '测试书');
      expect((await port.listChapters('book')).single['index'], 0);
      expect((await port.listSources()).single['bookSourceName'], '测试源');
      expect((await port.readingStats())['daily'], [
        {'date': '2026-07-29', 'chars': 12, 'durationSeconds': 34},
      ]);

      await port.addBook({'id': 'added', 'name': '新增书'});
      await port.deleteBook('book');
      expect(books.inserted?.id, 'added');
      expect(books.deleted, 'book');

      await port.addBook({'id': 'legacy-defaults', 'bookGroup': '默认分组'});
      expect(books.inserted?.name, '未知');
      expect(books.inserted?.author, isEmpty);
      expect(books.inserted?.group, '默认分组');
    },
  );

  test('rejects business access while the database is unavailable', () async {
    final port = RepositoryWebApiDataPort(
      bookRepository: _BookRepositoryFake(),
      sourceRepository: _SourceRepositoryFake(),
      readingRecordPort: _ReadingRecordPortFake(),
      isDatabaseReady: () => false,
    );

    expect(port.isAvailable, isFalse);
    await expectLater(port.listBooks(), throwsA(isA<WebApiDataUnavailable>()));
  });
}

class _BookRepositoryFake implements BookRepository {
  Book? inserted;
  String? deleted;

  @override
  Future<List<Book>> getAll() async => [Book(id: 'book', name: '测试书')];

  @override
  Future<List<Chapter>> getChapters(String bookId) async => [
    Chapter(id: 'chapter', bookId: bookId, title: '第一章', index: 0, url: '1'),
  ];

  @override
  Future<void> insert(Book book) async => inserted = book;

  @override
  Future<void> delete(String bookId) async => deleted = bookId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SourceRepositoryFake implements BookSourceRepository {
  @override
  Future<List<BookSource>> getAll() async => [
    BookSource(bookSourceUrl: 'https://source', bookSourceName: '测试源'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReadingRecordPortFake implements ReadingRecordPort {
  @override
  bool get isAvailable => true;

  @override
  ReadingStats? getStats(String range) => const ReadingStats(
    totalChars: 12,
    totalDurationSeconds: 34,
    todayChars: 12,
    todayDurationSeconds: 34,
    weekChars: 12,
    daily: [
      DailyReadingStat(date: '2026-07-29', chars: 12, durationSeconds: 34),
    ],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
