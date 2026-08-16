import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/reader/reader_progress_port_adapter.dart';

void main() {
  test('阅读进度适配器原样转发进度和定位参数', () async {
    String? bookId;
    double? progress;
    String? chapter;
    int? capturedPageIndex;
    int? capturedDurChapterIndex;
    Future<void> update(
      String receivedBookId,
      double receivedProgress,
      String? receivedChapter, {
      int pageIndex = 0,
      int? durChapterIndex,
    }) async {
      bookId = receivedBookId;
      progress = receivedProgress;
      chapter = receivedChapter;
      capturedPageIndex = pageIndex;
      capturedDurChapterIndex = durChapterIndex;
    }

    final adapter = ReaderProgressPortAdapter(update: update);

    await adapter.updateProgress(
      'book-1',
      0.75,
      '第三章',
      pageIndex: 17,
      durChapterIndex: 2,
    );

    expect(bookId, 'book-1');
    expect(progress, 0.75);
    expect(chapter, '第三章');
    expect(capturedPageIndex, 17);
    expect(capturedDurChapterIndex, 2);
  });
}
