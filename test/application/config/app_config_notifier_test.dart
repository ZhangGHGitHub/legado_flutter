import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/config/app_config_notifier.dart';
import 'package:legado_flutter/application/config/app_config_state.dart';
import 'package:legado_flutter/application/preferences/shared_preferences_runtime.dart';
import 'package:legado_flutter/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform interface is only used to simulate a failed persistence call;
// adding a production dependency for this test-only seam is out of scope.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesRuntime.resetForTest();
    AppConfig.resetForTest();
  });

  tearDown(() {
    AppConfig.resetForTest();
    SharedPreferencesRuntime.resetForTest();
    SharedPreferences.setMockInitialValues({});
  });

  test('loads all application fields through the Riverpod notifier', () async {
    SharedPreferences.setMockInitialValues({
      'app_config_show_discovery': false,
      'app_config_show_rss': false,
      'app_config_default_home': 'rss',
      'app_config_sync_book_progress': false,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appConfigNotifierProvider.notifier);

    expect(
      container.read(appConfigNotifierProvider).loadStatus,
      AppConfigLoadStatus.initial,
    );
    await notifier.load();

    final state = container.read(appConfigNotifierProvider);
    expect(state.loadStatus, AppConfigLoadStatus.loaded);
    expect(state.showDiscovery, isFalse);
    expect(state.showRSS, isFalse);
    expect(state.defaultHomePage, 'rss');
    expect(state.syncBookProgress, isFalse);
  });

  test('publishes optimistic writes and preserves the four setters', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appConfigNotifierProvider.notifier);
    await notifier.load();

    await notifier.setShowDiscovery(false);
    await notifier.setShowRSS(false);
    await notifier.setDefaultHomePage('explore');
    await notifier.setSyncBookProgress(false);

    var state = container.read(appConfigNotifierProvider);
    expect(state.showDiscovery, isFalse);
    expect(state.showRSS, isFalse);
    expect(state.defaultHomePage, 'explore');
    expect(state.syncBookProgress, isFalse);

    await notifier.setDefaultHomePage('unsupported');
    state = container.read(appConfigNotifierProvider);
    expect(state.defaultHomePage, 'bookshelf');
  });

  test(
    'deduplicates concurrent loads at the existing runtime boundary',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final pending = Completer<SharedPreferences>();
      var loaderCalls = 0;
      SharedPreferencesRuntime.setLoaderForTest(() {
        loaderCalls++;
        return pending.future;
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appConfigNotifierProvider.notifier);

      final first = notifier.load();
      final second = notifier.load();
      expect(loaderCalls, 1);
      expect(
        container.read(appConfigNotifierProvider).loadStatus,
        AppConfigLoadStatus.loading,
      );

      pending.complete(prefs);
      await Future.wait([first, second]);

      expect(loaderCalls, 1);
      expect(
        container.read(appConfigNotifierProvider).loadStatus,
        AppConfigLoadStatus.loaded,
      );
    },
  );

  test(
    'treats runtime initialization failure as loaded in-memory defaults',
    () async {
      SharedPreferencesRuntime.setLoaderForTest(() async {
        throw StateError('platform unavailable');
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appConfigNotifierProvider.notifier);

      await notifier.load();

      final state = container.read(appConfigNotifierProvider);
      expect(state.loadStatus, AppConfigLoadStatus.loaded);
      expect(state.loadError, isNull);
      expect(state.showDiscovery, isTrue);
      expect(
        SharedPreferencesRuntime.state,
        SharedPreferencesRuntimeState.failed,
      );
    },
  );

  test(
    'publishes load failure and keeps AppConfig retryable after bad data',
    () async {
      SharedPreferences.setMockInitialValues({
        'app_config_show_rss': 'not-a-bool',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(appConfigNotifierProvider.notifier);

      await expectLater(notifier.load(), throwsA(isA<TypeError>()));
      var state = container.read(appConfigNotifierProvider);
      expect(state.loadStatus, AppConfigLoadStatus.failure);
      expect(state.loadError, isA<TypeError>());
      expect(AppConfig.instance.isLoaded, isFalse);

      SharedPreferences.setMockInitialValues({});
      SharedPreferencesRuntime.resetForTest();
      await notifier.load();
      state = container.read(appConfigNotifierProvider);
      expect(state.loadStatus, AppConfigLoadStatus.loaded);
      expect(state.loadError, isNull);
    },
  );

  test('keeps optimistic state when persistence fails', () async {
    SharedPreferencesStorePlatform.instance = _FailingPreferencesStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appConfigNotifierProvider.notifier);
    await notifier.load();

    final write = notifier.setShowDiscovery(false);
    expect(container.read(appConfigNotifierProvider).showDiscovery, isFalse);
    await expectLater(write, throwsA(isA<StateError>()));
    expect(container.read(appConfigNotifierProvider).showDiscovery, isFalse);
  });
}

final class _FailingPreferencesStore extends InMemorySharedPreferencesStore {
  _FailingPreferencesStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    throw StateError('preference write failed');
  }
}
