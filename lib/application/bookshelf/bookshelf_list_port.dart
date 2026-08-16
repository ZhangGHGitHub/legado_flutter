import '../../domain/book/book.dart';
import '../../domain/ports/public_text_fetch_port.dart';

/// 书架书单导入/导出所需的应用层能力。
///
/// 页面不直接依赖文件选择器、书单 JSON 解析或旧版 BookshelfListIo。
typedef BookshelfListEntry = ({String name, String author, String intro});

abstract interface class BookshelfListPort {
  Future<String?> exportBooks(List<Book> books);

  Future<String?> pickFileText();

  Future<String> resolveInput(
    String input, {
    required PublicTextFetchPort fetchPort,
  });

  List<BookshelfListEntry> parseEntries(String text);
}
