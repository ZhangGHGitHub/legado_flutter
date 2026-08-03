import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import '../helpers/book_source_service_test_factory.dart';

class _GroupBookRepository extends BookDao {
  _GroupBookRepository(Iterable<Book> initialBooks)
    : books = List<Book>.from(initialBooks);

  final List<Book> books;
  final List<String> updateCalls = [];
  final Set<String> failingBookIds = {};
  int getAllCalls = 0;

  @override
  Future<List<Book>> getAll() async {
    getAllCalls++;
    return List<Book>.from(books);
  }

  @override
  Future<void> updateGroup(String bookId, String group) async {
    updateCalls.add('$bookId:$group');
    if (failingBookIds.contains(bookId)) {
      throw StateError('拒绝更新 $bookId');
    }
    final index = books.indexWhere((book) => book.id == bookId);
    if (index < 0) {
      throw StateError('书籍不存在 $bookId');
    }
    books[index] = books[index].copyWith(group: group);
  }
}

Book _book(String id, {String group = ''}) =>
    Book(id: id, name: '书籍$id', group: group);

BookProvider _createProvider(_GroupBookRepository repository) => BookProvider(
  repository: repository,
  sourceService: TestBookSourceService(),
  contentCache: const FileChapterContentCache(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('单本分组更新后刷新书架列表并只通知一次', () async {
    final repository = _GroupBookRepository([
      _book('one'),
      _book('two', group: '旧分组'),
    ]);
    final provider = _createProvider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.updateBookGroup('one', '新分组');

    expect(repository.updateCalls, ['one:新分组']);
    expect(repository.getAllCalls, 2);
    expect(provider.books.map((book) => '${book.id}:${book.group}'), [
      'one:新分组',
      'two:旧分组',
    ]);
    expect(notifications, 1);
  });

  test('批量分组更新按输入顺序写入并保持刷新列表顺序', () async {
    final repository = _GroupBookRepository([
      _book('one'),
      _book('two'),
      _book('three'),
    ]);
    final provider = _createProvider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.updateBooksGroup(['three', 'one', 'two'], '目标分组');

    expect(repository.updateCalls, ['three:目标分组', 'one:目标分组', 'two:目标分组']);
    expect(provider.books.map((book) => '${book.id}:${book.group}'), [
      'one:目标分组',
      'two:目标分组',
      'three:目标分组',
    ]);
    expect(notifications, 1);
  });

  test('空批量输入不写入仓储但仍完成一次列表刷新和通知', () async {
    final repository = _GroupBookRepository([_book('one', group: '原分组')]);
    final provider = _createProvider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.updateBooksGroup(const <String>[], '不会写入');

    expect(repository.updateCalls, isEmpty);
    expect(repository.getAllCalls, 2);
    expect(provider.books.single.group, '原分组');
    expect(notifications, 1);
  });

  test('仓储更新失败原样传播且不刷新列表或通知', () async {
    final repository = _GroupBookRepository([_book('one')])
      ..failingBookIds.add('one');
    final provider = _createProvider(repository);
    await provider.loadBooks(runMaintenance: false);
    var notifications = 0;
    provider.addListener(() => notifications++);

    await expectLater(
      provider.updateBookGroup('one', '失败分组'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          '拒绝更新 one',
        ),
      ),
    );

    expect(repository.updateCalls, ['one:失败分组']);
    expect(repository.getAllCalls, 1);
    expect(provider.books.single.group, isEmpty);
    expect(notifications, 0);
  });
}
