import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/domain/repositories/book_repository.dart';

void main() {
  test('SQLite book adapter satisfies the domain repository port', () {
    final BookRepository repository = BookDao();

    expect(repository, isA<BookDao>());
  });
}
