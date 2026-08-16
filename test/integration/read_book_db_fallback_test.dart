import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_db_bridge.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/database/database_helper.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/help/book_help.dart';
import 'package:legado_flutter/help/content_processor.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/infrastructure/content/content_processor_adapter.dart';
import 'package:legado_flutter/model/read_book.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/services/app_paths.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FallbackSourceService extends TestBookSourceService {
  int calls = 0;

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    calls++;
    return '网络正文';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;
  late DatabaseHelper db;
  late _FallbackSourceService service;
  late Book book;
  late Chapter chapter;
  late BookSource source;

  setUpAll(() async {
    await LegadoEngineBridge.tryInit();
    final dbRoot = await Directory.systemTemp.createTemp('legado_db_fallback_');
    await LegadoDbBridge.init(
      dbPathOverride: '${dbRoot.path}${Platform.pathSeparator}legado.db',
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp(
      'legado_db_fallback_cache_',
    );
    await AppDataPrefs.saveDataDir(tempRoot.path);
    db = DatabaseHelper();
    service = _FallbackSourceService();
    book = Book(id: 'db-fallback-book', name: '数据库回落测试');
    chapter = Chapter(
      id: 'db-fallback-chapter',
      bookId: book.id,
      title: '第一章',
      index: 0,
      url: '/chapter-1',
      isDownloaded: true,
      content: '数据库正文',
    );
    source = BookSource(
      bookSourceUrl: 'db-fallback-source',
      bookSourceName: 'db-fallback-source',
    );
    ReadBook.instance.reset();
    ReadBook.instance.configureDependencies(
      sourceService: service,
      repository: BookDao(db),
      contentProcessor: ContentProcessorAdapter(
        processor: ContentProcessor.instance,
      ),
      contentCache: const FileChapterContentCache(),
    );
    await db.insertBook(book);
    await db.insertChapters([chapter]);
    await BookHelp.deleteChapterContent(book.id, chapter.id);
  });

  tearDown(() async {
    ReadBook.instance.reset();
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test('DB正文回落 avoids network and restores the file cache', () async {
    final content = await ReadBook.instance.loadChapterContent(
      chapter: chapter,
      source: source,
      bookId: book.id,
    );

    expect(content, '数据库正文');
    expect(service.calls, 0);
    expect(await BookHelp.getCachedContent(book.id, chapter.id), '数据库正文');
  });

  test('placeholder DB正文 is skipped and network is retried', () async {
    await db.clearChapterContent(chapter);
    await db.insertChapters([
      Chapter(
        id: chapter.id,
        bookId: chapter.bookId,
        title: chapter.title,
        index: chapter.index,
        url: chapter.url,
        isDownloaded: true,
        content: '（此章节暂无内容）',
      ),
    ]);

    final content = await ReadBook.instance.loadChapterContent(
      chapter: chapter,
      source: source,
      bookId: book.id,
      saveCache: false,
    );

    expect(content, '网络正文');
    expect(service.calls, 1);
  });
}
