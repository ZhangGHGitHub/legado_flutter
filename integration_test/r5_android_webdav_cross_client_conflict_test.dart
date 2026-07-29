import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/domain/annotation/bookmark_snapshot.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/infrastructure/webdav/frb_webdav_repository.dart';
import 'package:legado_flutter/domain/reader/book_progress.dart';
import 'package:legado_flutter/services/book_progress_sync.dart';
import 'package:legado_flutter/services/bookmark_service.dart';
import 'package:legado_flutter/services/sync_conflict_policy.dart';

const _url = String.fromEnvironment(
  'R5_WEBDAV_URL',
  defaultValue: 'http://10.0.2.2:19080/',
);
const _user = 'legado';
const _password = 'legado-test';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R5 Android WebDAV cross-client ETag conflict', (tester) async {
    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);

    const WebDavRepository repository = FrbWebDavRepository();
    final root = '/r5-conflict-${DateTime.now().millisecondsSinceEpoch}';
    final config = _Config(url: _url, root: root);
    await repository.ensureDir(
      url: config.url,
      username: _user,
      password: _password,
      path: root,
    );
    await repository.ensureDir(
      url: config.url,
      username: _user,
      password: _password,
      path: '$root/bookProgress',
    );

    await _verifyBookmarkConflict(repository, config);
    await _verifyProgressConflict(repository, config);
  });
}

Future<void> _verifyBookmarkConflict(
  WebDavRepository repository,
  _Config config,
) async {
  final path = '${config.root}/bookmark.json';
  final base = _bookmark(time: 1000, content: 'base');
  final clientA = <BookmarkSnapshot>[base, _bookmark(time: 2000, content: 'A')];
  final clientB = <BookmarkSnapshot>[base, _bookmark(time: 3000, content: 'B')];

  await repository.upload(
    url: config.url,
    username: _user,
    password: _password,
    remotePath: path,
    data: utf8.encode(BookmarkService.encodeJson([base])),
  );
  final staleEtag = await _etag(
    repository,
    config,
    path,
    listPath: config.root,
  );

  await repository.uploadIfMatch(
    url: config.url,
    username: _user,
    password: _password,
    remotePath: path,
    data: utf8.encode(BookmarkService.encodeJson(clientA)),
    etag: staleEtag,
  );

  Object? conflict;
  try {
    await repository.uploadIfMatch(
      url: config.url,
      username: _user,
      password: _password,
      remotePath: path,
      data: utf8.encode(BookmarkService.encodeJson(clientB)),
      etag: staleEtag,
    );
  } catch (error) {
    conflict = error;
  }
  expect(conflict, isNotNull);
  expect(conflict.toString(), contains('412'));

  final remote = BookmarkService.decodeJson(
    utf8.decode(
      await repository.download(
        url: config.url,
        username: _user,
        password: _password,
        remotePath: path,
      ),
    ),
  );
  final merged = BookmarkService.mergeRemote(clientB, remote);
  final latestEtag = await _etag(
    repository,
    config,
    path,
    listPath: config.root,
  );
  await repository.uploadIfMatch(
    url: config.url,
    username: _user,
    password: _password,
    remotePath: path,
    data: utf8.encode(BookmarkService.encodeJson(merged)),
    etag: latestEtag,
  );

  final finalBookmarks = BookmarkService.decodeJson(
    utf8.decode(
      await repository.download(
        url: config.url,
        username: _user,
        password: _password,
        remotePath: path,
      ),
    ),
  );
  expect(
    finalBookmarks.map((item) => item.time),
    containsAll(<int>[1000, 2000, 3000]),
  );
}

Future<void> _verifyProgressConflict(
  WebDavRepository repository,
  _Config config,
) async {
  final path = '${config.root}/bookProgress/R5_conflict_book_Author.json';
  final base = _progress(time: 1000, position: 1);
  final clientA = _progress(time: 2000, position: 10);
  final clientB = _progress(time: 3000, position: 20);

  await repository.upload(
    url: config.url,
    username: _user,
    password: _password,
    remotePath: path,
    data: utf8.encode(jsonEncode(base.toJson())),
  );
  final staleEtag = await _etag(
    repository,
    config,
    path,
    listPath: '${config.root}/bookProgress',
  );
  await repository.uploadIfMatch(
    url: config.url,
    username: _user,
    password: _password,
    remotePath: path,
    data: utf8.encode(jsonEncode(clientA.toJson())),
    etag: staleEtag,
  );

  Object? conflict;
  try {
    await repository.uploadIfMatch(
      url: config.url,
      username: _user,
      password: _password,
      remotePath: path,
      data: utf8.encode(jsonEncode(clientB.toJson())),
      etag: staleEtag,
    );
  } catch (error) {
    conflict = error;
  }
  expect(conflict, isNotNull);
  expect(conflict.toString(), contains('412'));

  final decision = BookProgressSync.decideConflict(
    local: clientB,
    remote: clientA,
    baseRevision: base.durChapterTime,
  );
  expect(decision.decision, SyncConflictDecision.concurrentConflict);
  expect(decision.resolution, SyncConflictResolution.requireMerge);

  final latestEtag = await _etag(
    repository,
    config,
    path,
    listPath: '${config.root}/bookProgress',
  );
  await repository.uploadIfMatch(
    url: config.url,
    username: _user,
    password: _password,
    remotePath: path,
    data: utf8.encode(jsonEncode(clientB.toJson())),
    etag: latestEtag,
  );
  final finalProgress = BookProgress.fromJson(
    jsonDecode(
          utf8.decode(
            await repository.download(
              url: config.url,
              username: _user,
              password: _password,
              remotePath: path,
            ),
          ),
        )
        as Map<String, dynamic>,
  );
  expect(finalProgress.durChapterTime, clientB.durChapterTime);
  expect(finalProgress.durChapterPos, clientB.durChapterPos);
}

Future<String> _etag(
  WebDavRepository repository,
  _Config config,
  String path, {
  required String listPath,
}) async {
  final entries = await repository.list(
    url: config.url,
    username: _user,
    password: _password,
    path: listPath,
  );
  final entry = entries.firstWhere((item) => item.path == path);
  expect(entry.etag, isNotNull);
  return entry.etag!;
}

BookmarkSnapshot _bookmark({required int time, required String content}) {
  return BookmarkSnapshot(
    time: time,
    bookId: 'r5-conflict-book',
    bookName: 'R5 Conflict Book',
    bookAuthor: 'Author',
    chapterIndex: 0,
    chapterPos: time,
    chapterName: 'Chapter 1',
    bookText: 'text',
    content: content,
  );
}

BookProgress _progress({required int time, required int position}) {
  return BookProgress(
    name: 'R5 Conflict Book',
    author: 'Author',
    durChapterIndex: 0,
    durChapterPos: position,
    durChapterTime: time,
    durChapterTitle: 'Chapter 1',
  );
}

class _Config {
  const _Config({required this.url, required this.root});

  final String url;
  final String root;
}
