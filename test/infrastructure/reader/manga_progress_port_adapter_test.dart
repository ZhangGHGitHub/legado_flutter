import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/reader/manga_progress_port_adapter.dart';

void main() {
  test('forwards the existing progress update signature unchanged', () async {
    String? bookId;
    double? progress;
    String? chapter;
    int? capturedPageIndex;
    int? capturedDurChapterIndex;

    final adapter = MangaProgressPortAdapter(
      updateProgress:
          (
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
          },
    );

    await adapter.updateProgress(
      'book-1',
      0.75,
      '第 3 章',
      pageIndex: 12,
      durChapterIndex: 2,
    );

    expect(bookId, 'book-1');
    expect(progress, 0.75);
    expect(chapter, '第 3 章');
    expect(capturedPageIndex, 12);
    expect(capturedDurChapterIndex, 2);
  });

  test('does not swallow update exceptions', () async {
    final error = StateError('保存进度失败');
    final adapter = MangaProgressPortAdapter(
      updateProgress:
          (
            String bookId,
            double progress,
            String? chapter, {
            int pageIndex = 0,
            int? durChapterIndex,
          }) async {
            throw error;
          },
    );

    await expectLater(
      adapter.updateProgress('book-1', 0.5, '第 2 章'),
      throwsA(same(error)),
    );
  });
}
