import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/bookmark_hint.dart';

void main() {
  test('parses page from bookmark hint', () {
    expect(bookmarkPageIndexFromNote('书签 · 第3/10页'), 2);
    expect(bookmarkPageIndexFromNote('书签 · 第1/1页'), 0);
  });

  test('returns null for non-page hints', () {
    expect(bookmarkPageIndexFromNote('书签 · 滚动位置'), isNull);
    expect(bookmarkPageIndexFromNote('普通想法'), isNull);
  });
}
