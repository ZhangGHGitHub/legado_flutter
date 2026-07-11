import 'dart:io';

import 'package:flutter/material.dart';

import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../services/backup_service.dart';
import '../../services/webdav_prefs.dart';
import '../../theme/legado_tokens.dart';

/// 备份与恢复 — WebDAV + 本地（Phase 4.2）
class BackupConfigPage extends StatefulWidget {
  const BackupConfigPage({super.key});

  @override
  State<BackupConfigPage> createState() => _BackupConfigPageState();
}

class _BackupConfigPageState extends State<BackupConfigPage> {
  final _service = BackupService();
  bool _busy = false;
  WebDavConfig? _webdav;
  List<File> _localBackups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final webdav = await WebDavPrefs.load();
    List<File> local = [];
    if (LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady) {
      try {
        local = await _service.listLocalBackups();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _webdav = webdav;
        _localBackups = local;
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmRestore(Future<void> Function() restore) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复'),
        content: const Text('将用备份覆盖当前书架、书源与设置，是否继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('恢复')),
        ],
      ),
    );
    if (ok == true) {
      await _run(restore, '恢复完成');
    }
  }

  Future<void> _restoreFromWebDavList() async {
    if (_webdav?.isConfigured != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在「我的」配置 WebDAV')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final items = await _service.listWebDavBackups();
      if (!mounted) return;
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebDAV 上暂无备份文件')),
        );
        return;
      }
      final selected = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('选择 WebDAV 备份'),
          children: items
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
        await _confirmRestore(
          () => _service.restoreFromWebDav(selected),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('列出备份失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final engineReady = LegadoEngineBridge.isAvailable && LegadoDbBridge.isReady;
    final webdavOk = _webdav?.isConfigured ?? false;

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
              color: webdavOk ? theme.colorScheme.primary : theme.colorScheme.outline,
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
        if (_localBackups.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('最近本地备份', style: theme.textTheme.labelMedium),
          ..._localBackups.take(3).map(
            (f) => ListTile(
              dense: true,
              title: Text(f.uri.pathSegments.last, style: const TextStyle(fontSize: 13)),
              subtitle: Text(f.path, style: const TextStyle(fontSize: 11)),
              onTap: engineReady && !_busy
                  ? () => _confirmRestore(() async {
                        final raw = await f.readAsString();
                        await _service.restoreFromJson(raw);
                      })
                  : null,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('WebDAV 备份', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: engineReady && webdavOk && !_busy
              ? () => _run(_service.backupToWebDav, '已上传到 WebDAV')
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
