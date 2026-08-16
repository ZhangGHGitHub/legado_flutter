import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/application/book/book_metadata_port.dart';
import 'package:legado_flutter/application/reader/reader_source_access_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_search_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/features/book/change_cover_page.dart';

const _book = Book(
  id: 'book-1',
  name: '测试书',
  author: '作者：甲',
  sourceUrl: 'book-url',
);

BookSource _source(String name, {int order = 0, bool enabled = true}) =>
    BookSource(
      bookSourceUrl: 'https://$name.test',
      bookSourceName: name,
      enabled: enabled,
      customOrder: order,
      ruleSearchCoverUrl: 'cover',
    );

final class _SourceAccess implements ReaderSourceAccessPort {
  _SourceAccess(this.sources);

  final List<BookSource> sources;

  @override
  List<BookSource> get availableSources => sources;

  @override
  Future<Book?> autoChangeSource(
    Book book, {
    required List<BookSource> sources,
    int concurrency = 4,
  }) async => null;

  @override
  BookSource? sourceForBook(Book book) => null;
}

final class _SearchPort implements BookSourceSearchPort {
  final Map<String, Completer<List<Map<String, String>>>> pending = {};
  final List<String> calls = [];

  @override
  Future<List<Map<String, String>>> search(BookSource source, String keyword) {
    calls.add(source.bookSourceName);
    return pending.putIfAbsent(source.bookSourceName, Completer.new).future;
  }
}

final class _MetadataPort implements BookMetadataPort {
  String? coverUrl;
  Object? error;

  @override
  Future<Book> updateCover(Book book, String coverUrl) async {
    if (error case final error?) throw error;
    this.coverUrl = coverUrl;
    return book.copyWith(coverUrl: coverUrl);
  }

  @override
  Future<Book> updateCustomCover(Book book, String customCoverUrl) async {
    if (error case final error?) throw error;
    coverUrl = customCoverUrl;
    return book.copyWith(customCoverUrl: customCoverUrl);
  }

  @override
  Future<Book?> updateBookDetails(
    String bookId, {
    required String name,
    required String author,
    required String description,
  }) async => null;
}

void main() {
  testWidgets('shows default cover and exact source matches in source order', (
    tester,
  ) async {
    final search = _SearchPort();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeCoverPage(
          book: _book,
          metadataPort: _MetadataPort(),
          sourceAccessPort: _SourceAccess([
            _source('后源', order: 2),
            _source('前源', order: 1),
            _source('禁用源', enabled: false),
          ]),
          searchPort: search,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('默认封面'), findsOneWidget);
    expect(search.calls, ['前源', '后源']);
    search.pending['前源']!.complete([
      {'name': '测试书', 'author': '甲', 'coverUrl': 'https://cover/one'},
    ]);
    search.pending['后源']!.complete([
      {'name': '测试书', 'author': '乙', 'coverUrl': 'https://cover/wrong'},
      {'name': '其它书', 'author': '甲', 'coverUrl': 'https://cover/other'},
    ]);
    await tester.pumpAndSettle();

    expect(find.text('前源'), findsOneWidget);
    expect(find.text('后源'), findsNothing);
    expect(
      find.byKey(const ValueKey('cover:https://cover/one')),
      findsOneWidget,
    );
    expect(find.byTooltip('刷新'), findsOneWidget);
  });

  testWidgets('stops an active search and refreshes with a new generation', (
    tester,
  ) async {
    final search = _SearchPort();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeCoverPage(
          book: _book,
          metadataPort: _MetadataPort(),
          sourceAccessPort: _SourceAccess([_source('测试源')]),
          searchPort: search,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('停止'));
    await tester.pump();
    expect(find.byTooltip('刷新'), findsOneWidget);

    search.pending['测试源']!.complete(const []);
    await tester.tap(find.byTooltip('刷新'));
    await tester.pump();
    expect(search.calls, ['测试源', '测试源']);
  });

  testWidgets('persists a selected cover and returns the updated book', (
    tester,
  ) async {
    final search = _SearchPort();
    final metadata = _MetadataPort();
    Book? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.push<Book>(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeCoverPage(
                    book: _book,
                    metadataPort: metadata,
                    sourceAccessPort: _SourceAccess([_source('测试源')]),
                    searchPort: search,
                  ),
                ),
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    search.pending['测试源']!.complete([
      {'name': '测试书', 'author': '甲', 'coverUrl': 'https://cover/new'},
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cover:https://cover/new')));
    await tester.pumpAndSettle();

    expect(metadata.coverUrl, 'https://cover/new');
    expect(result?.coverUrl, isEmpty);
    expect(result?.customCoverUrl, 'https://cover/new');
  });

  testWidgets('keeps the page open when cover persistence fails', (
    tester,
  ) async {
    final metadata = _MetadataPort()..error = StateError('write failed');
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeCoverPage(
          book: _book,
          metadataPort: metadata,
          sourceAccessPort: _SourceAccess(const []),
          searchPort: _SearchPort(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cover:use_default_cover')));
    await tester.pump();

    expect(find.text('封面换源'), findsOneWidget);
    expect(find.textContaining('封面保存失败'), findsOneWidget);
  });
}
