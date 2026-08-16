import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/import_url_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ImportUrlHistoryStore', () {
    test('load returns empty list when unset', () async {
      expect(await ImportUrlHistoryStore.load(), isEmpty);
    });

    test('add prepends trimmed url and dedupes', () async {
      await ImportUrlHistoryStore.add('https://a.com');
      await ImportUrlHistoryStore.add('  https://b.com  ');
      await ImportUrlHistoryStore.add('https://a.com');

      expect(await ImportUrlHistoryStore.load(), [
        'https://a.com',
        'https://b.com',
      ]);
    });

    test('add ignores empty url', () async {
      await ImportUrlHistoryStore.add('   ');
      expect(await ImportUrlHistoryStore.load(), isEmpty);
    });

    test('add keeps at most maxEntries', () async {
      for (var i = 0; i < ImportUrlHistoryStore.maxEntries + 5; i++) {
        await ImportUrlHistoryStore.add('https://example.com/$i');
      }

      final list = await ImportUrlHistoryStore.load();
      expect(list.length, ImportUrlHistoryStore.maxEntries);
      expect(list.first, 'https://example.com/${ImportUrlHistoryStore.maxEntries + 4}');
      expect(list.last, 'https://example.com/5');
    });

    test('remove deletes url', () async {
      await ImportUrlHistoryStore.add('https://a.com');
      await ImportUrlHistoryStore.add('https://b.com');
      await ImportUrlHistoryStore.remove('https://a.com');

      expect(await ImportUrlHistoryStore.load(), ['https://b.com']);
    });

    test('clear removes all entries', () async {
      await ImportUrlHistoryStore.add('https://a.com');
      await ImportUrlHistoryStore.clear();

      expect(await ImportUrlHistoryStore.load(), isEmpty);
    });
  });
}
