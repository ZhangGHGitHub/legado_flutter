import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/ports/webdav_repository.dart';
import '../../domain/remote/webdav_entry.dart';
import '../../models/book.dart';
import '../../providers/book_provider.dart';
import '../../services/app_log.dart';
import '../../services/remote_archive_import_service.dart';
import '../../services/remote_book_sort.dart';
import '../../services/webdav_prefs.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../features/book/book_info_page.dart';
import '../../features/my/webdav_config_dialog.dart';
import 'app_log_dialog.dart';

/// 排序 — 对齐 Jingshiro [RemoteBookSort]（Name / Default=时间）。
enum _RemoteSort { name, time }

/// 远程书籍（WebDAV）— 对齐 Jingshiro [RemoteBookActivity] /
/// [RemoteBookViewModel] / [AppWebDav.defaultBookWebDav]。
///
/// 默认浏览根：`{WebDAV目录}/books/`。
class RemoteBookPage extends StatefulWidget {
  const RemoteBookPage({super.key, this.webdavRepository});

  @visibleForTesting
  final WebDavRepository? webdavRepository;

  @override
  State<RemoteBookPage> createState() => _RemoteBookPageState();
}

class _RemoteBookPageState extends State<RemoteBookPage> {
  late final WebDavRepository _webdav;
  WebDavConfig? _config;
  late String _booksRoot;
  String _path = '';
  final List<WebDavEntry> _dirStack = [];
  List<WebDavEntry> _entries = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _importing = false;
  String? _error;
  bool _needsConfig = false;
  String _filter = '';
  // 对齐 ViewModel：默认按时间、降序
  _RemoteSort _sort = _RemoteSort.time;
  bool _sortAscending = false;
  bool _searchOpen = false;
  bool _booksRootEnsured = false;
  final _searchCtl = TextEditingController();
  final _archiveImporter = const RemoteArchiveImportService();

  /// Jingshiro `bookFileRegex` 可导入子集（本地引擎仅 txt/epub）。
  static final _importableExt = RegExp(r'\.(txt|epub)$', caseSensitive: false);

  /// Jingshiro 列出但不支持本地导入的书籍扩展 — TODO: 接 LocalBook 多格式。
  static final _listedBookExt = RegExp(
    r'\.(txt|epub|umd|pdf|mobi|azw3?|cbz)$',
    caseSensitive: false,
  );

  /// Jingshiro `archiveFileRegex` — TODO: 解压后 importFiles。
  static final _archiveExt = RegExp(r'\.(zip|rar|7z)$', caseSensitive: false);

  @override
  void initState() {
    super.initState();
    _webdav = widget.webdavRepository ?? context.read<WebDavRepository>();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final cfg = await WebDavPrefs.load();
    if (!mounted) return;
    _applyConfig(cfg);
    await _reload();
  }

  void _applyConfig(WebDavConfig cfg) {
    _config = cfg;
    _booksRoot = cfg.booksDir;
    _path = _booksRoot;
    _dirStack.clear();
    _selected.clear();
    _booksRootEnsured = false;
  }

  String get _displayPath {
    final parts = <String>['books'];
    for (final d in _dirStack) {
      parts.add(d.name);
    }
    return '${parts.join('/')}/';
  }

  Future<void> _reload() async {
    final cfg = _config;
    if (cfg == null || !cfg.isReady) {
      setState(() {
        _loading = false;
        _needsConfig = true;
        _error = cfg == null || !cfg.isConfigured
            ? '请先配置 WebDAV 服务器'
            : '请填写 WebDAV 账号和密码';
        _entries = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _needsConfig = false;
    });
    try {
      if (!_booksRootEnsured) {
        await _webdav.ensureDir(
          url: cfg.url,
          username: cfg.account,
          password: cfg.password,
          path: _booksRoot,
        );
        _booksRootEnsured = true;
      }
      final list = await _webdav.list(
        url: cfg.url,
        username: cfg.account,
        password: cfg.password,
        path: _path,
      );
      final filtered = list.where((e) {
        if (e.isDir) return true;
        return _isListedRemoteFile(e.name);
      }).toList();
      if (!mounted) return;
      setState(() {
        _entries = filtered;
        _loading = false;
        _selected.removeWhere((path) => filtered.every((e) => e.path != path));
      });
    } catch (e) {
      await AppLog.e('获取webDav书籍出错\n$e');
      if (!mounted) return;
      final raw = '$e';
      final hint =
          raw.contains(RegExp(r'404|Not Found|PROPFIND', caseSensitive: false))
          ? '\n\n请检查 WebDAV 账号对「${cfg.booksDir}」目录的访问和创建权限。'
          : '';
      setState(() {
        _loading = false;
        _error = '获取webDav书籍出错\n$raw$hint';
        _entries = [];
      });
    }
  }

  List<WebDavEntry> get _visibleEntries {
    var list = List<WebDavEntry>.from(_entries);
    final key = _filter.trim().toLowerCase();
    if (key.isNotEmpty) {
      list = list.where((e) => e.name.toLowerCase().contains(key)).toList();
    }
    return sortRemoteBookEntries(
      list,
      mode: _sort == _RemoteSort.name
          ? RemoteBookSortMode.name
          : RemoteBookSortMode.time,
      ascending: _sortAscending,
    );
  }

  void _enterDir(WebDavEntry e) {
    if (!e.isDir) return;
    setState(() {
      _dirStack.add(e);
      _path = e.path;
      _selected.clear();
    });
    _reload();
  }

  bool _goBackDir() {
    if (_dirStack.isEmpty) return false;
    setState(() {
      _dirStack.removeLast();
      _path = _dirStack.isEmpty ? _booksRoot : _dirStack.last.path;
      _selected.clear();
    });
    _reload();
    return true;
  }

  bool _isListedRemoteFile(String name) =>
      _listedBookExt.hasMatch(name) || _archiveExt.hasMatch(name);

  bool _isImportable(String name) => _importableExt.hasMatch(name);

  bool _isArchive(String name) => _archiveExt.hasMatch(name);

  bool _isZipArchive(String name) =>
      RegExp(r'\.zip$', caseSensitive: false).hasMatch(name);

  bool _isSelectableImport(String name) =>
      _isImportable(name) || _isZipArchive(name);

  Book? _shelfBookFor(WebDavEntry e, BookProvider books) {
    final base = p.basenameWithoutExtension(e.name);
    for (final b in books.books) {
      if (b.type == 'local' &&
          (b.name == base || b.sourceUrl.endsWith(e.name))) {
        return b;
      }
    }
    return null;
  }

  void _toggleSelect(WebDavEntry e) {
    if (e.isDir || !_isSelectableImport(e.name)) return;
    setState(() {
      if (_selected.contains(e.path)) {
        _selected.remove(e.path);
      } else {
        _selected.add(e.path);
      }
    });
  }

  void _selectAllVisible(bool all) {
    final files = _visibleEntries
        .where((e) => !e.isDir && _isSelectableImport(e.name))
        .toList();
    setState(() {
      if (all) {
        _selected.addAll(files.map((e) => e.path));
      } else {
        for (final f in files) {
          _selected.remove(f.path);
        }
      }
    });
  }

  /// 对齐 Jingshiro [SelectActionBar.revertSelection]。
  void _invertVisibleSelection() {
    final files = _visibleEntries
        .where((e) => !e.isDir && _isSelectableImport(e.name))
        .toList();
    setState(() {
      for (final f in files) {
        if (_selected.contains(f.path)) {
          _selected.remove(f.path);
        } else {
          _selected.add(f.path);
        }
      }
    });
  }

  void _openShelfBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookInfoPage(book: book)),
    );
  }

  Future<void> _confirmReAdd(WebDavEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确定'),
        content: Text('是否重新加入书架？\n${e.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _selected
        ..clear()
        ..add(e.path);
    });
    await _addSelectedToShelf();
  }

  Future<void> _addSelectedToShelf() async {
    final cfg = _config;
    if (cfg == null || _selected.isEmpty) return;
    final targets = _entries
        .where((e) => _selected.contains(e.path))
        .toList(growable: false);
    setState(() => _importing = true);
    var ok = 0;
    var fail = 0;
    try {
      final books = context.read<BookProvider>();
      // 对齐 Jingshiro LocalBook.saveBookFile：落到持久目录，勿只用系统临时目录。
      final docs = await getApplicationDocumentsDirectory();
      final saveDir = Directory(p.join(docs.path, 'webdav_books'));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      for (final e in targets) {
        if (!_isSelectableImport(e.name)) {
          // RAR/7z/UMD/PDF/MOBI remain outside the current local importer.
          fail++;
          await AppLog.e('导入出错\n暂不支持: ${e.name}');
          continue;
        }
        try {
          final bytes = await _webdav.download(
            url: cfg.url,
            username: cfg.account,
            password: cfg.password,
            remotePath: e.path,
          );
          if (_isZipArchive(e.name)) {
            final extracted = await _archiveImporter.extractZipBookFiles(
              bytes,
              outputDir: saveDir,
              archiveName: e.name,
            );
            for (final path in extracted) {
              final book = await books.importLocalBookFromPath(
                path,
                displayName: p.basename(path),
              );
              if (book != null) ok++;
            }
          } else {
            final localPath = p.join(saveDir.path, e.name);
            await File(localPath).writeAsBytes(bytes, flush: true);
            final book = await books.importLocalBookFromPath(
              localPath,
              displayName: e.name,
            );
            if (book != null) {
              ok++;
            } else {
              fail++;
            }
          }
        } catch (err) {
          fail++;
          await AppLog.e('导入出错\n$err');
        }
      }
      await AppLog.i('远程书籍加入书架: 成功 $ok / ${targets.length}');
      if (!mounted) return;
      setState(() => _selected.clear());
      final msg = fail == 0 ? '成功添加 $ok 本书' : '成功 $ok 本，失败 $fail 本';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _openServerConfig() async {
    final saved = await WebDavConfigDialog.show(context, initial: _config);
    if (saved == null || !mounted) return;
    _applyConfig(saved);
    setState(() {});
    await _reload();
  }

  void _setSort(_RemoteSort key) {
    setState(() {
      if (_sort == key) {
        _sortAscending = !_sortAscending;
      } else {
        _sort = key;
        _sortAscending = true;
      }
    });
  }

  String _subtitleFor(WebDavEntry e, bool onShelf) {
    if (e.isDir) return '文件夹';
    if (onShelf) return '已在书架 · 点击打开';
    if (_isZipArchive(e.name)) return 'ZIP 压缩包（可导入 TXT/EPUB）';
    if (_isArchive(e.name)) return '压缩包（暂不支持导入）';
    if (_isImportable(e.name)) {
      final size = _formatSize(e.size);
      return size.isEmpty ? '可导入' : size;
    }
    return '暂不支持导入';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleEntries;
    final checkable = visible
        .where((e) => !e.isDir && _isSelectableImport(e.name))
        .length;
    final canBack = _dirStack.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !canBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBackDir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: _searchOpen
              ? TextField(
                  controller: _searchCtl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '筛选 • 远程书籍',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                )
              : const Text('远程书籍'),
          actions: [
            IconButton(
              tooltip: _searchOpen ? '关闭搜索' : '筛选',
              onPressed: () {
                setState(() {
                  _searchOpen = !_searchOpen;
                  if (!_searchOpen) {
                    _filter = '';
                    _searchCtl.clear();
                  }
                });
              },
              icon: Icon(_searchOpen ? Icons.close : Icons.search),
            ),
            IconButton(
              tooltip: '刷新',
              onPressed: _loading || _importing ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
            // 对齐 book_remote.xml：排序独立 always-show
            PopupMenuButton<_RemoteSort>(
              offset: legadoAppBarPopupOffset(context),
              tooltip: '排序',
              icon: const Icon(Icons.sort),
              onSelected: _setSort,
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: _RemoteSort.name,
                  checked: _sort == _RemoteSort.name,
                  child: Text(
                    '名称${_sort == _RemoteSort.name ? (_sortAscending ? ' ↑' : ' ↓') : ''}',
                  ),
                ),
                CheckedPopupMenuItem(
                  value: _RemoteSort.time,
                  checked: _sort == _RemoteSort.time,
                  child: Text(
                    '时间${_sort == _RemoteSort.time ? (_sortAscending ? ' ↑' : ' ↓') : ''}',
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              offset: legadoAppBarPopupOffset(context),
              tooltip: '更多',
              onSelected: (v) async {
                if (v == 'server') {
                  await _openServerConfig();
                } else if (v == 'log') {
                  await AppLogDialog.show(context);
                } else if (v == 'help') {
                  // TODO: menu_help — webDavBookHelp 帮助页尚未移植
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('WebDAV 远程书籍帮助页尚未移植')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'server', child: Text('服务器配置')),
                PopupMenuItem(value: 'help', child: Text('帮助')),
                PopupMenuItem(value: 'log', child: Text('日志')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // 对齐 activity 顶栏：上级 + 当前路径
            Material(
              color: scheme.surfaceContainerLow,
              child: ListTile(
                dense: true,
                leading: IconButton(
                  tooltip: '上级',
                  onPressed: canBack ? _goBackDir : null,
                  icon: const Icon(Icons.arrow_upward),
                ),
                title: Text(
                  _displayPath,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: scheme.onSurface),
                ),
              ),
            ),
            Expanded(child: _buildBody(visible, scheme)),
            if (checkable > 0)
              SafeArea(
                child: Material(
                  elevation: 4,
                  color: scheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: _importing
                              ? null
                              : () => _selectAllVisible(
                                  _selected.length < checkable,
                                ),
                          child: Text(
                            _selected.length >= checkable && checkable > 0
                                ? '取消全选'
                                : '全选',
                          ),
                        ),
                        TextButton(
                          onPressed: _importing
                              ? null
                              : _invertVisibleSelection,
                          child: const Text('反选'),
                        ),
                        Expanded(
                          child: Text(
                            '已选 ${_selected.length} / $checkable',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        FilledButton(
                          onPressed: _importing || _selected.isEmpty
                              ? null
                              : _addSelectedToShelf,
                          child: _importing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _selected.isEmpty
                                      ? '加入书架'
                                      : '加入书架（${_selected.length}）',
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<WebDavEntry> visible, ColorScheme scheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _needsConfig ? Icons.cloud_off_outlined : Icons.error_outline,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openServerConfig,
                child: const Text('服务器配置'),
              ),
              if (!_needsConfig) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _importing ? null : _reload,
                  child: const Text('重试'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: Text(
          _filter.trim().isEmpty ? '目录为空' : '无匹配项',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Consumer<BookProvider>(
      builder: (ctx, books, _) {
        return ListView.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final e = visible[i];
            final shelfBook = e.isDir ? null : _shelfBookFor(e, books);
            final onShelf = shelfBook != null;
            final selectable = !e.isDir && _isSelectableImport(e.name);
            final selected = _selected.contains(e.path);
            return ListTile(
              leading: e.isDir
                  ? Icon(Icons.folder_outlined, color: scheme.primary)
                  : selectable
                  ? Checkbox(
                      value: selected,
                      onChanged: (_) => _toggleSelect(e),
                    )
                  : Icon(
                      _isArchive(e.name)
                          ? Icons.folder_zip_outlined
                          : Icons.insert_drive_file_outlined,
                      color: scheme.onSurfaceVariant,
                    ),
              title: Text(e.name),
              subtitle: Text(_subtitleFor(e, onShelf)),
              trailing: e.isDir
                  ? const Icon(Icons.chevron_right)
                  : onShelf
                  ? IconButton(
                      tooltip: '重新加入书架',
                      icon: Icon(
                        Icons.check_circle,
                        color: scheme.primary,
                        size: 22,
                      ),
                      onPressed: _importing ? null : () => _confirmReAdd(e),
                    )
                  : null,
              onTap: () {
                if (e.isDir) {
                  _enterDir(e);
                } else if (shelfBook != null) {
                  // 对齐 RemoteBookActivity.startRead：已在书架则打开
                  _openShelfBook(shelfBook);
                } else if (selectable) {
                  _toggleSelect(e);
                } else if (_isArchive(e.name)) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('此压缩格式暂不支持导入')));
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('暂不支持导入: ${e.name}')));
                }
              },
              onLongPress: () {
                if (onShelf) {
                  _confirmReAdd(e);
                } else if (selectable) {
                  _toggleSelect(e);
                }
              },
            );
          },
        );
      },
    );
  }

  static String _formatSize(int size) {
    if (size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
