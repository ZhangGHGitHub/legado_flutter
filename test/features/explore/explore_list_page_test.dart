import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/source_management/source_management_book_source_port.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_explore_port.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/explore/explore_list_page.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import '../../helpers/book_source_service_test_factory.dart';

void main() {
  testWidgets('探索列表使用共享 SourceController 的当前书源并映射结果', (tester) async {
    final source = BookSource(
      bookSourceUrl: 'https://source.example/explore',
      bookSourceName: '当前发现源',
    );
    final sourceProvider = SourceProvider(
      repository: _SourceRepository([source]),
      validationPort: const _ValidationPort(),
      sourceService: const _SourceService(),
    );
    await sourceProvider.loadSources();

    final explorePort = _ExplorePort();
    final bookProvider = BookProvider(
      repository: BookDao(),
      sourceService: createTestBookSourceService(),
      contentCache: const FileChapterContentCache(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
            ChangeNotifierProvider<BookProvider>.value(value: bookProvider),
            Provider<BookSourceExplorePort>.value(value: explorePort),
          ],
          child: ExploreListPage(
            source: source,
            exploreUrl: 'https://source.example/explore/category',
            title: '玄幻',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(explorePort.sources, [source]);
    expect(find.text('当前发现源'), findsOneWidget);
    expect(find.text('探索结果书'), findsOneWidget);
  });
}

final class _ExplorePort implements BookSourceExplorePort {
  final sources = <BookSource>[];

  @override
  Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async {
    sources.add(source);
    return const [
      {
        'id': 'explore-1',
        'name': '探索结果书',
        'author': '探索作者',
        'url': 'https://source.example/book/explore-1',
      },
    ];
  }
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
