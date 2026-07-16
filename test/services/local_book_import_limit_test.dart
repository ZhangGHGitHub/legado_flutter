import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/local_book_service.dart';

void main() {
  test('maxImportBytes is 50MB', () {
    expect(LocalBookService.maxImportBytes, 50 * 1024 * 1024);
  });

  test('LocalBookImportException message is actionable Chinese', () {
    const msg = '文件过大（60.0MB），本地导入上限为 50MB。请压缩、拆分后再导入，或改用体积更小的 TXT/EPUB。';
    final e = LocalBookImportException(msg);
    expect(e.toString(), contains('50MB'));
    expect(e.toString(), contains('压缩'));
  });
}
