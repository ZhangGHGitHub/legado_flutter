import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/content_processing_port.dart';

void main() {
  group('ContentProcessingSourceRules Freezed contract', () {
    test('keeps empty replacement defaults', () {
      const rules = ContentProcessingSourceRules();

      expect(rules.contentReplace, isEmpty);
      expect(rules.contentReplaceTo, isEmpty);
    });

    test('preserves source replacement fields and value equality', () {
      const first = ContentProcessingSourceRules(
        contentReplace: '广告',
        contentReplaceTo: '',
      );
      const second = ContentProcessingSourceRules(
        contentReplace: '广告',
        contentReplaceTo: '',
      );

      expect(first, equals(second));
      expect(first.contentReplace, '广告');
      expect(first.contentReplaceTo, isEmpty);
    });

    test('supports replacing either source rule field through copyWith', () {
      const original = ContentProcessingSourceRules(
        contentReplace: '旧正文',
        contentReplaceTo: '新正文',
      );

      final updated = original.copyWith(contentReplaceTo: '');

      expect(updated.contentReplace, '旧正文');
      expect(updated.contentReplaceTo, isEmpty);
    });
  });
}
