import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/reader_config/read_style_config.dart';

void main() {
  group('ReadStyleConfig', () {
    test('uses value equality and preserves copyWith updates', () {
      const config = ReadStyleConfig(name: '默认', textSize: 20);

      expect(config, const ReadStyleConfig(name: '默认', textSize: 20));
      expect(config.copyWith(textSize: 22).textSize, 22);
      expect(config.copyWith().name, '默认');
    });

    test('keeps legacy JSON defaults and all configured values', () {
      final defaults = ReadStyleConfig.fromJson(const {});
      expect(defaults.bgStr, '#EEEEEE');
      expect(defaults.bgAlpha, 100);
      expect(defaults.darkStatusIcon, isTrue);

      final config = ReadStyleConfig.fromJson({
        'name': '夜读',
        'textSize': 21.9,
        'letterSpacing': 0.05,
        'darkStatusIcon': false,
      });

      expect(config.textSize, 21);
      expect(config.letterSpacing, 0.05);
      expect(config.toJson()['darkStatusIcon'], isFalse);
      expect(config.toJson()['name'], '夜读');
    });
  });
}
