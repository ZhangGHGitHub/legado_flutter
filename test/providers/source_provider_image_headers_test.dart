import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/providers/source_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('image headers expose the source custom header', () async {
    final source = BookSource.fromJson({
      'bookSourceUrl': 'https://example.com/source',
      'bookSourceName': 'fixture',
      'header': {'User-Agent': 'fixture-reader', 'Cookie': 'source=1'},
    });

    final headers = await SourceProvider().imageHeadersForSource(source);

    expect(headers, {'User-Agent': 'fixture-reader', 'Cookie': 'source=1'});
  });

  test('image style is read from ruleContent', () {
    final source = BookSource.fromJson({
      'bookSourceUrl': 'https://example.com/source',
      'bookSourceName': 'fixture',
      'ruleContent': {'imageStyle': 'single'},
    });

    expect(source.ruleContentImageStyle, 'single');
  });
}
