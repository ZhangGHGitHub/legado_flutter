import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../services/web_api_prefs.dart';
import '../../services/web_api_service.dart';
import '../../src/rust/api.dart' as rust_api;

/// 配置页 Web API 设置卡片
class WebApiSettingsCard extends StatefulWidget {
  const WebApiSettingsCard({super.key});

  @override
  State<WebApiSettingsCard> createState() => _WebApiSettingsCardState();
}

class _WebApiSettingsCardState extends State<WebApiSettingsCard> {
  bool _loading = true;
  bool _enabled = false;
  int _port = WebApiPrefs.defaultPort;
  final _portCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  rust_api.WebApiStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _portCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await WebApiPrefs.load();
    final status = WebApiService.currentStatus();
    if (!mounted) return;
    setState(() {
      _enabled = config.enabled;
      _port = config.port;
      _portCtrl.text = '${config.port}';
      _tokenCtrl.text = config.token;
      _status = status;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (!LegadoEngineBridge.isAvailable || !LegadoDbBridge.isReady) {
      _showSnack('Rust 引擎或数据库未就绪');
      return;
    }
    setState(() => _loading = true);
    final status = await WebApiService.setEnabled(value);
    await _load();
    if (!mounted) return;
    _showSnack(
      value
          ? 'Web API 已启动: ${status?.baseUrl ?? ''}'
          : 'Web API 已停止',
    );
  }

  Future<void> _applySettings() async {
    final port = int.tryParse(_portCtrl.text.trim()) ?? WebApiPrefs.defaultPort;
    final token = _tokenCtrl.text.trim();
    await WebApiPrefs.save(
      WebApiConfig(enabled: _enabled, port: port, token: token),
    );
    if (_enabled) {
      setState(() => _loading = true);
      final status = await WebApiService.start(port: port, token: token);
      if (status != null) {
        await WebApiPrefs.save(
          WebApiConfig(enabled: true, port: status.port, token: status.token),
        );
      }
      await _load();
      if (mounted) _showSnack('Web API 配置已应用');
    } else {
      await _load();
      if (mounted) _showSnack('配置已保存');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final running = _status?.running ?? false;
    final baseUrl = _status?.baseUrl ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Web API 服务'),
              subtitle: Text(
                running ? '运行中 · $baseUrl' : '局域网 HTTP 接口（书架/书源/阅读记录）',
              ),
              value: _enabled,
              onChanged: _toggle,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '端口',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Token（留空自动生成）',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _applySettings,
                  child: const Text('应用'),
                ),
                if (running && baseUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      final token = _status?.token ?? _tokenCtrl.text.trim();
                      final url = '$baseUrl/api/books?token=$token';
                      Clipboard.setData(ClipboardData(text: url));
                      _showSnack('API 地址已复制');
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制书架 API'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '端点: GET/POST /api/books · DELETE /api/books/:id · '
              'GET /api/books/:id/chapters · GET /api/sources · GET /api/records',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
