import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book_reading_stats.dart';
import 'package:legado_flutter/domain/ports/bookplate_port.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/services/bookplate_service.dart';

void main() {
  tearDown(BookplateService.resetBookplatePort);

  test('reset clears the configured bookplate port', () {
    BookplateService.configureBookplatePort(_FakeBookplatePort());
    BookplateService.resetBookplatePort();

    expect(BookplateService.loadBookStats('book-1'), isNull);
  });

  test('ratingFromProgress maps 0-1 to 0-5 stars', () {
    expect(BookplateService.ratingFromProgress(0), 0);
    expect(BookplateService.ratingFromProgress(0.5), 2.5);
    expect(BookplateService.ratingFromProgress(1), 5);
  });

  test('BookplateService.build assembles header/footer fields', () {
    final book = Book(id: 'b1', name: '斗破苍穹', author: '天蚕土豆', progress: 1.0);
    const stats = BookReadingStats(
      durationSeconds: 3661,
      readChars: 12000,
      startDate: '2026-07-01',
      lastDate: '2026-07-10',
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
      stats: const BookReadingStats(
        durationSeconds: 600,
        readChars: 3000,
        startDate: '2026-07-05',
        lastDate: '2026-07-08',
      ),
    );

    expect(data.chaptersRead, 4);
    expect(data.finishDate, isNull);
    expect(data.rating, 2);
  });

  test('book stats are loaded through the replaceable port', () {
    final port = _FakeBookplatePort();
    BookplateService.configureBookplatePort(port);

    final stats = BookplateService.loadBookStats('book-1');

    expect(stats?.readChars, 1234);
    expect(port.bookId, 'book-1');
  });
}

class _FakeBookplatePort implements BookplatePort {
  String? bookId;

  @override
  bool get isAvailable => true;

  @override
  BookReadingStats? loadBookStats(String bookId) {
    this.bookId = bookId;
    return const BookReadingStats(
      readChars: 1234,
      durationSeconds: 90,
      startDate: '2026-01-01',
      lastDate: '2026-01-02',
    );
  }
}
