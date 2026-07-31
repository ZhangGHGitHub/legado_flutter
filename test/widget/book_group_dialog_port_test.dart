import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/book_group_management_port.dart';
import 'package:legado_flutter/domain/book/book_group.dart';
import 'package:legado_flutter/widgets/book_group_edit_dialog.dart';
import 'package:legado_flutter/widgets/book_group_manage_dialog.dart';
import 'package:legado_flutter/widgets/book_group_select_dialog.dart';

void main() {
  testWidgets('edit dialog creates a group through the injected port', (
    tester,
  ) async {
    final port = _FakeBookGroupManagementPort()
      ..nextId = 8
      ..nextOrder = 3;
    late BuildContext hostContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            hostContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final resultFuture = showBookGroupEditDialog(hostContext, port: port);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' 新分组 ');
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(result?.groupId, 8);
    expect(result?.groupName, '新分组');
    expect(result?.order, 4);
    expect(port.updated.single.groupName, '新分组');
  });

  testWidgets('manage dialog loads and updates through the injected port', (
    tester,
  ) async {
    final port = _FakeBookGroupManagementPort()
      ..groups = [const BookGroup(groupId: 1, groupName: '收藏', order: 1)];
    late BuildContext hostContext;

    await tester.pumpWidget(_host((context) => hostContext = context));
    final resultFuture = showBookGroupManageDialog(hostContext, port: port);
    await tester.pumpAndSettle();

    expect(find.text('收藏'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(port.updated.single.show, isFalse);
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    await resultFuture;
  });

  testWidgets('select dialog returns names from port-provided groups', (
    tester,
  ) async {
    final port = _FakeBookGroupManagementPort()
      ..selectGroups = [const BookGroup(groupId: 2, groupName: '待读', order: 1)];
    late BuildContext hostContext;

    await tester.pumpWidget(_host((context) => hostContext = context));
    final resultFuture = showBookGroupSelectDialog(hostContext, port: port);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    final result = await resultFuture;
    expect(result?.groupNames, ['待读']);
    expect(port.selectLoadCount, 1);
  });
}

Widget _host(ValueChanged<BuildContext> onBuild) {
  return MaterialApp(
    home: Builder(
      builder: (context) {
        onBuild(context);
        return const SizedBox.shrink();
      },
    ),
  );
}

final class _FakeBookGroupManagementPort implements BookGroupManagementPort {
  List<BookGroup> groups = const [];
  List<BookGroup> selectGroups = const [];
  final updated = <BookGroup>[];
  int nextId = 1;
  int nextOrder = 0;
  int selectLoadCount = 0;

  @override
  Future<bool> canAddGroup() async => true;

  @override
  Future<void> delete(BookGroup group) async {
    groups = groups.where((item) => item.groupId != group.groupId).toList();
  }

  @override
  Future<List<BookGroup>> load() async => List<BookGroup>.from(groups);

  @override
  Future<List<BookGroup>> loadSelectGroups() async {
    selectLoadCount++;
    return List<BookGroup>.from(selectGroups);
  }

  @override
  Future<int> maxOrder() async => nextOrder;

  @override
  Future<void> syncNamesFromBooks(Iterable<String> names) async {}

  @override
  Future<int> unusedId() async => nextId;

  @override
  Future<void> update(BookGroup group) async {
    updated.add(group);
    groups = [...groups.where((item) => item.groupId != group.groupId), group];
  }
}
