import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/book/batch_book_progress_sync_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/reader/book_progress.dart';
import 'package:legado_flutter/infrastructure/book/batch_book_progress_sync_port_adapter.dart';
import 'package:legado_flutter/services/book_progress_sync.dart';

import '../../helpers/sync_test_ports.dart';

void main() {
  test(
    'forwards books and waits for the unchanged async apply callback',
    () async {
      final service = _RecordingBookProgressSync();
      final port = BatchBookProgressSyncPortAdapter(progressSync: service);
      final books = <Book>[
        Book(id: 'book-1', name: 'Reader', author: 'Author'),
      ];
      final applyStarted = Completer<void>();
      final releaseApply = Completer<void>();
      var completed = false;

      Future<void> apply(Book book, BookProgress progress) async {
        expect(identical(book, service.callbackBook), isTrue);
        expect(identical(progress, service.callbackProgress), isTrue);
        applyStarted.complete();
        await releaseApply.future;
      }

      final result = port
          .downloadAllBookProgress(books: books, apply: apply)
          .whenComplete(() => completed = true);

      await applyStarted.future;
      expect(identical(service.books, books), isTrue);
      expect(identical(service.apply, apply), isTrue);
      expect(completed, isFalse);

      releaseApply.complete();
      expect(await result, 1);
      expect(completed, isTrue);
    },
  );

  test('does not swallow errors from the existing sync service', () async {
    final service = _RecordingBookProgressSync(error: StateError('offline'));
    final port = BatchBookProgressSyncPortAdapter(progressSync: service);

    await expectLater(
      port.downloadAllBookProgress(
        books: const <Book>[],
        apply: (book, progress) async {},
      ),
      throwsA(isA<StateError>()),
    );
  });
}

final class _RecordingBookProgressSync extends BookProgressSync {
  _RecordingBookProgressSync({this.error})
    : super(
        webdav: const UnsupportedWebDavRepository(),
        store: MemoryBookProgressSyncStore(),
      );

  final Object? error;
  Iterable<Book>? books;
  BatchBookProgressApply? apply;
  final Book callbackBook = Book(
    id: 'remote-book',
    name: 'Remote Reader',
    author: 'Remote Author',
  );
  final BookProgress callbackProgress = const BookProgress(
    name: 'Remote Reader',
    author: 'Remote Author',
    durChapterIndex: 4,
    durChapterPos: 65537,
    durChapterTime: 123456,
    durChapterTitle: 'Chapter 5',
  );

  @override
  Future<int> downloadAllBookProgress({
    required Iterable<Book> books,
    required Future<void> Function(Book book, BookProgress progress) apply,
    WebDavListInvoker? list,
    WebDavDownloadInvoker? download,
    int Function()? nowMillis,
  }) async {
    this.books = books;
    this.apply = apply;
    if (error case final error?) throw error;
    await apply(callbackBook, callbackProgress);
    return 1;
  }
}
