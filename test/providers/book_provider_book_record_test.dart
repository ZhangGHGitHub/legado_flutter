import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_change_port.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

final class _RecordBookRepository extends BookDao {
  _RecordBookRepository(Book book) : books = [book];

  final List<Book> books;
  bool failCoverWrite = false;
  final List<String> calls = [];

  @override
  Future<List<Book>> getAll() async {
    calls.add('getAll');
    return List<Book>.of(books);
  }

  @override
  Future<void> updateCover(String bookId, String coverUrl) async {
    calls.add('updateCover:$bookId:$coverUrl');
    if (failCoverWrite) throw StateError('封面写入失败');
    final index = books.indexWhere((book) => book.id == bookId);
    books[index] = books[index].copyWith(coverUrl: coverUrl);
  }
}

Book _latestBook() => Book(
  id: 'book-1',
  name: '旧书名',
  author: '旧作者',
  coverUrl: 'https://cover/current',
  progress: 0.75,
  currentChapter: '第九章',
  durChapterIndex: 8,
  currentPageIndex: 65537,
  sourceUrl: 'https://source/book-1',
  bookSourceUrl: 'https://source',
);

BookProvider _provider(
  _RecordBookRepository repository,
  BookshelfChangePort changes,
) => BookProvider(
  repository: repository,
  sourceService: TestBookSourceService(),
  contentCache: const FileChapterContentCache(),
  bookshelfChangePort: changes,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('封面更新使用最新书架记录并发布刷新后的快照', () async {
    final repository = _RecordBookRepository(_latestBook());
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);
    await provider.loadBooks(runMaintenance: false);
    repository.calls.clear();

    final updated = await provider.updateBookCover(
      const Book(id: 'book-1', name: '过期页面记录'),
      'https://cover/new',
    );

    expect(repository.calls, ['updateCover:book-1:https://cover/new']);
    expect(updated.coverUrl, 'https://cover/new');
    expect(updated.currentPageIndex, 65537);
    expect(updated.durChapterIndex, 8);
    expect(provider.books.single, same(updated));
    expect(changes.latest?.books.single, same(updated));
  });

  test('封面写入失败时不刷新列表也不发布新快照', () async {
    final repository = _RecordBookRepository(_latestBook());
    final changes = BookshelfChangeBus();
    final provider = _provider(repository, changes);
    addTearDown(changes.dispose);
    await provider.loadBooks(runMaintenance: false);
    final revision = changes.revision;
    repository
      ..calls.clear()
      ..failCoverWrite = true;

    await expectLater(
      provider.updateBookCover(_latestBook(), 'https://cover/failed'),
      throwsA(isA<StateError>()),
    );

    expect(repository.calls, ['updateCover:book-1:https://cover/failed']);
    expect(provider.books.single.coverUrl, 'https://cover/current');
    expect(changes.revision, revision);
  });
}
