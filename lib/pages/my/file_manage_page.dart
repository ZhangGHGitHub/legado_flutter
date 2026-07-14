import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../services/app_paths.dart';
import '../../widgets/empty_state.dart';

/// 文件管理 — 对齐 Jingshiro [FileManageActivity] 基础浏览（数据目录内）
class FileManagePage extends StatefulWidget {
  const FileManagePage({super.key});

  @override
  State<FileManagePage> createState() => _FileManagePageState();
}

class _FileManagePageState extends State<FileManagePage> {
  Directory? _root;
  Directory? _current;
  List<FileSystemEntity> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final root = await AppPaths.dataRoot();
      if (!mounted) return;
      setState(() {
        _root = root;
        _current = root;
      });
      await _loadDir(root);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadDir(Directory dir) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await dir.list().toList();
      list.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir != bDir) return aDir ? -1 : 1;
        return p.basename(a.path).toLowerCase().compareTo(
              p.basename(b.path).toLowerCase(),
            );
      });
      if (!mounted) return;
      setState(() {
        _current = dir;
        _entries = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  bool get _atRoot {
    final root = _root;
    final cur = _current;
    if (root == null || cur == null) return true;
    return p.equals(root.path, cur.path);
  }

  Future<void> _goUp() async {
    final cur = _current;
    final root = _root;
    if (cur == null || root == null || _atRoot) return;
    final parent = cur.parent;
    if (p.isWithin(root.path, parent.path) || p.equals(root.path, parent.path)) {
      await _loadDir(parent);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_atRoot) {
      await _goUp();
      return false;
    }
    return true;
  }

  Future<void> _openEntry(FileSystemEntity entity) async {
    if (entity is Directory) {
      await _loadDir(entity);
      return;
    }
    if (entity is File) {
      await _showFileActions(entity);
    }
  }

  Future<void> _showFileActions(File file) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('复制路径'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('分享'),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text('删除', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: file.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已复制路径')),
          );
        }
      case 'share':
        await Share.shareXFiles([XFile(file.path)]);
      case 'delete':
        await _confirmDelete(file);
    }
  }

  Future<void> _confirmDelete(FileSystemEntity entity) async {
    final name = p.basename(entity.path);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除'),
        content: Text('确定删除「$name」？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await entity.delete(recursive: true);
      final cur = _current;
      if (cur != null) await _loadDir(cur);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final curPath = _current?.path ?? '';
    final relative = (_root != null && curPath.isNotEmpty)
        ? (p.equals(_root!.path, curPath)
            ? '数据目录'
            : p.relative(curPath, from: _root!.path))
        : '';

    return PopScope(
      canPop: _atRoot,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('文件管理'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: _current == null ? null : () => _loadDir(_current!),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (!_atRoot)
                      IconButton(
                        tooltip: '上级目录',
                        onPressed: _goUp,
                        icon: const Icon(Icons.arrow_upward),
                      ),
                    Expanded(
                      child: Text(
                        relative.isEmpty ? '…' : relative,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? EmptyState(
                          icon: Icons.error_outline,
                          title: '无法打开目录',
                          subtitle: _error!,
                        )
                      : _entries.isEmpty
                          ? const EmptyState(
                              icon: Icons.folder_open,
                              title: '空目录',
                              subtitle: '当前目录下没有文件',
                            )
                          : RefreshIndicator(
                              onRefresh: () => _loadDir(_current!),
                              child: ListView.separated(
                                itemCount: _entries.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final entity = _entries[index];
                                  final name = p.basename(entity.path);
                                  final isDir = entity is Directory;
                                  return ListTile(
                                    leading: Icon(
                                      isDir
                                          ? Icons.folder
                                          : Icons.insert_drive_file_outlined,
                                      color: isDir
                                          ? Theme.of(context).colorScheme.primary
                                          : null,
                                    ),
                                    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: isDir
                                        ? const Text('文件夹')
                                        : FutureBuilder<int>(
                                            future: (entity as File).length(),
                                            builder: (ctx, snap) {
                                              if (!snap.hasData) return const Text('文件');
                                              return Text(_formatSize(snap.data!));
                                            },
                                          ),
                                    onTap: () => _openEntry(entity),
                                    onLongPress: () => _confirmDelete(entity),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
