import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

void main() {
  test('publishes a change after a successful bookshelf write', () async {
    final repository = _RecordingBookDao();
    final changes = BookshelfChangeBus();
    final provider = BookProvider(
      repository: repository,
      sourceService: TestBookSourceService(),
      contentCache: const FileChapterContentCache(),
      bookshelfChangePort: changes,
    );
    addTearDown(changes.dispose);

    await provider.updateBookGroup('book-1', '新分组');

    expect(changes.revision, 1);
    expect(repository.updatedGroup, ('book-1', '新分组'));
  });

  test('does not publish when the bookshelf write fails', () async {
    final repository = _RecordingBookDao(throwOnUpdate: true);
    final changes = BookshelfChangeBus();
    final provider = BookProvider(
      repository: repository,
      sourceService: TestBookSourceService(),
      contentCache: const FileChapterContentCache(),
      bookshelfChangePort: changes,
    );
    addTearDown(changes.dispose);

    await expectLater(
      provider.updateBookGroup('book-1', '新分组'),
      throwsA(isA<StateError>()),
    );

    expect(changes.revision, 0);
  });
}

class _RecordingBookDao extends BookDao {
  _RecordingBookDao({this.throwOnUpdate = false});

  final bool throwOnUpdate;
  (String, String)? updatedGroup;

  @override
  Future<void> updateGroup(String bookId, String group) async {
    if (throwOnUpdate) throw StateError('write failed');
    updatedGroup = (bookId, group);
  }

  @override
  Future<List<Book>> getAll() async => const [];

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];
}
