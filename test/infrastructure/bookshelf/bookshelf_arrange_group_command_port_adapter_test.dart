import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_arrange_group_command_port_adapter.dart';

void main() {
  test('单本命令只委托一次并返回不可变最新快照', () async {
    final calls = <String>[];
    var books = const [Book(id: 'one', name: '书一')];
    final adapter = BookshelfArrangeGroupCommandPortAdapter(
      updateBookGroup: (bookId, group) async {
        calls.add('$bookId:$group');
        books = [books.single.copyWith(group: group)];
      },
      updateBooksGroup: (_, _) async {},
      books: () => books,
    );

    final snapshot = await adapter.updateBookGroup('one', '目标分组');

    expect(calls, ['one:目标分组']);
    expect(snapshot.single.group, '目标分组');
    expect(
      () => snapshot.add(const Book(id: 'two', name: '书二')),
      throwsUnsupportedError,
    );
  });

  test('批量命令保持重复 ID 和输入顺序且只委托一次', () async {
    final calls = <List<String>>[];
    final adapter = BookshelfArrangeGroupCommandPortAdapter(
      updateBookGroup: (_, _) async {},
      updateBooksGroup: (bookIds, group) async {
        calls.add(List<String>.of(bookIds));
      },
      books: () => const [],
    );

    await adapter.updateBooksGroup(['two', 'one', 'two'], '目标分组');

    expect(calls, [
      ['two', 'one', 'two'],
    ]);
  });

  test('底层异常原样传播且不读取快照', () async {
    final error = StateError('分组写入失败');
    var booksReads = 0;
    final adapter = BookshelfArrangeGroupCommandPortAdapter(
      updateBookGroup: (_, _) async => throw error,
      updateBooksGroup: (_, _) async {},
      books: () {
        booksReads++;
        return const [];
      },
    );

    await expectLater(
      adapter.updateBookGroup('one', '目标分组'),
      throwsA(same(error)),
    );
    expect(booksReads, 0);
  });

  test('批量底层异常原样传播且不读取快照', () async {
    final error = StateError('批量分组写入失败');
    var booksReads = 0;
    final adapter = BookshelfArrangeGroupCommandPortAdapter(
      updateBookGroup: (_, _) async {},
      updateBooksGroup: (_, _) async => throw error,
      books: () {
        booksReads++;
        return const [];
      },
    );

    await expectLater(
      adapter.updateBooksGroup(['one', 'two'], '目标分组'),
      throwsA(same(error)),
    );
    expect(booksReads, 0);
  });

  test('移除分组固化输入并按最新快照精确匹配，成功返回不可变最终快照', () async {
    final ids = <String>['one', 'missing', 'two', 'three'];
    final events = <String>[];
    var books = const [
      Book(id: 'one', name: '书一', group: '目标分组'),
      Book(id: 'two', name: '书二', group: '目标分组 '),
      Book(id: 'three', name: '书三', group: '目标分组'),
    ];
    final adapter = BookshelfArrangeGroupCommandPortAdapter(
      updateBookGroup: (bookId, group) async {
        events.add('update:$bookId:$group');
        books = [
          for (final book in books)
            if (book.id == bookId) book.copyWith(group: group) else book,
        ];
        if (bookId == 'one') {
          ids
            ..clear()
            ..add('unexpected');
        }
      },
      updateBooksGroup: (_, _) async {},
      books: () {
        events.add('read');
        return books;
      },
    );

    final snapshot = await adapter.clearBooksGroup(
      ids,
      onlyWhenGroupEquals: '目标分组',
    );

    expect(events, [
      'read',
      'update:one:',
      'read',
      'read',
      'read',
      'update:three:',
      'read',
    ]);
    expect(snapshot.map((book) => (book.id, book.group)), [
      ('one', ''),
      ('two', '目标分组 '),
      ('three', ''),
    ]);
    expect(
      () => snapshot.add(const Book(id: 'four', name: '书四')),
      throwsUnsupportedError,
    );
  });

  test('移除分组的空条件通配所有现存书籍', () async {
    final calls = <String>[];
    var books = const [
      Book(id: 'one', name: '书一', group: '分组甲'),
      Book(id: 'two', name: '书二', group: '分组乙'),
    ];
    final adapter = BookshelfArrangeGroupCommandPortAdapter(
      updateBookGroup: (bookId, group) async {
        calls.add('$bookId:$group');
        books = [
          for (final book in books)
            if (book.id == bookId) book.copyWith(group: group) else book,
        ];
      },
      updateBooksGroup: (_, _) async {},
      books: () => books,
    );

    final snapshot = await adapter.clearBooksGroup(['two', 'one']);

    expect(calls, ['two:', 'one:']);
    expect(snapshot.every((book) => book.group.isEmpty), isTrue);
  });

  test('移除分组第二项失败时保留首项效果并停止且不读取最终快照', () async {
    final error = StateError('第二项移除失败');
    final calls = <String>[];
    var booksReads = 0;
    var books = const [
      Book(id: 'one', name: '书一', group: '目标分组'),
      Book(id: 'two', name: '书二', group: '目标分组'),
      Book(id: 'three', name: '书三', group: '目标分组'),
    ];
    final adapter = BookshelfArrangeGroupCommandPortAdapter(
      updateBookGroup: (bookId, group) async {
        calls.add('$bookId:$group');
        if (bookId == 'two') throw error;
        books = [
          for (final book in books)
            if (book.id == bookId) book.copyWith(group: group) else book,
        ];
      },
      updateBooksGroup: (_, _) async {},
      books: () {
        booksReads++;
        return books;
      },
    );

    await expectLater(
      adapter.clearBooksGroup([
        'one',
        'two',
        'three',
      ], onlyWhenGroupEquals: '目标分组'),
      throwsA(same(error)),
    );

    expect(calls, ['one:', 'two:']);
    expect(booksReads, 2);
    expect(books.singleWhere((book) => book.id == 'one').group, isEmpty);
    expect(books.singleWhere((book) => book.id == 'two').group, '目标分组');
    expect(books.singleWhere((book) => book.id == 'three').group, '目标分组');
  });
}
