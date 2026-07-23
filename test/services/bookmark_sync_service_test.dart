import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/services/bookmark_sync_service.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:legado_flutter/src/rust/api.dart' as rust_api;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const local = [
    rust_api.BookmarkDto(
      time: 1,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 1,
      chapterPos: 10,
      chapterName: '第二章',
      bookText: '本地',
      content: '',
    ),
    rust_api.BookmarkDto(
      time: 2,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 2,
      chapterPos: 20,
      chapterName: '第三章',
      bookText: '仅本地',
      content: '',
    ),
  ];
  const remote = [
    rust_api.BookmarkDto(
      time: 1,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 3,
      chapterPos: 30,
      chapterName: '第四章',
      bookText: '远端更新',
      content: '',
    ),
    rust_api.BookmarkDto(
      time: 3,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 4,
      chapterPos: 40,
      chapterName: '第五章',
      bookText: '仅远端',
      content: '',
    ),
  ];

  test('upload merges remote bookmarks before writing bookmark.json', () async {
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

    final count = await BookmarkSyncService.uploadMerged(
      local: local,
      download:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
          }) async {
            return utf8.encode(BookmarkService.encodeJson(remote));
          },
      upload:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
            required List<int> data,
          }) async {
            uploadedPath = remotePath;
            uploadedJson = utf8.decode(data);
          },
    );

    expect(count, 3);
    expect(uploadedPath, '/legado/bookmark.json');
    final merged = BookmarkService.decodeJson(uploadedJson!);
    expect(merged.map((bookmark) => bookmark.time), [1, 2, 3]);
    expect(merged.first.bookText, '远端更新');
  });

  test('upload creates bookmark.json when remote file is missing', () async {
    await WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
    String? uploadedJson;

    final count = await BookmarkSyncService.uploadMerged(
      local: local,
      download:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
          }) async {
            throw StateError('下载失败: HTTP 404');
          },
      upload:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
            required List<int> data,
          }) async {
            uploadedJson = utf8.decode(data);
          },
    );

    expect(count, 2);
    expect(BookmarkService.decodeJson(uploadedJson!), local);
  });

  test('download merges remote bookmarks before applying locally', () async {
    await WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
    String? appliedJson;

    final count = await BookmarkSyncService.downloadAndMerge(
      local: local,
      download:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
          }) async {
            return utf8.encode(BookmarkService.encodeJson(remote));
          },
      apply: (json) async {
        appliedJson = json;
      },
    );

    expect(count, 3);
    expect(BookmarkService.decodeJson(appliedJson!).first.bookText, '远端更新');
  });

  test('bookmark sync rejects incomplete WebDAV config', () async {
    await WebDavPrefs.save(
      const WebDavConfig(url: 'https://dav.example.com/dav'),
    );
    expect(
      () => BookmarkSyncService.downloadAndMerge(
        local: const [],
        apply: (json) async {},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('concurrent uploads are serialized within the app process', () async {
    await WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
    final firstDownloadEntered = Completer<void>();
    final releaseFirstDownload = Completer<void>();
    var downloadCalls = 0;
    var activeOperations = 0;
    var maximumActiveOperations = 0;

    Future<void> enterOperation() async {
      activeOperations++;
      if (activeOperations > maximumActiveOperations) {
        maximumActiveOperations = activeOperations;
      }
    }

    Future<void> leaveOperation() async {
      activeOperations--;
    }

    Future<List<int>> download({
      required String url,
      required String username,
      required String password,
      required String remotePath,
    }) async {
      downloadCalls++;
      await enterOperation();
      if (downloadCalls == 1) {
        firstDownloadEntered.complete();
        await releaseFirstDownload.future;
      }
      await leaveOperation();
      return utf8.encode(BookmarkService.encodeJson(const []));
    }

    Future<void> upload({
      required String url,
      required String username,
      required String password,
      required String remotePath,
      required List<int> data,
    }) async {
      await enterOperation();
      await Future<void>.delayed(Duration.zero);
      await leaveOperation();
    }

    final first = BookmarkSyncService.uploadMerged(
      local: const [],
      download: download,
      upload: upload,
    );
    await firstDownloadEntered.future;
    final second = BookmarkSyncService.uploadMerged(
      local: const [],
      download: download,
      upload: upload,
    );
    await Future<void>.delayed(Duration.zero);
    expect(downloadCalls, 1);

    releaseFirstDownload.complete();
    await Future.wait([first, second]);
    expect(downloadCalls, 2);
    expect(maximumActiveOperations, 1);
  });

  test('sync gate releases after an operation fails', () async {
    await WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
    var downloadCalls = 0;

    Future<List<int>> download({
      required String url,
      required String username,
      required String password,
      required String remotePath,
    }) async {
      downloadCalls++;
      if (downloadCalls == 1) {
        throw StateError('模拟失败');
      }
      return utf8.encode(BookmarkService.encodeJson(const []));
    }

    Future<void> upload({
      required String url,
      required String username,
      required String password,
      required String remotePath,
      required List<int> data,
    }) async {}

    await expectLater(
      BookmarkSyncService.uploadMerged(
        local: const [],
        download: download,
        upload: upload,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      BookmarkSyncService.uploadMerged(
        local: const [],
        download: download,
        upload: upload,
      ),
      completion(0),
    );
    expect(downloadCalls, 2);
  });
}
