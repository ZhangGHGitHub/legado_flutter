import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/features/book/toc_sheet.dart';
import 'package:path_provider/path_provider.dart';

const _chapterCount = 2000;
const _bookId = 'module2-android-toc-performance-book';
const _fixtureId = 'module2-android-toc-performance-2000';
const _frameBudget = Duration(microseconds: 16667);

class _SyntheticEmptyCache implements ChapterContentCachePort {
  const _SyntheticEmptyCache();

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearBook(String bookId) async {}

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) async => <String>{};

  @override
  String sanitizeChapterId(String chapterId) => chapterId;

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async => <String, int>{};

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

class _FrameTimingCollector {
  final List<ui.FrameTiming> _frames = <ui.FrameTiming>[];
  bool _collecting = false;

  void attach() {
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }

  void detach() {
    WidgetsBinding.instance.removeTimingsCallback(_onTimings);
  }

  void begin() {
    _frames.clear();
    _collecting = true;
  }

  List<ui.FrameTiming> end() {
    _collecting = false;
    return List<ui.FrameTiming>.unmodifiable(_frames);
  }

  void _onTimings(List<ui.FrameTiming> timings) {
    if (_collecting) _frames.addAll(timings);
  }
}

class _TimingSummary {
  const _TimingSummary({required this.frames});

  final List<ui.FrameTiming> frames;

  Map<String, Object?> toJson() {
    final totalUs = frames.map((frame) => frame.totalSpan.inMicroseconds);
    final buildUs = frames.map((frame) => frame.buildDuration.inMicroseconds);
    final rasterUs = frames.map((frame) => frame.rasterDuration.inMicroseconds);
    return <String, Object?>{
      'frameCount': frames.length,
      'jankyFrameCount': frames
          .where((frame) => frame.totalSpan > _frameBudget)
          .length,
      'firstFrame': frames.isEmpty ? null : _frameToJson(frames.first),
      'totalSpanMs': _stats(totalUs),
      'buildMs': _stats(buildUs),
      'rasterMs': _stats(rasterUs),
    };
  }
}

Map<String, Object> _frameToJson(ui.FrameTiming frame) => <String, Object>{
  'totalSpanUs': frame.totalSpan.inMicroseconds,
  'buildUs': frame.buildDuration.inMicroseconds,
  'rasterUs': frame.rasterDuration.inMicroseconds,
  'vsyncOverheadUs': frame.vsyncOverhead.inMicroseconds,
};

Map<String, Object> _stats(Iterable<int> values) {
  final sorted = values.toList()..sort();
  if (sorted.isEmpty) {
    return <String, Object>{
      'count': 0,
      'averageMs': 0.0,
      'p50Ms': 0.0,
      'p95Ms': 0.0,
      'maxMs': 0.0,
    };
  }
  final sum = sorted.fold<int>(0, (total, value) => total + value);
  double percentile(double position) {
    final index = ((sorted.length - 1) * position).round();
    return sorted[index] / 1000.0;
  }

  return <String, Object>{
    'count': sorted.length,
    'averageMs': sum / sorted.length / 1000.0,
    'p50Ms': percentile(0.50),
    'p95Ms': percentile(0.95),
    'maxMs': sorted.last / 1000.0,
  };
}

class _ScenarioResult {
  const _ScenarioResult({
    required this.name,
    required this.initialVisibleTitles,
    required this.afterScrollVisibleTitles,
    required this.initialFirstChapterVisible,
    required this.initialLastChapterVisible,
    required this.afterScrollLastChapterVisible,
    required this.maxScrollExtent,
    required this.firstFrame,
    required this.scrollFrames,
  });

  final String name;
  final List<String> initialVisibleTitles;
  final List<String> afterScrollVisibleTitles;
  final bool initialFirstChapterVisible;
  final bool initialLastChapterVisible;
  final bool afterScrollLastChapterVisible;
  final double maxScrollExtent;
  final _TimingSummary firstFrame;
  final _TimingSummary scrollFrames;

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'initialVisibleTitles': initialVisibleTitles,
    'afterScrollVisibleTitles': afterScrollVisibleTitles,
    'initialFirstChapterVisible': initialFirstChapterVisible,
    'initialLastChapterVisible': initialLastChapterVisible,
    'afterScrollLastChapterVisible': afterScrollLastChapterVisible,
    'maxScrollExtent': maxScrollExtent,
    'firstFrame': firstFrame.toJson(),
    'scrollFrames': scrollFrames.toJson(),
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('module 2 Android TOC performance for 2000 chapters', (
    tester,
  ) async {
    final chapters = _buildChapters();
    final titles = chapters.map((chapter) => chapter.title).toSet();
    final timingCollector = _FrameTimingCollector()..attach();
    addTearDown(timingCollector.detach);

    final cold = await _runScenario(
      tester,
      timingCollector,
      chapters: chapters,
      expectedTitles: titles,
      key: const ValueKey<String>('module2-toc-cold'),
      name: 'cold_widget_build',
    );
    final warm = await _runScenario(
      tester,
      timingCollector,
      chapters: chapters,
      expectedTitles: titles,
      key: const ValueKey<String>('module2-toc-warm'),
      name: 'warm_widget_rebuild',
    );

    final firstIndex = chapters.indexWhere(
      (chapter) => chapter.title == cold.initialVisibleTitles.first,
    );
    final lastIndex = chapters.indexWhere(
      (chapter) =>
          chapter.title ==
          cold.afterScrollVisibleTitles.lastWhere(titles.contains),
    );
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final result = <String, Object?>{
      'schemaVersion': 1,
      'fixtureId': _fixtureId,
      'chapterCount': chapters.length,
      'cacheMode': 'synthetic_empty_in_process',
      'coldDefinition': 'first TocSheet construction in this process',
      'warmDefinition': 'second TocSheet construction with the same data',
      'viewport': <String, Object>{
        'physicalWidth': view.physicalSize.width,
        'physicalHeight': view.physicalSize.height,
        'devicePixelRatio': view.devicePixelRatio,
      },
      'structure': <String, Object?>{
        'indexesAreContiguous': _indexesAreContiguous(chapters),
        'firstChapterIndexInInitialVisible': firstIndex,
        'lastVisibleIndexAfterColdScroll': lastIndex,
        'firstChapterId': chapters.first.id,
        'lastChapterId': chapters.last.id,
      },
      'cold': cold.toJson(),
      'warm': warm.toJson(),
      'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    };

    expect(result['chapterCount'], _chapterCount);
    expect(_indexesAreContiguous(chapters), isTrue);
    expect(cold.initialFirstChapterVisible, isTrue);
    expect(cold.initialLastChapterVisible, isFalse);
    expect(cold.afterScrollLastChapterVisible, isTrue);
    expect(warm.initialFirstChapterVisible, isTrue);
    expect(warm.initialLastChapterVisible, isFalse);
    expect(warm.afterScrollLastChapterVisible, isTrue);
    expect(cold.firstFrame.frames, isNotEmpty);
    expect(cold.scrollFrames.frames, isNotEmpty);
    expect(warm.firstFrame.frames, isNotEmpty);
    expect(warm.scrollFrames.frames, isNotEmpty);

    final directory = await getApplicationDocumentsDirectory();
    final output = File(
      '${directory.path}/module2_android_toc_performance_2000.json',
    );
    await output.writeAsString(
      const JsonEncoder.withIndent('  ').convert(result),
      flush: true,
    );
    final encoded = const JsonEncoder.withIndent('  ').convert(result);
    developer.log(
      'MODULE2_TOC_PERFORMANCE_JSON=${output.path}',
      name: 'module2_toc_performance',
    );
    developer.log(encoded, name: 'module2_toc_performance');
    debugPrint('MODULE2_TOC_PERFORMANCE_JSON=${output.path}');
    debugPrint('MODULE2_TOC_PERFORMANCE_RESULT=${jsonEncode(result)}');
  });
}

List<Chapter> _buildChapters() {
  return List<Chapter>.generate(
    _chapterCount,
    (index) => Chapter(
      id: '$_bookId-chapter-$index',
      bookId: _bookId,
      title: '第${(index + 1).toString().padLeft(4, '0')}章 性能合成章节',
      index: index,
      url: 'module2://toc-performance/chapter/$index',
    ),
    growable: false,
  );
}

bool _indexesAreContiguous(List<Chapter> chapters) {
  for (var index = 0; index < chapters.length; index++) {
    if (chapters[index].index != index) return false;
  }
  return true;
}

Future<_ScenarioResult> _runScenario(
  WidgetTester tester,
  _FrameTimingCollector timingCollector, {
  required List<Chapter> chapters,
  required Set<String> expectedTitles,
  required Key key,
  required String name,
}) async {
  timingCollector.begin();
  await tester.pumpWidget(
    MaterialApp(
      home: TocSheet(
        key: key,
        chapters: chapters,
        book: Book(id: _bookId, name: '模块 2 目录性能测试'),
        bookId: _bookId,
        contentCache: const _SyntheticEmptyCache(),
        onChapterTap: (_, {pageIndex, chapterPos}) {},
      ),
    ),
  );
  await tester.pump();
  await _allowTimingCallbacks(tester);
  final firstFrames = timingCollector.end();

  final listFinder = find.byType(ListView);
  expect(listFinder, findsOneWidget);
  final initialVisibleTitles = _visibleChapterTitles(tester, expectedTitles);
  final initialFirstChapterVisible = initialVisibleTitles.contains(
    chapters.first.title,
  );
  final initialLastChapterVisible = initialVisibleTitles.contains(
    chapters.last.title,
  );

  timingCollector.begin();
  await tester.fling(listFinder, const Offset(0, -720), 2400);
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
  await _allowTimingCallbacks(tester);
  final scrollFrames = timingCollector.end();

  final scrollableState = tester.state<ScrollableState>(
    find.descendant(of: listFinder, matching: find.byType(Scrollable)),
  );
  final maxScrollExtent = scrollableState.position.maxScrollExtent;

  scrollableState.position.jumpTo(maxScrollExtent);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final afterScrollVisibleTitles = _visibleChapterTitles(
    tester,
    expectedTitles,
  );
  final afterScrollLastChapterVisible = afterScrollVisibleTitles.contains(
    chapters.last.title,
  );
  debugPrint(
    'MODULE2_TOC_SCROLL_STATE name=$name '
    'pixels=${scrollableState.position.pixels} '
    'max=$maxScrollExtent '
    'visible=${jsonEncode(afterScrollVisibleTitles)}',
  );

  expect(initialVisibleTitles, isNotEmpty);
  expect(initialFirstChapterVisible, isTrue);
  expect(initialLastChapterVisible, isFalse);
  expect(maxScrollExtent, greaterThan(0));
  expect(afterScrollLastChapterVisible, isTrue);

  return _ScenarioResult(
    name: name,
    initialVisibleTitles: initialVisibleTitles,
    afterScrollVisibleTitles: afterScrollVisibleTitles,
    initialFirstChapterVisible: initialFirstChapterVisible,
    initialLastChapterVisible: initialLastChapterVisible,
    afterScrollLastChapterVisible: afterScrollLastChapterVisible,
    maxScrollExtent: maxScrollExtent,
    firstFrame: _TimingSummary(frames: firstFrames),
    scrollFrames: _TimingSummary(frames: scrollFrames),
  );
}

List<String> _visibleChapterTitles(
  WidgetTester tester,
  Set<String> expectedTitles,
) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .where(expectedTitles.contains)
      .toList(growable: false);
}

Future<void> _allowTimingCallbacks(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 16));
  await Future<void>.delayed(const Duration(milliseconds: 50));
}
