import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/replace/replace_preset_port_adapter.dart';

void main() {
  final port = const ReplacePresetPortAdapter();

  test('内置规则只保留四条并维持 service 的顺序和唯一 id', () {
    final rules = port.builtInRules();

    expect(rules.map((rule) => rule.id).toList(), [
      'preset_ad_biquge',
      'preset_ad_shuwu',
      'preset_ad_next_page',
      'preset_fmt_blank_lines',
    ]);
    expect(rules, hasLength(4));
    expect(rules.map((rule) => rule.id).toSet(), hasLength(rules.length));
    expect(rules.every((rule) => rule.isEnabled), isTrue);
  });

  test('保留预置规则顺序和分组顺序', () {
    final presets = port.all;
    final groups = port.grouped();

    expect(presets, isNotEmpty);
    expect(presets.map((preset) => preset.id).toList(), [
      'ad_biquge',
      'ad_shuwu',
      'ad_next_page',
      'ad_domain',
      'fmt_blank_lines',
      'fmt_spaces',
      'sym_fullwidth_space',
      'sym_zero_width',
    ]);
    expect(groups.keys.toList(), ['广告脚注', '页面提示', '格式整理', '特殊符号']);
    expect(
      groups.values
          .expand((items) => items)
          .map((preset) => preset.id)
          .toList(),
      presets.map((preset) => preset.id).toList(),
    );
  });

  test('预置规则转换保留正则和替换语义并生成唯一 id', () {
    final rules = port.toRules(port.all);

    expect(rules, hasLength(port.all.length));
    expect(rules.map((rule) => rule.id).toSet(), hasLength(rules.length));
    expect(rules[4].replacement, '\n\n');
    expect(rules[6].isRegex, isFalse);
    expect(rules[6].replacement, ' ');
    expect(rules.every((rule) => rule.isEnabled), isTrue);
  });
}
