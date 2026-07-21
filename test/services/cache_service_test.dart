import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/help/book_help.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/models/replace_rule.dart';
import 'package:legado_flutter/services/app_paths.dart';
import 'package:legado_flutter/services/cache_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempRoot;
  final service = CacheService();

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('legado_cache_test_');
    SharedPreferences.setMockInitialValues({});
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('CacheStats formats byte labels', () {
    const stats = CacheStats(
      bookCacheBytes: 512,
      dbBytes: 2048,
      backupsBytes: 3 * 1024 * 1024,
    );
    expect(stats.bookCacheLabel, '512 B');
    expect(stats.dbLabel, '2.0 KB');
    expect(stats.backupsLabel, '3.00 MB');
    expect(stats.totalBytes, 512 + 2048 + 3 * 1024 * 1024);
  });

  test('CacheService loadStats and clearBookCache', () async {
    final cacheDir = await AppPaths.bookCacheDir();
    final sample = File(p.join(cacheDir.path, 'sample.txt'));
    await sample.writeAsString('hello cache');

    final dbFile = File(await AppPaths.dbPath());
    await dbFile.writeAsString('db');

    final statsBefore = await service.loadStats();
    expect(statsBefore.bookCacheBytes, greaterThan(0));
    expect(statsBefore.dbBytes, greaterThan(0));

    await service.clearBookCache();
    expect(await sample.exists(), isFalse);

    final statsAfter = await service.loadStats();
    expect(statsAfter.bookCacheBytes, 0);
    expect(statsAfter.dbBytes, greaterThan(0));
  });

  test('CacheService clearBackups removes backup files', () async {
    final backupsDir = await AppPaths.backupsDir();
    final backup = File(p.join(backupsDir.path, 'backup.json'));
    await backup.writeAsString('{}');

    expect((await service.loadStats()).backupsBytes, greaterThan(0));
    await service.clearBackups();
    expect(await backup.exists(), isFalse);
    expect((await service.loadStats()).backupsBytes, 0);
  });

  test(
    'BookHelp isolates chapter files by book and deletes one chapter only',
    () async {
      await BookHelp.saveContent('book-a', 'chapter/1', 'A 内容');
      await BookHelp.saveContent('book-b', 'chapter/1', 'B 内容');

      expect(await BookHelp.getCachedContent('book-a', 'chapter/1'), 'A 内容');
      expect(await BookHelp.getCachedContent('book-b', 'chapter/1'), 'B 内容');

      await BookHelp.deleteChapterContent('book-a', 'chapter/1');
      expect(await BookHelp.getCachedContent('book-a', 'chapter/1'), isNull);
      expect(await BookHelp.getCachedContent('book-b', 'chapter/1'), 'B 内容');
    },
  );

  test('ContentProcessor applies the current enabled replacement rules', () {
    final processor = ContentProcessor.instance;
    processor.loadRules([
      ReplaceRule(
        id: 'cache-test-remove',
        name: 'remove marker',
        pattern: '[广告]',
        replacement: '',
        isRegex: false,
      ),
    ]);
    expect(processor.getContent('正文[广告]内容'), '正文内容');

    processor.loadRules(const []);
    expect(processor.getContent('正文[广告]内容'), '正文[广告]内容');
  });
}
