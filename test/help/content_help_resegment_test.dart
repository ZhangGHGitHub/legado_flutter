import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/content_help.dart';

void main() {
  test(
    'reSegment expands captured punctuation instead of literal dollar groups',
    () {
      final result = ContentHelp.reSegment('他说。', '');

      expect(result, '他说。\n');
      expect(result, contains('说'));
    },
  );
}
