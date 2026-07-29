import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_group_prefs.dart';
import 'package:legado_flutter/models/book_group.dart';
import 'package:legado_flutter/services/book_group_store.dart';

void main() {
  late _FakeBookGroupPrefs prefs;

  setUp(() {
    prefs = _FakeBookGroupPrefs();
    BookGroupStore.configurePrefsPort(prefs);
  });

  tearDown(BookGroupStore.resetPrefsPort);

  test('requires an explicitly configured preferences port', () async {
    BookGroupStore.resetPrefsPort();

    await expectLater(BookGroupStore.load(), throwsA(isA<StateError>()));
  });

  test(
    'missing storage keeps defaults and persists the original JSON shape',
    () async {
      final groups = await BookGroupStore.load();

      expect(groups, hasLength(7));
      expect(groups.first.groupId, BookGroup.idAll);
      expect(prefs.values['book_groups_v1'], isNotNull);
      final encoded = jsonDecode(prefs.values['book_groups_v1']!) as List;
      expect(encoded.first, containsPair('groupId', BookGroup.idAll));
      expect(encoded.first, containsPair('groupName', '全部'));
    },
  );

  test(
    'loads JSON, restores missing system groups, and sorts by order',
    () async {
      prefs.values['book_groups_v1'] = jsonEncode([
        BookGroup(groupId: 8, groupName: '自定义', order: 5).toJson(),
        BookGroup(
          groupId: BookGroup.idAll,
          groupName: '全部',
          order: -10,
        ).toJson(),
      ]);

      final groups = await BookGroupStore.load();

      expect(groups.first.groupId, BookGroup.idAll);
      expect(groups.any((group) => group.groupId == 8), isTrue);
      expect(groups.where((group) => group.isSystem), hasLength(7));
      expect(
        groups.map((group) => group.order).toList(),
        orderedEquals(groups.map((group) => group.order).toList()..sort()),
      );
    },
  );

  test(
    'malformed JSON falls back without rewriting the stored value',
    () async {
      prefs.values['book_groups_v1'] = '{bad';

      final groups = await BookGroupStore.load();

      expect(groups, hasLength(7));
      expect(prefs.values['book_groups_v1'], '{bad');
    },
  );

  test(
    'writes sorted JSON through the injected port and propagates errors',
    () async {
      await BookGroupStore.saveAll([
        const BookGroup(groupId: 2, groupName: '后', order: 2),
        const BookGroup(groupId: 1, groupName: '前', order: 1),
      ]);
      final encoded = jsonDecode(prefs.values['book_groups_v1']!) as List;
      expect(encoded.map((item) => item['groupId']), [1, 2]);

      prefs.readError = StateError('read failed');
      BookGroupStore.resetPrefsPort();
      BookGroupStore.configurePrefsPort(prefs);
      await expectLater(BookGroupStore.load(), throwsA(isA<StateError>()));

      prefs.readError = null;
      prefs.writeError = StateError('write failed');
      await expectLater(
        BookGroupStore.saveAll([
          const BookGroup(groupId: 1, groupName: '写入测试', order: 1),
        ]),
        throwsA(isA<StateError>()),
      );
    },
  );
}

final class _FakeBookGroupPrefs implements BookGroupPrefsPort {
  final values = <String, String>{};
  Object? readError;
  Object? writeError;

  @override
  Future<String?> read(String key) {
    final error = readError;
    if (error != null) return Future<String?>.error(error);
    return Future.value(values[key]);
  }

  @override
  Future<bool> write(String key, String value) async {
    final error = writeError;
    if (error != null) throw error;
    values[key] = value;
    return true;
  }
}
