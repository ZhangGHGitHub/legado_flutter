import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/book_help.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/models/book.dart';
import 'package:legado_flutter/models/chapter.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:legado_flutter/services/book_cache_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;
  const service = BookCacheExportService(
    contentCache: FileChapterContentCache(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('legado_cache_export_');
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('buildText exports cached chapters in index order', () async {
    final book = Book(id: 'book-1', name: '测试书', author: '作者');
    final chapters = [
      Chapter(id: 'c2', bookId: book.id, title: '第二章', index: 1, url: 'u2'),
      Chapter(id: 'c1', bookId: book.id, title: '第一章', index: 0, url: 'u1'),
    ];
    await BookHelp.saveContent(book.id, 'c2', '第二章正文');
    await BookHelp.saveContent(book.id, 'c1', '第一章正文');

    final text = await service.buildText(book: book, chapters: chapters);

    expect(text.indexOf('第一章'), lessThan(text.indexOf('第二章')));
    expect(text, contains('第一章正文'));
    expect(text, contains('第二章正文'));
  });

  test('buildText returns empty when no chapter is cached', () async {
    final book = Book(id: 'book-2', name: '未缓存');
    final chapters = [
      Chapter(id: 'c1', bookId: book.id, title: '第一章', index: 0, url: 'u1'),
    ];

    expect(await service.buildText(book: book, chapters: chapters), isEmpty);
  });
}
