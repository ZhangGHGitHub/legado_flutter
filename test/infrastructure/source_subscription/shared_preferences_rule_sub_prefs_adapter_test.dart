import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/source_subscription/rule_sub.dart';
import 'package:legado_flutter/infrastructure/source_subscription/shared_preferences_rule_sub_prefs_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'preserves rule subscription key, defaults, and save/load behavior',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const adapter = SharedPreferencesRuleSubPrefsAdapter();

      expect(await adapter.load(), isEmpty);

      final later = RuleSub(
        id: 2,
        name: '后置',
        url: 'https://example.com/later.json',
        customOrder: 2,
      );
      final earlier = RuleSub(
        id: 1,
        name: '前置',
        url: 'https://example.com/earlier.json',
        customOrder: 1,
      );
      await adapter.save([later, earlier]);

      expect(prefs.getString('rule_subs_v1'), isNotEmpty);
      final stored = jsonDecode(prefs.getString('rule_subs_v1')!) as List;
      expect((stored.first as Map)['id'], 1);
      expect((await adapter.load()).map((sub) => sub.id), [1, 2]);
      expect((await adapter.load()).first.autoUpdate, isFalse);
      expect((await adapter.load()).first.updateInterval, 0);
      expect(await adapter.maxOrder(), 2);
      expect((await adapter.findByUrl(earlier.url))?.id, 1);
    },
  );
}
