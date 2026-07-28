import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/services/bookmark_sync_service.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const local = [
    BookmarkSnapshot(
      time: 5,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 5,
      chapterPos: 50,
      chapterName: '本地章节',
      bookText: '本地内容',
      content: '',
    ),
  ];

  const remote = [
    BookmarkSnapshot(
      time: 4,
      bookId: 'book-1',
      bookName: '测试书',
      bookAuthor: '作者',
      chapterIndex: 4,
      chapterPos: 40,
      chapterName: '远端章节',
      bookText: '远端内容',
      content: '',
    ),
  ];

  Future<void> saveConfig() {
    return WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
  }

  WebDavEntry entry(String? etag) {
    return WebDavEntry(
      name: 'bookmark.json',
      path: '/legado/bookmark.json',
      isDir: false,
      size: 100,
      lastModified: 1,
      etag: etag,
    );
  }

  test('reads bookmark ETag and uses conditional upload', () async {
    await saveConfig();
    String? uploadedEtag;
    List<BookmarkSnapshot>? uploadedBookmarks;

    final count = await BookmarkSyncService.uploadMerged(
      local: local,
      list:
          ({
            required String url,
            required String username,
            required String password,
            required String path,
          }) async {
            expect(path, '/legado');
            return [entry('"v1"')];
          },
      download:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
          }) async => utf8.encode(BookmarkService.encodeJson(remote)),
      uploadIfMatch:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
            required List<int> data,
            String? etag,
          }) async {
            uploadedEtag = etag;
            uploadedBookmarks = BookmarkService.decodeJson(utf8.decode(data));
          },
    );

    expect(count, 2);
    expect(uploadedEtag, '"v1"');
    expect(uploadedBookmarks?.map((item) => item.time), [5, 4]);
  });

  test('re-reads and merges the latest remote data after HTTP 412', () async {
    await saveConfig();
    var listCalls = 0;
    var downloadCalls = 0;
    var uploadCalls = 0;
    String? uploadedEtag;
    List<BookmarkSnapshot>? uploadedBookmarks;
    const latestRemote = [
      BookmarkSnapshot(
        time: 6,
        bookId: 'book-1',
        bookName: '测试书',
        bookAuthor: '作者',
        chapterIndex: 6,
        chapterPos: 60,
        chapterName: '最新远端章节',
        bookText: '最新远端内容',
        content: '',
      ),
    ];

    final count = await BookmarkSyncService.uploadMerged(
      local: local,
      list:
          ({
            required String url,
            required String username,
            required String password,
            required String path,
          }) async {
            listCalls++;
            return [entry(listCalls == 1 ? '"v1"' : '"v2"')];
          },
      download:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
          }) async {
            downloadCalls++;
            return utf8.encode(
              BookmarkService.encodeJson(
                downloadCalls == 1 ? remote : latestRemote,
              ),
            );
          },
      uploadIfMatch:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
            required List<int> data,
            String? etag,
          }) async {
            uploadCalls++;
            if (uploadCalls == 1) {
              throw StateError('HTTP 412 Precondition Failed');
            }
            uploadedEtag = etag;
            uploadedBookmarks = BookmarkService.decodeJson(utf8.decode(data));
          },
    );

    expect(count, 2);
    expect(listCalls, 2);
    expect(downloadCalls, 2);
    expect(uploadCalls, 2);
    expect(uploadedEtag, '"v2"');
    expect(uploadedBookmarks?.map((item) => item.time), [5, 6]);
  });

  test('stops after bounded 412 retries without ordinary overwrite', () async {
    await saveConfig();
    var uploadIfMatchCalls = 0;
    var ordinaryUploadCalls = 0;
    var listCalls = 0;
    var downloadCalls = 0;

    await expectLater(
      BookmarkSyncService.uploadMerged(
        local: local,
        maxConflictRetries: 1,
        list:
            ({
              required String url,
              required String username,
              required String password,
              required String path,
            }) async {
              listCalls++;
              return [entry('"v$listCalls"')];
            },
        download:
            ({
              required String url,
              required String username,
              required String password,
              required String remotePath,
            }) async {
              downloadCalls++;
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
              ordinaryUploadCalls++;
            },
        uploadIfMatch:
            ({
              required String url,
              required String username,
              required String password,
              required String remotePath,
              required List<int> data,
              String? etag,
            }) async {
              uploadIfMatchCalls++;
              throw StateError('HTTP 412 Precondition Failed');
            },
      ),
      throwsA(isA<StateError>()),
    );

    expect(uploadIfMatchCalls, 2);
    expect(ordinaryUploadCalls, 0);
    expect(listCalls, 2);
    expect(downloadCalls, 2);
  });

  test(
    'does not overwrite an existing file when its ETag is missing',
    () async {
      await saveConfig();
      var conditionalUploadCalled = false;
      var ordinaryUploadCalled = false;

      await expectLater(
        BookmarkSyncService.uploadMerged(
          local: local,
          list:
              ({
                required String url,
                required String username,
                required String password,
                required String path,
              }) async => [entry(null)],
          download:
              ({
                required String url,
                required String username,
                required String password,
                required String remotePath,
              }) async => utf8.encode(BookmarkService.encodeJson(remote)),
          upload:
              ({
                required String url,
                required String username,
                required String password,
                required String remotePath,
                required List<int> data,
              }) async {
                ordinaryUploadCalled = true;
              },
          uploadIfMatch:
              ({
                required String url,
                required String username,
                required String password,
                required String remotePath,
                required List<int> data,
                String? etag,
              }) async {
                conditionalUploadCalled = true;
              },
        ),
        throwsA(isA<StateError>()),
      );

      expect(conditionalUploadCalled, isFalse);
      expect(ordinaryUploadCalled, isFalse);
    },
  );
}
