import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/content/replace_rule.dart';
import 'package:legado_flutter/infrastructure/source_rules/replace_preview_port_adapter.dart';

void main() {
  test('preserves replacement preview output and invalid-rule fallback', () {
    const adapter = ReplacePreviewPortAdapter();
    final rules = [
      ReplaceRule(
        id: 'remove',
        name: 'remove',
        pattern: '广告',
        replacement: '',
        isRegex: false,
      ),
      ReplaceRule(id: 'invalid', name: 'invalid', pattern: '['),
    ];

    expect(adapter.defaultSampleText, isNotEmpty);
    expect(adapter.apply('正文广告', rules), '正文');
  });
}
