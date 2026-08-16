import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/book_read_status_policy.dart';

void main() {
  test('reading iteration labels preserve the existing Chinese policy', () {
    expect(BookReadStatusPolicy.labelForReadIteration(0), isNull);
    expect(BookReadStatusPolicy.labelForReadIteration(1), '读完');
    expect(BookReadStatusPolicy.labelForReadIteration(2), '2刷');
    expect(BookReadStatusPolicy.labelForReadIteration(3), '2刷完');
    expect(BookReadStatusPolicy.labelForReadIteration(4), '3刷');
  });
}
