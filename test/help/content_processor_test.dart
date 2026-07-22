import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/models/replace_rule.dart';

void main() {
  test('processForReading follows the original paragraph pipeline', () {
    final processor = ContentProcessor.instance;
    processor.loadRules([
      ReplaceRule(
        id: 'remove-ad',
        name: 'remove-ad',
        pattern: '广告词',
        replacement: '',
        isRegex: false,
      ),
    ]);

    final result = processor.processForReading(
      '第一章\n第一段广告词\n\n第二段',
      chapterTitle: '第一章',
      includeTitle: true,
      paragraphIndent: '　　',
      reSegment: false,
    );

    expect(result, '第一章\n　　第一段\n　　第二段');
  });
}
