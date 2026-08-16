import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../application/file_system/app_paths_port.dart';

/// 文件管理 — 1:1 对齐 Jingshiro [FileManageActivity] /
/// `activity_file_manage.xml`（TitleBar 搜索 + 路径条 + 文件列表）。
class FileManagePage extends StatefulWidget {
  const FileManagePage({super.key});

  @override
  State<FileManagePage> createState() => _FileManagePageState();
}

class _FileManagePageState extends State<FileManagePage> {
  static const _dirParent = '..';
  static const _hint = '筛选 • 文件管理';

  final _searchCtrl = TextEditingController();
  final _pathScrollCtrl = ScrollController();

  Directory? _root;
  final List<Directory> _subDocs = [];
  List<FileSystemEntity> _currentFiles = [];
  bool _loading = true;
  String? _error;

  Directory? get _lastDir => _subDocs.isEmpty ? _root : _subDocs.last;

  bool get _atRoot {
    final root = _root;
    final last = _lastDir;
    if (root == null || last == null) return true;
    return p.equals(root.path, last.path);
  }

  List<FileSystemEntity> get _visibleFiles {
    final q = _searchCtrl.text;
    if (q.isEmpty) return _currentFiles;
    return _currentFiles.where((e) {
      final name = p.basename(e.path);
      if (name == _dirParent) return true;
      return name.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pathScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final root = await context.read<AppPathsPort>().dataRoot();
      if (!mounted) return;
      setState(() => _root = root);
      await _upFiles(root);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  /// 对齐 [FileManageViewModel.upFiles]：根目录直接列子项；子目录首项为当前目录（UI 显示为 `..`）。
  Future<void> _upFiles(Directory? parent) async {
    if (parent == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final children = await parent.list().toList();
      children.sort((a, b) {
        final aFile = a is File;
        final bFile = b is File;
        if (aFile != bFile) return aFile ? 1 : -1;
        return p
            .basename(a.path)
            .toLowerCase()
            .compareTo(p.basename(b.path).toLowerCase());
      });

      final root = _root!;
      final List<FileSystemEntity> list;
      if (p.equals(parent.path, root.path)) {
        list = children;
      } else {
        list = [parent, ...children];
      }

      if (!mounted) return;
      _searchCtrl.clear();
      setState(() {
        _currentFiles = list;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pathScrollCtrl.hasClients) {
          _pathScrollCtrl.jumpTo(_pathScrollCtrl.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _gotoLastDir() async {
    if (_subDocs.isNotEmpty) {
      _subDocs.removeLast();
    }
    setState(() {});
    await _upFiles(_lastDir);
  }

  Future<void> _goRoot() async {
    _subDocs.clear();
    setState(() {});
    await _upFiles(_root);
  }

  Future<void> _goPathIndex(int index) async {
    // header「root」占 position 0；segment i 对应 layoutPosition i
    if (index <= 0) {
      await _goRoot();
      return;
    }
    if (index > _subDocs.length) return;
    _subDocs.removeRange(index, _subDocs.length);
    setState(() {});
    await _upFiles(_subDocs.isEmpty ? _root : _subDocs.last);
  }

  Future<void> _onTapEntry(FileSystemEntity entity) async {
    final last = _lastDir;
    if (last != null &&
        entity is Directory &&
        p.equals(entity.path, last.path) &&
        !_atRoot) {
      await _gotoLastDir();
      return;
    }
    if (entity is Directory) {
      _subDocs.add(entity);
      setState(() {});
      await _upFiles(entity);
      return;
    }
    if (entity is File) {
      await _openFile(entity);
    }
  }

  Future<void> _openFile(File file) async {
    try {
      final uri = Uri.file(file.path);
      final ok = await launchUrl(uri);
      if (ok) return;
    } catch (_) {
      // fall through
    }
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法打开: $e')));
    }
  }

  Future<void> _showFileMenu(
    Offset globalPosition,
    FileSystemEntity entity,
  ) async {
    final last = _lastDir;
    if (last != null &&
        entity is Directory &&
        p.equals(entity.path, last.path) &&
        !_atRoot) {
      return;
    }
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: const [PopupMenuItem(value: 'del', child: Text('删除'))],
    );
    if (selected == 'del') {
      await _delFile(entity);
    }
  }

  Future<void> _delFile(FileSystemEntity entity) async {
    try {
      await entity.delete();
      await _upFiles(_lastDir);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  bool _isUpEntry(FileSystemEntity entity) {
    final last = _lastDir;
    return last != null &&
        entity is Directory &&
        p.equals(entity.path, last.path) &&
        !_atRoot;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = _visibleFiles;
    final showEmpty = !_loading && _error == null && visible.isEmpty;

    return PopScope(
      canPop: _atRoot,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _gotoLastDir();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Container(
              height: 30,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: _hint,
                  hintStyle: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                  // view_search: searchIcon=@null，仅 hint 态 searchHintIcon
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                ),
                style: TextStyle(color: scheme.onSurface, fontSize: 14),
              ),
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // rv_path — 24dp / background_card / elevation 5 / pad 10
            Material(
              color: scheme.surfaceContainer,
              elevation: 5,
              shadowColor: Colors.black26,
              child: SizedBox(
                height: 24,
                child: ListView(
                  controller: _pathScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _PathChip(label: 'root', showArrow: true, onTap: _goRoot),
                    for (var i = 0; i < _subDocs.length; i++)
                      _PathChip(
                        label: p.basename(_subDocs[i].path),
                        showArrow: true,
                        onTap: () => _goPathIndex(i + 1),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entity = visible[index];
                        final up = _isUpEntry(entity);
                        final isDir = entity is Directory;
                        final name = up ? _dirParent : p.basename(entity.path);
                        final iconAsset = up
                            ? 'assets/file_picker/updir.png'
                            : isDir
                            ? 'assets/file_picker/folder.png'
                            : 'assets/file_picker/file.png';
                        return Builder(
                          builder: (tileCtx) {
                            return InkWell(
                              onTap: () => _onTapEntry(entity),
                              onLongPress: () {
                                final box =
                                    tileCtx.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                final origin = box.localToGlobal(Offset.zero);
                                _showFileMenu(
                                  origin +
                                      Offset(
                                        box.size.width / 2,
                                        box.size.height / 2,
                                      ),
                                  entity,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  children: [
                                    Image.asset(
                                      iconAsset,
                                      width: 24,
                                      height: 24,
                                      filterQuality: FilterQuality.medium,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  if (showEmpty)
                    Center(
                      child: Text(
                        '空',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathChip extends StatelessWidget {
  final String label;
  final bool showArrow;
  final VoidCallback onTap;

  const _PathChip({
    required this.label,
    required this.showArrow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurface)),
          if (showArrow)
            Image.asset(
              'assets/file_picker/arrow.png',
              width: 20,
              height: 20,
              filterQuality: FilterQuality.medium,
            ),
        ],
      ),
    );
  }
}
