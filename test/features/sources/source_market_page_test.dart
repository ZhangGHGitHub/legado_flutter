import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/application/source_market/source_market_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/sources/source_market_page.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:provider/provider.dart';

import '../../application/source_management/source_controller_test.dart'
    as source_fixtures;

void main() {
  testWidgets('全部导入等待批量写入完成后才返回', (tester) async {
    final source = BookSource(
      bookSourceUrl: 'https://market.example/source',
      bookSourceName: '市场书源',
    );
    final repository = _ControlledRepository();
    final sourceProvider = _createSourceProvider(repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
          Provider<SourceMarketPort>.value(
            value: _FakeSourceMarketPort([source]),
          ),
        ],
        child: riverpod.ProviderScope(
          overrides: [
            sourceControllerProvider.overrideWithValue(
              sourceProvider.controller,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (_) => const SourceMarketPage()),
                  ),
                  child: const Text('打开市场'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开市场'));
    await tester.pumpAndSettle();
    expect(find.text('市场书源'), findsOneWidget);

    await tester.tap(find.text('全部导入'));
    await tester.pump();
    await repository.writeStarted.future;

    expect(find.text('全部导入'), findsOneWidget);
    expect(find.text('已导入所有书源'), findsNothing);
    expect(sourceProvider.sources, isEmpty);

    repository.releaseWrites.complete();
    await tester.pumpAndSettle();

    expect(sourceProvider.sources, [source]);
    expect(find.text('打开市场'), findsOneWidget);
  });
}

SourceProvider _createSourceProvider(BookSourceRepository repository) {
  return SourceProvider(
    repository: repository,
    validationPort: source_fixtures.createValidationPortForNotifierTest(),
    sourceService: source_fixtures.createSourceServiceForNotifierTest(),
  );
}

final class _FakeSourceMarketPort implements SourceMarketPort {
  _FakeSourceMarketPort(this.sources);

  final List<BookSource> sources;

  @override
  Future<List<BookSource>> loadSources() async => sources;
}

final class _ControlledRepository implements BookSourceRepository {
  final sources = <BookSource>[];
  final writeStarted = Completer<void>();
  final releaseWrites = Completer<void>();

  @override
  Future<void> upsert(BookSource source) async {
    await upsertAll([source]);
  }

  @override
  Future<void> upsertAll(List<BookSource> values) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    await releaseWrites.future;
    for (final source in values) {
      sources.removeWhere((item) => item.bookSourceUrl == source.bookSourceUrl);
      sources.add(source);
    }
  }

  @override
  Future<void> update(BookSource source) => upsert(source);

  @override
  Future<List<BookSource>> getAll() async => List.unmodifiable(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {
    final source = sources.firstWhere((item) => item.bookSourceUrl == url);
    await upsert(source.copyWith(enabled: enabled));
  }

  @override
  Future<void> delete(String url) async {
    sources.removeWhere((source) => source.bookSourceUrl == url);
  }
}
