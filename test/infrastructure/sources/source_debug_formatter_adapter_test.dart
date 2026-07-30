import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/book_source_debug_port.dart';
import 'package:legado_flutter/infrastructure/sources/source_debug_formatter_adapter.dart';

void main() {
  test(
    'adapter preserves formatter output and limits listed results to ten',
    () {
      const snapshot = BookSourceDebugSnapshot(
        requestUrl: 'https://source.example/search',
        requestMethod: 'GET',
        responseStatus: '200',
        responseCharset: 'UTF-8',
        responseSize: 42,
        responseBodyPreview: '',
        ruleSteps: [],
        results: [
          BookSourceDebugItem(
            name: '书籍 1',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 2',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 3',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 4',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 5',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 6',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 7',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 8',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 9',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 10',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
          BookSourceDebugItem(
            name: '书籍 11',
            author: '',
            coverUrl: '',
            bookUrl: '',
            kind: '',
            note: '',
          ),
        ],
      );

      final log = const SourceDebugFormatterAdapter().format(snapshot);

      expect(log, contains('── 请求 ──\nGET https://source.example/search'));
      expect(log, contains('── 结果 (11) ──'));
      expect(log, contains('10. 书籍 10'));
      expect(log, isNot(contains('11. 书籍 11')));
      expect(log, contains('... 还有 1 条'));
    },
  );
}
