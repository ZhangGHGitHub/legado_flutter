import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/ports/bookmark_port.dart';
import 'package:legado_flutter/infrastructure/reader/reader_bookmark_readiness_port_adapter.dart';
import 'package:legado_flutter/services/bookmark_service.dart';

void main() {
  const port = ReaderBookmarkReadinessPortAdapter();

  setUp(BookmarkService.resetBookmarkPort);
  tearDown(BookmarkService.resetBookmarkPort);

  test('is not ready before a bookmark port is configured', () {
    expect(port.isReady, isFalse);
  });

  test('reflects the configured bookmark port availability', () {
    final bookmarkPort = _FakeBookmarkPort(isAvailable: true);
    BookmarkService.configureBookmarkPort(bookmarkPort);

    expect(port.isReady, isTrue);

    bookmarkPort.isAvailable = false;

    expect(port.isReady, isFalse);
  });
}

final class _FakeBookmarkPort implements BookmarkPort {
  _FakeBookmarkPort({required this.isAvailable});

  @override
  bool isAvailable;

  @override
  bool delete(int time) => throw UnimplementedError();

  @override
  List<BookmarkSnapshot> list({String? bookId}) => throw UnimplementedError();

  @override
  bool save(BookmarkSnapshot bookmark) => throw UnimplementedError();
}
