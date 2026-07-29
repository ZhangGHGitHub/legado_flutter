import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/features/book/toc_sheet.dart';
import 'package:legado_flutter/features/reader/search_content_page.dart';
import 'package:legado_flutter/providers/replace_provider.dart';
import 'package:legado_flutter/services/search_content_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TocSheet reads cache metadata through the injected port', (
    tester,
  ) async {
    final cache = _FakeChapterContentCache(
      cachedIds: {'normalized-chapter_1'},
      wordCounts: {'normalized-chapter_1': 123},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TocSheet(
          bookId: 'book',
          chapters: [
            _chapter(id: 'chapter/1', title: '第一章', index: 0),
            _chapter(id: 'chapter-2', title: '第二章', index: 1),
          ],
          contentCache: cache,
          onChapterTap: (_, {pageIndex, chapterPos}) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(cache.listedBookIds, ['book']);
    expect(cache.sanitizedIds, contains('chapter/1'));
    expect(
      cache.wordCountRequests.any(
        (ids) => ids.length == 1 && ids.contains('normalized-chapter_1'),
      ),
      isTrue,
    );
    expect(find.text('123字'), findsOneWidget);
    expect(find.text('第一章'), findsOneWidget);
  });

  testWidgets(
    'SearchContentPage reads cached chapters through the injected port',
    (tester) async {
      final cache = _FakeChapterContentCache(
        cachedIds: {'normalized-chapter-2'},
        contents: {
          'book\u0000chapter-2':
              '前置前置前置前置前置前置前置前置前置前置'
              '目标词'
              '后置后置后置后置后置后置后置后置后置后置',
        },
      );
      final chapters = [
        _chapter(id: 'chapter-1', title: '当前章', index: 0),
        _chapter(id: 'chapter-2', title: '缓存章', index: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ReplaceProvider(repository: _EmptyRuleRepository()),
            child: SearchContentPage(
              bookId: 'book',
              bookName: '测试书',
              chapters: chapters,
              durChapterIndex: 0,
              currentChapterContent: '当前正文没有命中',
              initialQuery: '目标词',
              contentCache: cache,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(cache.listedBookIds, ['book']);
      expect(cache.sanitizedIds, contains('chapter-2'));
      expect(cache.readKeys, ['book\u0000chapter-2']);
      expect(find.textContaining('缓存章'), findsOneWidget);
      expect(find.text('搜索结果: 1'), findsOneWidget);
    },
  );

  testWidgets('stopping a network search drops late results from the old run', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'search_content_scope': SearchContentPrefs.scopeCurrentAndNetwork,
    });
    final lateContent = Completer<String?>();
    final chapters = [
      _chapter(id: 'chapter-1', title: '当前章', index: 0),
      _chapter(id: 'chapter-2', title: '远程章', index: 1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ReplaceProvider(repository: _EmptyRuleRepository()),
          child: SearchContentPage(
            bookId: 'book',
            bookName: '测试书',
            chapters: chapters,
            durChapterIndex: 0,
            currentChapterContent: '当前正文没有命中',
            initialQuery: '迟到词',
            onlineContentLoader: (_) => lateContent.future,
            contentCache: _FakeChapterContentCache(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byTooltip('停止搜索'), findsOneWidget);

    await tester.tap(find.byTooltip('停止搜索'));
    await tester.pump();
    expect(find.byTooltip('停止搜索'), findsNothing);

    lateContent.complete('迟到词应该被丢弃');
    await tester.pumpAndSettle();
    expect(find.textContaining('远程章'), findsNothing);
    expect(find.textContaining('迟到词应该被丢弃'), findsNothing);
  });
}

Chapter _chapter({
  required String id,
  required String title,
  required int index,
}) {
  return Chapter(
    id: id,
    bookId: 'book',
    title: title,
    index: index,
    url: 'https://example.com/$id',
  );
}

class _FakeChapterContentCache implements ChapterContentCachePort {
  _FakeChapterContentCache({
    this.cachedIds = const {},
    this.wordCounts = const {},
    this.contents = const {},
  });

  final Set<String> cachedIds;
  final Map<String, int> wordCounts;
  final Map<String, String> contents;
  final listedBookIds = <String>[];
  final sanitizedIds = <String>[];
  final wordCountRequests = <Set<String>>[];
  final readKeys = <String>[];

  String key(String bookId, String chapterId) => '$bookId\u0000$chapterId';

  @override
  Future<String?> get(String bookId, String chapterId) async {
    readKeys.add(key(bookId, chapterId));
    return contents[key(bookId, chapterId)];
  }

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
  Future<bool> has(String bookId, String chapterId) async =>
      cachedIds.contains(sanitizeChapterId(chapterId));

  @override
  Future<Set<String>> listChapterIds(String bookId) async {
    listedBookIds.add(bookId);
    return cachedIds;
  }

  @override
  String sanitizeChapterId(String chapterId) {
    sanitizedIds.add(chapterId);
    return 'normalized-$chapterId'.replaceAll('/', '_');
  }

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async {
    wordCountRequests.add(Set<String>.from(chapterIds ?? {}));
    return Map<String, int>.from(wordCounts);
  }

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

class _EmptyRuleRepository implements ReplaceRuleRepository {
  @override
  Future<List<ReplaceRule>> getAll() async => [];

  @override
  Future<void> insert(ReplaceRule rule) async {}

  @override
  Future<void> insertAll(List<ReplaceRule> rules) async {}

  @override
  Future<void> update(ReplaceRule rule) async {}

  @override
  Future<void> toggle(String ruleId, bool enabled) async {}

  @override
  Future<void> delete(String ruleId) async {}

  @override
  Future<void> clear() async {}
}
