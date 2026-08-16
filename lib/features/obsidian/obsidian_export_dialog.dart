import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/obsidian/obsidian_export_port.dart';

/// 导出到 Obsidian — 对齐 `dialog_obsidian_export.xml`
class ObsidianExportDialog extends StatefulWidget {
  /// 仅导出某本书；空=全部
  final String? bookId;
  final ObsidianExportPort? port;

  const ObsidianExportDialog({super.key, this.bookId, this.port});

  static Future<void> show(
    BuildContext context, {
    String? bookId,
    ObsidianExportPort? port,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ObsidianExportDialog(bookId: bookId, port: port),
    );
  }

  @override
  State<ObsidianExportDialog> createState() => _ObsidianExportDialogState();
}

class _ObsidianExportDialogState extends State<ObsidianExportDialog> {
  late final ObsidianExportPort _port;
  ObsidianExportMethod _method = ObsidianExportMethod.localFile;
  late final TextEditingController _apiUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _localPath;
  late final TextEditingController _vaultPath;
  bool _autoExport = false;
  bool _loading = true;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _port = widget.port ?? context.read<ObsidianExportPort>();
    _apiUrl = TextEditingController();
    _apiKey = TextEditingController();
    _localPath = TextEditingController();
    _vaultPath = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _apiUrl.dispose();
    _apiKey.dispose();
    _localPath.dispose();
    _vaultPath.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await _port.load();
    if (!mounted) return;
    setState(() {
      _method = prefs.method;
      _apiUrl.text = prefs.apiUrl;
      _apiKey.text = prefs.apiKey;
      _localPath.text = prefs.localPath;
      _vaultPath.text = prefs.vaultPath;
      _autoExport = prefs.autoExport;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = ObsidianExportPrefs(
      method: _method,
      apiUrl: _apiUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
      localPath: _localPath.text.trim(),
      vaultPath: _vaultPath.text.trim(),
      autoExport: _autoExport,
    );
    await _port.save(prefs);
  }

  Future<void> _pickDir() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择 Obsidian 仓库目录',
    );
    if (path != null && mounted) {
      setState(() => _localPath.text = path);
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final url = _apiUrl.text.trim();
      if (url.isEmpty) throw Exception('请填写 API URL');
      final code = await _port.testConnection(url: url, apiKey: _apiKey.text);
      if (!mounted) return;
      setState(() {
        _message = code > 0 ? '连接返回 HTTP $code' : '无响应状态码';
      });
    } catch (e) {
      if (mounted) setState(() => _message = '测试失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    if (!_port.isNoteEngineReady) {
      setState(() => _message = '笔记引擎未就绪');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _persist();
      if (_method == ObsidianExportMethod.localFile) {
        final out = await _port.exportLocal(
          bookId: widget.bookId,
          localPath: _localPath.text,
          vaultPath: _vaultPath.text,
        );
        if (!mounted) return;
        setState(() => _message = out);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(out)));
      } else {
        final out = await _port.exportRestApi(
          bookId: widget.bookId,
          url: _apiUrl.text,
          vaultPath: _vaultPath.text,
          apiKey: _apiKey.text,
        );
        if (!mounted) return;
        setState(() => _message = out);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(out)));
      }
    } catch (e) {
      if (mounted) setState(() => _message = '导出失败: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        builder: (ctx, scrollCtrl) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                AppBar(
                  title: const Text('导出到 Obsidian'),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          children: [
                            Text(
                              '导出方式',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            RadioGroup<ObsidianExportMethod>(
                              groupValue: _method,
                              onChanged: (v) {
                                if (v != null) setState(() => _method = v);
                              },
                              child: Column(
                                children: [
                                  RadioListTile<ObsidianExportMethod>(
                                    value: ObsidianExportMethod.restApi,
                                    title: const Text('Obsidian REST API'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  RadioListTile<ObsidianExportMethod>(
                                    value: ObsidianExportMethod.localFile,
                                    title: const Text('本地文件'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_method == ObsidianExportMethod.restApi) ...[
                              TextField(
                                controller: _apiUrl,
                                decoration: const InputDecoration(
                                  labelText: 'API URL',
                                  hintText: 'http://127.0.0.1:27123/vault/',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _apiKey,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'API Token',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _busy ? null : _testConnection,
                                  child: const Text('测试连接'),
                                ),
                              ),
                            ] else ...[
                              TextField(
                                controller: _localPath,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: '本地目录',
                                  hintText: '选择 Obsidian 仓库文件夹',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _pickDir,
                                  child: const Text('选择目录'),
                                ),
                              ),
                            ],
                            TextField(
                              controller: _vaultPath,
                              decoration: InputDecoration(
                                labelText:
                                    _method == ObsidianExportMethod.restApi
                                    ? 'Vault 内路径（可选）'
                                    : '相对子目录（可选）',
                                hintText: 'Notes/Legado',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('添加想法后自动导出'),
                              value: _autoExport,
                              onChanged: (v) =>
                                  setState(() => _autoExport = v ?? false),
                            ),
                            if (_message != null) Text(_message!),
                          ],
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _busy ? null : _export,
                        child: const Text('导出'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
