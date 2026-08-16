import '../../domain/book/book.dart';
import '../../domain/repositories/book_repository.dart';

/// 书架书籍分组写入的 application 控制器。
///
/// 该控制器暂不承载书架状态，也不替换 [BookProvider]。它只复用现有
/// [BookRepository] 的顺序和异常语义，为后续生产接入提供单一写入边界。
final class BookshelfBookGroupController {
  BookshelfBookGroupController({required BookRepository repository})
    : _repository = repository;

  final BookRepository _repository;

  /// 更新一本书的分组，并返回 repository 刷新后的书架列表。
  Future<List<Book>> updateBookGroup(String bookId, String group) async {
    await _repository.updateGroup(bookId, group);
    return _repository.getAll();
  }

  /// 按 [bookIds] 的迭代顺序逐本更新分组，并返回刷新后的书架列表。
  ///
  /// 空输入仍会执行一次 [BookRepository.getAll]，与现有兼容入口一致。
  Future<List<Book>> updateBooksGroup(
    Iterable<String> bookIds,
    String group,
  ) async {
    for (final bookId in bookIds) {
      await _repository.updateGroup(bookId, group);
    }
    return _repository.getAll();
  }
}
