import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/read_style_config.dart';
import 'package:legado_flutter/services/read_style_zip_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReadStyleConfig', () {
    test('hex roundtrip', () {
      const c = Color(0xFF3E3D3B);
      expect(ReadStyleConfig.parseColor(ReadStyleConfig.toHex(c)), c);
    });

    test('fromJson / toJson preserves colors', () {
      final cfg = ReadStyleConfig.fromJson({
        'name': '舒适',
        'bgStr': '#F5F0E8',
        'bgType': 0,
        'textColor': '#3C3C3C',
        'textSize': 22,
        'letterSpacing': 0.05,
      });
      expect(cfg.name, '舒适');
      expect(cfg.dayBgColor, const Color(0xFFF5F0E8));
      expect(cfg.dayTextColor, const Color(0xFF3C3C3C));
      expect(cfg.textSize, 22);
      final round = ReadStyleConfig.fromJson(cfg.toJson());
      expect(round.name, cfg.name);
      expect(round.bgStr, cfg.bgStr);
    });
  });

  group('ReadStyleZipService', () {
    test('importBytes reads readConfig.json from zip', () async {
      final configJson = jsonEncode({
        'name': '导入主题',
        'bgStr': '#FFFFFF',
        'bgType': 0,
        'textColor': '#222222',
        'textAccentColor': '#FF5722',
        'textSize': 18,
        'lineSpacingExtra': 10,
        'paragraphSpacing': 2,
        'paddingLeft': 20,
        'paddingRight': 20,
      });
      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'readConfig.json',
            utf8.encode(configJson).length,
            utf8.encode(configJson),
          ),
        );
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final service = ReadStyleZipService();
      final cfg = await service.importBytes(bytes);
      expect(cfg.name, '导入主题');
      expect(cfg.dayBgColor, const Color(0xFFFFFFFF));
      expect(cfg.dayTextColor, const Color(0xFF222222));
      expect(cfg.textSize, 18);
    });

    test('exportBytes then importBytes roundtrip', () async {
      const original = ReadStyleConfig(
        name: '圆程',
        bgStr: '#C7EDCC',
        textColor: '#2C4C3B',
        textAccentColor: '#4CAF50',
        textSize: 19,
        letterSpacing: 0.02,
      );
      final service = ReadStyleZipService();
      final zip = await service.exportBytes(original);
      final back = await service.importBytes(zip);
      expect(back.name, original.name);
      expect(back.bgStr.toUpperCase(), original.bgStr.toUpperCase());
      expect(back.textColor.toUpperCase(), original.textColor.toUpperCase());
      expect(back.textSize, original.textSize);
    });

    test('importBytes fails without readConfig.json', () async {
      final archive = Archive()
        ..addFile(ArchiveFile('readme.txt', 4, utf8.encode('hi')));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final service = ReadStyleZipService();
      expect(
        () => service.importBytes(bytes),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
