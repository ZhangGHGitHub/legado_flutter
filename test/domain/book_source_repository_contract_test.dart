import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';

void main() {
  test('SQLite source adapter satisfies the source repository port', () {
    final BookSourceRepository repository = SourceDao();

    expect(repository, isA<SourceDao>());
  });
}
