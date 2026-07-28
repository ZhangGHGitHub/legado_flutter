import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/config/app_config.dart';
import 'package:legado_flutter/models/book_progress.dart';
import 'package:legado_flutter/services/book_progress_sync.dart';
import 'package:legado_flutter/services/webdav_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const progress = BookProgress(
    name: '测试书',
    author: '作者',
    durChapterIndex: 8,
    durChapterPos: 120,
    durChapterTime: 200,
    durChapterTitle: '第九章',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.resetForTest();
  });

  Future<void> configure() {
    return WebDavPrefs.save(
      const WebDavConfig(
        url: 'https://dav.example.com/dav',
        account: 'account',
        password: 'password',
        dir: '/legado',
      ),
    );
  }

  test('default path reads ETag and uploads conditionally', () async {
    await configure();
    String? observedEtag;
    var readCount = 0;
    String? uploadedJson;

    await BookProgressSync.uploadBookProgress(
      progress,
      readEtag:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
          }) async {
            expect(url, 'https://dav.example.com/dav');
            expect(username, 'account');
            expect(password, 'password');
            expect(remotePath, '/legado/bookProgress/测试书_作者.json');
            readCount++;
            return '"etag-v1"';
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
            observedEtag = etag;
            uploadedJson = utf8.decode(data);
          },
      nowMillis: () => 700,
    );

    expect(readCount, 1);
    expect(observedEtag, '"etag-v1"');
    expect(jsonDecode(uploadedJson!), progress.toJson());
    expect(await BookProgressSync.loadSyncTime('测试书', '作者'), 700);
  });

  test('legacy upload injector bypasses ETag path', () async {
    await configure();
    var legacyCalled = false;
    var etagRead = false;
    var conditionalCalled = false;

    await BookProgressSync.uploadBookProgress(
      progress,
      upload:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
            required List<int> data,
          }) async {
            legacyCalled = true;
          },
      readEtag:
          ({
            required String url,
            required String username,
            required String password,
            required String remotePath,
          }) async {
            etagRead = true;
            return null;
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
            conditionalCalled = true;
          },
      nowMillis: () => 701,
    );

    expect(legacyCalled, isTrue);
    expect(etagRead, isFalse);
    expect(conditionalCalled, isFalse);
    expect(await BookProgressSync.loadSyncTime('测试书', '作者'), 701);
  });

  test(
    '412 rereads ETag once and keeps local sync time until retry succeeds',
    () async {
      await configure();
      await BookProgressSync.saveSyncTime('测试书', '作者', syncTime: 600);
      final etags = <String?>['"stale"', '"fresh"'];
      final attemptedEtags = <String?>[];

      await BookProgressSync.uploadBookProgress(
        progress,
        readEtag:
            ({
              required String url,
              required String username,
              required String password,
              required String remotePath,
            }) async {
              return etags.removeAt(0);
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
              attemptedEtags.add(etag);
              if (attemptedEtags.length == 1) {
                throw StateError('HTTP 412 Precondition Failed');
              }
            },
        nowMillis: () => 702,
      );

      expect(attemptedEtags, ['"stale"', '"fresh"']);
      expect(await BookProgressSync.loadSyncTime('测试书', '作者'), 702);
    },
  );

  test('repeated 412 stops after one retry and preserves sync time', () async {
    await configure();
    await BookProgressSync.saveSyncTime('测试书', '作者', syncTime: 600);
    var readCount = 0;
    var uploadCount = 0;

    await expectLater(
      BookProgressSync.uploadBookProgress(
        progress,
        readEtag:
            ({
              required String url,
              required String username,
              required String password,
              required String remotePath,
            }) async {
              readCount++;
              return '"etag-$readCount"';
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
              uploadCount++;
              throw StateError('HTTP 412 Precondition Failed');
            },
        nowMillis: () => 703,
      ),
      throwsA(isA<StateError>()),
    );

    expect(readCount, 2);
    expect(uploadCount, 2);
    expect(await BookProgressSync.loadSyncTime('测试书', '作者'), 600);
  });
}
