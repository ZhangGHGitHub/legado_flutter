import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/reader/reader_chapter_refresh_port_adapter.dart';

void main() {
  test('目录刷新适配器强制刷新并返回不可变最新快照', () async {
    var wasForced = false;
    var chapters = <Chapter>[];
    final adapter = ReaderChapterRefreshPortAdapter(
      loadChapters:
          (
            Book book, {
            required BookSource source,
            required bool forceRefresh,
          }) async {
            wasForced = forceRefresh;
            chapters = [
              const Chapter(
                id: 'chapter-1',
                bookId: 'book-1',
                title: '第一章',
                index: 0,
                url: 'chapter-1',
              ),
            ];
          },
      currentChapters: () => chapters,
    );
    const book = Book(id: 'book-1', name: '测试书');
    const source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );

    final result = await adapter.refreshChapters(book, source: source);

    expect(wasForced, isTrue);
    expect(result.single.title, '第一章');
    expect(
      () => result.add(
        const Chapter(
          id: 'x',
          bookId: 'book-1',
          title: 'x',
          index: 0,
          url: 'x',
        ),
      ),
      throwsUnsupportedError,
    );
  });
}
