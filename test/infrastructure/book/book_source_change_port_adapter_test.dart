import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/book/book_source_change_port_adapter.dart';

void main() {
  test('forwards source change and forced chapter refresh arguments', () async {
    const current = Book(id: 'book-1', name: '旧书');
    const selected = Book(id: 'book-1', name: '新书');
    const source = BookSource(
      bookSourceUrl: 'https://source.example',
      bookSourceName: '测试书源',
    );
    Book? changedCurrent;
    Book? changedSelected;
    BookSource? changedSource;
    Book? loadedBook;
    BookSource? loadedSource;
    bool? forced;

    final adapter = BookSourceChangePortAdapter(
      changeSource: (current, selected, {source}) async {
        changedCurrent = current;
        changedSelected = selected;
        changedSource = source;
        return selected;
      },
      loadChapters: (book, {required source, forceRefresh = false}) async {
        loadedBook = book;
        loadedSource = source;
        forced = forceRefresh;
      },
    );

    final updated = await adapter.changeSource(
      current,
      selected,
      source: source,
    );
    await adapter.loadChapters(updated, source: source, forceRefresh: true);

    expect(changedCurrent, current);
    expect(changedSelected, selected);
    expect(changedSource, source);
    expect(loadedBook, selected);
    expect(loadedSource, source);
    expect(forced, isTrue);
  });
}
