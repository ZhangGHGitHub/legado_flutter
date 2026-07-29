import '../../models/book_source.dart';

/// 阅读会话获取原始章节正文所需的最小能力。
abstract interface class ReaderContentSourcePort {
  Future<String> getChapterContent(String url, {required BookSource source});
}
