import '../../application/annotation/bookplate_overlay_port.dart';
import '../../domain/book/book.dart';
import '../../domain/book_reading_stats.dart';
import '../../services/bookplate_service.dart';

/// Reuses BookplateService's stats, progress, duration and completion mapping.
final class BookplateOverlayPortAdapter implements BookplateOverlayPort {
  const BookplateOverlayPortAdapter();

  @override
  BookplateData build({
    required Book book,
    required int currentChapterIndex,
    required int totalChapters,
  }) {
    BookReadingStats? stats;
    try {
      stats = BookplateService.loadBookStats(book.id);
    } catch (_) {}
    return BookplateService.build(
      book: book,
      currentChapterIndex: currentChapterIndex,
      totalChapters: totalChapters,
      stats: stats,
    );
  }
}
