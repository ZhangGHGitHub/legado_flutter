import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/rule_sub.dart';
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
}
