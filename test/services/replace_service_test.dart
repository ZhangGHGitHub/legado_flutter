import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/models/replace_rule.dart';
import 'package:legado_flutter/services/replace_preset_library.dart';
import 'package:legado_flutter/services/replace_service.dart';

void main() {
  group('ReplaceService', () {
    test('applyWithRules removes biquge ad from sample', () {
      final adRule = ReplaceRule(
        id: 't1',
        name: '笔趣阁',
        pattern: r'笔趣阁.*?为你提供.*?更新|一秒记住.*',
      );
      final blankRule = ReplaceRule(
        id: 't2',
        name: '空行',
        pattern: r'\n{3,}',
        replacement: '\n\n',
      );

      final out = ReplaceService.applyWithRules(
        ReplacePresetLibrary.sampleText,
        [adRule, blankRule],
      );

      expect(out, isNot(contains('笔趣阁')));
      expect(out, isNot(contains('一秒记住')));
      expect(out, contains('正文内容开始'));
    });

    test('applyWithRules skips disabled rules', () {
      final rule = ReplaceRule(
        id: 't1',
        name: 'remove',
        pattern: '正文',
        replacement: '',
        isEnabled: false,
      );
      final out = ReplaceService.applyWithRules('正文测试', [rule]);
      expect(out, '正文测试');
    });

    test('applyWithRules supports plain text replace', () {
      final rule = ReplaceRule(
        id: 't1',
        name: 'space',
        pattern: '\u3000',
        replacement: ' ',
        isRegex: false,
      );
      final out = ReplaceService.applyWithRules('全角\u3000空格', [rule]);
      expect(out, '全角 空格');
    });

    test('builtInRules returns non-empty defaults', () {
      final rules = ReplaceService.builtInRules();
      expect(rules, isNotEmpty);
      expect(rules.every((r) => r.isEnabled), isTrue);
    });
  });

  group('ReplacePresetLibrary', () {
    test('grouped contains expected categories', () {
      final groups = ReplacePresetLibrary.grouped();
      expect(groups.keys, contains('广告脚注'));
      expect(groups.keys, contains('格式整理'));
      expect(ReplacePresetLibrary.all.length, greaterThanOrEqualTo(6));
    });

    test('toRules generates unique preset ids', () {
      final rules = ReplacePresetLibrary.toRules(ReplacePresetLibrary.all);
      expect(rules.map((r) => r.id).toSet().length, rules.length);
    });
  });
}
