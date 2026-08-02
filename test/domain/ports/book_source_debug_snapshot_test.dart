import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_debug_port.dart';

void main() {
  group('BookSourceDebugSnapshot Freezed contract', () {
    test('preserves the complete debug result shape', () {
      const step = BookSourceDebugStep(
        step: 'search',
        rule: '.book',
        result: 'matched',
        ok: true,
      );
      const item = BookSourceDebugItem(
        name: 'Book',
        author: 'Author',
        coverUrl: 'https://example.com/cover.png',
        bookUrl: 'https://example.com/book',
        kind: 'novel',
        note: 'available',
      );
      const snapshot = BookSourceDebugSnapshot(
        requestUrl: 'https://example.com/search?q=keyword',
        requestMethod: 'GET',
        responseStatus: '200 OK',
        responseCharset: 'UTF-8',
        responseSize: 128,
        responseBodyPreview: '<html>preview</html>',
        ruleSteps: [step],
        results: [item],
      );

      expect(snapshot.requestUrl, 'https://example.com/search?q=keyword');
      expect(snapshot.requestMethod, 'GET');
      expect(snapshot.responseStatus, '200 OK');
      expect(snapshot.responseCharset, 'UTF-8');
      expect(snapshot.responseSize, 128);
      expect(snapshot.responseBodyPreview, '<html>preview</html>');
      expect(snapshot.ruleSteps.single, equals(step));
      expect(snapshot.results.single, equals(item));
    });

    test('provides value equality and copyWith for nested debug results', () {
      const first = BookSourceDebugSnapshot(
        requestUrl: 'https://example.com',
        requestMethod: 'POST',
        responseStatus: '500',
        responseCharset: 'GBK',
        responseSize: 0,
        responseBodyPreview: 'error',
        ruleSteps: [
          BookSourceDebugStep(
            step: 'toc',
            rule: '.chapter',
            result: 'failed',
            ok: false,
          ),
        ],
        results: [],
      );
      const second = BookSourceDebugSnapshot(
        requestUrl: 'https://example.com',
        requestMethod: 'POST',
        responseStatus: '500',
        responseCharset: 'GBK',
        responseSize: 0,
        responseBodyPreview: 'error',
        ruleSteps: [
          BookSourceDebugStep(
            step: 'toc',
            rule: '.chapter',
            result: 'failed',
            ok: false,
          ),
        ],
        results: [],
      );

      expect(first, equals(second));
      expect(first.copyWith(responseStatus: '200 OK').responseStatus, '200 OK');
      expect(
        first
            .copyWith(
              ruleSteps: [
                const BookSourceDebugStep(
                  step: 'toc',
                  rule: '.chapter',
                  result: 'matched',
                  ok: true,
                ),
              ],
            )
            .ruleSteps
            .single
            .ok,
        isTrue,
      );
    });

    test('keeps rule step and result lists read-only at the boundary', () {
      const snapshot = BookSourceDebugSnapshot(
        requestUrl: 'https://example.com',
        requestMethod: 'GET',
        responseStatus: '200',
        responseCharset: 'UTF-8',
        responseSize: 1,
        responseBodyPreview: 'ok',
        ruleSteps: [
          BookSourceDebugStep(
            step: 'search',
            rule: '.book',
            result: 'matched',
            ok: true,
          ),
        ],
        results: [
          BookSourceDebugItem(
            name: 'Book',
            author: 'Author',
            coverUrl: '',
            bookUrl: 'https://example.com/book',
            kind: '',
            note: '',
          ),
        ],
      );

      expect(
        () => snapshot.ruleSteps.add(snapshot.ruleSteps.single),
        throwsUnsupportedError,
      );
      expect(() => snapshot.results.clear(), throwsUnsupportedError);
    });
  });
}
