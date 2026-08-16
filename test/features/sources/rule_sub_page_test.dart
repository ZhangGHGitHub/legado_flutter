import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/repositories/replace_rule_repository.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/source_subscription/rule_sub.dart';
import 'package:legado_flutter/application/replace/replace_notifier.dart';
import 'package:legado_flutter/application/rss/rss_notifier.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/application/source_subscription/rule_sub_import_port.dart';
import 'package:legado_flutter/application/source_subscription/rule_sub_prefs_port.dart';
import 'package:legado_flutter/features/sources/rule_sub_page.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/providers/replace_provider.dart';
import 'package:legado_flutter/providers/rss_provider.dart';
import 'package:legado_flutter/providers/source_provider.dart';

import '../../helpers/book_source_service_test_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('规则订阅导入通过共享 Riverpod Controller 更新三类状态', (tester) async {
    final sourceProvider = SourceProvider(
      repository: _FakeBookSourceRepository(),
      validationPort: FrbBookSourceValidationPort(),
      sourceService: createTestBookSourceService(),
    );
    final rssProvider = RssProvider();
    final replaceProvider = ReplaceProvider(
      repository: _FakeReplaceRuleRepository(),
      contentProcessor: ContentProcessorAdapter(),
    );
    final importPort = _FakeRuleSubImportPort();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
          ChangeNotifierProvider<RssProvider>.value(value: rssProvider),
          ChangeNotifierProvider<ReplaceProvider>.value(value: replaceProvider),
          Provider<RuleSubImportPort>.value(value: importPort),
        ],
        child: _withSharedControllers(
          sourceProvider: sourceProvider,
          rssProvider: rssProvider,
          replaceProvider: replaceProvider,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    FilledButton(
                      key: const ValueKey('book-source'),
                      onPressed: () => RuleSubPage.openImport(
                        context,
                        const RuleSub(id: 1, type: 0, url: 'book'),
                      ),
                      child: const Text('书源'),
                    ),
                    FilledButton(
                      key: const ValueKey('rss-source'),
                      onPressed: () => RuleSubPage.openImport(
                        context,
                        const RuleSub(id: 2, type: 1, url: 'rss'),
                      ),
                      child: const Text('订阅源'),
                    ),
                    FilledButton(
                      key: const ValueKey('replace-rule'),
                      onPressed: () => RuleSubPage.openImport(
                        context,
                        const RuleSub(id: 3, type: 2, url: 'replace'),
                      ),
                      child: const Text('替换规则'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await _importFrom(tester, 'book-source');
    expect(sourceProvider.sources.single.bookSourceUrl, 'https://source.test');

    await _importFrom(tester, 'rss-source');
    expect(rssProvider.sources.single.sourceUrl, 'https://rss.test');

    await _importFrom(tester, 'replace-rule');
    expect(replaceProvider.replaceRules.single.id, 'replace-1');
  });

  testWidgets('规则订阅页面保留订阅列表、重排和 URL 去重行为', (tester) async {
    final prefs = _FakeRuleSubPrefs([
      const RuleSub(
        id: 10,
        name: '示例订阅',
        url: 'https://sub.test',
        customOrder: 1,
      ),
    ]);
    final sourceProvider = SourceProvider(
      repository: _FakeBookSourceRepository(),
      validationPort: FrbBookSourceValidationPort(),
      sourceService: createTestBookSourceService(),
    );
    final rssProvider = RssProvider();
    final replaceProvider = ReplaceProvider(
      repository: _FakeReplaceRuleRepository(),
      contentProcessor: ContentProcessorAdapter(),
    );
    final importPort = _FakeRuleSubImportPort();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceProvider>.value(value: sourceProvider),
          ChangeNotifierProvider<RssProvider>.value(value: rssProvider),
          ChangeNotifierProvider<ReplaceProvider>.value(value: replaceProvider),
          Provider<RuleSubPrefsPort>.value(value: prefs),
          Provider<RuleSubImportPort>.value(value: importPort),
        ],
        child: _withSharedControllers(
          sourceProvider: sourceProvider,
          rssProvider: rssProvider,
          replaceProvider: replaceProvider,
          child: const MaterialApp(home: RuleSubPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('示例订阅'), findsOneWidget);
    expect(find.text('https://sub.test'), findsOneWidget);
    expect(find.byTooltip('编辑'), findsOneWidget);
    expect(importPort.autoUpdateChecks, 1);
  });
}

Widget _withSharedControllers({
  required SourceProvider sourceProvider,
  required RssProvider rssProvider,
  required ReplaceProvider replaceProvider,
  required Widget child,
}) {
  return riverpod.ProviderScope(
    overrides: [
      sourceControllerProvider.overrideWithValue(sourceProvider.controller),
      rssSourceControllerProvider.overrideWithValue(rssProvider.controller),
      replaceRulesControllerProvider.overrideWithValue(
        replaceProvider.controller,
      ),
    ],
    child: child,
  );
}

Future<void> _importFrom(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  expect(find.text('导入'), findsOneWidget);
  await tester.tap(find.text('导入'));
  await tester.pumpAndSettle();
}

final class _FakeRuleSubImportPort implements RuleSubImportPort {
  int autoUpdateChecks = 0;

  @override
  Future<RuleSubImportResult> fetchForImport(RuleSub sub) async {
    return switch (sub.type) {
      0 => RuleSubImportResult.bookSources([
        const BookSource(
          bookSourceUrl: 'https://source.test',
          bookSourceName: '测试书源',
        ),
      ]),
      1 => RuleSubImportResult.rssSources([
        const RssSource(sourceUrl: 'https://rss.test', sourceName: '测试订阅源'),
      ]),
      _ => RuleSubImportResult.replaceRules([
        const ReplaceRule(id: 'replace-1', name: '测试替换', pattern: '广告'),
      ]),
    };
  }

  @override
  Future<List<RuleSub>> checkAutoUpdates() async {
    autoUpdateChecks++;
    return const [];
  }
}

final class _FakeRuleSubPrefs implements RuleSubPrefsPort {
  _FakeRuleSubPrefs(Iterable<RuleSub> initial) : _subs = [...initial];

  final List<RuleSub> _subs;
  int autoUpdateChecks = 0;

  @override
  List<RuleSub> get cached => List.unmodifiable(_subs);

  @override
  Future<List<RuleSub>> load() async => List.unmodifiable(_subs);

  @override
  Future<void> save(List<RuleSub> subs) async {
    _subs
      ..clear()
      ..addAll(subs);
  }

  @override
  Future<RuleSub?> findByUrl(String url) async =>
      _subs.where((sub) => sub.url == url).firstOrNull;

  @override
  Future<int> maxOrder() async => _subs.fold<int>(
    0,
    (max, sub) => sub.customOrder > max ? sub.customOrder : max,
  );

  @override
  Future<void> upsert(RuleSub sub) async {
    _subs.removeWhere((item) => item.id == sub.id);
    _subs.add(sub);
  }

  @override
  Future<void> delete(RuleSub sub) async => _subs.remove(sub);

  @override
  Future<void> updateAll(List<RuleSub> changed) => save(changed);
}

final class _FakeBookSourceRepository implements BookSourceRepository {
  final List<BookSource> sources = [];

  @override
  Future<void> upsert(BookSource source) async {
    sources.removeWhere((item) => item.bookSourceUrl == source.bookSourceUrl);
    sources.add(source);
  }

  @override
  Future<void> upsertAll(List<BookSource> values) async {
    for (final source in values) {
      await upsert(source);
    }
  }

  @override
  Future<void> update(BookSource source) => upsert(source);

  @override
  Future<List<BookSource>> getAll() async => List.unmodifiable(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {}

  @override
  Future<void> delete(String url) async =>
      sources.removeWhere((source) => source.bookSourceUrl == url);
}

final class _FakeReplaceRuleRepository implements ReplaceRuleRepository {
  final List<ReplaceRule> rules = [];

  @override
  Future<List<ReplaceRule>> getAll() async => List.unmodifiable(rules);

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
  Future<void> update(ReplaceRule rule) => insert(rule);

  @override
  Future<void> toggle(String ruleId, bool enabled) async {}

  @override
  Future<void> delete(String ruleId) async {}

  @override
  Future<void> clear() async => rules.clear();
}
