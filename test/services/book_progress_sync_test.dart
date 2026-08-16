import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/config/app_config.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/domain/reader/book_progress.dart';
import 'package:legado_flutter/services/book_progress_sync.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';

import '../helpers/sync_test_ports.dart';

void main() {
  late MemoryBookProgressSyncStore store;
  late BookProgressSync sync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.resetForTest();
    store = MemoryBookProgressSyncStore();
    sync = BookProgressSync(
      webdav: const UnsupportedWebDavRepository(),
      store: store,
    );
  });

  const remote = BookProgress(
    name: '测试书',
    author: '作者',
    durChapterIndex: 8,
    durChapterPos: 120,
    durChapterTime: 200,
    durChapterTitle: '第九章',
  );

  test('sync time is persisted per book progress file', () async {
    expect(await sync.loadSyncTime('测试书', '作者'), 0);

    await sync.saveSyncTime('测试书', '作者', syncTime: 1234);

    expect(await sync.loadSyncTime('测试书', '作者'), 1234);
    expect(await sync.loadSyncTime('另一本书', '作者'), 0);
  });

  test('sync time uses the injected persistence boundary', () async {
    final injectedStore = MemoryBookProgressSyncStore();
    final injectedSync = BookProgressSync(
      webdav: const UnsupportedWebDavRepository(),
      store: injectedStore,
    );

    await injectedSync.saveSyncTime('注入书', '作者', syncTime: 1234);

    expect(await injectedSync.loadSyncTime('注入书', '作者'), 1234);
    expect(
      injectedStore.values,
      containsPair('webdav_book_progress_sync_注入书_作者.json', 1234),
    );
  });

  test('progress sync requires complete WebDAV credentials', () async {
    await WebDavPrefs.save(
      const WebDavConfig(url: 'https://dav.example.com/dav'),
    );

    var called = false;
    final result = await sync.downloadAllBookProgress(
      books: const [],
      list:
          ({
            required String url,
            required String username,
            required String password,
            required String path,
          }) async {
            called = true;
            return const [];
          },
      apply: (book, progress) async {},
    );

    expect(result, 0);
    expect(called, isFalse);
    expect(await sync.isConfigured(), isFalse);
  });

  test('unchanged remote file is skipped before progress comparison', () {
    final decision = BookProgressSync.decideRemoteProgress(
      remote: remote,
      remoteLastModified: 100,
      localSyncTime: 100,
      localChapterIndex: 1,
      localChapterPos: 0,
    );

    expect(decision, BookProgressSyncDecision.skipUnchangedRemote);
  });

  test('newer remote file is applied only when its position is ahead', () {
    expect(
      BookProgressSync.decideRemoteProgress(
        remote: remote,
        remoteLastModified: 101,
        localSyncTime: 100,
        localChapterIndex: 1,
        localChapterPos: 0,
      ),
      BookProgressSyncDecision.applyRemote,
    );
    expect(
      BookProgressSync.decideRemoteProgress(
        remote: remote,
        remoteLastModified: 101,
        localSyncTime: 100,
        localChapterIndex: 8,
        localChapterPos: 120,
      ),
      BookProgressSyncDecision.keepLocal,
    );
  });

  test(
    'batch download applies a newer remote file and records its sync time',
    () async {
      await WebDavPrefs.save(
        const WebDavConfig(
          url: 'https://dav.example.com/dav',
          account: 'account',
          password: 'password',
          dir: '/legado',
        ),
      );
      final book = Book(
        id: 'book-1',
        name: '测试书',
        author: '作者',
        totalChapterNum: 20,
        durChapterIndex: 2,
        currentPageIndex: 1,
      );
      final fileName = BookProgressSync.progressFileName(
        book.name,
        book.author,
      );
      Book? appliedBook;
      BookProgress? appliedProgress;

      final count = await sync.downloadAllBookProgress(
        books: [book],
        list:
            ({
              required String url,
              required String username,
              required String password,
              required String path,
            }) async {
              expect(path, '/legado/bookProgress/');
              return [
                WebDavEntry(
                  name: fileName,
                  path: '/legado/bookProgress/$fileName',
                  isDir: false,
                  size: 100,
                  lastModified: 200,
                ),
              ];
            },
        download:
            ({
              required String url,
              required String username,
              required String password,
              required String remotePath,
            }) async {
              expect(remotePath, '/legado/bookProgress/$fileName');
              return Uint8List.fromList(
                utf8.encode(jsonEncode(remote.toJson())),
              );
            },
        nowMillis: () => 300,
        apply: (book, progress) async {
          appliedBook = book;
          appliedProgress = progress;
        },
      );

      expect(count, 1);
      expect(appliedBook?.id, 'book-1');
      expect(appliedProgress?.durChapterIndex, 8);
      expect(await sync.loadSyncTime('测试书', '作者'), 300);
    },
  );

  test('upload writes progress JSON and records its sync time', () async {
    await WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
    String? uploadedPath;
    String? uploadedJson;

    await sync.uploadBookProgress(
      remote,
      upload:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
            required List<int> data,
          }) async {
            expect(url, 'https://dav.example.com/dav');
            expect(username, 'account');
            expect(password, 'password');
            uploadedPath = remotePath;
            uploadedJson = utf8.decode(data);
          },
      nowMillis: () => 400,
    );

    expect(uploadedPath, '/legado/bookProgress/测试书_作者.json');
    expect(jsonDecode(uploadedJson!), remote.toJson());
    expect(await sync.loadSyncTime('测试书', '作者'), 400);
  });

  test('disabled progress sync does not upload or update sync time', () async {
    await WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
    await AppConfig.instance.setSyncBookProgress(false);
    var called = false;

    await sync.uploadBookProgress(
      remote,
      upload:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
            required List<int> data,
          }) async {
            called = true;
          },
      nowMillis: () => 500,
    );

    expect(called, isFalse);
    expect(await sync.loadSyncTime('测试书', '作者'), 0);
  });
}
