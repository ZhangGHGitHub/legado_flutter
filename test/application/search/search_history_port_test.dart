import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/infrastructure/preferences/shared_preferences_search_history_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('保留搜索历史的 trim、去重和最多 20 条语义', () async {
    final adapter = const SharedPreferencesSearchHistoryAdapter();

    await adapter.add('  first  ');
    await adapter.add('second');
    await adapter.add(' first ');
    for (var i = 0; i < 20; i++) {
      await adapter.add('item-$i');
    }

    final history = await adapter.load();
    expect(history, hasLength(20));
    expect(history.first, 'item-19');
    expect(history, isNot(contains('second')));
    expect(history, isNot(contains('first')));
  });

  test('通过既有 SharedPreferences 键加载、删除和清空历史', () async {
    SharedPreferences.setMockInitialValues({
      'legado_search_history': ['third', 'second', 'first'],
    });
    final adapter = const SharedPreferencesSearchHistoryAdapter();

    expect(await adapter.load(), ['third', 'second', 'first']);
    await adapter.remove('second');
    expect(await adapter.load(), ['third', 'first']);
    await adapter.clear();
    expect(await adapter.load(), isEmpty);
  });
}
