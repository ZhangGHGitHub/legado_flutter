import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/chapter.dart';

/// 与 BookProvider._mergeTocWithLocal 同源逻辑的轻量单测
List<Chapter> mergeTocWithLocal(List<Chapter> remote, List<Chapter> local) {
  final byUrl = <String, Chapter>{
    for (final c in local)
      if (c.url.isNotEmpty) c.url: c,
  };
  final byId = <String, Chapter>{for (final c in local) c.id: c};

  return remote.map((r) {
    final old = (r.url.isNotEmpty ? byUrl[r.url] : null) ?? byId[r.id];
    if (old == null) return r;
    final downloaded =
        old.isDownloaded || (old.content != null && old.content!.isNotEmpty);
    return Chapter(
      id: r.id,
      bookId: r.bookId,
      title: r.title,
      index: r.index,
      url: r.url,
      isDownloaded: downloaded,
      content: downloaded ? old.content : r.content,
    );
  }).toList();
}

void main() {
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
}
