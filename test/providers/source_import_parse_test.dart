import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/providers/source_provider.dart';

void main() {
  group('extractSourceListFromDecoded', () {
    test('unwraps nested bookSources key', () {
      final list = SourceProvider.extractSourceListFromDecoded({
        'bookSources': [
          {'bookSourceUrl': 'https://a.test', 'bookSourceName': 'A'},
        ],
      });
      expect(list, isNotNull);
      expect(list!.length, 1);
    });

    test('wraps single source map', () {
      final list = SourceProvider.extractSourceListFromDecoded({
        'bookSourceUrl': 'https://b.test',
        'bookSourceName': 'B',
      });
      expect(list, isNotNull);
      expect(list!.length, 1);
    });
  });
}
