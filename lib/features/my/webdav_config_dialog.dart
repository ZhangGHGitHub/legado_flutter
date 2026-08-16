import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/mine/webdav_config_dialog_port.dart';

/// WebDAV 配置 Dialog — 供「我的」与「远程书籍 → 服务器配置」复用。
class WebDavConfigDialog extends StatefulWidget {
  const WebDavConfigDialog({super.key, this.initial, this.port});

  final WebDavConfig? initial;
  final WebDavConfigDialogPort? port;

  static Future<WebDavConfig?> show(
    BuildContext context, {
    WebDavConfig? initial,
    WebDavConfigDialogPort? port,
  }) {
    return showDialog<WebDavConfig>(
      context: context,
      builder: (_) => WebDavConfigDialog(initial: initial, port: port),
    );
  }

  @override
  State<WebDavConfigDialog> createState() => _WebDavConfigDialogState();
}

class _WebDavConfigDialogState extends State<WebDavConfigDialog> {
  late final WebDavConfigDialogPort _port;
  late final TextEditingController _url;
  late final TextEditingController _account;
  late final TextEditingController _password;
  late final TextEditingController _dir;
  late final TextEditingController _device;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _port = widget.port ?? context.read<WebDavConfigDialogPort>();
    final c = widget.initial;
    _url = TextEditingController(text: c?.url ?? '');
    _account = TextEditingController(text: c?.account ?? '');
    _password = TextEditingController(text: c?.password ?? '');
    _dir = TextEditingController(text: c?.dir ?? '/legado');
    _device = TextEditingController(text: c?.device ?? 'Legado Flutter');
    if (c == null) {
      _port.load().then((loaded) {
        if (!mounted) return;
        _url.text = loaded.url;
        _account.text = loaded.account;
        _password.text = loaded.password;
        _dir.text = loaded.dir;
        _device.text = loaded.device;
      });
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _account.dispose();
    _password.dispose();
    _dir.dispose();
    _device.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final config = WebDavConfig(
      url: _url.text.trim(),
      account: _account.text.trim(),
      password: _password.text,
      dir: _dir.text.trim().isEmpty ? '/legado' : _dir.text.trim(),
      device: _device.text.trim().isEmpty
          ? 'Legado Flutter'
          : _device.text.trim(),
    );
    await _port.save(config);
    if (config.isReady) {
      try {
        await _port.initialize(config);
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('WebDAV 连接或目录初始化失败: $e')));
        return;
      }
    }
    if (!mounted) return;
    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('服务器配置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: '服务器 URL',
                hintText: 'https://dav.example.com',
              ),
            ),
            TextField(
              controller: _account,
              decoration: const InputDecoration(
                labelText: '账号',
                helperText: '远程书籍需同时填写账号与密码',
              ),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: '密码'),
            ),
            TextField(
              controller: _dir,
              decoration: const InputDecoration(
                labelText: '目录',
                helperText: '远程书籍浏览根为「目录/books」',
              ),
            ),
            TextField(
              controller: _device,
              decoration: const InputDecoration(labelText: '设备名'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
