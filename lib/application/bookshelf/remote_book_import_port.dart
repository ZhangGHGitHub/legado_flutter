import '../../domain/book/book.dart';

/// 远程书籍页访问本地书架和导入本地文件所需的应用端口。
abstract interface class RemoteBookImportPort {
  List<Book> get books;

  Future<Book?> importLocalBookFromPath(
    String path, {
    required String displayName,
  });
}

/// 独立远程页面宿主未提供书架导入能力时的空实现。
final class EmptyRemoteBookImportPort implements RemoteBookImportPort {
  const EmptyRemoteBookImportPort();

  @override
  List<Book> get books => const [];

  @override
  Future<Book?> importLocalBookFromPath(
    String path, {
    required String displayName,
  }) async => null;
}
