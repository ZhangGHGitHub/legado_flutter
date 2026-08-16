import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/ports/bookmark_port.dart';
import 'package:legado_flutter/infrastructure/annotation/bookmark_editor_port_adapter.dart';
import 'package:legado_flutter/services/bookmark_service.dart';

void main() {
  late _MemoryBookmarkPort bookmarkPort;

  setUp(() {
    bookmarkPort = _MemoryBookmarkPort();
    BookmarkService.configureBookmarkPort(bookmarkPort);
  });

  tearDown(BookmarkService.resetBookmarkPort);

  test('delegates bookmark fields and preserves the generated time', () {
    const adapter = BookmarkEditorPortAdapter();

    final time = adapter.save(
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 2,
      chapterPos: 88,
      chapterName: '第三章',
      bookText: '正文',
      content: '备注',
    );

    expect(time, isNotNull);
    expect(bookmarkPort.items.single, isA<BookmarkSnapshot>());
    final saved = bookmarkPort.items.single;
    expect(saved.time, time);
    expect(saved.bookId, 'book-1');
    expect(saved.chapterIndex, 2);
    expect(saved.chapterPos, 88);
    expect(saved.chapterName, '第三章');
    expect(saved.bookText, '正文');
    expect(saved.content, '备注');
  });

  test('reports the existing service readiness gate', () {
    const adapter = BookmarkEditorPortAdapter();
    expect(adapter.isAvailable, isTrue);

    bookmarkPort.isAvailable = false;
    expect(adapter.isAvailable, isFalse);
    expect(
      adapter.save(
        bookId: 'book-1',
        bookName: '测试书',
        bookAuthor: '作者',
        chapterIndex: 0,
        chapterPos: 0,
        chapterName: '第一章',
        bookText: '正文',
      ),
      isNull,
    );
  });
}

final class _MemoryBookmarkPort implements BookmarkPort {
  final items = <BookmarkSnapshot>[];
  @override
  bool isAvailable = true;

  @override
  bool save(BookmarkSnapshot bookmark) {
    items.add(bookmark);
    return true;
  }

  @override
  List<BookmarkSnapshot> list({String? bookId}) => items;

  @override
  bool delete(int time) => false;
}
