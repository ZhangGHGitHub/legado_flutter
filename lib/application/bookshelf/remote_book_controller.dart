import 'package:flutter/foundation.dart';

import '../../application/diagnostics/app_log_port.dart';
import '../../domain/ports/webdav_repository.dart';
import '../../domain/remote/webdav_entry.dart';
import 'remote_archive_import_port.dart';
import 'remote_book_sort_port.dart';
import 'remote_book_state.dart';
import 'webdav_prefs_port.dart';

typedef RemoteBookStateListener = void Function(RemoteBookState state);

/// 远程书籍页面的应用层控制器。
///
/// 页面只保留本地文件导入和导航等 UI 绑定；WebDAV 目录状态集中在这里，
/// 迁移期间由 Provider 和 Riverpod 共享同一份状态。
final class RemoteBookController {
  RemoteBookController({
    required WebDavRepository webdavRepository,
    required RemoteArchiveImportPort archiveImporter,
    required RemoteBookSortPort bookSorter,
    required WebDavPrefsPort webdavPrefs,
    AppLogPort? appLog,
  }) : _webdav = webdavRepository,
       _archiveImporter = archiveImporter,
       _bookSorter = bookSorter,
       _webdavPrefs = webdavPrefs,
       _appLog = appLog;

  final WebDavRepository _webdav;
  final RemoteArchiveImportPort _archiveImporter;
  final RemoteBookSortPort _bookSorter;
  final WebDavPrefsPort _webdavPrefs;
  final AppLogPort? _appLog;
  final Set<RemoteBookStateListener> _listeners = {};
  RemoteBookState _state = RemoteBookState.initial();
  int _requestId = 0;

  static final _listedBookExt = RegExp(
    r'\.(txt|epub|umd|pdf|mobi|azw3?|cbz)$',
    caseSensitive: false,
  );
  static final _archiveExt = RegExp(r'\.(zip|rar|7z)$', caseSensitive: false);

  RemoteBookState get state => _state;
  WebDavRepository get webdavRepository => _webdav;
  RemoteArchiveImportPort get archiveImporter => _archiveImporter;

  void addListener(RemoteBookStateListener listener) =>
      _listeners.add(listener);

  void removeListener(RemoteBookStateListener listener) =>
      _listeners.remove(listener);

  Future<void> bootstrap() async {
    try {
      final config = await _webdavPrefs.load();
      applyConfig(config);
      await reload();
    } catch (error, stackTrace) {
      await _logError('读取 WebDAV 配置出错\n$error');
      _publish(
        _state.copyWith(
          status: RemoteBookStatus.failure,
          error: '$error',
          needsConfig: false,
        ),
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void applyConfig(WebDavConfig config) {
    _requestId++;
    _publish(
      _state.copyWith(
        config: config,
        booksRoot: config.booksDir,
        path: config.booksDir,
        dirStack: const [],
        selected: const {},
        entries: const [],
        error: null,
        needsConfig: false,
        booksRootEnsured: false,
      ),
    );
  }

  Future<void> reload() async {
    final requestId = ++_requestId;
    final config = _state.config;
    if (config == null || !config.isReady) {
      _publish(
        _state.copyWith(
          status: RemoteBookStatus.failure,
          error: config == null || !config.isConfigured
              ? '请先配置 WebDAV 服务器'
              : '请填写 WebDAV 账号和密码',
          entries: const [],
          needsConfig: true,
        ),
      );
      return;
    }

    _publish(
      _state.copyWith(
        status: RemoteBookStatus.loading,
        error: null,
        needsConfig: false,
      ),
    );
    try {
      var ensured = _state.booksRootEnsured;
      if (!ensured) {
        await _webdav.ensureDir(
          url: config.url,
          username: config.account,
          password: config.password,
          path: _state.booksRoot,
        );
        ensured = true;
      }
      final list = await _webdav.list(
        url: config.url,
        username: config.account,
        password: config.password,
        path: _state.path,
      );
      if (requestId != _requestId) return;
      final entries = list.where(_isListedRemoteFile).toList(growable: false);
      final selected = _state.selected
          .where((path) => entries.any((entry) => entry.path == path))
          .toSet();
      _publish(
        _state.copyWith(
          status: RemoteBookStatus.success,
          entries: List.unmodifiable(entries),
          selected: Set.unmodifiable(selected),
          booksRootEnsured: ensured,
        ),
      );
    } catch (error) {
      if (requestId != _requestId) return;
      await _logError('获取webDav书籍出错\n$error');
      final raw = '$error';
      final hint =
          raw.contains(RegExp(r'404|Not Found|PROPFIND', caseSensitive: false))
          ? '\n\n请检查 WebDAV 账号对「${config.booksDir}」目录的访问和创建权限。'
          : '';
      _publish(
        _state.copyWith(
          status: RemoteBookStatus.failure,
          error: '获取webDav书籍出错\n$raw$hint',
          entries: const [],
        ),
      );
    }
  }

  List<WebDavEntry> get visibleEntries {
    final key = _state.filter.trim().toLowerCase();
    final filtered = key.isEmpty
        ? _state.entries
        : _state.entries
              .where((entry) => entry.name.toLowerCase().contains(key))
              .toList(growable: false);
    return _bookSorter.sort(
      filtered,
      mode: _state.sortMode,
      ascending: _state.sortAscending,
    );
  }

  Future<void> enterDirectory(WebDavEntry entry) async {
    if (!entry.isDir) return;
    _publish(
      _state.copyWith(
        dirStack: [..._state.dirStack, entry],
        path: entry.path,
        selected: const {},
      ),
    );
    await reload();
  }

  bool goBackDirectory() {
    if (_state.dirStack.isEmpty) return false;
    final stack = [..._state.dirStack]..removeLast();
    _publish(
      _state.copyWith(
        dirStack: stack,
        path: stack.isEmpty ? _state.booksRoot : stack.last.path,
        selected: const {},
      ),
    );
    reload();
    return true;
  }

  void setFilter(String filter) => _publish(_state.copyWith(filter: filter));

  void setSearchOpen(bool open) => _publish(
    _state.copyWith(searchOpen: open, filter: open ? _state.filter : ''),
  );

  void setSort(RemoteBookSortMode mode) {
    _publish(
      _state.copyWith(
        sortMode: mode,
        sortAscending: _state.sortMode == mode ? !_state.sortAscending : true,
      ),
    );
  }

  void toggleSelection(WebDavEntry entry) {
    if (entry.isDir || !isSelectableImport(entry.name)) return;
    final selected = {..._state.selected};
    if (!selected.add(entry.path)) selected.remove(entry.path);
    _publish(_state.copyWith(selected: Set.unmodifiable(selected)));
  }

  void selectAllVisible(bool all) {
    final files = visibleEntries.where(_isSelectableImportEntry);
    final selected = {..._state.selected};
    if (all) {
      selected.addAll(files.map((entry) => entry.path));
    } else {
      selected.removeAll(files.map((entry) => entry.path));
    }
    _publish(_state.copyWith(selected: Set.unmodifiable(selected)));
  }

  void invertVisibleSelection() {
    final selected = {..._state.selected};
    for (final entry in visibleEntries.where(_isSelectableImportEntry)) {
      if (!selected.add(entry.path)) selected.remove(entry.path);
    }
    _publish(_state.copyWith(selected: Set.unmodifiable(selected)));
  }

  void clearSelection() => _publish(_state.copyWith(selected: const {}));

  void selectOnly(WebDavEntry entry) {
    if (entry.isDir) return;
    _publish(_state.copyWith(selected: Set.unmodifiable({entry.path})));
  }

  void setImporting(bool importing) => _publish(
    _state.copyWith(
      isImporting: importing,
      importedCount: importing ? 0 : _state.importedCount,
      failedCount: importing ? 0 : _state.failedCount,
    ),
  );

  void recordImportResult({required int imported, required int failed}) =>
      _publish(
        _state.copyWith(
          isImporting: false,
          importedCount: imported,
          failedCount: failed,
        ),
      );

  static bool isZipArchive(String name) =>
      RegExp(r'\.zip$', caseSensitive: false).hasMatch(name);

  static bool isImportable(String name) =>
      RegExp(r'\.(txt|epub)$', caseSensitive: false).hasMatch(name);

  static bool isArchive(String name) => _archiveExt.hasMatch(name);

  static bool isSelectableImport(String name) =>
      isImportable(name) || isZipArchive(name);

  bool _isListedRemoteFile(WebDavEntry entry) =>
      entry.isDir || _isListedBookFile(entry.name);

  static bool _isListedBookFile(String name) =>
      _listedBookExt.hasMatch(name) || _archiveExt.hasMatch(name);

  static bool _isSelectableImportEntry(WebDavEntry entry) =>
      !entry.isDir && isSelectableImport(entry.name);

  Future<void> _logError(String message) =>
      _appLog?.e(message) ?? Future<void>.value();

  void _publish(RemoteBookState next) {
    _state = next;
    for (final listener in List<RemoteBookStateListener>.of(_listeners)) {
      listener(next);
    }
  }
}
