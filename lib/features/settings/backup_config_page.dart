import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../application/database/legacy_room_import_service.dart';
import '../../domain/ports/backup_local_file_port.dart';
import '../../domain/remote/webdav_entry.dart';
import '../../services/backup_service.dart';
import '../../services/database_status_service.dart';
import '../../services/engine_status_service.dart';
import '../../services/app_paths.dart';
import '../../services/legacy_room_import_service_factory.dart';
import '../../services/webdav_prefs.dart';
import '../../infrastructure/file_system/backup_local_file_adapter.dart';
import '../../theme/legado_tokens.dart';

enum BackupOperation { other, list, upload, restore, delete, rename }

String backupOperationErrorMessage(
  Object error, {
  required BackupOperation operation,
}) {
  final raw = error.toString();
  final message = raw.toLowerCase();
  final unsupported =
      message.contains('405') ||
      message.contains('501') ||
      message.contains('method not allowed') ||
      message.contains('not implemented');
  final permission =
      message.contains('401') ||
      message.contains('403') ||
      message.contains('unauthorized') ||
      message.contains('forbidden') ||
      message.contains('permission') ||
      message.contains('access denied') ||
      message.contains('无权限') ||
      message.contains('权限') ||
      message.contains('拒绝');

  if (unsupported) {
    switch (operation) {
      case BackupOperation.delete:
        return '服务器不支持删除（HTTP 405/501）。原备份未删除，仍可使用；请在服务器端启用 DELETE，或通过服务器管理界面删除。';
      case BackupOperation.rename:
        return '服务器不支持重命名（HTTP 405/501）。原备份未删除，仍可使用；请在服务器端启用 MOVE，或保留原名称。';
      case BackupOperation.restore:
        return '服务器不支持下载（HTTP 405/501）。当前数据未修改；请检查 WebDAV 读取能力后重试。';
      case BackupOperation.list:
        return '服务器不支持列出目录（HTTP 405/501）。云端原文件未改变；请检查 WebDAV 目录访问能力。';
      case BackupOperation.upload:
      case BackupOperation.other:
        return '服务器不支持此 WebDAV 操作（HTTP 405/501）。本地备份仍保留；请检查服务器能力后重试。';
    }
  }

  if (permission) {
    switch (operation) {
      case BackupOperation.delete:
        return 'WebDAV 账号没有删除权限。原备份未删除，仍可使用；请改用有删除权限的账号或联系管理员。';
      case BackupOperation.rename:
        return 'WebDAV 账号没有重命名权限。原备份未删除，仍可使用；请改用有写入权限的账号或保留原名称。';
      case BackupOperation.restore:
        return 'WebDAV 账号没有读取权限。当前数据未修改；请检查账号权限和备份目录后重试。';
      case BackupOperation.list:
        return 'WebDAV 账号没有读取目录权限。云端原文件未改变；请检查账号权限和备份目录。';
      case BackupOperation.upload:
        return 'WebDAV 账号没有写入权限。本地备份仍保留；请改用有写入权限的账号或检查备份目录。';
      case BackupOperation.other:
        return 'WebDAV 账号权限不足。现有备份和本地数据未删除；请检查账号权限后重试。';
    }
  }

  return '操作失败：$raw';
}

/// 备份与恢复 — WebDAV + 本地（Phase 4.2）
class BackupConfigPage extends StatefulWidget {
  const BackupConfigPage({
    super.key,
    this.service,
    this.localFilePort,
    this.legacyRoomImportService,
  });

  @visibleForTesting
  final BackupService? service;

  @visibleForTesting
  final BackupLocalFilePort? localFilePort;

  @visibleForTesting
  final LegacyRoomImportService? legacyRoomImportService;

  @override
  State<BackupConfigPage> createState() => _BackupConfigPageState();
}

class _BackupConfigPageState extends State<BackupConfigPage> {
  late final BackupService _service = widget.service ?? BackupService();
  late final BackupLocalFilePort _localFilePort =
      widget.localFilePort ?? FileSystemBackupLocalFileAdapter(_service);
  late final LegacyRoomImportService _legacyRoomImportService =
      widget.legacyRoomImportService ?? LegacyRoomImportServices.create();
  bool _busy = false;
  WebDavConfig? _webdav;
  List<LocalBackupEntry> _localBackups = [];
  List<WebDavEntry> _remoteBackups = [];
  bool _remoteBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final webdav = await WebDavPrefs.load();
    List<LocalBackupEntry> local = [];
    if (_localFilePort.isAvailable) {
      try {
        local = await _localFilePort.listBackups();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _webdav = webdav;
        _localBackups = local;
      });
    }
    if (webdav.isReady) {
      await _refreshRemoteBackups(silent: true);
    }
  }

  Future<void> _refreshRemoteBackups({bool silent = false}) async {
    if (_webdav?.isReady != true) return;
    if (mounted) setState(() => _remoteBusy = true);
    try {
      final items = await _service.listWebDavBackups();
      if (mounted) setState(() => _remoteBackups = items);
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backupOperationErrorMessage(e, operation: BackupOperation.list),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
  }

  Future<void> _importLegacyRoomDatabase() async {
    if (_busy) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite', 'sqlite3'],
    );
    final sourcePath = result?.files.single.path;
    if (sourcePath == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入原版数据库'),
        content: const Text('导入前会先保存当前数据库备份。导入失败会自动回滚；相同数据库重复导入会跳过。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final backupsDir = await AppPaths.backupsDir();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final backupPath = p.join(
        backupsDir.path,
        'legacy_room_pre_import_$stamp.json',
      );
      final report = _legacyRoomImportService.importDatabase(
        sourcePath: sourcePath,
        backupPath: backupPath,
      );
      await _load();
      if (!mounted) return;
      final duplicate = report.skippedDuplicate ? '，重复快照已跳过' : '';
      final warning = report.hasWarnings ? '，请查看迁移警告' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '原版数据库导入完成：${report.counts['books'] ?? 0} 本书$duplicate$warning',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('原版数据库导入失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(
    Future<void> Function() action,
    String success, {
    BackupOperation operation = BackupOperation.other,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(backupOperationErrorMessage(e, operation: operation)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRestore(
    Future<void> Function() restore, {
    BackupOperation operation = BackupOperation.restore,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('将用备份覆盖当前书架、书源与设置，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(restore, '恢复完成', operation: operation);
    }
  }

  Future<void> _restoreFromWebDavList() async {
    if (_webdav?.isReady != true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先在「我的」配置 WebDAV')));
      return;
    }
    setState(() => _busy = true);
    try {
      await _refreshRemoteBackups();
      if (!mounted) return;
      if (_remoteBackups.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('WebDAV 上暂无备份文件')));
        return;
      }
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('选择 WebDAV 备份'),
          children: _remoteBackups
              .map(
                (e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, e.path),
                  child: Text('${e.name} (${e.size} B)'),
                ),
              )
              .toList(),
        ),
      );
      if (selected != null) {
        if (mounted) setState(() => _busy = false);
        await _confirmRestore(() => _service.restoreFromWebDav(selected));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backupOperationErrorMessage(e, operation: BackupOperation.list),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteRemoteBackup(WebDavEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除备份'),
        content: Text('确定删除「${entry.name}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _remoteBusy = true);
    try {
      await _service.deleteWebDavBackup(entry.path);
      await _refreshRemoteBackups(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已删除 ${entry.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backupOperationErrorMessage(e, operation: BackupOperation.delete),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
  }

  Future<void> _renameRemoteBackup(WebDavEntry entry) async {
    final controller = TextEditingController(text: entry.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名备份'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim() == entry.name || !mounted) return;
    setState(() => _remoteBusy = true);
    try {
      await _service.renameWebDavBackup(entry.path, name);
      await _refreshRemoteBackups(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('重命名成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backupOperationErrorMessage(e, operation: BackupOperation.rename),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _remoteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engineReady =
        EngineStatusService.isAvailable && DatabaseStatusService.isReady;
    final webdavOk = _webdav?.isReady ?? false;

    return ListView(
      padding: const EdgeInsets.all(LegadoTokens.spacingMd),
      children: [
        if (!engineReady)
          Card(
            color: theme.colorScheme.errorContainer,
            child: const ListTile(
              leading: Icon(Icons.warning_amber),
              title: Text('Rust 引擎或数据库未就绪'),
              subtitle: Text('请先编译 legado_engine 并启动应用'),
            ),
          ),
        Card(
          child: ListTile(
            leading: Icon(
              webdavOk ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: webdavOk
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
            title: const Text('WebDAV'),
            subtitle: Text(
              webdavOk ? (_webdav!.url) : '未配置 — 请在「我的 → WebDAV」设置',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('本地备份', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: engineReady && !_busy
              ? () => _run(() async {
                  final f = await _service.backupToLocalFile();
                  debugPrint('saved ${f.path}');
                }, '已保存到应用文档/backups/')
              : null,
          icon: const Icon(Icons.save_alt),
          label: const Text('一键本地备份'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: engineReady && !_busy
              ? () => _confirmRestore(() async {
                  await _service.pickAndRestore();
                })
              : null,
          icon: const Icon(Icons.restore),
          label: const Text('从文件恢复'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: engineReady && !_busy ? _importLegacyRoomDatabase : null,
          icon: const Icon(Icons.storage_outlined),
          label: const Text('导入原版数据库'),
        ),
        if (_localBackups.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('最近本地备份', style: theme.textTheme.labelMedium),
          ..._localBackups
              .take(3)
              .map(
                (f) => ListTile(
                  dense: true,
                  title: Text(f.name, style: const TextStyle(fontSize: 13)),
                  subtitle: Text(f.path, style: const TextStyle(fontSize: 11)),
                  onTap: engineReady && !_busy
                      ? () => _confirmRestore(() async {
                          await _service.restoreFromBytes(
                            await _localFilePort.readBytes(f),
                          );
                        })
                      : null,
                ),
              ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('WebDAV 备份', style: theme.textTheme.titleSmall),
            ),
            IconButton(
              tooltip: '刷新 WebDAV 备份',
              onPressed: webdavOk && !_busy && !_remoteBusy
                  ? _refreshRemoteBackups
                  : null,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (webdavOk && _remoteBusy)
          const LinearProgressIndicator(minHeight: 2),
        if (webdavOk && !_remoteBusy && _remoteBackups.isEmpty)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_queue_outlined),
            title: Text('暂无云端备份'),
          ),
        if (webdavOk && !_remoteBusy)
          ..._remoteBackups.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_outlined),
              title: Text(entry.name),
              subtitle: Text('${entry.size} B'),
              onTap: !_busy
                  ? () => _confirmRestore(
                      () => _service.restoreFromWebDav(entry.path),
                      operation: BackupOperation.restore,
                    )
                  : null,
              trailing: PopupMenuButton<String>(
                tooltip: '备份操作',
                onSelected: (action) {
                  if (action == 'rename') {
                    _renameRemoteBackup(entry);
                  } else if (action == 'delete') {
                    _deleteRemoteBackup(entry);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('重命名')),
                  PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: engineReady && webdavOk && !_busy
              ? () => _run(
                  _service.backupToWebDav,
                  '已上传到 WebDAV',
                  operation: BackupOperation.upload,
                )
              : null,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('上传到 WebDAV'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: engineReady && webdavOk && !_busy
              ? _restoreFromWebDavList
              : null,
          icon: const Icon(Icons.cloud_download_outlined),
          label: const Text('从 WebDAV 恢复'),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
