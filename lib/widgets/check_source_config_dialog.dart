import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/check_source_prefs.dart';

/// 校验设置 — 对齐 Jingshiro `CheckSourceConfig` / `strings_zh` check_source_*
Future<void> showCheckSourceConfigDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const CheckSourceConfigDialog(),
  );
}

class CheckSourceConfigDialog extends StatefulWidget {
  const CheckSourceConfigDialog({super.key});

  @override
  State<CheckSourceConfigDialog> createState() =>
      _CheckSourceConfigDialogState();
}

class _CheckSourceConfigDialogState extends State<CheckSourceConfigDialog> {
  static const _minTimeoutSec = 5;
  static const _maxTimeoutSec = 300;

  late final TextEditingController _timeoutCtrl;
  bool _checkSearch = true;
  bool _checkDiscovery = true;
  bool _checkToc = true;
  bool _checkContent = true;
  bool _showDebugMessage = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _timeoutCtrl = TextEditingController();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final timeout = await CheckSourcePrefs.timeoutSec();
    final search = await CheckSourcePrefs.checkSearch();
    final discovery = await CheckSourcePrefs.checkDiscovery();
    final toc = await CheckSourcePrefs.checkToc();
    final content = await CheckSourcePrefs.checkContent();
    final showDebug = await CheckSourcePrefs.showDebugMessage();
    if (!mounted) return;
    setState(() {
      _timeoutCtrl.text = '$timeout';
      _checkSearch = search;
      _checkDiscovery = discovery;
      _checkToc = toc;
      _checkContent = content;
      _showDebugMessage = showDebug;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _timeoutCtrl.dispose();
    super.dispose();
  }

  int? _parseTimeout() {
    final v = int.tryParse(_timeoutCtrl.text.trim());
    if (v == null || v < _minTimeoutSec || v > _maxTimeoutSec) return null;
    return v;
  }

  Future<void> _save() async {
    final timeout = _parseTimeout();
    if (timeout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('超时请输入 $_minTimeoutSec–$_maxTimeoutSec 之间的整数'),
        ),
      );
      return;
    }
    await CheckSourcePrefs.setTimeoutSec(timeout);
    await CheckSourcePrefs.setCheckSearch(_checkSearch);
    await CheckSourcePrefs.setCheckDiscovery(_checkDiscovery);
    await CheckSourcePrefs.setCheckToc(_checkToc);
    await CheckSourcePrefs.setCheckContent(_checkContent);
    await CheckSourcePrefs.setShowDebugMessage(_showDebugMessage);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('校验设置'),
      content: _loading
          ? const SizedBox(
              width: 240,
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '单个书源校验超时（秒）',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _timeoutCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '超时',
                      suffixText: '秒',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '校验项目',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('搜索'),
                    value: _checkSearch,
                    onChanged: (v) => setState(() => _checkSearch = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('发现'),
                    value: _checkDiscovery,
                    onChanged: (v) => setState(() => _checkDiscovery = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('目录'),
                    value: _checkToc,
                    onChanged: (v) => setState(() => _checkToc = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('正文'),
                    value: _checkContent,
                    onChanged: (v) => setState(() => _checkContent = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('显示详细信息'),
                    subtitle: const Text('校验时在书源行显示步骤文案'),
                    value: _showDebugMessage,
                    onChanged: (v) => setState(() => _showDebugMessage = v),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
