import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';

void main() {
  group('Book Freezed contract', () {
    test('is const constructible, value comparable, and copyable', () {
      const first = Book(id: 'book-1', name: '书名');
      const second = Book(id: 'book-1', name: '书名');

      expect(first, equals(second));
      expect(first.copyWith(name: '新书名').name, '新书名');
      expect(first.toJson()['readConfig'], {'reverseToc': false});
    });

    test(
      'keeps legacy readConfig compatibility while preserving extra fields',
      () {
        final book = Book.fromJson({
          'id': 'book-1',
          'name': '书名',
          'readConfig': {'reverseToc': true, 'lineHeight': 1.5},
        });

        expect(book.readConfig.reverseToc, isTrue);
        expect(book.readConfig.extra['lineHeight'], 1.5);
        expect(book.toJson()['readConfig'], {
          'lineHeight': 1.5,
          'reverseToc': true,
        });
      },
    );
  });

  group('BookSource Freezed contract', () {
    test('is const constructible, value comparable, and copyable', () {
      const first = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '示例',
      );
      const second = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: '示例',
      );

      expect(first, equals(second));
      expect(first.copyWith(enabled: false).enabled, isFalse);
    });

    test('keeps nested Legado JSON and flat compatibility fields', () {
      final source = BookSource.fromJson({
        'bookSourceUrl': 'https://example.com',
        'bookSourceName': '示例',
        'ruleBookInfo': {'bookUrl': 'a'},
        'ruleContent': {'content': r'$.data.content'},
      });
      final roundTrip = BookSource.fromJson(source.toJson());

      expect(roundTrip.ruleBookUrlPattern, 'a');
      expect(roundTrip.ruleContentPath, r'$.data.content');
      expect(roundTrip.toJson()['ruleContent'], {'content': r'$.data.content'});
    });
  });
}
