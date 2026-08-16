import '../../domain/repositories/book_repository.dart';

typedef NormalizedBookDetails = ({
  String name,
  String author,
  String description,
});

/// 书籍基础元数据的 application 写入边界。
final class BookMetadataController {
  BookMetadataController({required BookRepository repository})
    : _repository = repository;

  final BookRepository _repository;

  Future<void> updateCover(String bookId, String coverUrl) =>
      _repository.updateCover(bookId, coverUrl);

  Future<void> updateCustomCover(String bookId, String customCoverUrl) {
    final repository = _repository;
    if (repository is! BookCustomCoverRepository) {
      return Future<void>.error(UnsupportedError('自定义封面存储服务不可用'));
    }
    return (repository as BookCustomCoverRepository).updateCustomCover(
      bookId,
      customCoverUrl,
    );
  }

  Future<NormalizedBookDetails> updateBookDetails({
    required String bookId,
    required String fallbackName,
    required String name,
    required String author,
    required String description,
  }) async {
    final trimmedName = name.trim();
    final details = (
      name: trimmedName.isEmpty ? fallbackName.trim() : trimmedName,
      author: author.trim(),
      description: description.trim(),
    );
    await _repository.updateBookDetails(
      bookId,
      details.name,
      details.author,
      details.description,
    );
    return details;
  }
}
