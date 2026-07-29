import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/help/book_help.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/features/reader/reader_page.dart';
import 'package:legado_flutter/features/reader/reader_settings.dart';
import 'package:legado_flutter/features/reader/turn/page_direction.dart';
import 'package:legado_flutter/features/reader/turn/page_snapshot.dart';
import 'package:legado_flutter/features/reader/turn/reader_turn_view.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/services/read_book_config_prefs.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import 'package:legado_flutter/widgets/reader_selectable_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/helpers/book_source_service_test_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('module 3 Android real ReaderPage snapshot', (tester) async {
    await LegadoEngineBridge.tryInit();
    final dbRoot = await Directory.systemTemp.createTemp(
      'module3_reader_page_db_',
    );
    await LegadoDbBridge.init(
      dbPathOverride: '${dbRoot.path}${Platform.pathSeparator}legado.db',
    );

    const sourceUrl = 'module3://android-reader-page';
    const bookId = 'module3-real-reader-page-book';
    const chapterId = 'module3-real-reader-page-chapter';
    final sourceText = [
      '第一章 固定快照测试',
      List<String>.filled(
        24,
        '中文与English混排，数字123和URL https://example.com/a_long_path。',
      ).join(),
      '[newpage]',
      '第二段用于确认章节边界和分页范围。',
    ].join('\n');
    final book = Book(
      id: bookId,
      name: '模块3 ReaderPage 验收',
      author: 'integration-test',
      sourceUrl: sourceUrl,
      bookSourceUrl: sourceUrl,
      totalChapterNum: 1,
    );
    final chapter = Chapter(
      id: chapterId,
      bookId: bookId,
      title: '第一章 固定快照测试',
      index: 0,
      url: 'module3://chapter/1',
    );
    final bookSource = BookSource(
      bookSourceUrl: sourceUrl,
      bookSourceName: '模块3集成测试书源',
    );

    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);
    await LegadoDbBridge.init();

    // Make the production ReaderPage load the fixture through its normal
    // BookProvider -> ReadBook -> file-cache path.
    await BookHelp.deleteChapterContent(bookId, chapterId);
    await BookHelp.saveContent(bookId, chapterId, sourceText);
    final sourceService = createFrbBookSourceService();
    final sourceProvider = SourceProvider(
      repository: SourceDao(),
      validationPort: FrbBookSourceValidationPort(),
      sourceService: sourceService,
    );
    await sourceProvider.addSource(bookSource);
    final bookProvider = BookProvider(
      repository: BookDao(),
      sourceService: sourceService,
      contentCache: const FileChapterContentCache(),
    );
    final prefs = await SharedPreferences.getInstance();
    final oldConfig = prefs.getString('read_book_config_v1');
    addTearDown(() async {
      await sourceProvider.deleteSource(sourceUrl);
      await BookHelp.deleteChapterContent(bookId, chapterId);
      if (oldConfig == null) {
        await prefs.remove('read_book_config_v1');
      } else {
        await prefs.setString('read_book_config_v1', oldConfig);
      }
    });
    await ReadBookConfigPrefs.save(
      const ReaderSettings(
        fontSize: 16,
        lineHeight: 1.5,
        pageMode: 'none',
        fontFamily: 'sans-serif',
        paddingHorizontal: 16,
        paddingVertical: 0,
        paragraphIndent: 0,
        paragraphSpacing: 0,
        textFullJustify: false,
        textBottomJustify: false,
        hideStatusBar: false,
      ),
    );

    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<BookSourceService>.value(value: sourceService),
          ChangeNotifierProvider.value(value: bookProvider),
          ChangeNotifierProvider.value(value: sourceProvider),
        ],
        child: MaterialApp(
          home: RepaintBoundary(
            key: boundaryKey,
            child: ReaderPage(
              book: book,
              chapter: chapter,
              allChapters: [chapter],
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(ReaderSelectableText).evaluate().isNotEmpty &&
          find.byType(ReaderTurnView).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byType(ReaderTurnView), findsOneWidget);
    expect(find.byType(ReaderSelectableText), findsAtLeastNWidgets(1));

    List<Map<String, Object>> readCurrentPage() {
      // ReaderTurnView keeps the previous/current/next snapshot pages mounted
      // under opacity and renders the actual live page last.
      final widget = tester
          .widgetList<ReaderSelectableText>(find.byType(ReaderSelectableText))
          .last;
      return [
        {
          'text': widget.text,
          'start': widget.markupStart,
          'end': widget.markupEnd ?? widget.markupStart + widget.text.length,
        },
      ];
    }

    final turnState = tester.state<ReaderTurnViewState>(
      find.byType(ReaderTurnView),
    );
    final pageCount = tester
        .widget<ReaderTurnView>(find.byType(ReaderTurnView))
        .pageCount;
    expect(pageCount, greaterThan(0));
    final actualPages = <Map<String, Object>>[];
    for (var index = 0; index < pageCount; index++) {
      actualPages.add(readCurrentPage().single);
      if (index + 1 < pageCount) {
        await turnState.turnByAnim(PageTurnDirection.next);
        await tester.pump();
      }
    }

    // Export the real ReaderPage result before contract assertions so a
    // deliberate compatibility failure still leaves host-side evidence.
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    final image = await captureBoundary(boundaryKey, pixelRatio: 2);
    expect(image, isNotNull);
    expect(image!.width, 720);
    expect(image.height, 1280);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(png, isNotNull);
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
    final jsonFile = File(
      '${directory.path}/module3_android_reader_page_001.json',
    );
    final pngFile = File(
      '${directory.path}/module3_android_reader_page_001.png',
    );
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'fixtureId': 'module3-android-reader-page-001',
        'pageCount': pageCount,
        'pages': actualPages,
      }),
    );
    await pngFile.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    developer.log('MODULE3_READER_PAGE_JSON=${jsonFile.path}');
    developer.log('MODULE3_READER_PAGE_PNG=${pngFile.path}');
    image.dispose();

    const expectedRanges = <List<int>>[
      [0, 529],
      [529, 1079],
      [1079, 1331],
      [1342, 1359],
    ];
    const synthesizedNewlinePages = <int>{2, 3};
    final expectedPages = [
      for (var i = 0; i < expectedRanges.length; i++)
        {
          'text':
              sourceText.substring(expectedRanges[i][0], expectedRanges[i][1]) +
              (synthesizedNewlinePages.contains(i) ? '\n' : ''),
          'start': expectedRanges[i][0],
          'end': expectedRanges[i][1],
        },
    ];
    expect(actualPages, expectedPages);
    expect(
      actualPages.map((page) => [page['start'], page['end']]).toList(),
      expectedRanges,
    );
    expect(
      actualPages.any((page) => (page['text'] as String).contains('[newpage]')),
      isFalse,
    );
    expect(actualPages[2]['text'], endsWith('\n'));
    expect(actualPages[3]['text'], endsWith('\n'));
  });
}
