import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/reader/reader_font_port_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const port = ReaderFontPortAdapter();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('legado_reader_font_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationSupportDirectory') {
            return tempRoot.path;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  test('exposes system family mapping and fallback chain', () {
    expect(port.platformSansFamily(), isNotEmpty);
    expect(port.platformSerifFamily(), isNotEmpty);
    expect(port.platformMonoFamily(), isNotEmpty);
    expect(port.cjkFallbackFamilies(), isNotEmpty);
    expect(port.cjkFallbackFamilies(), contains('sans-serif'));
  });

  test('resolves system names and custom path presentation', () {
    expect(port.resolveFamilySync(''), port.platformSansFamily());
    expect(port.resolveFamilySync('serif'), port.platformSerifFamily());
    expect(port.resolveFamilySync('monospace'), port.platformMonoFamily());
    expect(port.isFontFilePath(r'C:\fonts\reader.ttf'), isTrue);
    expect(port.isFontFilePath('serif'), isFalse);
    expect(port.displayName(''), '系统默认');
    expect(port.displayName('serif'), '衬线');
    expect(port.displayName('monospace'), '等宽');
    expect(port.displayName(r'C:\fonts\reader.ttf'), 'reader');
  });

  test('missing font keeps loader fallback contract', () async {
    final path = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}legado_missing_port_font.ttf',
    ).path;

    expect(await port.ensureLoaded(path), isNull);
    expect(await port.resolveFamily(path), port.platformSansFamily());
  });

  test(
    'loads a custom font and resolves its registered family through port',
    () async {
      final file = File(
        'reference${Platform.pathSeparator}Jingshiro-legado${Platform.pathSeparator}'
        'app${Platform.pathSeparator}src${Platform.pathSeparator}main${Platform.pathSeparator}'
        'assets${Platform.pathSeparator}font${Platform.pathSeparator}number.ttf',
      );
      expect(await file.exists(), isTrue);

      final family = await port.ensureLoaded(file.path);
      expect(family, isNotNull);
      expect(await port.resolveFamily(file.path), family);
    },
  );

  test(
    'font directory and custom font listing are available through port',
    () async {
      final directory = await port.fontDirectory();
      expect(directory.existsSync(), isTrue);

      final files = await port.listCustomFontFiles();
      expect(files, everyElement(isA<File>()));
      expect(
        files,
        orderedEquals(
          [...files]..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          ),
        ),
      );
    },
  );
}
