import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/config/app_config.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_progress_sync_store.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/domain/reader/book_progress.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/infrastructure/reader/reader_progress_sync_port_adapter.dart';
import 'package:legado_flutter/services/book_progress_sync.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _MemoryProgressStore store;
  late _FakeWebDavRepository webdav;
  late ReaderProgressSyncPortAdapter port;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.resetForTest();
    store = _MemoryProgressStore();
    webdav = _FakeWebDavRepository();
    port = ReaderProgressSyncPortAdapter(
      progressSync: BookProgressSync(webdav: webdav, store: store),
    );
  });

  Future<void> configureWebDav() {
    return WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'reader',
        password: 'secret',
        dir: '/legado',
      ),
    );
  }

  test('reports the existing WebDAV configuration gate', () async {
    await WebDavPrefs.save(
      const WebDavConfig(url: 'https://dav.example.com/dav'),
    );
    expect(await port.isConfigured(), isFalse);

    await configureWebDav();
    expect(await port.isConfigured(), isTrue);
  });

  test(
    'returns remote progress without changing conflict position data',
    () async {
      await configureWebDav();
      const remote = BookProgress(
        name: 'Reader',
        author: 'Author',
        durChapterIndex: 4,
        durChapterPos: 65537,
        durChapterTime: 123456,
        durChapterTitle: 'Chapter 5',
      );
      webdav.downloadData = utf8.encode(jsonEncode(remote.toJson()));

      final result = await port.getBookProgress(
        Book(id: 'book-1', name: remote.name, author: remote.author),
      );

      expect(result, isNotNull);
      expect(result!.toJson(), remote.toJson());
      expect(
        result.isBehind(chapterIndex: 4, chapterPos: remote.durChapterPos + 1),
        isTrue,
      );
      expect(
        result.isAheadOf(chapterIndex: 4, chapterPos: remote.durChapterPos - 1),
        isTrue,
      );
      expect(webdav.downloadPaths, ['/legado/bookProgress/Reader_Author.json']);
    },
  );

  test(
    'preserves conditional upload retry and post-success sync time',
    () async {
      await configureWebDav();
      const progress = BookProgress(
        name: 'Reader',
        author: 'Author',
        durChapterIndex: 7,
        durChapterPos: 70001,
        durChapterTime: 234567,
        durChapterTitle: 'Chapter 8',
      );
      webdav.etags.addAll(['"stale"', '"fresh"']);
      webdav.failFirstConditionalUpload = true;

      await port.uploadBookProgress(progress, toast: true);

      expect(webdav.attemptedEtags, ['"stale"', '"fresh"']);
      expect(webdav.uploadedPaths, [
        '/legado/bookProgress/Reader_Author.json',
        '/legado/bookProgress/Reader_Author.json',
      ]);
      expect(
        jsonDecode(utf8.decode(webdav.uploadedData.last)),
        progress.toJson(),
      );
      expect(
        await store.read(BookProgressSync.syncTimeKey('Reader', 'Author')),
        greaterThan(0),
      );
    },
  );
}

final class _MemoryProgressStore implements BookProgressSyncStore {
  final Map<String, int> _values = {};

  @override
  Future<int?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, int value) async {
    _values[key] = value;
  }
}

final class _FakeWebDavRepository implements WebDavRepository {
  List<int> downloadData = const [];
  final List<String> downloadPaths = [];
  final List<String> etags = [];
  final List<String?> attemptedEtags = [];
  final List<String> uploadedPaths = [];
  final List<List<int>> uploadedData = [];
  bool failFirstConditionalUpload = false;

  Never _unexpected(String operation) =>
      throw UnsupportedError('Unexpected WebDAV $operation');

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async => _unexpected('check');

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async => _unexpected('delete');

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async {
    downloadPaths.add(remotePath);
    return downloadData;
  }

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async => _unexpected('ensureDir');

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    final etag = etags.removeAt(0);
    return [
      WebDavEntry(
        name: 'Reader_Author.json',
        path: '${path}Reader_Author.json',
        isDir: false,
        size: uploadedData.isEmpty ? 0 : uploadedData.last.length,
        lastModified: 0,
        etag: etag,
      ),
    ];
  }

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) async => _unexpected('move');

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) async => _unexpected('upload');

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) async {
    attemptedEtags.add(etag);
    uploadedPaths.add(remotePath);
    uploadedData.add(List<int>.of(data));
    if (failFirstConditionalUpload && attemptedEtags.length == 1) {
      throw StateError('HTTP 412 Precondition Failed');
    }
  }
}
