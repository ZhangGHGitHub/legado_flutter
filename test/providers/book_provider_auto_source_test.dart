import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/book_dao.dart';
import 'package:legado_flutter/infrastructure/cache/file_chapter_content_cache.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/models/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import 'package:legado_flutter/providers/book_provider.dart';
import 'package:legado_flutter/services/app_paths.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyDao extends BookDao {
  @override
  Future<List<Book>> getAll() async => const [];

  @override
  Future<List<Chapter>> getChapters(String bookId) async => const [];
}

class _AutoSourceService extends TestBookSourceService {
  final Set<String> workingSources;

  _AutoSourceService(this.workingSources);

  @override
  Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    if (!workingSources.contains(source.bookSourceUrl)) return const [];
    return [
      {
        'name': keyword,
        'author': '作者',
        'url': '${source.bookSourceUrl}/book/1',
      },
    ];
  }

  @override
  Future<List<Chapter>> getChapters(
    Book book, {
    required BookSource source,
  }) async {
    if (!workingSources.contains(source.bookSourceUrl)) return const [];
    return [
      Chapter(
        id: '${book.id}-chapter',
        bookId: book.id,
        title: '当前章',
        index: 0,
        url: '${source.bookSourceUrl}/chapter/1',
      ),
    ];
  }

  @override
  Future<String> getChapterContent(
    String url, {
    required BookSource source,
  }) async {
    return workingSources.contains(source.bookSourceUrl) ? '可读正文' : '';
  }

  @override
  Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async => {};
}

BookSource _source(String url) =>
    BookSource(bookSourceUrl: url, bookSourceName: url);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempRoot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('legado_auto_source_');
    await AppDataPrefs.saveDataDir(tempRoot.path);
  });

  tearDown(() async {
    if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
  });

  test(
    'auto source picks first readable source and keeps chapter progress',
    () async {
      final current = Book(
        id: 'book-1',
        name: '测试书',
        author: '作者',
        bookSourceUrl: 'source-current',
        durChapterIndex: 0,
      );
      final source = _source('source-new');
      final provider = BookProvider(
        repository: _EmptyDao(),
        contentCache: const FileChapterContentCache(),
        sourceService: _AutoSourceService({source.bookSourceUrl}),
      );

      final updated = await provider.autoChangeSource(
        current,
        sources: [_source(current.bookSourceUrl), source],
      );

      expect(updated, isNotNull);
      expect(updated!.bookSourceUrl, source.bookSourceUrl);
      expect(provider.currentChapters.single.title, '当前章');
      expect(provider.currentChapters.single.bookId, updated.id);
    },
  );
}
