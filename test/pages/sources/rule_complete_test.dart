import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/features/sources/rule_complete.dart';

void main() {
  test('currentToken extracts trailing rule fragment', () {
    expect(RuleComplete.currentToken('foo @cs', 7), '@cs');
    expect(RuleComplete.currentToken('a.class', 7), 'a.class');
  });

  test('suggestions match prefix', () {
    final s = RuleComplete.suggestions('@cs');
    expect(s.any((e) => e.key == '@css:'), isTrue);
  });

  test('applySnippet places cursor inside paired markers', () {
    const value = TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    final js = RuleComplete.applySnippet(value, '<js></js>');
    expect(js.text, '<js></js>');
    expect(js.selection.baseOffset, 4);

    final brace = RuleComplete.applySnippet(value, '{{}}');
    expect(brace.selection.baseOffset, 2);
  });

  test('applySnippet replaces completing token', () {
    const value = TextEditingValue(
      text: '@cs',
      selection: TextSelection.collapsed(offset: 3),
    );
    final next = RuleComplete.applySnippet(value, '@css:');
    expect(next.text, '@css:');
  });
}
