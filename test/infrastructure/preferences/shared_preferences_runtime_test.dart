import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_book_group_prefs.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_book_progress_sync_store.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_code_edit_prefs_store.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferencesRuntime.resetForTest();
  });

  tearDown(() {
    SharedPreferencesRuntime.resetForTest();
  });

  test('coalesces concurrent initialization into one ready state', () async {
    SharedPreferences.setMockInitialValues({'answer': 42});
    var calls = 0;
    final futures = [
      SharedPreferencesRuntime.load(
        loader: () async {
          calls++;
          await Future<void>.delayed(Duration.zero);
          return SharedPreferences.getInstance();
        },
      ),
      SharedPreferencesRuntime.load(),
    ];

    final values = await Future.wait(futures);

    expect(calls, 1);
    expect(values[0]?.getInt('answer'), 42);
    expect(values[1]?.getInt('answer'), 42);
    expect(SharedPreferencesRuntime.state, SharedPreferencesRuntimeState.ready);
  });

  test(
    'failed initialization returns null and exposes a retryable state',
    () async {
      var attempts = 0;
      SharedPreferencesRuntime.setLoaderForTest(() async {
        attempts++;
        throw StateError('platform unavailable');
      });

      expect(await SharedPreferencesRuntime.getOrNull(), isNull);
      expect(
        SharedPreferencesRuntime.state,
        SharedPreferencesRuntimeState.failed,
      );
      expect(SharedPreferencesRuntime.error, isA<StateError>());

      SharedPreferences.setMockInitialValues({'recovered': true});
      SharedPreferencesRuntime.setLoaderForTest(SharedPreferences.getInstance);
      final recovered = await SharedPreferencesRuntime.getOrNull();

      expect(recovered?.getBool('recovered'), isTrue);
      expect(attempts, 1);
      expect(SharedPreferencesRuntime.isReady, isTrue);
    },
  );

  test(
    'startup preference adapters degrade to safe empty operations',
    () async {
      SharedPreferencesRuntime.setLoaderForTest(() async {
        throw StateError('platform unavailable');
      });

      final groups = await SharedPreferencesBookGroupPrefs.load();
      final progress = await SharedPreferencesBookProgressSyncStore.load();
      final editor = await SharedPreferencesCodeEditPrefsStore.load();

      expect(await groups.read('missing'), isNull);
      expect(await groups.write('key', 'value'), isFalse);
      expect(await progress.read('missing'), isNull);
      await progress.write('key', 1);
      expect(editor.getInt('missing'), isNull);
      expect(await editor.setBool('key', true), isFalse);
    },
  );
}
