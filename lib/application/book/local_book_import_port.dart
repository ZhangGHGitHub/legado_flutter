import '../../domain/book/book.dart';

/// 本地书籍导入的应用边界。
abstract interface class LocalBookImportPort {
  /// 通过平台文件选择器导入；用户取消或文件路径不可用时返回 null。
  Future<Book?> importFromFile();

  /// 从已有本地路径导入，供远程书籍下载等流程复用。
  Future<Book> importFromPath(String filePath, {String? displayName});
}

/// Application-only fallback for hosts that do not provide local import IO.
final class UnavailableLocalBookImportPort implements LocalBookImportPort {
  const UnavailableLocalBookImportPort();

  @override
  Future<Book?> importFromFile() => Future.error(StateError('本地书籍导入端口不可用'));

  @override
  Future<Book> importFromPath(String filePath, {String? displayName}) =>
      Future.error(StateError('本地书籍导入端口不可用'));
}

/// 可直接展示给用户的本地书籍导入错误。
final class LocalBookImportPortException implements Exception {
  const LocalBookImportPortException(this.message);

  final String message;

  @override
  String toString() => message;
}
