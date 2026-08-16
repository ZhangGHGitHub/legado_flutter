import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/reader_config/read_style_flutter_mapper.dart';

void main() {
  group('ReadStyleSlotOverride', () {
    test('keeps JSON keys, color conversion, and dark status default', () {
      final value = ReadStyleSlotOverride(
        name: '自定义',
        background: const Color(0xFF112233),
        text: const Color(0xFF445566),
        accent: const Color(0xFF778899),
        bgImagePath: 'images/paper.jpg',
      );

      expect(value.darkStatusIcon, isTrue);
      expect(value.toJson(), {
        'name': '自定义',
        'background': '#112233',
        'text': '#445566',
        'accent': '#778899',
        'bgImagePath': 'images/paper.jpg',
        'darkStatusIcon': true,
      });

      final restored = ReadStyleSlotOverride.fromJson(value.toJson());
      expect(restored, value);
    });

    test('retains clearBgImage copyWith semantics', () {
      const value = ReadStyleSlotOverride(
        name: '原主题',
        bgImagePath: 'images/original.jpg',
        darkStatusIcon: false,
      );

      expect(
        value.copyWith(name: '重命名'),
        const ReadStyleSlotOverride(
          name: '重命名',
          bgImagePath: 'images/original.jpg',
          darkStatusIcon: false,
        ),
      );
      expect(value.copyWith(clearBgImage: true).bgImagePath, isNull);
      expect(
        value
            .copyWith(bgImagePath: 'images/new.jpg', clearBgImage: true)
            .bgImagePath,
        isNull,
      );
    });
  });
}
