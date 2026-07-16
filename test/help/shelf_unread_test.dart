import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/shelf_unread.dart';
import 'package:legado_flutter/models/book.dart';

void main() {
  group('ShelfUnread.evaluate', () {
    test('uses total chapters minus dur index', () {
      final book = Book(
        id: '1',
        name: 'Test',
        currentChapter: '第50章',
        lastChapter: '第60章',
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

    test('hidden when caught up', () {
      final book = Book(
        id: '1',
        name: 'Test',
        currentChapter: '终章',
        lastChapter: '终章',
      );
      final r = ShelfUnread.evaluate(
        book: book,
        totalChapters: 100,
        durChapterIndex: 99,
      );
      expect(r.visible, isFalse);
    });
  });
}
