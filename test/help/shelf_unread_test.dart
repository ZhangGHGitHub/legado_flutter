import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/shelf_unread.dart';
import 'package:legado_flutter/domain/book/book.dart';

void main() {
  group('ShelfUnread.evaluate', () {
    test('uses total chapters minus dur index', () {
      final book = Book(
        id: '1',
        name: 'Test',
        currentChapter: '第50章',
        lastChapter: '第60章',
        totalChapterNum: 60,
        durChapterIndex: 49,
      );
      final r = ShelfUnread.evaluate(book: book);
      expect(r.count, 10);
      expect(r.highlight, isTrue);
      expect(r.visible, isTrue);
    });

    test('override meta wins over book fields', () {
      final book = Book(
        id: '1',
        name: 'Test',
        currentChapter: '第50章',
        lastChapter: '第60章',
        totalChapterNum: 60,
        durChapterIndex: 49,
      );
      final r = ShelfUnread.evaluate(
        book: book,
        totalChapters: 60,
        durChapterIndex: 49,
      );
      expect(r.count, 10);
      expect(r.visible, isTrue);
    });

    test('falls back to chapter title numbers', () {
      final book = Book(
        id: '1',
        name: 'Test',
        currentChapter: '第10章 开端',
        lastChapter: '第15章 续',
      );
      final r = ShelfUnread.evaluate(book: book);
      expect(r.count, 5);
      expect(r.highlight, isTrue);
    });

    test('highlight-only when titles differ but unread is zero', () {
      final book = Book(
        id: '1',
        name: 'Test',
        currentChapter: '最终话',
        lastChapter: '终章改名',
        totalChapterNum: 100,
        durChapterIndex: 99,
      );
      final r = ShelfUnread.evaluate(book: book);
      expect(r.count, isNull);
      expect(r.highlight, isTrue);
      expect(r.hasUpdate, isTrue);
      expect(r.visible, isTrue);
    });

    test('hidden when caught up', () {
      final book = Book(
        id: '1',
        name: 'Test',
        currentChapter: '终章',
        lastChapter: '终章',
        totalChapterNum: 100,
        durChapterIndex: 99,
      );
      final r = ShelfUnread.evaluate(book: book);
      expect(r.visible, isFalse);
    });
  });
}
