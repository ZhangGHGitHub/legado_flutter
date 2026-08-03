import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_metadata_controller.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';

final class _RecordingBookRepository extends BookDao {
  (String, String)? updatedCover;
  Object? error;

  @override
  Future<void> updateCover(String bookId, String coverUrl) async {
    if (error case final error?) throw error;
    updatedCover = (bookId, coverUrl);
  }
}

void main() {
  test('封面参数原样委托给仓储字段级写入', () async {
    final repository = _RecordingBookRepository();
    final controller = BookMetadataController(repository: repository);

    await controller.updateCover('book-1', 'https://cover/new');

    expect(repository.updatedCover, ('book-1', 'https://cover/new'));
  });

  test('封面仓储异常原样传播', () async {
    final error = StateError('封面写入失败');
    final repository = _RecordingBookRepository()..error = error;
    final controller = BookMetadataController(repository: repository);

    await expectLater(
      controller.updateCover('book-1', 'https://cover/new'),
      throwsA(same(error)),
    );

    expect(repository.updatedCover, isNull);
  });
}
