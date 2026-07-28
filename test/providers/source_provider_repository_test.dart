import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBookSourceRepository implements BookSourceRepository {
  final List<BookSource> sources = [];

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SourceProvider uses the injected source repository', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = _FakeBookSourceRepository();
    final provider = SourceProvider(
      repository: repository,
      validationPort: FrbBookSourceValidationPort(),
    );
    final source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );

    await provider.loadSources();
    await provider.addSource(source);

    expect(provider.repository, same(repository));
    expect(provider.sources.single.bookSourceUrl, source.bookSourceUrl);
  });

  test(
    'SourceProvider imports built-in sources only when the repository is empty',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _FakeBookSourceRepository();
      var loadCount = 0;
      final builtIn = BookSource(
        bookSourceUrl: 'https://builtin.example',
        bookSourceName: '内置测试源',
      );
      final provider = SourceProvider(
        repository: repository,
        validationPort: FrbBookSourceValidationPort(),
        builtInSourcesLoader: () async {
          loadCount++;
          return [builtIn];
        },
      );

      await provider.ensureBuiltInSources();
      await provider.ensureBuiltInSources();

      expect(loadCount, 1);
      expect(repository.sources.single.bookSourceUrl, builtIn.bookSourceUrl);
    },
  );

  test(
    'SourceProvider skips built-in loading for a non-empty repository',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = _FakeBookSourceRepository();
      await repository.upsert(
        BookSource(
          bookSourceUrl: 'https://existing.example',
          bookSourceName: '已有源',
        ),
      );
      var invoked = false;
      final provider = SourceProvider(
        repository: repository,
        validationPort: FrbBookSourceValidationPort(),
        builtInSourcesLoader: () async {
          invoked = true;
          return const [];
        },
      );

      await provider.ensureBuiltInSources();

      expect(invoked, isFalse);
      expect(repository.sources, hasLength(1));
    },
  );

  test('SourceProvider propagates startup repository failures', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = SourceProvider(
      repository: _FailingBookSourceRepository(),
      validationPort: FrbBookSourceValidationPort(),
      builtInSourcesLoader: () async => const [],
    );

    await expectLater(
      provider.ensureBuiltInSources(),
      throwsA(isA<StateError>()),
    );
  });
}

class _FailingBookSourceRepository extends _FakeBookSourceRepository {
  @override
  Future<List<BookSource>> getAll() async {
    throw StateError('source repository unavailable');
  }
}
