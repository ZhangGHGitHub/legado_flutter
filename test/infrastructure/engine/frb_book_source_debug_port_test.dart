import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_debug_port.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_debug_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

void main() {
  test('debug port exposes a replaceable pure Dart contract', () {
    final port = _FakeDebugPort();
    expect(port, isA<BookSourceDebugPort>());
    expect(port.isAvailable, isTrue);
  });

  test('FRB adapter reports unavailable engine before invoking bridge', () {
    final port = FrbBookSourceDebugPort();
    if (port.isAvailable) return;

    expect(
      () => port.debugSearch(_source(), 'keyword'),
      throwsA(isA<StateError>()),
    );
  });
}

class _FakeDebugPort implements BookSourceDebugPort {
  @override
  bool get isAvailable => true;

  @override
  Future<BookSourceDebugSnapshot> debugSearch(
    BookSource source,
    String keyword,
  ) async => _snapshot();

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
  }) async => 'body';
}

BookSource _source() =>
    BookSource(bookSourceUrl: 'https://example.com', bookSourceName: 'test');

BookSourceDebugSnapshot _snapshot() => const BookSourceDebugSnapshot(
  requestUrl: '',
  requestMethod: 'GET',
  responseStatus: '',
  responseCharset: '',
  responseSize: 0,
  responseBodyPreview: '',
  ruleSteps: [],
  results: [],
);
