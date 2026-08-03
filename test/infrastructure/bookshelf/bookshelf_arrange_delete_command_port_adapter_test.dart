import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/bookshelf/bookshelf_arrange_delete_command_port_adapter.dart';

void main() {
  test('单本删除只委托一次并原样传递 ID', () async {
    final calls = <String>[];
    final adapter = BookshelfArrangeDeleteCommandPortAdapter(
      removeBook: (bookId) async => calls.add(bookId),
      removeBooks: (_) async {},
    );

    await adapter.removeBook('one');

    expect(calls, ['one']);
  });

  test('批量删除固化输入并保持顺序和重复 ID', () async {
    final ids = <String>['two', 'one', 'two'];
    final calls = <List<String>>[];
    final adapter = BookshelfArrangeDeleteCommandPortAdapter(
      removeBook: (_) async {},
      removeBooks: (bookIds) async {
        calls.add(List<String>.of(bookIds));
        ids.clear();
      },
    );

    await adapter.removeBooks(ids);

    expect(calls, [
      ['two', 'one', 'two'],
    ]);
  });

  test('单本与批量底层异常均原样传播', () async {
    final singleError = StateError('单本删除失败');
    final batchError = StateError('批量删除失败');
    final adapter = BookshelfArrangeDeleteCommandPortAdapter(
      removeBook: (_) async => throw singleError,
      removeBooks: (_) async => throw batchError,
    );

    await expectLater(adapter.removeBook('one'), throwsA(same(singleError)));
    await expectLater(
      adapter.removeBooks(['one', 'two']),
      throwsA(same(batchError)),
    );
  });
}
