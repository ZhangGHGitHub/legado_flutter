import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/services/book_source_service.dart';

void main() {
  test('BookSourceService 仅走 Rust 引擎', () async {
    await LegadoEngineBridge.tryInit();
    final service = BookSourceService();
    final source = BookSource.fromJson({
      'bookSourceUrl': 'http://x.com',
      'searchUrl': '@js:java.ajax(...)',
    });

    if (!LegadoEngineBridge.isAvailable) {
      expect(
        () => service.search(source, 'test'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Rust'),
          ),
        ),
      );
      return;
    }

    expect(LegadoEngineBridge.isAvailable, isTrue);
    expect(LegadoEngineBridge.engineVersion(), isNotEmpty);
  });
}
