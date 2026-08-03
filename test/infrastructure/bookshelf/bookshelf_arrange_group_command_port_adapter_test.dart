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
}
