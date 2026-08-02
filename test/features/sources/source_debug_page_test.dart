import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/application/sources/source_debug_formatter_port.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/ports/book_source_debug_port.dart';
import 'package:legado_flutter/features/sources/source_debug_page.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:provider/provider.dart';

import '../../application/source_management/source_controller_test.dart'
    as source_fixtures;

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
        home: _withDependencies(
          SourceDebugPage(source: source, debugPort: port),
        ),
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
        home: _withDependencies(
          SourceDebugPage(source: source, debugPort: port),
        ),
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
        home: _withDependencies(
          SourceDebugPage(source: source, debugPort: port),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '关键字');
    await tester.tap(find.text('测试搜索'));
    await tester.pumpAndSettle();

    expect(find.textContaining('搜索出错'), findsOneWidget);
    expect(find.textContaining('fixture failure'), findsOneWidget);
  });

  testWidgets('一键校验通过共享 SourceNotifier 转发关键词并展示结果', (tester) async {
    final debugPort = _FakeDebugPort();
    final validationPort = _FakeValidationPort();
    final sourceProvider = SourceProvider(
      repository: source_fixtures.createRepositoryForNotifierTest(),
      validationPort: validationPort,
      sourceService: source_fixtures.createSourceServiceForNotifierTest(),
    );
    await tester.binding.setSurfaceSize(const Size(720, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: _withDependencies(
          SourceDebugPage(source: source, debugPort: debugPort),
          sourceProvider: sourceProvider,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '校验关键词');
    await tester.tap(find.byTooltip('一键校验'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(validationPort.calls, 1);
    expect(validationPort.source, source);
    expect(validationPort.keyword, '校验关键词');
    expect(find.text('校验通过'), findsOneWidget);
  });
}

Widget _withDependencies(Widget child, {SourceProvider? sourceProvider}) {
  final provider =
      sourceProvider ??
      SourceProvider(
        repository: source_fixtures.createRepositoryForNotifierTest(),
        validationPort: source_fixtures.createValidationPortForNotifierTest(),
        sourceService: source_fixtures.createSourceServiceForNotifierTest(),
      );
  return riverpod.ProviderScope(
    overrides: [
      sourceControllerProvider.overrideWithValue(provider.controller),
    ],
    child: _withFormatter(child),
  );
}

Widget _withFormatter(Widget child) {
  return Provider<SourceDebugFormatterPort>.value(
    value: _FakeFormatter(),
    child: child,
  );
}

class _FakeValidationPort implements BookSourceValidationPort {
  int calls = 0;
  BookSource? source;
  String? keyword;

  @override
  bool get isAvailable => true;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  }) async {
    calls++;
    this.source = source;
    this.keyword = keyword;
    return const BookSourceValidationSnapshot(
      searchOk: true,
      discoveryOk: true,
      tocOk: true,
      contentOk: true,
      searchTimeMs: 0,
    );
  }
}

class _FakeFormatter implements SourceDebugFormatterPort {
  @override
  String format(BookSourceDebugSnapshot snapshot) {
    return 'formatted ${snapshot.results.first.name}';
  }
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
