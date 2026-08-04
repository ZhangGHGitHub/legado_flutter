import '../../domain/source/book_source.dart';
import 'bookshelf_list_port.dart';

typedef BookshelfBooklistImportProgress =
    void Function(int index, int total, String status);

/// 书单条目解析后的书架入库能力。
abstract interface class BookshelfBooklistImportPort {
  Future<({int added, int skipped, int failed})> importBookshelfEntries(
    List<BookshelfListEntry> entries, {
    required List<BookSource> sources,
    BookshelfBooklistImportProgress? onProgress,
  });
}
