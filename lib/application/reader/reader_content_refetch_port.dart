import '../../domain/book/book.dart';
import '../../domain/book/chapter.dart';

/// 正文编辑页重新获取原始章节内容的应用层边界。
abstract interface class ReaderContentRefetchPort {
  Future<String> fetchRawContent({
    required Book book,
    required Chapter chapter,
  });
}
