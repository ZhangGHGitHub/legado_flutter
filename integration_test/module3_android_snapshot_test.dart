import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/features/reader/reader_pagination_snapshot.dart';
import 'package:legado_flutter/features/reader/reader_pagination_snapshot_diff.dart';
import 'package:legado_flutter/features/reader/reader_paginator.dart';
import 'package:legado_flutter/features/reader/turn/page_snapshot.dart';
import 'package:legado_flutter/widgets/reader_selectable_text.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const holdSeconds = int.fromEnvironment('MODULE3_SNAPSHOT_HOLD_SECONDS');

  testWidgets('module 3 Android snapshot fixture is exported', (tester) async {
    const config = ReaderPaginationSnapshotConfig(
      fontFamily: 'sans-serif',
      fontSize: 16,
      fontWeight: 400,
      devicePixelRatio: 2,
      viewportWidth: 360,
      viewportHeight: 640,
      contentLeft: 16,
      contentTop: 24,
      contentWidth: 328,
      contentHeight: 560,
      lineHeight: 1.5,
      renderedLineHeight: 28.125,
      letterSpacing: 0,
      paragraphSpacingTenths: 0,
      pageMode: 'horizontal',
      textFullJustify: true,
      titleFontSize: 16,
      titleFontWeight: 700,
    );
    final source = [
      '第一章 固定快照测试',
      List<String>.filled(
        24,
        '中文与English混排，数字123和URL https://example.com/a_long_path。',
      ).join(),
      '[newpage]',
      '第二段用于确认章节边界和分页范围。',
    ].join('\n');
    final pages = ReaderPaginator.paginate(
      text: source,
      style: const TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
      maxWidth: config.contentWidth,
      maxHeight: config.contentHeight,
      renderedLineHeight: config.renderedLineHeight,
    );
    final snapshot = ReaderPaginationSnapshot.fromSlices(
      fixtureId: 'module3-android-fixed-001',
      sourceText: source,
      chapterIndex: 0,
      chapterCount: 1,
      chapterStart: 0,
      chapterEnd: source.length,
      config: config,
      pages: pages,
    );

    // Keep the original Android page contract executable on the device. The
    // baseline JSON is intentionally not loaded as an asset because this
    // integration test must remain runnable without changing pubspec assets.
    const expectedRanges = <List<int>>[
      [0, 529],
      [529, 1079],
      [1079, 1331],
      [1342, 1359],
    ];
    const synthesizedNewlinePages = <int>{2, 3};
    final expectedSnapshot = ReaderPaginationSnapshot(
      fixtureId: 'module3-android-fixed-001',
      sourceTextLength: source.length,
      chapterIndex: 0,
      chapterCount: 1,
      chapterStart: 0,
      chapterEnd: source.length,
      config: config,
      pages: [
        for (var i = 0; i < expectedRanges.length; i++)
          ReaderPageSnapshot(
            index: i,
            text:
                source.substring(expectedRanges[i][0], expectedRanges[i][1]) +
                (synthesizedNewlinePages.contains(i) ? '\n' : ''),
            start: expectedRanges[i][0],
            end: expectedRanges[i][1],
          ),
      ],
    );
    expect(expectedSnapshot.validate(source), isEmpty);
    expect(snapshot.validate(source), isEmpty);
    expect(
      ReaderPaginationSnapshotDiff.compare(
        expectedSnapshot,
        snapshot,
      ).differences,
      isEmpty,
    );
    expect(
      snapshot.pages.map((page) => <int>[page.start, page.end]).toList(),
      expectedRanges,
    );
    expect(
      snapshot.pages.map((page) => page.text).toList(),
      expectedSnapshot.pages.map((page) => page.text).toList(),
    );
    expect(
      source.substring(snapshot.pages[2].end, snapshot.pages[3].start),
      '\n[newpage]\n',
    );
    expect(
      snapshot.pages.any((page) => page.text.contains('[newpage]')),
      isFalse,
    );
    expect(snapshot.pages[2].text.endsWith('\n'), isTrue);
    expect(snapshot.pages[3].text.endsWith('\n'), isTrue);
    expect(snapshot.pages[0].text.endsWith('\n'), isFalse);
    expect(snapshot.pages[1].text.endsWith('\n'), isFalse);

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: RepaintBoundary(
            key: boundaryKey,
            child: ColoredBox(
              color: Colors.white,
              child: SizedBox(
                width: config.viewportWidth,
                height: config.viewportHeight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: config.contentLeft,
                    top: config.contentTop,
                    right:
                        config.viewportWidth -
                        config.contentLeft -
                        config.contentWidth,
                    bottom:
                        config.viewportHeight -
                        config.contentTop -
                        config.contentHeight,
                  ),
                  child: ReaderSelectableText(
                    text: pages.first.text,
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: config.fontSize,
                      height: config.renderedLineHeight / config.fontSize,
                      color: Colors.black,
                    ),
                    richText: TextSpan(
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: config.fontSize,
                        height: config.renderedLineHeight / config.fontSize,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: '${pages.first.text.split('\n').first}\n',
                          style: TextStyle(
                            fontSize: config.titleFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: pages.first.text.substring(
                            pages.first.text.indexOf('\n') + 1,
                          ),
                        ),
                      ],
                    ),
                    textAlign: config.textFullJustify
                        ? TextAlign.justify
                        : TextAlign.start,
                    onWriteNote: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final image = await captureBoundary(
      boundaryKey,
      pixelRatio: config.devicePixelRatio,
    );
    expect(image, isNotNull);
    expect(image!.width, 720);
    expect(image.height, 1280);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(png, isNotNull);
    expect(config.viewportWidth * config.devicePixelRatio, 720);
    expect(config.viewportHeight * config.devicePixelRatio, 1280);
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(rgba, isNotNull);
    var hasTextPixel = false;
    for (var offset = 0; offset < rgba!.lengthInBytes; offset += 4) {
      if (rgba.getUint8(offset + 3) > 0 &&
          rgba.getUint8(offset) < 32 &&
          rgba.getUint8(offset + 1) < 32 &&
          rgba.getUint8(offset + 2) < 32) {
        hasTextPixel = true;
        break;
      }
    }
    expect(hasTextPixel, isTrue);

    final directory = await getApplicationDocumentsDirectory();
    final jsonFile = File('${directory.path}/module3_android_fixed_001.json');
    final pngFile = File('${directory.path}/module3_android_fixed_001.png');
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
    );
    await pngFile.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    // The paths are consumed by the host-side adb pull step.
    developer.log('MODULE3_SNAPSHOT_JSON=${jsonFile.path}');
    developer.log('MODULE3_SNAPSHOT_PNG=${pngFile.path}');
    if (holdSeconds > 0) {
      await Future<void>.delayed(Duration(seconds: holdSeconds));
    }
    image.dispose();
  });
}
