import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book_group.dart';
import 'package:legado_flutter/domain/ports/book_group_prefs.dart';
import 'package:legado_flutter/infrastructure/bookshelf/book_group_management_port_adapter.dart';
import 'package:legado_flutter/services/book_group_store.dart';

void main() {
  late _FakeBookGroupPrefs prefs;

  setUp(() {
    prefs = _FakeBookGroupPrefs();
    BookGroupStore.configurePrefsPort(prefs);
  });

  tearDown(BookGroupStore.resetPrefsPort);

  test('delegates group lifecycle while retaining store semantics', () async {
    prefs.values['book_groups_v1'] = jsonEncode([
      const BookGroup(groupId: 1, groupName: '已有', order: 4).toJson(),
      const BookGroup(
        groupId: BookGroup.idAll,
        groupName: '全部',
        order: -10,
      ).toJson(),
    ]);
    const port = BookGroupManagementPortAdapter();

    final loaded = await port.load();
    expect(loaded.first.groupId, BookGroup.idAll);
    expect(await port.unusedId(), 2);
    expect(await port.maxOrder(), 4);
    expect(await port.canAddGroup(), isTrue);

    const added = BookGroup(groupId: 2, groupName: '新增', order: 5);
    await port.update(added);
    await port.syncNamesFromBooks(['同步分组']);

    final selected = await port.loadSelectGroups();
    expect(selected.map((group) => group.groupName), ['已有', '新增', '同步分组']);

    await port.delete(added);
    final afterDelete = await port.load();
    expect(afterDelete.any((group) => group.groupId == added.groupId), isFalse);
  });
}

final class _FakeBookGroupPrefs implements BookGroupPrefsPort {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<bool> write(String key, String value) async {
    values[key] = value;
    return true;
  }
}
