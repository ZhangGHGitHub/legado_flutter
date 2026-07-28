import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/database/database_record_codec.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/chapter.dart';

void main() {
  test('book database record preserves domain fields and defaults', () {
    final book = Book(
      id: 'book-1',
      name: '测试书',
      author: '作者',
      sourceUrl: 'https://example.test/book',
      tocUrl: 'https://example.test/book/toc',
      durChapterIndex: 7,
      currentPageIndex: 3,
      readIteration: 2,
      simReadEnabled: true,
      simReadDailyChapters: 5,
    );

    final decoded = DatabaseRecordCodec.decodeBook(
      DatabaseRecordCodec.encodeBook(book),
    );

    expect(decoded.id, book.id);
    expect(decoded.name, book.name);
    expect(decoded.sourceUrl, book.sourceUrl);
    expect(decoded.tocUrl, book.tocUrl);
    expect(decoded.durChapterIndex, 7);
    expect(decoded.currentPageIndex, 3);
    expect(decoded.readIteration, 2);
    expect(decoded.simReadEnabled, isTrue);
    expect(decoded.simReadDailyChapters, 5);

    final copied = book.copyWith(tocUrl: 'https://example.test/book/toc?v=2');
    expect(copied.tocUrl, 'https://example.test/book/toc?v=2');
  });

  test('book database record defaults missing tocUrl to an empty string', () {
    final decoded = DatabaseRecordCodec.decodeBook(
      jsonEncode({'id': 'book-2', 'name': '缺少目录链接'}),
    );

    expect(decoded.tocUrl, isEmpty);
    expect(decoded.toJson()['tocUrl'], isEmpty);
  });

  test('chapter record preserves index identity and content metadata', () {
    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 9,
      url: '/chapter/9',
      isDownloaded: true,
      content: '正文',
    );
    final rows =
        jsonDecode(DatabaseRecordCodec.encodeChapters([chapter]))
            as List<dynamic>;

    final decoded = DatabaseRecordCodec.decodeChapter(jsonEncode(rows.single));

    expect(decoded.id, chapter.id);
    expect(decoded.bookId, chapter.bookId);
    expect(decoded.index, 9);
    expect(decoded.url, chapter.url);
    expect(decoded.isDownloaded, isTrue);
    expect(decoded.content, '正文');
  });

  test(
    'clearing a chapter record carries explicit cache invalidation fields',
    () {
      final chapter = Chapter(
        id: 'chapter-1',
        bookId: 'book-1',
        title: '第一章',
        index: 0,
        url: '/chapter/1',
        isDownloaded: true,
        content: '旧正文',
      );
      final rows =
          jsonDecode(
                DatabaseRecordCodec.encodeChapter(
                  chapter,
                  clearDownloaded: true,
                ),
              )
              as List<dynamic>;
      final row = rows.single as Map<String, dynamic>;

      expect(row['isDownloaded'], isFalse);
      expect(row['content'], isNull);
      expect(row['clearDownloaded'], isTrue);
    },
  );
}
