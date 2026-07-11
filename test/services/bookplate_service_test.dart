import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/services/bookplate_service.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;

void main() {
  test('ratingFromProgress maps 0-1 to 0-5 stars', () {
    expect(BookplateService.ratingFromProgress(0), 0);
    expect(BookplateService.ratingFromProgress(0.5), 2.5);
    expect(BookplateService.ratingFromProgress(1), 5);
  });

  test('BookplateService.build assembles header/footer fields', () {
    final book = Book(
      id: 'b1',
      name: '斗破苍穹',
      author: '天蚕土豆',
      progress: 1.0,
    );
    const stats = rust_api.BookReadingStats(
      durationSeconds: 3661,
      readChars: 12000,
      startDate: '2026-07-01',
      lastDate: '2026-07-10',
      readingDays: 5,
    );

    final data = BookplateService.build(
      book: book,
      currentChapterIndex: 9,
      totalChapters: 10,
      stats: stats,
    );

    expect(data.bookName, '斗破苍穹');
    expect(data.rating, 5);
    expect(data.durationLabel, contains('小时'));
    expect(data.charsLabel, contains('万'));
    expect(data.startDate, '2026-07-01');
    expect(data.finishDate, '2026-07-10');
    expect(data.chaptersRead, 10);
    expect(data.totalChapters, 10);
  });

  test('finishDate hidden when book not completed', () {
    final book = Book(id: 'b2', name: '遮天', progress: 0.4);
    final data = BookplateService.build(
      book: book,
      currentChapterIndex: 3,
      totalChapters: 20,
      stats: const rust_api.BookReadingStats(
        durationSeconds: 600,
        readChars: 3000,
        startDate: '2026-07-05',
        lastDate: '2026-07-08',
        readingDays: 2,
      ),
    );

    expect(data.chaptersRead, 4);
    expect(data.finishDate, isNull);
    expect(data.rating, 2);
  });
}
