import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_bookshelf_display_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();
  });

  tearDown(SharedPreferencesRuntime.resetForTest);

  test(
    'loads and saves bookshelf display preferences with legacy keys',
    () async {
      SharedPreferences.setMockInitialValues({
        'shelf_show_grouped': true,
        'shelf_pinned_ids': ['book-1', 'book-2'],
      });
      SharedPreferencesRuntime.resetForTest();
      final adapter = await SharedPreferencesBookshelfDisplayPrefs.create();

      final loaded = await adapter.load();
      expect(loaded.showGrouped, isTrue);
      expect(loaded.pinnedIds, {'book-1', 'book-2'});

      expect(await adapter.saveGrouped(false), isTrue);
      expect(await adapter.savePinned(['book-3']), isTrue);
      final saved = await adapter.load();
      expect(saved.showGrouped, isFalse);
      expect(saved.pinnedIds, {'book-3'});
    },
  );

  test('degrades to defaults when preference storage is unavailable', () async {
    SharedPreferencesRuntime.setLoaderForTest(() async {
      throw StateError('platform unavailable');
    });
    final adapter = await SharedPreferencesBookshelfDisplayPrefs.create();

    final loaded = await adapter.load();
    expect(loaded.showGrouped, isFalse);
    expect(loaded.pinnedIds, isEmpty);
    expect(await adapter.saveGrouped(true), isFalse);
    expect(await adapter.savePinned(['book-1']), isFalse);
  });
}
