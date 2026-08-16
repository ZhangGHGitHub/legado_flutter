import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_rules/check_source_prefs_port.dart';
import 'package:legado_flutter/application/source_validation/source_validation_store_port.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';
import 'package:legado_flutter/providers/source_provider.dart';

import '../helpers/book_source_service_test_factory.dart';

final class _FakeBookSourceRepository implements BookSourceRepository {
  _FakeBookSourceRepository(Iterable<BookSource> sources)
    : sources = sources.toList();

  final List<BookSource> sources;

  @override
  Future<void> delete(String url) async {
    sources.removeWhere((source) => source.bookSourceUrl == url);
  }

  @override
  Future<List<BookSource>> getAll() async => List.unmodifiable(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {
    final source = sources.firstWhere((item) => item.bookSourceUrl == url);
    await update(source.copyWith(enabled: enabled));
  }

  @override
  Future<void> update(BookSource source) => upsert(source);

  @override
  Future<void> upsert(BookSource source) async {
    sources.removeWhere((item) => item.bookSourceUrl == source.bookSourceUrl);
    sources.add(source);
  }

  @override
  Future<void> upsertAll(List<BookSource> values) async {
    for (final source in values) {
      await upsert(source);
    }
  }
}

final class _FakeSourceValidationStorePort
    implements SourceValidationStorePort {
  _FakeSourceValidationStorePort({
    Map<String, SourceValidationResult>? initial,
    this.putError,
  }) : values = {...?initial};

  final Map<String, SourceValidationResult> values;
  final Object? putError;
  final putUrls = <String>[];
  final removedUrls = <String>[];
  int loadCount = 0;

  @override
  Future<Map<String, SourceValidationResult>> load() async {
    loadCount++;
    return Map.of(values);
  }

  @override
  Future<void> put(String sourceUrl, SourceValidationResult result) async {
    putUrls.add(sourceUrl);
    if (putError != null) throw putError!;
    values[sourceUrl] = result;
  }

  @override
  Future<void> remove(String sourceUrl) async {
    removedUrls.add(sourceUrl);
    values.remove(sourceUrl);
  }
}

final class _FakeValidationPort implements BookSourceValidationPort {
  _FakeValidationPort({this.error, this.neverCompletes = false});

  final Object? error;
  final bool neverCompletes;

  @override
  bool get isAvailable => true;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  }) async {
    if (error != null) throw error!;
    if (neverCompletes) return Completer<BookSourceValidationSnapshot>().future;
    return const BookSourceValidationSnapshot(
      searchOk: true,
      discoveryOk: true,
      tocOk: true,
      contentOk: true,
      searchTimeMs: 0,
    );
  }
}

final class _FakeCheckSourcePrefsPort implements CheckSourcePrefsPort {
  const _FakeCheckSourcePrefsPort({this.timeoutSecValue = 5});

  final int timeoutSecValue;

  @override
  Future<bool> checkContent() async => true;

  @override
  Future<bool> checkDiscovery() async => true;

  @override
  Future<bool> checkSearch() async => true;

  @override
  Future<bool> checkToc() async => true;

  @override
  Future<String> lastKeyword() async => '';

  @override
  Future<void> setCheckContent(bool value) async {}

  @override
  Future<void> setCheckDiscovery(bool value) async {}

  @override
  Future<void> setCheckSearch(bool value) async {}

  @override
  Future<void> setCheckToc(bool value) async {}

  @override
  Future<void> setLastKeyword(String value) async {}

  @override
  Future<void> setShowDebugMessage(bool value) async {}

  @override
  Future<void> setTimeoutSec(int value) async {}

  @override
  Future<bool> showDebugMessage() async => false;

  @override
  Future<int> timeoutSec() async => timeoutSecValue;
}

void main() {
  const firstUrl = 'https://one.example';
  const secondUrl = 'https://two.example';
  final firstSource = BookSource(
    bookSourceUrl: firstUrl,
    bookSourceName: '一号源',
  );
  final secondSource = BookSource(
    bookSourceUrl: secondUrl,
    bookSourceName: '二号源',
  );
  const cached = SourceValidationResult(
    searchOk: true,
    discoveryOk: false,
    tocOk: true,
    contentOk: false,
    searchTimeMs: 123,
    errors: ['cached'],
  );

  SourceProvider createProvider({
    required _FakeBookSourceRepository repository,
    required _FakeSourceValidationStorePort store,
    _FakeValidationPort? validation,
    int timeoutSec = 5,
  }) {
    return SourceProvider(
      repository: repository,
      validationPort: validation ?? _FakeValidationPort(),
      sourceService: createTestBookSourceService(),
      checkSourcePrefsPort: _FakeCheckSourcePrefsPort(
        timeoutSecValue: timeoutSec,
      ),
      validationStorePort: store,
    );
  }

  test(
    'loadSources restores validation results from the injected store',
    () async {
      final store = _FakeSourceValidationStorePort(initial: {firstUrl: cached});
      final provider = createProvider(
        repository: _FakeBookSourceRepository([firstSource]),
        store: store,
      );

      await provider.loadSources();

      expect(store.loadCount, 1);
      expect(provider.validationOf(firstUrl)?.errors, cached.errors);
    },
  );

  test(
    'successful validation writes the exact source URL to the store',
    () async {
      final store = _FakeSourceValidationStorePort();
      final provider = createProvider(
        repository: _FakeBookSourceRepository([firstSource]),
        store: store,
      );

      final result = await provider.validateSource(firstSource, keyword: '测试');

      expect(result, isNotNull);
      expect(store.putUrls, [firstUrl]);
      expect(store.values[firstUrl], same(result));
    },
  );

  test(
    'single and batch deletion remove matching validation entries',
    () async {
      final store = _FakeSourceValidationStorePort(
        initial: {firstUrl: cached, secondUrl: cached},
      );
      final provider = createProvider(
        repository: _FakeBookSourceRepository([firstSource, secondSource]),
        store: store,
      );
      await provider.loadSources();

      await provider.deleteSource(firstUrl);
      await provider.deleteSources([secondUrl]);

      expect(store.removedUrls, [firstUrl, secondUrl]);
      expect(provider.validationOf(firstUrl), isNull);
      expect(provider.validationOf(secondUrl), isNull);
    },
  );

  test('validation exception does not write to the store', () async {
    final store = _FakeSourceValidationStorePort();
    final provider = createProvider(
      repository: _FakeBookSourceRepository([firstSource]),
      store: store,
      validation: _FakeValidationPort(error: StateError('engine failed')),
    );

    final result = await provider.validateSource(firstSource, keyword: '测试');

    expect(result, isNull);
    expect(store.putUrls, isEmpty);
  });

  test('validation timeout does not write to the store', () async {
    final store = _FakeSourceValidationStorePort();
    final provider = createProvider(
      repository: _FakeBookSourceRepository([firstSource]),
      store: store,
      validation: _FakeValidationPort(neverCompletes: true),
      timeoutSec: 0,
    );

    final result = await provider.validateSource(firstSource, keyword: '测试');

    expect(result, isNull);
    expect(store.putUrls, isEmpty);
  });

  test(
    'persistence failure keeps the successful in-memory result but returns null',
    () async {
      final store = _FakeSourceValidationStorePort(
        putError: StateError('persistence failed'),
      );
      final provider = createProvider(
        repository: _FakeBookSourceRepository([firstSource]),
        store: store,
      );

      final result = await provider.validateSource(firstSource, keyword: '测试');

      expect(result, isNull);
      expect(store.putUrls, [firstUrl]);
      expect(provider.validationOf(firstUrl), isNotNull);
    },
  );
}
