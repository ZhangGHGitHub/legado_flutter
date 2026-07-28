import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/ports/bookmark_port.dart';

void main() {
  test('bookmark snapshot is a pure value with all persisted fields', () {
    const first = BookmarkSnapshot(
      time: 123,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 2,
      chapterPos: 18,
      chapterName: '第三章',
      bookText: '原文',
      content: '备注',
    );
    const second = BookmarkSnapshot(
      time: 123,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 2,
      chapterPos: 18,
      chapterName: '第三章',
      bookText: '原文',
      content: '备注',
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first.time, 123);
    expect(first.content, '备注');
  });

  test(
    'port contract exposes availability and independent bookmark operations',
    () {
      final port = _MemoryBookmarkPort();
      const bookmark = BookmarkSnapshot(
        time: 456,
        bookId: 'book-2',
        bookName: '另一本书',
        bookAuthor: '另一位作者',
        chapterIndex: 0,
        chapterPos: 3,
        chapterName: '第一章',
        bookText: '片段',
        content: '',
      );

      expect(port.isAvailable, isTrue);
      expect(port.save(bookmark), isTrue);
      expect(port.list(bookId: 'book-2'), [bookmark]);
      expect(port.delete(bookmark.time), isTrue);
      expect(port.list(), isEmpty);
    },
  );
}

class _MemoryBookmarkPort implements BookmarkPort {
  final Map<int, BookmarkSnapshot> _items = {};

  @override
  bool isAvailable = true;

  @override
  List<BookmarkSnapshot> list({String? bookId}) {
    return _items.values
        .where((item) => bookId == null || item.bookId == bookId)
        .toList(growable: false);
  }

  @override
  bool save(BookmarkSnapshot bookmark) {
    _items[bookmark.time] = bookmark;
    return true;
  }

  @override
  bool delete(int time) => _items.remove(time) != null;
}
