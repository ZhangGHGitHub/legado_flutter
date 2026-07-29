import '../../domain/book/book.dart';
import '../../domain/ports/reading_record_port.dart';
import '../../domain/ports/web_api_data_port.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/book_source_repository.dart';

/// 使用现有领域仓储提供本地 Web API 的业务数据。
class RepositoryWebApiDataPort implements WebApiDataPort {
  const RepositoryWebApiDataPort({
    required BookRepository bookRepository,
    required BookSourceRepository sourceRepository,
    required ReadingRecordPort readingRecordPort,
    required bool Function() isDatabaseReady,
  }) : _bookRepository = bookRepository,
       _sourceRepository = sourceRepository,
       _readingRecordPort = readingRecordPort,
       _isDatabaseReady = isDatabaseReady;

  final BookRepository _bookRepository;
  final BookSourceRepository _sourceRepository;
  final ReadingRecordPort _readingRecordPort;
  final bool Function() _isDatabaseReady;

  @override
  bool get isAvailable => _isDatabaseReady() && _readingRecordPort.isAvailable;

  @override
  Future<List<Map<String, dynamic>>> listBooks() async {
    _requireAvailable();
    return (await _bookRepository.getAll())
        .map((book) => book.toJson())
        .toList(growable: false);
  }

  @override
  Future<void> addBook(Map<String, dynamic> book) async {
    _requireAvailable();
    final normalized = Map<String, dynamic>.from(book);
    if (normalized['name'] is! String) normalized['name'] = '未知';
    if (normalized['author'] is! String) normalized['author'] = '';
    if (normalized['group'] is! String) {
      normalized['group'] = normalized['bookGroup'] is String
          ? normalized['bookGroup']
          : '';
    }
    await _bookRepository.insert(Book.fromJson(normalized));
  }

  @override
  Future<void> deleteBook(String bookId) async {
    _requireAvailable();
    await _bookRepository.delete(bookId);
  }

  @override
  Future<List<Map<String, dynamic>>> listChapters(String bookId) async {
    _requireAvailable();
    return (await _bookRepository.getChapters(
      bookId,
    )).map((chapter) => chapter.toJson()).toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> listSources() async {
    _requireAvailable();
    return (await _sourceRepository.getAll())
        .map((source) => source.toJson())
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> readingStats() async {
    _requireAvailable();
    final stats = _readingRecordPort.getStats('month');
    if (stats == null) throw StateError('读取阅读统计失败');
    return {
      'totalChars': stats.totalChars,
      'totalDurationSeconds': stats.totalDurationSeconds,
      'todayChars': stats.todayChars,
      'todayDurationSeconds': stats.todayDurationSeconds,
      'weekChars': stats.weekChars,
      'daily': stats.daily
          .map(
            (item) => {
              'date': item.date,
              'chars': item.chars,
              'durationSeconds': item.durationSeconds,
            },
          )
          .toList(growable: false),
    };
  }

  void _requireAvailable() {
    if (!isAvailable) {
      throw const WebApiDataUnavailable('数据库未初始化');
    }
  }
}
