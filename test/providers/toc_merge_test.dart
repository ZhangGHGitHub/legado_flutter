import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/chapter.dart';

/// 与 BookProvider._mergeTocWithLocal 同源逻辑的轻量单测
List<Chapter> mergeTocWithLocal(List<Chapter> remote, List<Chapter> local) {
  return Chapter.mergeWithLocal(remote, local);
}

void main() {
  test('Chapter.idFor is stable for online chapter URLs', () {
    final first = Chapter.idFor(
      bookId: 'book',
      url: 'https://example.com/chapter/1',
      index: 0,
    );
    final afterReorder = Chapter.idFor(
      bookId: 'book',
      url: 'https://example.com/chapter/1',
      index: 9,
    );
    final other = Chapter.idFor(
      bookId: 'book',
      url: 'https://example.com/chapter/2',
      index: 0,
    );

    expect(afterReorder, first);
    expect(other, isNot(first));
  });

  test('mergeTocWithLocal keeps downloaded content matched by url', () {
    final local = [
      Chapter(
        id: 'book_ch_0',
        bookId: 'book',
        title: '旧标题',
        index: 0,
        url: 'https://example.com/1.html',
        isDownloaded: true,
        content: '正文缓存',
      ),
    ];
    final remote = [
      Chapter(
        id: 'book_ch_0',
        bookId: 'book',
        title: '新标题',
        index: 0,
        url: 'https://example.com/1.html',
      ),
      Chapter(
        id: 'book_ch_1',
        bookId: 'book',
        title: '第二章',
        index: 1,
        url: 'https://example.com/2.html',
      ),
    ];

    final merged = mergeTocWithLocal(remote, local);
    expect(merged.length, 2);
    expect(merged[0].title, '新标题');
    expect(merged[0].isDownloaded, isTrue);
    expect(merged[0].content, '正文缓存');
    expect(merged[1].isDownloaded, isFalse);
  });

  test(
    'mergeTocWithLocal keeps chapter identity when remote order changes',
    () {
      final local = [
        Chapter(
          id: 'book_ch_0',
          bookId: 'book',
          title: '第一章',
          index: 0,
          url: 'https://example.com/1.html',
          isDownloaded: true,
          content: '第一章缓存',
        ),
        Chapter(
          id: 'book_ch_1',
          bookId: 'book',
          title: '第二章',
          index: 1,
          url: 'https://example.com/2.html',
          isDownloaded: true,
          content: '第二章缓存',
        ),
      ];
      final remote = [
        // 模拟刷新后目录顺序变化：新索引不能成为章节身份。
        Chapter(
          id: 'book_ch_0',
          bookId: 'book',
          title: '第二章（更新）',
          index: 0,
          url: 'https://example.com/2.html',
        ),
        Chapter(
          id: 'book_ch_1',
          bookId: 'book',
          title: '第一章（更新）',
          index: 1,
          url: 'https://example.com/1.html',
        ),
      ];

      final merged = mergeTocWithLocal(remote, local);
      expect(merged.map((c) => c.url), [
        'https://example.com/2.html',
        'https://example.com/1.html',
      ]);
      expect(merged[0].id, 'book_ch_1');
      expect(merged[0].content, '第二章缓存');
      expect(merged[1].id, 'book_ch_0');
      expect(merged[1].content, '第一章缓存');
    },
  );
}
