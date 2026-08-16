import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/reader/reader_simulated_reading_port_adapter.dart';

void main() {
  test('模拟追读适配器原样转发查询和写入参数', () async {
    const stored = Book(id: 'book-1', name: '测试书');
    String? lookedUpId;
    Book? updatedBook;
    bool? capturedEnabled;
    String? capturedStartDate;
    int? capturedStartChapter;
    int? capturedDailyChapters;
    final adapter = ReaderSimulatedReadingPortAdapter(
      findBookById: (bookId) {
        lookedUpId = bookId;
        return stored;
      },
      updateSimulatedReading:
          (
            Book book, {
            required bool enabled,
            required String startDate,
            required int startChapter,
            required int dailyChapters,
          }) async {
            updatedBook = book;
            capturedEnabled = enabled;
            capturedStartDate = startDate;
            capturedStartChapter = startChapter;
            capturedDailyChapters = dailyChapters;
            return book;
          },
    );

    expect(adapter.findBookById('book-1'), same(stored));
    final result = await adapter.updateSimulatedReading(
      stored,
      enabled: true,
      startDate: '2026-08-05',
      startChapter: 4,
      dailyChapters: 7,
    );

    expect(lookedUpId, 'book-1');
    expect(result, same(stored));
    expect(updatedBook, same(stored));
    expect(capturedEnabled, isTrue);
    expect(capturedStartDate, '2026-08-05');
    expect(capturedStartChapter, 4);
    expect(capturedDailyChapters, 7);
  });
}
