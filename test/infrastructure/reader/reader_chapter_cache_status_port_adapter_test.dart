import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/reader/reader_chapter_cache_status_port_adapter.dart';

void main() {
  test('章节缓存状态适配器原样转发章节 ID', () {
    String? chapterId;
    final adapter = ReaderChapterCacheStatusPortAdapter(
      markChapterDownloaded: (received) => chapterId = received,
    );

    adapter.markChapterDownloaded('chapter-1');

    expect(chapterId, 'chapter-1');
  });
}
