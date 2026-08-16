import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_management/source_controller.dart';
import 'package:legado_flutter/application/source_management/source_management_book_source_port.dart';
import 'package:legado_flutter/application/source_management/source_state.dart';
import 'package:legado_flutter/application/source_rules/check_source_prefs_port.dart';
import 'package:legado_flutter/application/source_validation/source_validation_store_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';

void main() {
  group('SourceController 状态契约', () {
    test('loadSources 发布可观察且不可变的 sources 和 validationResults 快照', () async {
      final source = _source('https://source.example/one', '源一');
      final validation = _validationSnapshot(searchTimeMs: 12);
      final repository = _FakeBookSourceRepository([source]);
      final validationStore = _FakeValidationStore(
        values: {source.bookSourceUrl: validation},
      );
      final controller = _newController(
        repository: repository,
        validationStorePort: validationStore,
      );
      final published = <SourceState>[];
      controller.addListener(published.add);

      await controller.loadSources();

      expect(published, isNotEmpty);
      final state = published.last;
      expect(state.sources, [source]);
      expect(state.validationResults[source.bookSourceUrl], validation);
      expect(
        () => state.sources.add(_source('https://source.example/two', '源二')),
        throwsUnsupportedError,
      );
      expect(
        () => state.validationResults[source.bookSourceUrl] = validation,
        throwsUnsupportedError,
      );

      repository.sources.add(_source('https://source.example/three', '源三'));
      expect(state.sources, [source]);
    });

    test('并发 loadSources 不允许旧结果覆盖后发请求', () async {
      final oldSource = _source('https://source.example/old', '旧结果');
      final newSource = _source('https://source.example/new', '新结果');
      final repository = _FakeBookSourceRepository();
      final oldResponse = Completer<List<BookSource>>();
      final newResponse = Completer<List<BookSource>>();
      repository.getAllResponses.addAll([
        oldResponse.future,
        newResponse.future,
      ]);
      final controller = _newController(repository: repository);

      final oldLoad = controller.loadSources();
      await _waitFor(() => repository.getAllCallCount == 1);
      final newLoad = controller.loadSources();
      await _waitFor(() => repository.getAllCallCount == 2);

      newResponse.complete([newSource]);
      await newLoad;
      oldResponse.complete([oldSource]);
      await oldLoad;

      expect(controller.state.sources, [newSource]);
      expect(controller.state.sources, isNot(contains(oldSource)));
    });

    test('并发 searchAll 不允许旧关键词结果污染新关键词', () async {
      final source = _source('https://source.example/search', '搜索源');
      final repository = _FakeBookSourceRepository([source]);
      final service = _FakeSourceService();
      final oldSearch = Completer<List<Map<String, String>>>();
      final newSearch = Completer<List<Map<String, String>>>();
      service.searchResponses['旧关键词'] = oldSearch.future;
      service.searchResponses['新关键词'] = newSearch.future;
      final controller = _newController(
        repository: repository,
        sourceService: service,
      );

      final oldRequest = controller.searchAll('旧关键词');
      await _waitFor(() => service.requestedKeywords.contains('旧关键词'));
      final newRequest = controller.searchAll('新关键词');
      await _waitFor(() => service.requestedKeywords.contains('新关键词'));

      newSearch.complete([
        {'id': 'new', 'name': '新关键词结果', 'author': '作者'},
      ]);
      await newRequest;
      oldSearch.complete([
        {'id': 'old', 'name': '旧关键词结果', 'author': '作者'},
      ]);
      await oldRequest;

      final results = controller.state.searchResults[source.bookSourceUrl];
      expect(results, isNotNull);
      expect(results, hasLength(1));
      expect(results!.single.name, '新关键词结果');
      expect(
        controller.state.searchResults.values.expand((books) => books),
        isNot(
          contains(isA<Book>().having((book) => book.name, 'name', '旧关键词结果')),
        ),
      );
    });

    test('validateSource 成功、失败、超时后完整复位校验状态', () async {
      final successSource = _source('https://source.example/success', '成功源');
      final failureSource = _source('https://source.example/failure', '失败源');
      final timeoutSource = _source('https://source.example/timeout', '超时源');
      final validationPort = _FakeValidationPort();
      final prefs = _FakeCheckSourcePrefs(timeoutSeconds: 1);
      final controller = _newController(
        repository: _FakeBookSourceRepository([
          successSource,
          failureSource,
          timeoutSource,
        ]),
        validationPort: validationPort,
        checkSourcePrefsPort: prefs,
      );

      validationPort.handler = (_, _) async =>
          _validationSnapshot(searchTimeMs: 0);
      final success = await controller.validateSource(
        successSource,
        keyword: '成功关键词',
      );
      expect(success, isNotNull);
      _expectValidationReset(controller);
      expect(controller.state.validationProgress, isEmpty);

      validationPort.handler = (_, _) async {
        throw StateError('校验失败');
      };
      final failure = await controller.validateSource(
        failureSource,
        keyword: '失败关键词',
      );
      expect(failure, isNull);
      _expectValidationReset(controller);
      expect(controller.state.validationProgress, isEmpty);

      prefs.timeoutSeconds = 0;
      validationPort.handler = (_, _) => Future.delayed(
        const Duration(milliseconds: 30),
        () => _validationSnapshot(searchTimeMs: 0),
      );
      final timeout = await controller.validateSource(
        timeoutSource,
        keyword: '超时关键词',
      );
      expect(timeout, isNull);
      _expectValidationReset(controller);
      expect(controller.state.validationProgress, isEmpty);
    });

    test('JSON 导入保留 Legado 书源规则并完成 CRUD 写入', () async {
      final repository = _FakeBookSourceRepository();
      final controller = _newController(repository: repository);
      final json = jsonEncode({
        'bookSources': [
          {
            'bookSourceUrl': 'https://source.example/json',
            'bookSourceName': 'JSON 书源',
            'bookSourceGroup': '测试,导入',
            'ruleSearch': {'bookList': r'$.data[*]', 'name': r'$.name'},
            'ruleToc': {'chapterList': r'$.chapters[*]'},
          },
        ],
      });

      expect(await controller.importSources(json), isTrue);

      expect(repository.sources, hasLength(1));
      final imported = controller.state.sources.single;
      expect(imported.bookSourceName, 'JSON 书源');
      expect(imported.bookSourceGroup, '测试,导入');
      expect(imported.ruleSearchList, r'$.data[*]');
      expect(imported.ruleTocChapterList, r'$.chapters[*]');
      expect(imported.rawSourceJson, contains('ruleSearch'));
    });
  });
}

void _expectValidationReset(SourceController controller) {
  expect(controller.state.isValidating, isFalse);
  expect(controller.state.validatingSourceUrl, isNull);
  expect(controller.state.validationProgress, isEmpty);
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100 && !predicate(); attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue, reason: '异步 fake 未在测试窗口内启动');
}

SourceController _newController({
  _FakeBookSourceRepository? repository,
  _FakeSourceService? sourceService,
  _FakeValidationPort? validationPort,
  _FakeCheckSourcePrefs? checkSourcePrefsPort,
  _FakeValidationStore? validationStorePort,
}) {
  return SourceController(
    repository: repository ?? _FakeBookSourceRepository(),
    validationPort: validationPort ?? _FakeValidationPort(),
    sourceService: sourceService ?? _FakeSourceService(),
    checkSourcePrefsPort: checkSourcePrefsPort,
    validationStorePort: validationStorePort,
  );
}

BookSourceRepository createRepositoryForNotifierTest() =>
    _FakeBookSourceRepository();

BookSourceValidationPort createValidationPortForNotifierTest() =>
    _FakeValidationPort();

SourceManagementBookSourcePort createSourceServiceForNotifierTest() =>
    _FakeSourceService();

BookSource _source(String url, String name) =>
    BookSource(bookSourceUrl: url, bookSourceName: name, enabled: true);

BookSourceValidationSnapshot _validationSnapshot({required int searchTimeMs}) =>
    BookSourceValidationSnapshot(
      searchOk: true,
      discoveryOk: true,
      tocOk: true,
      contentOk: true,
      searchTimeMs: searchTimeMs,
    );

final class _FakeBookSourceRepository implements BookSourceRepository {
  _FakeBookSourceRepository([Iterable<BookSource> initial = const []])
    : sources = List<BookSource>.of(initial);

  final List<BookSource> sources;
  final List<Future<List<BookSource>>> getAllResponses = [];
  int getAllCallCount = 0;

  @override
  Future<void> upsert(BookSource source) async {
    final index = sources.indexWhere(
      (item) => item.bookSourceUrl == source.bookSourceUrl,
    );
    if (index < 0) {
      sources.add(source);
    } else {
      sources[index] = source;
    }
  }

  @override
  Future<void> upsertAll(List<BookSource> values) async {
    for (final source in values) {
      await upsert(source);
    }
  }

  @override
  Future<void> update(BookSource source) => upsert(source);

  @override
  Future<List<BookSource>> getAll() {
    getAllCallCount++;
    if (getAllResponses.isNotEmpty) return getAllResponses.removeAt(0);
    return Future<List<BookSource>>.value(List<BookSource>.of(sources));
  }

  @override
  Future<List<BookSource>> getEnabled() async =>
      List<BookSource>.of(sources.where((source) => source.enabled));

  @override
  Future<void> toggle(String url, bool enabled) async {
    final index = sources.indexWhere((source) => source.bookSourceUrl == url);
    if (index >= 0) sources[index] = sources[index].copyWith(enabled: enabled);
  }

  @override
  Future<void> delete(String url) async {
    sources.removeWhere((source) => source.bookSourceUrl == url);
  }
}

final class _FakeSourceService implements SourceManagementBookSourcePort {
  final Map<String, Future<List<Map<String, String>>>> searchResponses = {};
  final List<String> requestedKeywords = [];
  List<BookSource> urlImportResult = const [];

  @override
  Future<List<BookSource>> fetchSourcesFromUrl(String url) async =>
      List<BookSource>.of(urlImportResult);

  @override
  Future<List<Map<String, String>>> search(BookSource source, String keyword) {
    requestedKeywords.add(keyword);
    return searchResponses[keyword] ?? Future.value(const []);
  }

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => results
      .map(
        (result) => Book(
          id: result['id'] ?? result['name'] ?? '',
          name: result['name'] ?? '',
          author: result['author'] ?? '未知作者',
          bookSourceUrl: sourceUrl,
        ),
      )
      .toList();
}

final class _FakeValidationPort implements BookSourceValidationPort {
  Future<BookSourceValidationSnapshot> Function(BookSource, String)? handler;

  @override
  bool get isAvailable => true;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  }) =>
      handler?.call(source, keyword) ??
      Future<BookSourceValidationSnapshot>.value(
        _validationSnapshot(searchTimeMs: 0),
      );
}

final class _FakeCheckSourcePrefs implements CheckSourcePrefsPort {
  _FakeCheckSourcePrefs({required this.timeoutSeconds});

  int timeoutSeconds;

  @override
  Future<int> timeoutSec() async => timeoutSeconds;

  @override
  Future<void> setTimeoutSec(int value) async => timeoutSeconds = value;

  @override
  Future<bool> checkSearch() async => true;

  @override
  Future<void> setCheckSearch(bool value) async {}

  @override
  Future<bool> checkDiscovery() async => true;

  @override
  Future<void> setCheckDiscovery(bool value) async {}

  @override
  Future<bool> checkToc() async => true;

  @override
  Future<void> setCheckToc(bool value) async {}

  @override
  Future<bool> checkContent() async => true;

  @override
  Future<void> setCheckContent(bool value) async {}

  @override
  Future<bool> showDebugMessage() async => false;

  @override
  Future<void> setShowDebugMessage(bool value) async {}

  @override
  Future<String> lastKeyword() async => '';

  @override
  Future<void> setLastKeyword(String value) async {}
}

final class _FakeValidationStore implements SourceValidationStorePort {
  _FakeValidationStore({Map<String, SourceValidationResult>? values})
    : values = Map<String, SourceValidationResult>.of(values ?? {});

  final Map<String, SourceValidationResult> values;

  @override
  Future<Map<String, SourceValidationResult>> load() async =>
      Map<String, SourceValidationResult>.of(values);

  @override
  Future<void> put(String sourceUrl, SourceValidationResult result) async {
    values[sourceUrl] = result;
  }

  @override
  Future<void> remove(String sourceUrl) async {
    values.remove(sourceUrl);
  }
}
