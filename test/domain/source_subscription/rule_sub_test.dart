import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/source_subscription/rule_sub.dart';

void main() {
  test('保留默认值和 nullable 字段', () {
    const ruleSub = RuleSub(id: 1);

    expect(ruleSub.name, '');
    expect(ruleSub.url, '');
    expect(ruleSub.type, 0);
    expect(ruleSub.customOrder, 0);
    expect(ruleSub.autoUpdate, isFalse);
    expect(ruleSub.update, 0);
    expect(ruleSub.updateInterval, 0);
    expect(ruleSub.silentUpdate, isFalse);
    expect(ruleSub.js, isNull);
    expect(ruleSub.showRule, isNull);
    expect(ruleSub.sourceUrl, isNull);
  });

  test('fromJson and toJson preserve every field', () {
    const json = <String, dynamic>{
      'id': 9,
      'name': '完整订阅',
      'url': 'https://example.com/rules.json',
      'type': 2,
      'customOrder': 3,
      'autoUpdate': true,
      'update': 123,
      'updateInterval': 24,
      'silentUpdate': true,
      'js': 'return data;',
      'showRule': 'body',
      'sourceUrl': 'https://example.com/source',
    };

    final ruleSub = RuleSub.fromJson(json);

    expect(ruleSub.toJson(), json);
    expect(RuleSub.fromJson(ruleSub.toJson()), ruleSub);
  });

  test('fromJson uses fallback id and field defaults', () {
    final ruleSub = RuleSub.fromJson(const {'name': '无 ID'}, fallbackId: 42);

    expect(ruleSub.id, 42);
    expect(ruleSub.name, '无 ID');
    expect(ruleSub.url, '');
    expect(ruleSub.autoUpdate, isFalse);
    expect(ruleSub.js, isNull);
  });

  test('identity equality and hashCode use id only', () {
    const first = RuleSub(id: 7, name: '旧名称');
    const second = RuleSub(id: 7, name: '新名称');
    const different = RuleSub(id: 8, name: '新名称');

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(different));
  });

  test('copyWith preserves, replaces, and clears nullable fields', () {
    const original = RuleSub(
      id: 10,
      js: 'old-js',
      showRule: 'old-show-rule',
      sourceUrl: 'old-source-url',
    );

    final preserved = original.copyWith();
    final replaced = original.copyWith(
      name: '新名称',
      js: 'new-js',
      showRule: 'new-show-rule',
      sourceUrl: 'new-source-url',
    );
    final cleared = original.copyWith(
      js: null,
      showRule: null,
      sourceUrl: null,
    );

    expect(preserved, original);
    expect(replaced.name, '新名称');
    expect(replaced.js, 'new-js');
    expect(replaced.showRule, 'new-show-rule');
    expect(replaced.sourceUrl, 'new-source-url');
    expect(cleared.js, isNull);
    expect(cleared.showRule, isNull);
    expect(cleared.sourceUrl, isNull);
  });
}
