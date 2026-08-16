import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/source_rules/check_source_prefs_port.dart';
import 'check_source_config_dialog.dart';

/// 校验前输入关键词 — 对齐 Jingshiro 校验书源弹窗
Future<String?> showCheckSourceKeywordDialog(
  BuildContext context, {
  CheckSourcePrefsPort? prefs,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => CheckSourceKeywordDialog(prefs: prefs),
  );
}

class CheckSourceKeywordDialog extends StatefulWidget {
  const CheckSourceKeywordDialog({super.key, this.prefs});

  final CheckSourcePrefsPort? prefs;

  @override
  State<CheckSourceKeywordDialog> createState() =>
      _CheckSourceKeywordDialogState();
}

class _CheckSourceKeywordDialogState extends State<CheckSourceKeywordDialog> {
  late final TextEditingController _keywordCtrl;
  late final CheckSourcePrefsPort _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _prefs =
        widget.prefs ??
        Provider.of<CheckSourcePrefsPort?>(context, listen: false) ??
        const UnavailableCheckSourcePrefsPort();
    _keywordCtrl = TextEditingController();
    _loadLastKeyword();
  }

  Future<void> _loadLastKeyword() async {
    final last = await _prefs.lastKeyword();
    if (!mounted) return;
    _keywordCtrl.text = last;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.pop(context, _keywordCtrl.text.trim());
  }

  Future<void> _openConfig() async {
    await showCheckSourceConfigDialog(context, prefs: _prefs);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('校验书源'),
      content: _loading
          ? const SizedBox(
              width: 240,
              height: 56,
              child: Center(child: CircularProgressIndicator()),
            )
          : TextField(
              controller: _keywordCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '校验关键字（checkKeyWord）',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
            ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _loading ? null : _openConfig,
          child: const Text('校验设置'),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirm,
          child: const Text('确定校验'),
        ),
      ],
    );
  }
}
