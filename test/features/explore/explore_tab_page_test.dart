import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/source_management/source_management_book_source_port.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/explore/explore_tab_page.dart';
import 'package:legado_flutter/providers/source_provider.dart';

void main() {
  testWidgets('发现页从共享 SourceController 读取可发现书源', (tester) async {
    final source = BookSource(
      bookSourceUrl: 'https://source.example/explore',
      bookSourceName: '发现书源',
      rawSourceJson: jsonEncode({
        'exploreUrl': jsonEncode([
          {'title': '玄幻', 'url': 'https://source.example/explore/xuanhuan'},
        ]),
      }),
    );
    final sourceProvider = SourceProvider(
      repository: _SourceRepository([source]),
      validationPort: const _ValidationPort(),
      sourceService: const _SourceService(),
    );
    await sourceProvider.loadSources();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
          ],
          child: riverpod.ProviderScope(
            overrides: [
              sourceControllerProvider.overrideWithValue(
                sourceProvider.controller,
              ),
            ],
            child: const ExploreTabPage(),
          ),
        ),
      ),
    );

    expect(find.text('发现书源'), findsOneWidget);
    expect(find.text('玄幻'), findsOneWidget);
  });
}

final class _SourceRepository implements BookSourceRepository {
  _SourceRepository(Iterable<BookSource> initial)
    : values = List<BookSource>.of(initial);

  final List<BookSource> values;

  @override
  Future<void> delete(String url) async {}

  @override
  Future<List<BookSource>> getAll() async => List<BookSource>.of(values);

  @override
  Future<List<BookSource>> getEnabled() async =>
      values.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {}

  @override
  Future<void> update(BookSource source) async {}

  @override
  Future<void> upsert(BookSource source) async {}

  @override
  Future<void> upsertAll(List<BookSource> sources) async {}
}

final class _SourceService implements SourceManagementBookSourcePort {
  const _SourceService();

  @override
  Future<List<BookSource>> fetchSourcesFromUrl(String url) async => const [];

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async => const [];

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => const [];
}

final class _ValidationPort implements BookSourceValidationPort {
  const _ValidationPort();

  @override
  bool get isAvailable => false;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  }) => throw UnsupportedError('validation is not used in this test');
}
