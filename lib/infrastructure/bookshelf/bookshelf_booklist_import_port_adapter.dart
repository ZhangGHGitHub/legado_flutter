import '../../application/bookshelf/bookshelf_booklist_import_port.dart';
import '../../application/bookshelf/bookshelf_list_port.dart';
import '../../domain/source/book_source.dart';

/// 将现有 BookProvider 书单入库方法接入 application 端口。
final class BookshelfBooklistImportPortAdapter
    implements BookshelfBooklistImportPort {
  const BookshelfBooklistImportPortAdapter(this._importBookshelfEntries);

  final Future<({int added, int skipped, int failed})> Function(
    List<BookshelfListEntry> entries, {
    required List<BookSource> sources,
    BookshelfBooklistImportProgress? onProgress,
  })
  _importBookshelfEntries;

  @override
  Future<({int added, int skipped, int failed})> importBookshelfEntries(
    List<BookshelfListEntry> entries, {
    required List<BookSource> sources,
    BookshelfBooklistImportProgress? onProgress,
  }) => _importBookshelfEntries(
    entries,
    sources: sources,
    onProgress: onProgress,
  );
}
