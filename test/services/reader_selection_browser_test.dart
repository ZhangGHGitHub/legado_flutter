import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/reader_selection_browser.dart';

void main() {
  test('absolute http URL keeps ACTION_VIEW target', () {
    expect(
      readerSelectionIsAbsoluteWebUrl('https://example.com/a?q=1'),
      isTrue,
    );
    final uri = readerSelectionBrowserUri('  https://example.com/a?q=1  ');
    expect(uri?.toString(), 'https://example.com/a?q=1');
  });

  test('ordinary selected text maps to web search', () {
    final uri = readerSelectionBrowserUri('目标 词');
    expect(uri?.scheme, 'https');
    expect(uri?.host, 'www.google.com');
    expect(uri?.path, '/search');
    expect(uri?.queryParameters['q'], '目标 词');
  });

  test('empty text returns no browser target', () {
    expect(readerSelectionBrowserUri('  '), isNull);
  });

  test('non-http URI is searched as text like original isAbsUrl', () {
    expect(readerSelectionIsAbsoluteWebUrl('ftp://example.com/file'), isFalse);
    final uri = readerSelectionBrowserUri('ftp://example.com/file');
    expect(uri?.host, 'www.google.com');
    expect(uri?.queryParameters['q'], 'ftp://example.com/file');
  });

  test('absolute URL classification follows original prefix semantics', () {
    expect(readerSelectionIsAbsoluteWebUrl('HTTP://example.com'), isTrue);
    expect(readerSelectionIsAbsoluteWebUrl('https://'), isTrue);
    expect(readerSelectionIsAbsoluteWebUrl(' https://example.com'), isFalse);
  });
}
