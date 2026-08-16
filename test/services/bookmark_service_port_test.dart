import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/ports/bookmark_port.dart';
import 'package:legado_flutter/services/bookmark_service.dart';

void main() {
  late _FakeBookmarkPort port;

  setUp(() {
    port = _FakeBookmarkPort();
    BookmarkService.configureBookmarkPort(port);
  });

  tearDown(BookmarkService.resetBookmarkPort);

  test('reset clears the configured bookmark port', () {
    BookmarkService.resetBookmarkPort();

    expect(BookmarkService.isReady, isFalse);
    expect(BookmarkService.list(), isEmpty);
  });

  test('list, save and delete use the injected bookmark port', () {
    const existing = BookmarkSnapshot(
      time: 100,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 1,
      chapterPos: 7,
      chapterName: '第二章',
      bookText: '已有片段',
      content: '已有备注',
    );
    port.items.add(existing);

    final listed = BookmarkService.list(bookId: 'book-1');
    expect(listed.single.bookId, 'book-1');
    expect(listed.single.bookText, '已有片段');

    expect(
      BookmarkService.save(
        time: 200,
        bookId: 'book-2',
        bookName: '新书',
        bookAuthor: '新作者',
        chapterIndex: 3,
        chapterPos: 12,
        chapterName: '第四章',
        bookText: '新片段',
        content: '新备注',
      ),
      200,
    );
    expect(
      port.saved.single,
      const BookmarkSnapshot(
        time: 200,
        bookId: 'book-2',
        bookName: '新书',
        bookAuthor: '新作者',
        chapterIndex: 3,
        chapterPos: 12,
        chapterName: '第四章',
        bookText: '新片段',
        content: '新备注',
      ),
    );

    BookmarkService.delete(200);
    expect(port.deleted, [200]);
  });

  test('unavailable and failed ports preserve service failure results', () {
    port.isAvailable = false;
    expect(BookmarkService.list(), isEmpty);
    expect(
      BookmarkService.save(
        time: 1,
        bookId: 'book',
        bookName: '书',
        bookAuthor: '作者',
        chapterIndex: 0,
        chapterPos: 0,
        chapterName: '第一章',
        bookText: '正文',
      ),
      isNull,
    );

    port.isAvailable = true;
    port.saveResult = false;
    expect(
      BookmarkService.save(
        time: 2,
        bookId: 'book',
        bookName: '书',
        bookAuthor: '作者',
        chapterIndex: 0,
        chapterPos: 0,
        chapterName: '第一章',
        bookText: '正文',
      ),
      isNull,
    );
  });

  test('JSON import and export retain the existing bookmark format', () {
    const raw = '''[
      {
        "time": 300,
        "bookName": "导入书",
        "bookAuthor": "作者",
        "chapterIndex": 4,
        "chapterPos": 20,
        "chapterName": "第五章",
        "bookText": "正文片段",
        "content": "备注"
      }
    ]''';

    expect(BookmarkService.importJson(raw), 1);
    expect(port.saved.single.time, 300);
    expect(port.saved.single.bookId, isEmpty);

    final exported = BookmarkService.exportJson();
    expect(exported, contains('"time": 300'));
    expect(exported, contains('"chapterName": "第五章"'));
  });
}

class _FakeBookmarkPort implements BookmarkPort {
  final List<BookmarkSnapshot> items = [];
  final List<BookmarkSnapshot> saved = [];
  final List<int> deleted = [];
  bool saveResult = true;

  @override
  bool isAvailable = true;

  @override
  List<BookmarkSnapshot> list({String? bookId}) {
    return items
        .where((item) => bookId == null || item.bookId == bookId)
        .toList(growable: false);
  }

  @override
  bool save(BookmarkSnapshot bookmark) {
    saved.add(bookmark);
    if (saveResult) {
      items.removeWhere((item) => item.time == bookmark.time);
      items.add(bookmark);
    }
    return saveResult;
  }

  @override
  bool delete(int time) {
    deleted.add(time);
    items.removeWhere((item) => item.time == time);
    return true;
  }
}
