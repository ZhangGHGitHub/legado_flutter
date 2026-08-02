import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/search/search_history_port.dart';
import 'package:legado_flutter/application/source_management/source_management_book_source_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/search/search_page.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/widgets/book_list_tile.dart';

void main() {
  testWidgets('搜索页通过共享 SourceController 展示搜索结果', (tester) async {
    final source = BookSource(
      bookSourceUrl: 'https://source.example/search',
      bookSourceName: '测试书源',
    );
    final service = _SearchSourceService();
    final sourceProvider = SourceProvider(
      repository: _SourceRepository([source]),
      validationPort: const _ValidationPort(),
      sourceService: service,
    );
    await sourceProvider.loadSources();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
            Provider<SearchHistoryPort>.value(value: _SearchHistory()),
          ],
          child: const SearchPage(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '目标书');
    await tester.tap(find.widgetWithIcon(IconButton, Icons.search));
    await tester.pumpAndSettle();

    expect(service.keywords, ['目标书']);
    expect(find.byType(BookListTile), findsOneWidget);
    expect(find.text('测试书源 (1)'), findsOneWidget);
  });
}

final class _SearchHistory implements SearchHistoryPort {
  final values = <String>[];

  @override
  Future<void> add(String keyword) async => values.add(keyword);

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<List<String>> load() async => List<String>.of(values);

  @override
  Future<void> remove(String keyword) async => values.remove(keyword);
}

final class _SourceRepository implements BookSourceRepository {
  _SourceRepository(Iterable<BookSource> initial)
    : values = List<BookSource>.of(initial);

  final List<BookSource> values;

  @override
  Future<void> delete(String url) async {
    values.removeWhere((source) => source.bookSourceUrl == url);
  }

  @override
  Future<List<BookSource>> getAll() async => List<BookSource>.of(values);

  @override
  Future<List<BookSource>> getEnabled() async =>
      values.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {
    final index = values.indexWhere((source) => source.bookSourceUrl == url);
    if (index >= 0) values[index] = values[index].copyWith(enabled: enabled);
  }

  @override
  Future<void> update(BookSource source) => upsert(source);

  @override
  Future<void> upsert(BookSource source) async {
    final index = values.indexWhere(
      (item) => item.bookSourceUrl == source.bookSourceUrl,
    );
    if (index < 0) {
      values.add(source);
    } else {
      values[index] = source;
    }
  }

  @override
  Future<void> upsertAll(List<BookSource> sources) async {
    for (final source in sources) {
      await upsert(source);
    }
  }
}

final class _SearchSourceService implements SourceManagementBookSourcePort {
  final keywords = <String>[];

  @override
  Future<List<BookSource>> fetchSourcesFromUrl(String url) async => const [];

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    keywords.add(keyword);
    return [
      {
        'id': 'book-1',
        'name': keyword,
        'author': '测试作者',
        'url': 'https://source.example/book-1',
      },
    ];
  }

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => results
      .map(
        (result) => Book(
          id: result['id'] ?? '',
          name: result['name'] ?? '',
          author: result['author'] ?? '',
          sourceUrl: result['url'] ?? '',
          bookSourceUrl: sourceUrl,
        ),
      )
      .toList();
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
