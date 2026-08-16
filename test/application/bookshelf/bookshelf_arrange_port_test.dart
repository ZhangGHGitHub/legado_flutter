import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/bookshelf/bookshelf_arrange_port.dart';

void main() {
  test('returns an independent list when no saved order exists', () {
    final input = ['one', 'two'];

    final result = BookshelfArrangeOrderPolicy.apply(
      input,
      const [],
      (value) => value,
    );
    result.removeAt(0);

    expect(result, ['two']);
    expect(input, ['one', 'two']);
  });

  test('keeps saved order and appends unknown items', () {
    final result = BookshelfArrangeOrderPolicy.apply(
      ['new', 'saved-2', 'saved-1'],
      ['saved-1', 'saved-2'],
      (value) => value,
    );

    expect(result, ['saved-1', 'saved-2', 'new']);
  });
}
