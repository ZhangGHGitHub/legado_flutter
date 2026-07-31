import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/core_api.dart';
import 'package:legado_flutter/application/core_api_provider.dart';
import 'package:legado_flutter/application/mock_core_api.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/search_result_item.dart';

void main() {
  group('coreApiProvider', () {
    test('defaults to MockCoreApi for Rust-free UI development', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(coreApiProvider), isA<MockCoreApi>());
    });

    test('allows replacing the implementation through its Notifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final api = _TestCoreApi();

      container.read(coreApiNotifierProvider.notifier).replace(api);

      expect(container.read(coreApiProvider), same(api));
    });

    test('supports direct provider override for isolated consumers', () {
      final api = _TestCoreApi();
      final container = ProviderContainer(
        overrides: [coreApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      expect(container.read(coreApiProvider), same(api));
    });
  });
}

class _TestCoreApi implements CoreApi {
  @override
  Future<List<Book>> getBookshelf() async => const [];

  @override
  Future<List<SearchResultItem>> searchBooks({
    required String sourceUrl,
    required String keyword,
  }) async => const [];
}
