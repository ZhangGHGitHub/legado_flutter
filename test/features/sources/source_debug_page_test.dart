import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_debug_port.dart';
import 'package:legado_flutter/features/sources/source_debug_page.dart';
import 'package:legado_flutter/models/book_source.dart';

void main() {
  final source = BookSource(
    bookSourceUrl: 'https://source.example',
    bookSourceName: '测试书源',
  );

  testWidgets('search debug uses the injected domain port', (tester) async {
    final port = _FakeDebugPort();
    await tester.binding.setSurfaceSize(const Size(720, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SourceDebugPage(source: source, debugPort: port),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '关键字');
    await tester.tap(find.text('测试搜索'));
    await tester.pumpAndSettle();

    expect(port.searchKeyword, '关键字');
    expect(port.searchSource, source);
    expect(find.textContaining('测试书籍'), findsAtLeastNWidgets(1));
  });

  testWidgets('unavailable engine does not issue a debug request', (
    tester,
  ) async {
    final port = _FakeDebugPort(isAvailable: false);
    await tester.binding.setSurfaceSize(const Size(720, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SourceDebugPage(source: source, debugPort: port),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '关键字');
    await tester.tap(find.text('测试搜索'));
    await tester.pump();

    expect(port.searchKeyword, isNull);
    expect(find.textContaining('Rust 引擎不可用'), findsOneWidget);
  });

  testWidgets('debug failure is rendered as a page log', (tester) async {
    final port = _FakeDebugPort(searchError: StateError('fixture failure'));
    await tester.binding.setSurfaceSize(const Size(720, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SourceDebugPage(source: source, debugPort: port),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '关键字');
    await tester.tap(find.text('测试搜索'));
    await tester.pumpAndSettle();

    expect(find.textContaining('搜索出错'), findsOneWidget);
    expect(find.textContaining('fixture failure'), findsOneWidget);
  });
}

class _FakeDebugPort implements BookSourceDebugPort {
  _FakeDebugPort({this.isAvailable = true, this.searchError});

  @override
  final bool isAvailable;
  final Object? searchError;
  String? searchKeyword;
  BookSource? searchSource;

  @override
  Future<BookSourceDebugSnapshot> debugSearch(
    BookSource source,
    String keyword,
  ) async {
    searchSource = source;
    searchKeyword = keyword;
    if (searchError != null) throw searchError!;
    return _snapshot();
  }

  @override
  Future<BookSourceDebugSnapshot> debugToc(
    BookSource source,
    String bookUrl,
  ) async => _snapshot();

  @override
  Future<String> httpFetch(
    String url, {
    String method = 'GET',
    String? referer,
    String charset = 'UTF-8',
    BookSource? source,
  }) async => 'fixture response';

  BookSourceDebugSnapshot _snapshot() => const BookSourceDebugSnapshot(
    requestUrl: 'https://source.example/search',
    requestMethod: 'GET',
    responseStatus: '200',
    responseCharset: 'UTF-8',
    responseSize: 42,
    responseBodyPreview: 'fixture body',
    ruleSteps: [
      BookSourceDebugStep(
        step: '搜索',
        rule: 'ruleSearch',
        result: 'ok',
        ok: true,
      ),
    ],
    results: [
      BookSourceDebugItem(
        name: '测试书籍',
        author: '作者',
        coverUrl: '',
        bookUrl: 'https://source.example/book',
        kind: 'search',
        note: '',
      ),
    ],
  );
}
