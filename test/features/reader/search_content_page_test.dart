import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/preferences/search_content_prefs_port.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/ports/content_processing_port.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/features/reader/search_content_page.dart';
import 'package:legado_flutter/providers/replace_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('全文搜索通过共享 ReplaceController 应用净化规则', (tester) async {
    final rule = const ReplaceRule(
      id: 'shared-rule',
      name: '测试净化',
      pattern: '原始',
      replacement: '净化',
      isRegex: false,
    );
    final repository = _FakeReplaceRuleRepository([rule]);
    final processor = _FakeContentProcessingPort();
    final controller = ReplaceProvider(
      repository: repository,
      contentProcessor: processor,
    );
    addTearDown(controller.dispose);

    final chapter = Chapter(
      id: 'chapter-1',
      bookId: 'book-1',
      title: '第一章',
      index: 0,
      url: '',
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReplaceProvider>.value(value: controller),
          Provider<SearchContentPrefsPort>.value(
            value: const _FakeSearchContentPrefsPort(),
          ),
        ],
        child: MaterialApp(
          home: SearchContentPage(
            bookId: 'book-1',
            bookName: '测试书',
            chapters: [chapter],
            durChapterIndex: 0,
            currentChapterContent: '原始正文这是一段足够长的正文内容，用于搜索测试',
            contentCache: _FakeChapterContentCache(),
            initialQuery: '净化',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(processor.loadedRules, [rule]);
    expect(processor.processedContents, ['原始正文这是一段足够长的正文内容，用于搜索测试']);
    expect(find.text('搜索结果: 1'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });
}

final class _FakeSearchContentPrefsPort implements SearchContentPrefsPort {
  const _FakeSearchContentPrefsPort();

  @override
  Future<SearchContentPrefs> load() async => const SearchContentPrefs(
    enableReplace: true,
    scope: SearchContentPrefs.scopeCurrent,
  );

  @override
  Future<void> save(SearchContentPrefs prefs) async {}
}

final class _FakeChapterContentCache implements ChapterContentCachePort {
  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearBook(String bookId) async {}

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) async => {};

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async => {};

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  String sanitizeChapterId(String chapterId) => chapterId;

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

final class _FakeContentProcessingPort implements ContentProcessingPort {
  List<ReplaceRule> loadedRules = const [];
  final List<String> processedContents = [];

  @override
  String applyWithRules(String raw, List<ReplaceRule> rules) => raw;

  @override
  String getContent(String raw) {
    processedContents.add(raw);
    var result = raw;
    for (final rule in loadedRules) {
      if (rule.isEnabled && !rule.isRegex) {
        result = result.replaceAll(rule.pattern, rule.replacement);
      }
    }
    return result;
  }

  @override
  void loadRules(List<ReplaceRule> rules) {
    loadedRules = List<ReplaceRule>.of(rules);
  }

  @override
  String process(String raw, {ContentProcessingSourceRules? sourceRules}) =>
      raw;

  @override
  String processForReading(
    String raw, {
    String chapterTitle = '',
    String bookName = '',
    bool includeTitle = true,
    bool useReplace = true,
    String paragraphIndent = '',
    bool reSegment = true,
    ContentProcessingSourceRules? sourceRules,
  }) => raw;
}

final class _FakeReplaceRuleRepository implements ReplaceRuleRepository {
  _FakeReplaceRuleRepository(Iterable<ReplaceRule> rules)
    : rules = List<ReplaceRule>.of(rules);

  final List<ReplaceRule> rules;

  @override
  Future<void> clear() async => rules.clear();

  @override
  Future<void> delete(String ruleId) async {
    rules.removeWhere((rule) => rule.id == ruleId);
  }

  @override
  Future<List<ReplaceRule>> getAll() async => List<ReplaceRule>.of(rules);

  @override
  Future<void> insert(ReplaceRule rule) async {
    rules.removeWhere((item) => item.id == rule.id);
    rules.add(rule);
  }

  @override
  Future<void> insertAll(List<ReplaceRule> values) async {
    for (final rule in values) {
      await insert(rule);
    }
  }

  @override
  Future<void> toggle(String ruleId, bool enabled) async {
    final index = rules.indexWhere((rule) => rule.id == ruleId);
    if (index >= 0) rules[index] = rules[index].copyWith(isEnabled: enabled);
  }

  @override
  Future<void> update(ReplaceRule rule) => insert(rule);
}
