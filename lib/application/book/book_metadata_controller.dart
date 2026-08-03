import '../../domain/repositories/book_repository.dart';

/// 书籍基础元数据的 application 写入边界。
final class BookMetadataController {
  BookMetadataController({required BookRepository repository})
    : _repository = repository;

  final BookRepository _repository;

  Future<void> updateCover(String bookId, String coverUrl) =>
      _repository.updateCover(bookId, coverUrl);
}
