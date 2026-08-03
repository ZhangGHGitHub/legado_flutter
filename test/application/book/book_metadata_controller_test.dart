import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_metadata_controller.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';

final class _RecordingBookRepository implements BookRepository {
  (String, String)? updatedCover;
  (String, String, String, String)? updatedDetails;
  Object? error;

  @override
  Future<void> updateCover(String bookId, String coverUrl) async {
    if (error case final error?) throw error;
    updatedCover = (bookId, coverUrl);
  }

  @override
  Future<void> updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) async {
    if (error case final error?) throw error;
    updatedDetails = (bookId, name, author, description);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  test('基础信息去除首尾空白后执行字段级写入', () async {
    final repository = _RecordingBookRepository();
    final controller = BookMetadataController(repository: repository);

    final details = await controller.updateBookDetails(
      bookId: 'book-1',
      fallbackName: ' 原书名 ',
      name: ' 新书名 ',
      author: ' 新作者 ',
      description: ' 新简介 ',
    );

    expect(details, (name: '新书名', author: '新作者', description: '新简介'));
    expect(repository.updatedDetails, ('book-1', '新书名', '新作者', '新简介'));
  });

  test('空书名回退到去除首尾空白后的当前书名', () async {
    final repository = _RecordingBookRepository();
    final controller = BookMetadataController(repository: repository);

    final details = await controller.updateBookDetails(
      bookId: 'book-1',
      fallbackName: ' 当前书名 ',
      name: '   ',
      author: ' 作者 ',
      description: ' 简介 ',
    );

    expect(details.name, '当前书名');
    expect(repository.updatedDetails, ('book-1', '当前书名', '作者', '简介'));
  });

  test('基础信息仓储异常原样传播', () async {
    final error = StateError('基础信息写入失败');
    final repository = _RecordingBookRepository()..error = error;
    final controller = BookMetadataController(repository: repository);

    await expectLater(
      controller.updateBookDetails(
        bookId: 'book-1',
        fallbackName: '当前书名',
        name: '新书名',
        author: '新作者',
        description: '新简介',
      ),
      throwsA(same(error)),
    );

    expect(repository.updatedDetails, isNull);
  });
}
