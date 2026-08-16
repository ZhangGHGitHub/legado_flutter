import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/annotation/bookplate_overlay_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book_reading_stats.dart';
import 'package:legado_flutter/domain/ports/bookplate_port.dart';
import 'package:legado_flutter/infrastructure/annotation/bookplate_overlay_port_adapter.dart';
import 'package:legado_flutter/services/bookplate_service.dart';

void main() {
  late _FakeBookplatePort bookplatePort;
  final book = Book(id: 'book-1', name: '测试书', author: '作者', progress: 0.8);

  setUp(() {
    bookplatePort = _FakeBookplatePort();
    BookplateService.configureBookplatePort(bookplatePort);
  });

  tearDown(BookplateService.resetBookplatePort);

  test('reuses stats, progress and display mapping from the service', () {
    final BookplateOverlayPort adapter = const BookplateOverlayPortAdapter();

    final data = adapter.build(
      book: book,
      currentChapterIndex: 7,
      totalChapters: 10,
    );

    if (data == null) fail('bookplate adapter returned no display data');
    final resolved = data;
    expect(resolved.bookName, '测试书');
    expect(resolved.author, '作者');
    expect(resolved.durationLabel, '1 小时');
    expect(resolved.charsLabel, '1.2 万字');
    expect(resolved.chaptersRead, 8);
    expect(resolved.totalChapters, 10);
    expect(resolved.progress, 0.8);
    expect(resolved.finishDate, isNull);
    expect(bookplatePort.bookId, 'book-1');
  });
}

final class _FakeBookplatePort implements BookplatePort {
  String? bookId;

  @override
  bool get isAvailable => true;

  @override
  BookReadingStats? loadBookStats(String bookId) {
    this.bookId = bookId;
    return const BookReadingStats(
      readChars: 12000,
      durationSeconds: 3600,
      startDate: '2026-07-01',
      lastDate: '2026-07-02',
    );
  }
}
