import '../../domain/book/book.dart';

/// Display-ready data for the reader bookplate overlay.
final class BookplateData {
  const BookplateData({
    required this.bookName,
    required this.author,
    required this.rating,
    required this.durationLabel,
    required this.charsLabel,
    this.startDate,
    this.finishDate,
    required this.chaptersRead,
    required this.totalChapters,
    required this.progress,
  });

  final String bookName;
  final String author;
  final double rating;
  final String durationLabel;
  final String charsLabel;
  final String? startDate;
  final String? finishDate;
  final int chaptersRead;
  final int totalChapters;
  final double progress;
}

/// Application boundary for bookplate data assembly.
abstract interface class BookplateOverlayPort {
  BookplateData? build({
    required Book book,
    required int currentChapterIndex,
    required int totalChapters,
  });
}

/// Keep the existing display semantics for missing dates.
String formatBookplateDateLabel(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '—';
  return isoDate;
}

/// Used before the composition root provides the annotation adapter.
final class UnavailableBookplateOverlayPort implements BookplateOverlayPort {
  const UnavailableBookplateOverlayPort();

  @override
  BookplateData? build({
    required Book book,
    required int currentChapterIndex,
    required int totalChapters,
  }) => null;
}
