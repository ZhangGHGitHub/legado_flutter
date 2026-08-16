import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/ports/webdav_repository.dart';
import 'package:legado_flutter/domain/remote/webdav_entry.dart';

class _FakeWebDavRepository implements WebDavRepository {
  final calls = <String>[];

  @override
  Future<void> check({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    calls.add('check:$path');
  }

  @override
  Future<List<WebDavEntry>> list({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    calls.add('list:$path');
    return const [
      WebDavEntry(
        name: 'book.txt',
        path: '/books/book.txt',
        isDir: false,
        size: 3,
        lastModified: 1,
      ),
    ];
  }

  @override
  Future<void> ensureDir({
    required String url,
    required String username,
    required String password,
    required String path,
  }) async {
    calls.add('ensure:$path');
  }

  @override
  Future<List<int>> download({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async {
    calls.add('download:$remotePath');
    return const [1, 2, 3];
  }

  @override
  Future<void> upload({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
  }) async {
    calls.add('upload:$remotePath');
  }

  @override
  Future<void> uploadIfMatch({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required List<int> data,
    String? etag,
  }) async {
    calls.add('uploadIfMatch:$remotePath:$etag');
  }

  @override
  Future<void> delete({
    required String url,
    required String username,
    required String password,
    required String remotePath,
  }) async {
    calls.add('delete:$remotePath');
  }

  @override
  Future<void> move({
    required String url,
    required String username,
    required String password,
    required String remotePath,
    required String destinationPath,
  }) async {
    calls.add('move:$remotePath->$destinationPath');
  }
}

void main() {
  test(
    'WebDAV repository exposes remote book operations without FRB types',
    () async {
      final repository = _FakeWebDavRepository();
      final entries = await repository.list(
        url: 'https://dav.example.com',
        username: 'user',
        password: 'password',
        path: '/books',
      );
      await repository.ensureDir(
        url: 'https://dav.example.com',
        username: 'user',
        password: 'password',
        path: '/books',
      );
      expect(entries.single.name, 'book.txt');
      expect(repository.calls, ['list:/books', 'ensure:/books']);
    },
  );
}
