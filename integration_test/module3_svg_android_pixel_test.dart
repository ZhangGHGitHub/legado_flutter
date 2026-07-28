import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/features/reader/turn/page_snapshot.dart';
import 'package:legado_flutter/services/reader_image_cache.dart';
import 'package:legado_flutter/widgets/reader_inline_image.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const holdSeconds = int.fromEnvironment('MODULE3_SVG_HOLD_SECONDS');

  testWidgets('module 3 Android SVG renders with fixed pixels', (tester) async {
    const source = 'https://module3.invalid/fixed-svg.svg';
    const svgText = '''
<svg xmlns="http://www.w3.org/2000/svg" width="120" height="80"
    viewBox="0 0 120 80">
  <rect width="120" height="80" fill="#16a085"/>
  <circle cx="60" cy="40" r="22" fill="#f1c40f"/>
</svg>
''';
    final svgBytes = Uint8List.fromList(utf8.encode(svgText));
    final cache = ReaderImageCache(
      directory: Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}module3-svg',
      ),
      downloader: (uri, headers) async {
        expect(uri.toString(), source);
        expect(headers, isEmpty);
        return svgBytes;
      },
    );

    expect(ReaderInlineImage.isSvgBytes(svgBytes), isTrue);
    final loadedBytes = await cache.loadBytes(source);
    expect(loadedBytes, isNotNull);
    expect(loadedBytes, orderedEquals(svgBytes));
    expect(
      await cache.getSize(source),
      const ReaderImageSize(width: 120, height: 80),
    );

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          color: Colors.white,
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 360,
              height: 640,
              child: Padding(
                padding: EdgeInsets.only(left: 60, top: 80),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 240,
                    height: 160,
                    child: ReaderInlineImage(
                      key: ValueKey('module3-svg-image'),
                      source: source,
                      width: 240,
                      height: 160,
                      imageCache: cache,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final bounds = tester.renderObject<RenderBox>(
      find.byKey(const ValueKey('reader-inline-image-bounds')),
    );
    expect(bounds.size, const Size(240, 160));

    final image = await captureBoundary(boundaryKey, pixelRatio: 2);
    expect(image, isNotNull);
    expect(image!.width, 720);
    expect(image.height, 1280);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(png, isNotNull);
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(rgba, isNotNull);

    var tealPixels = 0;
    var yellowPixels = 0;
    for (var offset = 0; offset < rgba!.lengthInBytes; offset += 4) {
      final red = rgba.getUint8(offset);
      final green = rgba.getUint8(offset + 1);
      final blue = rgba.getUint8(offset + 2);
      final alpha = rgba.getUint8(offset + 3);
      if (alpha > 0 && green > 100 && red < 80 && blue < 150) {
        tealPixels++;
      }
      if (alpha > 0 && red > 150 && green > 100 && blue < 100) {
        yellowPixels++;
      }
    }
    expect(tealPixels, greaterThan(20 * 1000));
    expect(yellowPixels, greaterThan(10 * 1000));

    final directory = await getApplicationDocumentsDirectory();
    final output = File('${directory.path}/module3_svg_android_fixed_001.png');
    await output.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    debugPrint('MODULE3_SVG_PNG=${output.path}');
    if (holdSeconds > 0) {
      await Future<void>.delayed(Duration(seconds: holdSeconds));
    }
    image.dispose();
  });
}
