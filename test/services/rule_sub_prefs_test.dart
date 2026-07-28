import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/models/rule_sub.dart';
import 'package:legado_flutter/models/replace_rule.dart';
import 'package:legado_flutter/models/rss_source.dart';
import 'package:legado_flutter/providers/replace_provider.dart';
import 'package:legado_flutter/providers/rss_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:legado_flutter/services/rule_sub_import_service.dart';
import 'package:legado_flutter/services/rule_sub_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RuleSubImportService.cacheBookSources.clear();
    RuleSubImportService.cacheRssSources.clear();
    RuleSubImportService.cacheReplaceRules.clear();
  });

  test('RuleSub json round-trip', () {
    final sub = RuleSub(
      id: 42,
      name: '测试源',
      url: 'https://example.com/sources.json',
      type: 1,
      customOrder: 3,
      autoUpdate: true,
      update: 1000,
      updateInterval: 24,
      silentUpdate: true,
    );
    final again = RuleSub.fromJson(sub.toJson());
    expect(again.id, 42);
    expect(again.name, '测试源');
    expect(again.url, 'https://example.com/sources.json');
    expect(again.type, 1);
    expect(again.typeLabel, '订阅源');
    expect(again.autoUpdate, isTrue);
    expect(again.silentUpdate, isTrue);
    expect(again.updateInterval, 24);
  });

  test('RuleSubPrefs upsert / findByUrl / delete', () async {
    final a = RuleSub(
      id: 1,
      name: 'A',
      url: 'https://a.example/x.json',
      customOrder: 1,
    );
    final b = RuleSub(
      id: 2,
      name: 'B',
      url: 'https://b.example/y.json',
      customOrder: 2,
    );
    await RuleSubPrefs.upsert(a);
    await RuleSubPrefs.upsert(b);
    expect((await RuleSubPrefs.load()).length, 2);
    expect((await RuleSubPrefs.findByUrl(a.url))?.name, 'A');
    expect(await RuleSubPrefs.maxOrder(), 2);

    await RuleSubPrefs.upsert(a.copyWith(name: 'A2'));
    expect((await RuleSubPrefs.findByUrl(a.url))?.name, 'A2');

    await RuleSubPrefs.delete(b);
    expect((await RuleSubPrefs.load()).length, 1);
  });

  test('parseRssSources and parseReplaceRules', () {
    final rss = RuleSubImportService.parseRssSources('''
[{"sourceUrl":"https://rss.example/1","sourceName":"示例RSS"}]
''');
    expect(rss.length, 1);
    expect(rss.first.sourceName, '示例RSS');

    final rules = RuleSubImportService.parseReplaceRules('''
[{"id":99,"name":"去广告","pattern":"广告","replacement":"","isRegex":true,"isEnabled":true}]
''');
    expect(rules.length, 1);
    expect(rules.first.id, '99');
    expect(rules.first.name, '去广告');
  });

  test(
    'auto update replaces newer RSS sources and preserves local groups',
    () async {
      final rssProvider = RssProvider();
      await rssProvider.upsertSource(
        const RssSource(
          sourceUrl: 'https://rss.example/source',
          sourceName: '旧名称',
          sourceGroup: '本地分组',
          lastUpdateTime: 10,
        ),
      );

      final ruleSub = RuleSub(
        id: 3,
        url: 'https://rules.example/rss.json',
        type: 1,
        silentUpdate: true,
      );
      final result = await RuleSubImportService.cacheSource(
        ruleSub: ruleSub,
        sourceProvider: SourceProvider(
          repository: _FakeBookSourceRepository(),
          validationPort: FrbBookSourceValidationPort(),
        ),
        rssProvider: rssProvider,
        replaceProvider: ReplaceProvider(
          repository: _FakeReplaceRuleRepository(),
        ),
        fetchTextOverride: (_) async =>
            '[{"sourceUrl":"https://rss.example/source",'
            '"sourceName":"新名称","sourceGroup":"远端分组",'
            '"lastUpdateTime":20}]',
      );

      expect(result, isFalse);
      expect(rssProvider.sources.single.sourceName, '新名称');
      expect(rssProvider.sources.single.sourceGroup, '本地分组');
      expect(rssProvider.sources.single.lastUpdateTime, 20);
    },
  );

  test(
    'auto update does not replace an RSS source with an older version',
    () async {
      final rssProvider = RssProvider();
      await rssProvider.upsertSource(
        const RssSource(
          sourceUrl: 'https://rss.example/source',
          sourceName: '当前名称',
          lastUpdateTime: 20,
        ),
      );

      final result = await RuleSubImportService.cacheSource(
        ruleSub: RuleSub(
          id: 4,
          url: 'https://rules.example/rss.json',
          type: 1,
          silentUpdate: true,
        ),
        sourceProvider: SourceProvider(
          repository: _FakeBookSourceRepository(),
          validationPort: FrbBookSourceValidationPort(),
        ),
        rssProvider: rssProvider,
        replaceProvider: ReplaceProvider(
          repository: _FakeReplaceRuleRepository(),
        ),
        fetchTextOverride: (_) async =>
            '[{"sourceUrl":"https://rss.example/source",'
            '"sourceName":"旧名称","lastUpdateTime":10}]',
      );

      expect(result, isFalse);
      expect(rssProvider.sources.single.sourceName, '当前名称');
      expect(rssProvider.sources.single.lastUpdateTime, 20);
    },
  );

  test(
    'non-silent auto update caches newer RSS sources for confirmation',
    () async {
      final rssProvider = RssProvider();
      await rssProvider.upsertSource(
        const RssSource(
          sourceUrl: 'https://rss.example/source',
          sourceName: '当前名称',
          lastUpdateTime: 10,
        ),
      );

      final result = await RuleSubImportService.cacheSource(
        ruleSub: RuleSub(id: 5, url: 'https://rules.example/rss.json', type: 1),
        sourceProvider: SourceProvider(
          repository: _FakeBookSourceRepository(),
          validationPort: FrbBookSourceValidationPort(),
        ),
        rssProvider: rssProvider,
        replaceProvider: ReplaceProvider(
          repository: _FakeReplaceRuleRepository(),
        ),
        fetchTextOverride: (_) async =>
            '[{"sourceUrl":"https://rss.example/source",'
            '"sourceName":"新名称","lastUpdateTime":20}]',
      );

      expect(result, isTrue);
      expect(rssProvider.sources.single.sourceName, '当前名称');
      expect(
        RuleSubImportService
            .cacheRssSources['https://rules.example/rss.json']
            ?.single
            .sourceName,
        '新名称',
      );
    },
  );
}

class _FakeBookSourceRepository implements BookSourceRepository {
  final List<BookSource> sources = [];

  @override
  Future<void> upsert(BookSource source) async => sources.add(source);

  @override
  Future<void> upsertAll(List<BookSource> values) async =>
      sources.addAll(values);

  @override
  Future<void> update(BookSource source) async => upsert(source);

  @override
  Future<List<BookSource>> getAll() async => List.unmodifiable(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {}

  @override
  Future<void> delete(String url) async {}
}

class _FakeReplaceRuleRepository implements ReplaceRuleRepository {
  final List<ReplaceRule> rules = [];

  @override
  Future<List<ReplaceRule>> getAll() async => List.unmodifiable(rules);

  @override
  Future<void> insert(ReplaceRule rule) async => rules.add(rule);

  @override
  Future<void> insertAll(List<ReplaceRule> values) async =>
      rules.addAll(values);

  @override
  Future<void> update(ReplaceRule rule) async => insert(rule);

  @override
  Future<void> toggle(String ruleId, bool enabled) async {}

  @override
  Future<void> delete(String ruleId) async {}

  @override
  Future<void> clear() async => rules.clear();
}
