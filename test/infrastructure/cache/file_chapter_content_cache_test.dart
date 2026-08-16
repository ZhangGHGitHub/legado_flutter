import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/chapter_content_cache_port.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;
  const cache = FileChapterContentCache();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('legado_chapter_cache_');
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('implements the chapter content cache port', () {
    expect(cache, isA<ChapterContentCachePort>());
  });

  test('get returns null for a missing chapter', () async {
    expect(await cache.get('book-1', 'chapter-1'), isNull);
  });

  test('save and get delegate to the BookHelp file cache', () async {
    await cache.save('book-1', 'chapter-1', '第一章正文');

    expect(await cache.get('book-1', 'chapter-1'), '第一章正文');
  });

  test(
    'delete removes a cached chapter and tolerates missing content',
    () async {
      await cache.save('book-1', 'chapter-1', '第一章正文');
      await cache.delete('book-1', 'chapter-1');

      expect(await cache.get('book-1', 'chapter-1'), isNull);
      await cache.delete('book-1', 'chapter-1');
    },
  );

  test('empty content keeps BookHelp empty-save behavior', () async {
    await cache.save('book-1', 'chapter-1', '');

    expect(await cache.get('book-1', 'chapter-1'), isNull);
  });

  test(
    'metadata operations preserve BookHelp identifiers and counts',
    () async {
      await cache.save('book-1', 'chapter/1', '一二三');
      await cache.save('book-1', 'chapter-2', '四五');

      expect(await cache.has('book-1', 'chapter/1'), isTrue);
      expect(
        await cache.listChapterIds('book-1'),
        containsAll(['chapter_1', 'chapter-2']),
      );
      expect(cache.sanitizeChapterId('chapter/1'), 'chapter_1');
      expect(await cache.mapWordCounts('book-1'), {
        'chapter_1': 3,
        'chapter-2': 2,
      });
      expect(await cache.stats('book-1'), (bytes: 15, chapterFiles: 2));
    },
  );

  test('clear operations delegate to the file cache lifecycle', () async {
    await cache.save('book-1', 'chapter-1', '正文');
    await cache.save('book-2', 'chapter-1', '正文');

    expect(await cache.clearInvalid({'book-1'}), 1);
    expect(await cache.has('book-2', 'chapter-1'), isFalse);
    await cache.clearBook('book-1');
    expect(await cache.has('book-1', 'chapter-1'), isFalse);

    await cache.save('book-3', 'chapter-1', '正文');
    await cache.clearAll();
    expect(await cache.has('book-3', 'chapter-1'), isFalse);
  });
}
