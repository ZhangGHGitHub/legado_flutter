import '../book_reading_stats.dart';

abstract interface class BookplatePort {
  bool get isAvailable;

  BookReadingStats? loadBookStats(String bookId);
}
