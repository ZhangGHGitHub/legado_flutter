import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/local_book_import_port.dart';

void main() {
  test('application import exception exposes the original display message', () {
    const exception = LocalBookImportPortException('文件过大');

    expect(exception.message, '文件过大');
    expect(exception.toString(), '文件过大');
  });
}
