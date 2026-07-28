import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../services/app_paths.dart';
import '../../services/cache_service.dart';
import '../../services/engine_status_service.dart';
import '../../services/network_prefs.dart';
import '../../services/tts_service.dart';
import '../../theme/legado_tokens.dart';

/// 其它设置 — 代理 / DNS / 缓存 / 数据目录（Phase 4.3）
class OtherSettingsCard extends StatefulWidget {
  const OtherSettingsCard({super.key});

  @override
  State<OtherSettingsCard> createState() => _OtherSettingsCardState();
}

class _OtherSettingsCardState extends State<OtherSettingsCard> {
  final _cacheService = CacheService();
  bool _loading = true;
  bool _proxyEnabled = false;
  String _proxyType = 'http';
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '7890');
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _dnsCtrl = TextEditingController();
  final _dataDirCtrl = TextEditingController();
  CacheStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _dnsCtrl.dispose();
    _dataDirCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final net = await NetworkPrefs.load();
      final dataDir = await AppDataPrefs.loadDataDir();
      CacheStats? stats;
      try {
        stats = await _cacheService.loadStats();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _proxyEnabled = net.proxyEnabled;
        _proxyType = net.proxyType;
        _hostCtrl.text = net.proxyHost;
        _portCtrl.text = '${net.proxyPort}';
        _userCtrl.text = net.proxyUsername;
        _passCtrl.text = net.proxyPassword;
        _dnsCtrl.text = net.dnsServers;
        _dataDirCtrl.text = dataDir ?? '';
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  NetworkPrefsConfig _currentNetworkConfig() {
    return NetworkPrefsConfig(
      proxyEnabled: _proxyEnabled,
      proxyType: _proxyType,
      proxyHost: _hostCtrl.text.trim(),
      proxyPort: int.tryParse(_portCtrl.text.trim()) ?? 7890,
      proxyUsername: _userCtrl.text.trim(),
      proxyPassword: _passCtrl.text,
      dnsServers: _dnsCtrl.text.trim(),
    );
  }

  Future<void> _saveNetwork() async {
    final config = _currentNetworkConfig();
    await NetworkPrefs.save(config);
    await NetworkPrefs.applyToEngine(config);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('网络设置已保存')));
    }
  }

  Future<void> _saveDataDir() async {
    final path = _dataDirCtrl.text.trim();
    await AppDataPrefs.saveDataDir(path.isEmpty ? null : path);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据目录已保存，重启应用后生效')));
    }
  }

  Future<void> _clearCache(String type) async {
    switch (type) {
      case 'book':
        await _cacheService.clearBookCache();
      case 'engine':
        await _cacheService.clearEngineCache();
      case 'backup':
        await _cacheService.clearBackups();
      case 'all':
        await _cacheService.clearAll();
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('缓存已清理')));
    }
  }

  Future<void> _clearHttpTtsCache() async {
    try {
      await TtsService.instance.clearHttpTtsCache();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('HTTP TTS 缓存已清理')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('HTTP TTS 缓存清理失败')));
      }
    }
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

    final engineReady = EngineStatusService.isAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('默认首页', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LegadoTokens.spacingMd),
            child: Row(
              children: [
                const Text('启动时默认显示'),
                const SizedBox(width: 16),
                ListenableBuilder(
                  listenable: AppConfig.instance,
                  builder: (context, _) {
                    return DropdownButton<String>(
                      value: AppConfig.instance.defaultHomePage,
                      items: const [
                        DropdownMenuItem(value: 'bookshelf', child: Text('书架')),
                        DropdownMenuItem(value: 'explore', child: Text('发现')),
                        DropdownMenuItem(value: 'rss', child: Text('订阅')),
                        DropdownMenuItem(value: 'mine', child: Text('我的')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          AppConfig.instance.setDefaultHomePage(v);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('网络代理', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LegadoTokens.spacingMd),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('启用代理'),
                  subtitle: Text(_proxyType == 'socks5' ? 'SOCKS5' : 'HTTP'),
                  value: _proxyEnabled,
                  onChanged: engineReady
                      ? (v) => setState(() => _proxyEnabled = v)
                      : null,
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'http', label: Text('HTTP')),
                    ButtonSegment(value: 'socks5', label: Text('SOCKS5')),
                  ],
                  selected: {_proxyType},
                  onSelectionChanged: engineReady
                      ? (s) => setState(() => _proxyType = s.first)
                      : null,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _hostCtrl,
                  decoration: const InputDecoration(
                    labelText: '代理主机',
                    hintText: '127.0.0.1',
                  ),
                ),
                TextField(
                  controller: _portCtrl,
                  decoration: const InputDecoration(labelText: '端口'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(labelText: '用户名（可选）'),
                ),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '密码（可选）'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dnsCtrl,
                  decoration: const InputDecoration(
                    labelText: '自定义 DNS',
                    hintText: '8.8.8.8,1.1.1.1',
                    helperText: '逗号分隔，配置将持久化',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: engineReady ? _saveNetwork : null,
                  child: const Text('保存网络设置'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('数据目录', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LegadoTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _dataDirCtrl,
                  decoration: const InputDecoration(
                    labelText: '自定义数据目录',
                    hintText: '留空使用系统默认目录',
                    helperText: '存放 legado.db、书籍缓存与备份',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saveDataDir,
                  child: const Text('保存数据目录'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('缓存管理', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(LegadoTokens.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_stats != null) ...[
                  Text('书籍缓存：${_stats!.bookCacheLabel}'),
                  Text('数据库：${_stats!.dbLabel}'),
                  Text('本地备份：${_stats!.backupsLabel}'),
                  Text('合计：${_stats!.totalLabel}'),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _clearCache('book'),
                      child: const Text('清书籍缓存'),
                    ),
                    OutlinedButton(
                      onPressed: engineReady
                          ? () => _clearCache('engine')
                          : null,
                      child: const Text('清 Cookie/JS'),
                    ),
                    OutlinedButton(
                      onPressed: () => _clearCache('backup'),
                      child: const Text('清本地备份'),
                    ),
                    OutlinedButton(
                      onPressed: _clearHttpTtsCache,
                      child: const Text('清理 HTTP TTS 缓存'),
                    ),
                    FilledButton.tonal(
                      onPressed: engineReady ? () => _clearCache('all') : null,
                      child: const Text('一键清理'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
