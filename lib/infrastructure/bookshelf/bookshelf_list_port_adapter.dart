import '../../application/bookshelf/bookshelf_list_port.dart';
import '../../domain/book/book.dart';
import '../../domain/ports/public_text_fetch_port.dart';
import '../../services/bookshelf_list_io.dart' as legacy;

/// 书架书单端口的旧实现适配器。
///
/// 文件选择、JSON 兼容字段、URL 获取和导出格式均继续由既有实现负责，
/// 避免迁移边界时改变书单行为。
final class BookshelfListPortAdapter implements BookshelfListPort {
  const BookshelfListPortAdapter();

  @override
  Future<String?> exportBooks(List<Book> books) =>
      legacy.BookshelfListIo.exportBooks(books);

  @override
  Future<String?> pickFileText() => legacy.BookshelfListIo.pickFileText();

  @override
  Future<String> resolveInput(
    String input, {
    required PublicTextFetchPort fetchPort,
  }) => legacy.BookshelfListIo.resolveInput(input, fetchPort: fetchPort);

  @override
  List<BookshelfListEntry> parseEntries(String text) =>
      legacy.BookshelfListIo.parseEntries(text);
}
