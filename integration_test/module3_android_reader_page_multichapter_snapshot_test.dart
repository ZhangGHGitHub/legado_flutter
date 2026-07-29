import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/help/book_help.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/features/reader/reader_page.dart';
import 'package:legado_flutter/features/reader/reader_settings.dart';
import 'package:legado_flutter/features/reader/turn/page_direction.dart';
import 'package:legado_flutter/features/reader/turn/page_snapshot.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/features/reader/turn/reader_turn_view.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/services/book_reader_prefs.dart';
import 'package:legado_flutter/services/book_source_service.dart';
import 'package:legado_flutter/services/read_book_config_prefs.dart';
import 'package:legado_flutter/widgets/reader_selectable_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/helpers/book_source_service_test_factory.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('module 3 Android ReaderPage multichapter snapshot gate', (
    tester,
  ) async {
    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);

    final dbRoot = await Directory.systemTemp.createTemp(
      'module3_reader_page_multichapter_db_',
    );
    await LegadoDbBridge.init(
      dbPathOverride: '${dbRoot.path}${Platform.pathSeparator}legado.db',
    );

    const sourceUrl = 'module3://android-reader-page-multichapter';
    const bookId = 'module3-real-reader-page-multichapter-book';
    const firstChapterId = 'module3-real-reader-page-multichapter-chapter-1';
    const secondChapterId = 'module3-real-reader-page-multichapter-chapter-2';
    final firstText = [
      '第一章 双章门禁',
      List<String>.filled(10, '第一章正文只属于第一章，包含中文与English混排以及数字123。').join('\n'),
      '[newpage]',
      '第一章末页，用于验证硬分页后的章节边界。',
    ].join('\n');
    final secondText = [
      '第二章 末章边界',
      List<String>.filled(3, '第二章正文只属于第二章，不能从第一章分页范围借入内容。').join('\n'),
    ].join('\n');
    final secondDisplayText = secondText.substring('第二章 末章边界\n'.length);
    final book = Book(
      id: bookId,
      name: '模块3 ReaderPage 双章门禁',
      author: 'integration-test',
      sourceUrl: sourceUrl,
      bookSourceUrl: sourceUrl,
      totalChapterNum: 2,
    );
    final chapters = [
      Chapter(
        id: firstChapterId,
        bookId: bookId,
        title: '第一章 双章门禁',
        index: 0,
        url: 'module3://chapter/multichapter/1',
      ),
      Chapter(
        id: secondChapterId,
        bookId: bookId,
        title: '第二章 末章边界',
        index: 1,
        url: 'module3://chapter/multichapter/2',
      ),
    ];
    final bookSource = BookSource(
      bookSourceUrl: sourceUrl,
      bookSourceName: '模块3双章集成测试书源',
    );

    await BookHelp.deleteChapterContent(bookId, firstChapterId);
    await BookHelp.deleteChapterContent(bookId, secondChapterId);
    await BookHelp.saveContent(bookId, firstChapterId, firstText);
    await BookHelp.saveContent(bookId, secondChapterId, secondText);

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
    final oldPageAnim = await BookReaderPrefs.getPageAnim(bookId);
    addTearDown(() async {
      await sourceProvider.deleteSource(sourceUrl);
      await BookHelp.deleteChapterContent(bookId, firstChapterId);
      await BookHelp.deleteChapterContent(bookId, secondChapterId);
      ReadBook.instance.reset();
      if (oldConfig == null) {
        await prefs.remove('read_book_config_v1');
      } else {
        await prefs.setString('read_book_config_v1', oldConfig);
      }
      if (oldPageAnim == null) {
        await prefs.remove('book_page_anim:$bookId');
      } else {
        await BookReaderPrefs.setPageAnim(bookId, oldPageAnim);
      }
      await dbRoot.delete(recursive: true);
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
    await BookReaderPrefs.setPageAnim(bookId, 4);

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
              chapter: chapters.first,
              allChapters: chapters,
            ),
          ),
        ),
      ),
    );

    Future<void> waitForChapter(String marker) async {
      for (var i = 0; i < 160; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final texts = tester.widgetList<ReaderSelectableText>(
          find.byType(ReaderSelectableText),
        );
        if (find.byType(ReaderTurnView).evaluate().isNotEmpty &&
            texts.isNotEmpty &&
            texts.last.text.contains(marker)) {
          return;
        }
      }
      fail('ReaderPage did not load chapter marker: $marker');
    }

    Map<String, Object> readCurrentPage() {
      final widget = tester
          .widgetList<ReaderSelectableText>(find.byType(ReaderSelectableText))
          .last;
      return {
        'text': widget.text,
        'start': widget.markupStart,
        'end': widget.markupEnd ?? widget.markupStart + widget.text.length,
      };
    }

    Future<List<Map<String, Object>>> readChapterPages() async {
      final pages = <Map<String, Object>>[];
      var turn = tester.state<ReaderTurnViewState>(find.byType(ReaderTurnView));
      final pageCount = tester
          .widget<ReaderTurnView>(find.byType(ReaderTurnView))
          .pageCount;
      expect(pageCount, greaterThan(0));
      for (var index = 0; index < pageCount; index++) {
        pages.add(readCurrentPage());
        if (index + 1 < pageCount) {
          await turn.turnByAnim(PageTurnDirection.next);
          await tester.pump();
          turn = tester.state<ReaderTurnViewState>(find.byType(ReaderTurnView));
        }
      }
      return pages;
    }

    void expectChapterLocalPages(
      List<Map<String, Object>> pages,
      String sourceText,
    ) {
      expect(pages, isNotEmpty);
      for (final page in pages) {
        final start = page['start']! as int;
        final end = page['end']! as int;
        final text = page['text']! as String;
        expect(start, greaterThanOrEqualTo(0));
        expect(end, greaterThanOrEqualTo(start));
        expect(end, lessThanOrEqualTo(sourceText.length));
        expect(text.contains('[newpage]'), isFalse);
        final sourceSlice = sourceText.substring(start, end);
        expect(
          text == sourceSlice || text == '$sourceSlice\n',
          isTrue,
          reason: 'page=$page sourceSlice=${jsonEncode(sourceSlice)}',
        );
      }
    }

    await waitForChapter('第一章');
    final firstPages = await readChapterPages();
    expectChapterLocalPages(firstPages, firstText);
    expect(firstPages.length, greaterThanOrEqualTo(2));
    expect(
      firstPages.any((page) => (page['text']! as String).contains('第一章末页')),
      isTrue,
    );
    expect(firstText.contains('[newpage]'), isTrue);

    final firstPng = await _capturePng(boundaryKey);
    expect(firstPng, isNotNull);

    var turn = tester.state<ReaderTurnViewState>(find.byType(ReaderTurnView));
    await turn.turnByAnim(PageTurnDirection.next);
    await tester.pump();
    await waitForChapter('第二章');

    final secondPages = await readChapterPages();
    // ReadBook removes a duplicate chapter title before pagination. The
    // ReaderPage offsets are relative to this display text, not raw cache.
    expectChapterLocalPages(secondPages, secondDisplayText);
    expect(secondPages.length, greaterThan(0));
    expect(secondPages.first['start'], 0);
    expect(secondPages.first['text'], isNot(contains('第二章 末章边界')));
    expect(
      secondPages.every(
        (page) =>
            !(page['text']! as String).contains('第一章双章门禁') &&
            !(page['text']! as String).contains('第一章末页'),
      ),
      isTrue,
    );

    final secondPageCount = tester
        .widget<ReaderTurnView>(find.byType(ReaderTurnView))
        .pageCount;
    final secondLastPage = readCurrentPage();
    turn = tester.state<ReaderTurnViewState>(find.byType(ReaderTurnView));
    await turn.turnByAnim(PageTurnDirection.next);
    await tester.pump();
    expect(
      tester.widget<ReaderTurnView>(find.byType(ReaderTurnView)).pageCount,
      secondPageCount,
    );
    expect(readCurrentPage(), secondLastPage);

    final secondPng = await _capturePng(boundaryKey);
    expect(secondPng, isNotNull);

    turn = tester.state<ReaderTurnViewState>(find.byType(ReaderTurnView));
    await turn.turnByAnim(PageTurnDirection.prev);
    await tester.pump();
    await waitForChapter('第一章末页');
    final returnedPage = readCurrentPage();
    expect(returnedPage['text'], contains('第一章末页'));
    expectChapterLocalPages([returnedPage], firstText);

    final directory = await getApplicationDocumentsDirectory();
    final jsonFile = File(
      '${directory.path}/module3_android_reader_page_multichapter_001.json',
    );
    final firstPngFile = File(
      '${directory.path}/module3_android_reader_page_multichapter_001_ch1.png',
    );
    final secondPngFile = File(
      '${directory.path}/module3_android_reader_page_multichapter_001_ch2.png',
    );
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'fixtureId': 'module3-android-reader-page-multichapter-001',
        'chapterCount': 2,
        'chapters': [
          {'index': 0, 'id': firstChapterId},
          {'index': 1, 'id': secondChapterId},
        ],
        'snapshots': [
          {'chapterIndex': 0, 'pages': firstPages},
          {'chapterIndex': 1, 'pages': secondPages},
        ],
      }),
    );
    await firstPngFile.writeAsBytes(firstPng!, flush: true);
    await secondPngFile.writeAsBytes(secondPng!, flush: true);
    developer.log('MODULE3_MULTICHAPTER_JSON=${jsonFile.path}');
    developer.log('MODULE3_MULTICHAPTER_CH1_PNG=${firstPngFile.path}');
    developer.log('MODULE3_MULTICHAPTER_CH2_PNG=${secondPngFile.path}');
  });
}

Future<Uint8List?> _capturePng(GlobalKey boundaryKey) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final image = await captureBoundary(boundaryKey, pixelRatio: 2);
  expect(image, isNotNull);
  expect(image!.width, 720);
  expect(image.height, 1280);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png?.buffer.asUint8List();
}
