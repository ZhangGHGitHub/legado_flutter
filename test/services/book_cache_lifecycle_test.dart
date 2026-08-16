import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/book_help.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('legado_cache_lifecycle_');
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('clearInvalidCache removes orphan book directories only', () async {
    await BookHelp.saveContent('valid/book', 'chapter-1', '有效正文');
    await BookHelp.saveContent('deleted/book', 'chapter-1', '孤立正文');

    final removed = await BookHelp.clearInvalidCache({'valid/book'});

    expect(removed, 1);
    expect(await BookHelp.getCachedContent('valid/book', 'chapter-1'), '有效正文');
    expect(
      await BookHelp.getCachedContent('deleted/book', 'chapter-1'),
      isNull,
    );
  });

  test(
    'clearInvalidCache with no books removes all book directories',
    () async {
      await BookHelp.saveContent('orphan-a', 'chapter-1', 'A');
      await BookHelp.saveContent('orphan-b', 'chapter-1', 'B');

      expect(await BookHelp.clearInvalidCache({}), 2);
      final cacheRoot = await AppPaths.bookCacheDir();
      expect((await cacheRoot.list().toList()).whereType<Directory>(), isEmpty);
    },
  );
}
