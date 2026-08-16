import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/infrastructure/bookshelf/remote_book_import_port_adapter.dart';

void main() {
  test(
    'keeps an immutable bookshelf snapshot and forwards path import',
    () async {
      const book = Book(id: 'book-1', name: '测试书');
      String? importedPath;
      String? importedName;

      final adapter = RemoteBookImportPortAdapter(
        books: () => [book],
        importLocalBookFromPath: (path, {required displayName}) async {
          importedPath = path;
          importedName = displayName;
          return book;
        },
      );

      expect(adapter.books, [book]);
      expect(() => adapter.books.add(book), throwsUnsupportedError);

      expect(
        await adapter.importLocalBookFromPath(
          r'C:\books\test.txt',
          displayName: 'test.txt',
        ),
        same(book),
      );
      expect(importedPath, r'C:\books\test.txt');
      expect(importedName, 'test.txt');
    },
  );
}
