import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/features/book/toc_sheet.dart';

class _BlockingCache implements ChapterContentCachePort {
  final listed = Completer<Set<String>>();
  int wordCountCalls = 0;

  @override
  Future<String?> get(String bookId, String chapterId) async => null;

  @override
  Future<void> save(String bookId, String chapterId, String content) async {}

  @override
  Future<void> delete(String bookId, String chapterId) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearBook(String bookId) async {}

  @override
  Future<int> clearInvalid(Set<String> validBookIds) async => 0;

  @override
  Future<bool> has(String bookId, String chapterId) async => false;

  @override
  Future<Set<String>> listChapterIds(String bookId) => listed.future;

  @override
  String sanitizeChapterId(String chapterId) => chapterId;

  @override
  Future<Map<String, int>> mapWordCounts(
    String bookId, {
    Set<String>? chapterIds,
  }) async {
    wordCountCalls++;
    return {};
  }

  @override
  Future<({int bytes, int chapterFiles})> stats(String bookId) async =>
      (bytes: 0, chapterFiles: 0);
}

List<Chapter> _chapters() => List.generate(
  30,
  (index) => Chapter(
    id: 'chapter-$index',
    bookId: 'book-1',
    title: '章节 $index',
    index: index,
    url: 'https://example.test/$index',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'first frame renders directory without waiting for cache metadata',
    (tester) async {
      final cache = _BlockingCache();
      await tester.pumpWidget(
        MaterialApp(
          home: TocSheet(
            chapters: _chapters(),
            bookId: 'book-1',
            contentCache: cache,
            onChapterTap: (_, {pageIndex, chapterPos}) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('章节 0'), findsOneWidget);
      expect(find.text('章节 1'), findsOneWidget);
      expect(cache.wordCountCalls, 0);

      cache.listed.complete({});
      await tester.pump();
    },
  );
}
