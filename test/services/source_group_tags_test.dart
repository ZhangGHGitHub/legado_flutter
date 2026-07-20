import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/source_group_tags.dart';

void main() {
  test('split handles comma and Chinese comma', () {
    expect(splitSourceGroups('A, B，C'), ['A', 'B', 'C']);
  });

  test('add does not duplicate', () {
    expect(addSourceGroupTag('A,B', 'A'), 'A,B');
    expect(addSourceGroupTag('A', 'B'), 'A,B');
  });

  test('remove keeps others', () {
    expect(removeSourceGroupTag('A,B,C', 'B'), 'A,C');
  });

  test('rename updates one tag', () {
    expect(renameSourceGroupTag('A,B', 'A', 'X'), 'X,B');
  });

  test('has tag', () {
    expect(sourceHasGroupTag('A,B', 'B'), true);
    expect(sourceHasGroupTag('A,B', 'C'), false);
  });
}
