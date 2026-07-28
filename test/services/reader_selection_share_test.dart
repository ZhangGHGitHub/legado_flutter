import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/reader_selection_share.dart';

void main() {
  test('share keeps the original chooser subject', () {
    expect(readerSelectionShareSubject, '分享');
  });

  test('share keeps selected text exactly as selected', () {
    expect(readerSelectionShareText('  选中的文本  '), '  选中的文本  ');
  });

  test('empty selection has no share action', () {
    expect(readerSelectionShareText(''), isNull);
  });
}
