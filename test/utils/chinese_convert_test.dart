import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/utils/chinese_convert.dart';

void main() {
  test('uses phrase mappings before character conversion', () {
    expect(ChineseConvert.apply('干净的后台在这里', 2), '乾淨的後台在這裡');
    expect(ChineseConvert.apply('乾淨的後台在這裡', 1), '干净的后台在这里');
  });

  test('keeps disabled conversion unchanged', () {
    const text = '干净的後台';
    expect(ChineseConvert.apply(text, 0), text);
  });
}
