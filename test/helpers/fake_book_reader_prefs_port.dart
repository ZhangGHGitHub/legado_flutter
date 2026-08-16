import 'package:legado_flutter/application/reader/book_reader_prefs_port.dart';

final class FakeBookReaderPrefsPort implements BookReaderPrefsPort {
  FakeBookReaderPrefsPort({this.pageAnim, this.reSegment = false});

  int? pageAnim;
  bool reSegment;
  final List<({String bookId, int value})> pageAnimWrites = [];
  final List<({String bookId, bool value})> reSegmentWrites = [];

  @override
  Future<int?> getPageAnim(String bookId) async => pageAnim;

  @override
  Future<void> setPageAnim(String bookId, int value) async {
    pageAnim = value;
    pageAnimWrites.add((bookId: bookId, value: value));
  }

  @override
  Future<bool> getReSegment(String bookId) async => reSegment;

  @override
  Future<void> setReSegment(String bookId, bool value) async {
    reSegment = value;
    reSegmentWrites.add((bookId: bookId, value: value));
  }
}
