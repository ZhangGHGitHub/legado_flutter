import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../application/bookshelf/remote_archive_import_port.dart';
import '../../application/bookshelf/remote_book_controller.dart';
import '../../application/bookshelf/remote_book_import_port.dart';
import '../../application/bookshelf/remote_book_notifier.dart';
import '../../application/bookshelf/remote_book_sort_port.dart';
import '../../application/bookshelf/remote_book_state.dart';
import '../../application/bookshelf/webdav_prefs_port.dart';
import '../../application/diagnostics/app_log_port.dart';
import '../../domain/ports/webdav_repository.dart';
import '../../domain/remote/webdav_entry.dart';
import 'package:legado_flutter/domain/book/book.dart';
import '../../widgets/legado_popup_menu.dart';
import '../../features/book/book_info_page.dart';
import '../../features/my/webdav_config_dialog.dart';
import 'app_log_dialog.dart';

/// 远程书籍（WebDAV）— 对齐 Jingshiro [RemoteBookActivity] /
/// [RemoteBookViewModel] / [AppWebDav.defaultBookWebDav]。
///
/// 默认浏览根：`{WebDAV目录}/books/`。
class RemoteBookPage extends StatefulWidget {
  const RemoteBookPage({
    super.key,
    this.webdavRepository,
    this.archiveImporter,
    this.bookSorter,
    this.webdavPrefs,
    this.bookImportPort,
  });

  @visibleForTesting
  final WebDavRepository? webdavRepository;

  @visibleForTesting
  final RemoteArchiveImportPort? archiveImporter;

  @visibleForTesting
  final RemoteBookSortPort? bookSorter;

  @visibleForTesting
  final WebDavPrefsPort? webdavPrefs;

  @visibleForTesting
  final RemoteBookImportPort? bookImportPort;

  @override
  State<RemoteBookPage> createState() => _RemoteBookPageState();
}

class _RemoteBookPageState extends State<RemoteBookPage> {
  late final WebDavRepository _webdav;
  late final RemoteBookController _remoteBookController;
  late final RemoteBookImportPort _bookImportPort;
  final _searchCtl = TextEditingController();
  RemoteArchiveImportPort get _archiveImporter =>
      widget.archiveImporter ?? context.read<RemoteArchiveImportPort>();

  RemoteBookSortPort get _bookSorter =>
      widget.bookSorter ?? context.read<RemoteBookSortPort>();

  WebDavPrefsPort get _webdavPrefs =>
      widget.webdavPrefs ?? context.read<WebDavPrefsPort>();

  @override
  void initState() {
    super.initState();
    _webdav = widget.webdavRepository ?? context.read<WebDavRepository>();
    _bookImportPort =
        widget.bookImportPort ??
        Provider.of<RemoteBookImportPort?>(context, listen: false) ??
        const EmptyRemoteBookImportPort();
    _remoteBookController = RemoteBookController(
      webdavRepository: _webdav,
      archiveImporter: _archiveImporter,
      bookSorter: _bookSorter,
      webdavPrefs: _webdavPrefs,
      appLog: context.read<AppLogPort>(),
    );
    _remoteBookController.bootstrap();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  String _displayPath(RemoteBookState state) {
    final parts = <String>['books'];
    for (final d in state.dirStack) {
      parts.add(d.name);
    }
    return '${parts.join('/')}/';
  }

  Future<void> _reload() => _remoteBookController.reload();

  bool _isImportable(String name) => RemoteBookController.isImportable(name);

  bool _isArchive(String name) => RemoteBookController.isArchive(name);

  bool _isZipArchive(String name) => RemoteBookController.isZipArchive(name);

  bool _isSelectableImport(String name) =>
      RemoteBookController.isSelectableImport(name);

  Book? _shelfBookFor(WebDavEntry e, List<Book> books) {
    final base = p.basenameWithoutExtension(e.name);
    for (final b in books) {
      if (b.type == 'local' &&
          (b.name == base || b.sourceUrl.endsWith(e.name))) {
        return b;
      }
    }
    return null;
  }

  void _toggleSelect(WebDavEntry e) => _remoteBookController.toggleSelection(e);

  void _selectAllVisible(bool all) =>
      _remoteBookController.selectAllVisible(all);

  /// 对齐 Jingshiro [SelectActionBar.revertSelection]。
  void _invertVisibleSelection() =>
      _remoteBookController.invertVisibleSelection();

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
    _remoteBookController.selectOnly(e);
    await _addSelectedToShelf();
  }

  Future<void> _addSelectedToShelf() async {
    final appLog = context.read<AppLogPort>();
    final state = _remoteBookController.state;
    final cfg = state.config;
    if (cfg == null || state.selected.isEmpty) return;
    final targets = state.entries
        .where((e) => state.selected.contains(e.path))
        .toList(growable: false);
    _remoteBookController.setImporting(true);
    var ok = 0;
    var fail = 0;
    try {
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
          await appLog.e('导入出错\n暂不支持: ${e.name}');
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
              final book = await _bookImportPort.importLocalBookFromPath(
                path,
                displayName: p.basename(path),
              );
              if (book != null) ok++;
            }
          } else {
            final localPath = p.join(saveDir.path, e.name);
            await File(localPath).writeAsBytes(bytes, flush: true);
            final book = await _bookImportPort.importLocalBookFromPath(
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
          await appLog.e('导入出错\n$err');
        }
      }
      await appLog.i('远程书籍加入书架: 成功 $ok / ${targets.length}');
      if (!mounted) return;
      _remoteBookController.clearSelection();
      _remoteBookController.recordImportResult(imported: ok, failed: fail);
      final msg = fail == 0 ? '成功添加 $ok 本书' : '成功 $ok 本，失败 $fail 本';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted && _remoteBookController.state.isImporting) {
        _remoteBookController.recordImportResult(imported: ok, failed: fail);
      }
    }
  }

  Future<void> _openServerConfig() async {
    final saved = await WebDavConfigDialog.show(
      context,
      initial: _remoteBookController.state.config,
    );
    if (saved == null || !mounted) return;
    _remoteBookController.applyConfig(saved);
    await _reload();
  }

  void _setSort(RemoteBookSortMode key) => _remoteBookController.setSort(key);

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
    return riverpod.ProviderScope(
      overrides: [
        remoteBookControllerProvider.overrideWithValue(_remoteBookController),
      ],
      child: riverpod.Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(remoteBookNotifierProvider);
          return _buildWithState(context, state);
        },
      ),
    );
  }

  Widget _buildWithState(BuildContext context, RemoteBookState state) {
    final visible = _remoteBookController.visibleEntries;
    final shelfBooks = _bookImportPort.books;
    final checkable = visible
        .where((e) => !e.isDir && _isSelectableImport(e.name))
        .length;
    final canBack = state.canGoBack;
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !canBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _remoteBookController.goBackDirectory();
      },
      child: Scaffold(
        appBar: AppBar(
          title: state.searchOpen
              ? TextField(
                  controller: _searchCtl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: '筛选 • 远程书籍',
                    border: InputBorder.none,
                  ),
                  onChanged: _remoteBookController.setFilter,
                )
              : const Text('远程书籍'),
          actions: [
            IconButton(
              tooltip: state.searchOpen ? '关闭搜索' : '筛选',
              onPressed: () {
                final open = !state.searchOpen;
                _remoteBookController.setSearchOpen(open);
                if (!open) _searchCtl.clear();
              },
              icon: Icon(state.searchOpen ? Icons.close : Icons.search),
            ),
            IconButton(
              tooltip: '刷新',
              onPressed: state.isLoading || state.isImporting ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
            // 对齐 book_remote.xml：排序独立 always-show
            PopupMenuButton<RemoteBookSortMode>(
              offset: legadoAppBarPopupOffset(context),
              tooltip: '排序',
              icon: const Icon(Icons.sort),
              onSelected: _setSort,
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: RemoteBookSortMode.name,
                  checked: state.sortMode == RemoteBookSortMode.name,
                  child: Text(
                    '名称${state.sortMode == RemoteBookSortMode.name ? (state.sortAscending ? ' ↑' : ' ↓') : ''}',
                  ),
                ),
                CheckedPopupMenuItem(
                  value: RemoteBookSortMode.time,
                  checked: state.sortMode == RemoteBookSortMode.time,
                  child: Text(
                    '时间${state.sortMode == RemoteBookSortMode.time ? (state.sortAscending ? ' ↑' : ' ↓') : ''}',
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
                  // 契约门禁：原版通过 LocalConfig 记录首次展示版本，并用
                  // Markwon 完整渲染 webDavBookHelp.md（含引用、粗体和外链）。
                  // 当前 Flutter 尚无对应的 WebDAV 帮助状态端口，现有轻量帮助
                  // 组件也不能保持原版 Markdown/链接行为，因此暂不虚构替代页。
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
                  onPressed: canBack
                      ? _remoteBookController.goBackDirectory
                      : null,
                  icon: const Icon(Icons.arrow_upward),
                ),
                title: Text(
                  _displayPath(state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: scheme.onSurface),
                ),
              ),
            ),
            Expanded(child: _buildBody(visible, scheme, state, shelfBooks)),
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
                          onPressed: state.isImporting
                              ? null
                              : () => _selectAllVisible(
                                  state.selected.length < checkable,
                                ),
                          child: Text(
                            state.selected.length >= checkable && checkable > 0
                                ? '取消全选'
                                : '全选',
                          ),
                        ),
                        TextButton(
                          onPressed: state.isImporting
                              ? null
                              : _invertVisibleSelection,
                          child: const Text('反选'),
                        ),
                        Expanded(
                          child: Text(
                            '已选 ${state.selected.length} / $checkable',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        FilledButton(
                          onPressed: state.isImporting || state.selected.isEmpty
                              ? null
                              : _addSelectedToShelf,
                          child: state.isImporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  state.selected.isEmpty
                                      ? '加入书架'
                                      : '加入书架（${state.selected.length}）',
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

  Widget _buildBody(
    List<WebDavEntry> visible,
    ColorScheme scheme,
    RemoteBookState state,
    List<Book> shelfBooks,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.needsConfig
                    ? Icons.cloud_off_outlined
                    : Icons.error_outline,
                size: 48,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openServerConfig,
                child: const Text('服务器配置'),
              ),
              if (!state.needsConfig) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: state.isImporting ? null : _reload,
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
          state.filter.trim().isEmpty ? '目录为空' : '无匹配项',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.separated(
      itemCount: visible.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final e = visible[i];
        final shelfBook = e.isDir ? null : _shelfBookFor(e, shelfBooks);
        final onShelf = shelfBook != null;
        final selectable = !e.isDir && _isSelectableImport(e.name);
        final selected = state.selected.contains(e.path);
        return ListTile(
          leading: e.isDir
              ? Icon(Icons.folder_outlined, color: scheme.primary)
              : selectable
              ? Checkbox(value: selected, onChanged: (_) => _toggleSelect(e))
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
                  onPressed: state.isImporting ? null : () => _confirmReAdd(e),
                )
              : null,
          onTap: () {
            if (e.isDir) {
              _remoteBookController.enterDirectory(e);
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
