import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/database/database_helper.dart';
import 'package:legado_flutter/infrastructure/database/rust_database_port.dart';

class _RecordingRustDatabasePort implements RustDatabasePort {
  int readyChecks = 0;
  (String, String, String, String)? updatedBookDetails;

  @override
  void requireReady() => readyChecks++;

  @override
  void updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) {
    updatedBookDetails = (bookId, name, author, description);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('BookDao forwards book details without rebuilding the book', () async {
    final port = _RecordingRustDatabasePort();
    final dao = BookDao(DatabaseHelper.forPort(port));

    await dao.updateBookDetails('book-1', '新书名', '新作者', '新简介');

    expect(port.readyChecks, 1);
    expect(port.updatedBookDetails, ('book-1', '新书名', '新作者', '新简介'));
  });
}
