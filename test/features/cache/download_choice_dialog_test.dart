import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/download_choice_prefs_port.dart';
import 'package:legado_flutter/features/cache/download_choice_dialog.dart';
import 'package:legado_flutter/infrastructure/preferences/shared_preferences_download_choice_prefs.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'SharedPreferences adapter preserves keys, defaults, and clamps',
    () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesDownloadChoicePrefs.concurrencyKey: 99,
        SharedPreferencesDownloadChoicePrefs.nextNKey: 0,
      });
      final prefs = await SharedPreferences.getInstance();
      final adapter = SharedPreferencesDownloadChoicePrefs(prefs);

      final loaded = await adapter.load();

      expect(loaded.concurrency, 8);
      expect(loaded.nextN, 1);
      expect(await adapter.save(concurrency: 0, nextN: 10000), isTrue);
      expect(prefs.getInt('download_choice_concurrency'), 1);
      expect(prefs.getInt('download_choice_next_n'), 9999);
    },
  );

  testWidgets('dialog keeps loading until the preference port resolves', (
    tester,
  ) async {
    final loadCompleter = Completer<DownloadChoicePrefs>();
    final port = _FakeDownloadChoicePrefsPort(loadFuture: loadCompleter.future);

    await tester.pumpWidget(
      _withPort(
        port,
        const DownloadChoiceDialog(currentChapterIndex: 0, totalChapters: 10),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '下载'))
          .onPressed,
      isNull,
    );

    loadCompleter.complete(
      const DownloadChoicePrefs(concurrency: 4, nextN: 12),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('12'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 4);
  });

  testWidgets('dialog saves through the preference port before closing', (
    tester,
  ) async {
    final port = _FakeDownloadChoicePrefsPort(
      loaded: const DownloadChoicePrefs(concurrency: 3, nextN: 5),
    );

    await tester.pumpWidget(
      _withPort(
        port,
        const DownloadChoiceDialog(currentChapterIndex: 1, totalChapters: 10),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '下载'));
    await tester.pumpAndSettle();

    expect(port.savedConcurrency, 3);
    expect(port.savedNextN, 5);
    expect(find.byType(DownloadChoiceDialog), findsNothing);
  });
}

Widget _withPort(DownloadChoicePrefsPort port, Widget child) {
  return MaterialApp(
    home: Provider<DownloadChoicePrefsPort>.value(value: port, child: child),
  );
}

final class _FakeDownloadChoicePrefsPort implements DownloadChoicePrefsPort {
  _FakeDownloadChoicePrefsPort({
    this.loaded = const DownloadChoicePrefs(concurrency: 1, nextN: 50),
    Future<DownloadChoicePrefs>? loadFuture,
  }) : _loadFuture = loadFuture;

  final DownloadChoicePrefs loaded;
  final Future<DownloadChoicePrefs>? _loadFuture;
  int? savedConcurrency;
  int? savedNextN;

  @override
  Future<DownloadChoicePrefs> load() => _loadFuture ?? Future.value(loaded);

  @override
  Future<bool> save({required int concurrency, required int nextN}) async {
    savedConcurrency = concurrency;
    savedNextN = nextN;
    return true;
  }
}
