import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legado_flutter/application/bookshelf/remote_archive_import_port.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_controller.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_notifier.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_sort_port.dart';
import 'package:legado_flutter/application/bookshelf/remote_book_state.dart';
import 'package:legado_flutter/application/bookshelf/webdav_prefs_port.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';

final class _FakeWebDavRepository implements WebDavRepository {
  _FakeWebDavRepository({this.entries = const []});

  List<WebDavEntry> entries;
  final List<String> listedPaths = [];
  int ensureDirCalls = 0;
  final List<Future<List<WebDavEntry>>> listResponses = [];

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {}

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    ensureDirCalls++;
  }

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) {
    listedPaths.add(path);
    if (listResponses.isNotEmpty) return listResponses.removeAt(0);
    return Future.value(entries);
  }

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async => const [];

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) async {}

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) async {}

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async {}

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) async {}
}

final class _FakeArchiveImporter implements RemoteArchiveImportPort {
  @override
  Future<List<String>> extractZipBookFiles(
    List<int> bytes, {
    required Directory outputDir,
    required String archiveName,
  }) async => const [];
}

final class _FakeBookSorter implements RemoteBookSortPort {
  @override
  List<WebDavEntry> sort(
    Iterable<WebDavEntry> entries, {
    required RemoteBookSortMode mode,
    required bool ascending,
  }) {
    final result = entries.toList();
    result.sort((left, right) {
      final comparison = left.name.compareTo(right.name);
      return ascending ? comparison : -comparison;
    });
    return result;
  }
}

final class _FakeWebDavPrefs implements WebDavPrefsPort {
  const _FakeWebDavPrefs(this.config);

  final WebDavConfig config;

  @override
  Future<WebDavConfig> load() async => config;
}

RemoteBookController _controller(_FakeWebDavRepository repository) =>
    RemoteBookController(
      webdavRepository: repository,
      archiveImporter: _FakeArchiveImporter(),
      bookSorter: _FakeBookSorter(),
      webdavPrefs: const _FakeWebDavPrefs(
        WebDavConfig(
          url: 'https://example.test/dav',
          account: 'reader',
          password: 'secret',
          dir: '/legado',
        ),
      ),
    );

void main() {
  test(
    'keeps remote directory state, selection and navigation in controller',
    () async {
      final folder = WebDavEntry(
        name: '章节',
        path: '/legado/books/章节',
        isDir: true,
        size: 0,
        lastModified: 1,
      );
      final repository = _FakeWebDavRepository(
        entries: [
          folder,
          const WebDavEntry(
            name: 'beta.txt',
            path: '/legado/books/beta.txt',
            isDir: false,
            size: 20,
            lastModified: 2,
          ),
          const WebDavEntry(
            name: 'alpha.epub',
            path: '/legado/books/alpha.epub',
            isDir: false,
            size: 30,
            lastModified: 3,
          ),
          const WebDavEntry(
            name: 'image.png',
            path: '/legado/books/image.png',
            isDir: false,
            size: 30,
            lastModified: 4,
          ),
        ],
      );
      final controller = _controller(repository);

      await controller.bootstrap();

      expect(controller.state.status, RemoteBookStatus.success);
      expect(controller.state.entries, hasLength(3));
      expect(controller.visibleEntries.map((entry) => entry.name), [
        '章节',
        'beta.txt',
        'alpha.epub',
      ]);
      controller.setFilter('alpha');
      expect(controller.visibleEntries.map((entry) => entry.name), [
        'alpha.epub',
      ]);
      controller.setFilter('');
      controller.selectAllVisible(true);
      expect(
        controller.state.selected,
        containsAll(<String>[
          '/legado/books/beta.txt',
          '/legado/books/alpha.epub',
        ]),
      );

      await controller.enterDirectory(folder);
      expect(controller.state.path, folder.path);
      expect(controller.state.dirStack, [folder]);
      expect(repository.listedPaths.last, folder.path);
      expect(controller.goBackDirectory(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.path, '/legado/books');
    },
  );

  test('ignores an older directory response after a newer reload', () async {
    final repository = _FakeWebDavRepository();
    final first = Completer<List<WebDavEntry>>();
    final second = Completer<List<WebDavEntry>>();
    repository.listResponses
      ..add(first.future)
      ..add(second.future);
    final controller = _controller(repository);
    controller.applyConfig(
      const WebDavConfig(
        url: 'https://example.test/dav',
        account: 'reader',
        password: 'secret',
      ),
    );

    final firstReload = controller.reload();
    await Future<void>.delayed(Duration.zero);
    final secondReload = controller.reload();
    await Future<void>.delayed(Duration.zero);
    expect(repository.listedPaths, hasLength(2));

    second.complete(const [
      WebDavEntry(
        name: 'new.txt',
        path: '/legado/books/new.txt',
        isDir: false,
        size: 1,
        lastModified: 1,
      ),
    ]);
    await secondReload;
    first.complete(const [
      WebDavEntry(
        name: 'old.txt',
        path: '/legado/books/old.txt',
        isDir: false,
        size: 1,
        lastModified: 1,
      ),
    ]);
    await firstReload;

    expect(controller.state.entries.single.name, 'new.txt');
  });

  test('Riverpod notifier publishes the shared controller state', () async {
    final repository = _FakeWebDavRepository();
    final controller = _controller(repository);
    final container = ProviderContainer(
      overrides: [remoteBookControllerProvider.overrideWithValue(controller)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(remoteBookNotifierProvider).status,
      RemoteBookStatus.initial,
    );
    controller.applyConfig(
      const WebDavConfig(
        url: 'https://example.test/dav',
        account: 'reader',
        password: 'secret',
      ),
    );
    await container.read(remoteBookNotifierProvider.notifier).reload();

    expect(
      container.read(remoteBookNotifierProvider).status,
      RemoteBookStatus.success,
    );
  });
}
