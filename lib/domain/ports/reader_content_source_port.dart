import 'package:legado_flutter/domain/source/book_source.dart';

/// 阅读会话获取原始章节正文所需的最小能力。
abstract interface class ReaderContentSourcePort {
  Future<String> getChapterContent(String url, {required BookSource source});
}

abstract interface class PaginatedReaderContentSourcePort {
  Future<String> getChapterContentWithNextChapter(
    String url, {
    required BookSource source,
    String? nextChapterUrl,
  });
}
