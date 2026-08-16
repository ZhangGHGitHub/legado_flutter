import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/database_helper.dart';
import 'package:legado_flutter/infrastructure/database/rust_database_port.dart';
import 'package:legado_flutter/domain/book/book.dart';

class _FakeRustDatabasePort implements RustDatabasePort {
  int readyChecks = 0;
  final List<String> books = [];
  String? insertedBook;
  (String, String, String, String)? updatedBookDetails;
  (String, String)? updatedCustomCover;

  @override
  void requireReady() => readyChecks++;

  @override
  void insertBook({required String bookJson}) => insertedBook = bookJson;

  @override
  List<String> getBooks() => List<String>.from(books);

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
  void updateBookCustomCover({
    required String bookId,
    required String customCoverUrl,
  }) {
    updatedCustomCover = (bookId, customCoverUrl);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test(
    'DatabaseHelper can use a port without importing the FRB database API',
    () async {
      final port = _FakeRustDatabasePort();
      final book = Book(id: 'book-1', name: '测试书');
      port.books.add(jsonEncode(book.toJson()));
      final database = DatabaseHelper.forPort(port);

      final books = await database.getBooks();
      await database.insertBook(book);

      expect(port.readyChecks, 2);
      expect(books.single.id, 'book-1');
      expect(jsonDecode(port.insertedBook!)['name'], '测试书');
    },
  );

  test(
    'DatabaseHelper forwards book details through the database port',
    () async {
      final port = _FakeRustDatabasePort();
      final database = DatabaseHelper.forPort(port);

      await database.updateBookDetails('book-1', '新书名', '新作者', '新简介');

      expect(port.readyChecks, 1);
      expect(port.updatedBookDetails, ('book-1', '新书名', '新作者', '新简介'));
    },
  );

  test(
    'DatabaseHelper forwards custom cover without touching source cover',
    () async {
      final port = _FakeRustDatabasePort();
      final database = DatabaseHelper.forPort(port);

      await database.updateBookCustomCover('book-1', legadoDefaultCoverMarker);

      expect(port.readyChecks, 1);
      expect(port.updatedCustomCover, ('book-1', legadoDefaultCoverMarker));
    },
  );
}
