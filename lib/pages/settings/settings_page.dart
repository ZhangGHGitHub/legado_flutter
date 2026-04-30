import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../replace/replace_page.dart';

/// 设置页面 - 应用配置
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _autoDownload = false;
  double _defaultFontSize = 18;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _autoDownload = prefs.getBool('autoDownload') ?? false;
      _defaultFontSize = prefs.getDouble('defaultFontSize') ?? 18;
    });
  }

  Future<void> _setSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('defaultFontSize', size);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ── 内容净化 ──
          const _SectionHeader(title: '内容净化'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                radius: 16,
                child: Icon(Icons.auto_fix_high, size: 18,
                    color: theme.colorScheme.primary),
              ),
              title: const Text('替换净化'),
              subtitle: const Text('去除广告脚注、排版净化'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReplacePage()),
              ),
            ),
          ),

          // ── 阅读设置 ──
          const _SectionHeader(title: '阅读设置'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('深色模式'),
                  subtitle: const Text('跟随系统深色主题'),
                  value: _darkMode,
                  onChanged: (v) {
                    setState(() => _darkMode = v);
                    _setSetting('darkMode', v);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('自动下载'),
                  subtitle: const Text('添加书籍后自动下载章节'),
                  value: _autoDownload,
                  onChanged: (v) {
                    setState(() => _autoDownload = v);
                    _setSetting('autoDownload', v);
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('默认字体大小'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_defaultFontSize > 12) {
                            setState(() => _defaultFontSize -= 1);
                            _setFontSize(_defaultFontSize);
                          }
                        },
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${_defaultFontSize.toInt()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (_defaultFontSize < 32) {
                            setState(() => _defaultFontSize += 1);
                            _setFontSize(_defaultFontSize);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 关于 ──
          const _SectionHeader(title: '关于'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    radius: 16,
                    child: Icon(Icons.info_outline, size: 18,
                        color: theme.colorScheme.primary),
                  ),
                  title: const Text('版本'),
                  trailing: const Text('1.1.0'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    radius: 16,
                    child: Icon(Icons.code, size: 18,
                        color: theme.colorScheme.secondary),
                  ),
                  title: const Text('开源许可'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Legado Flutter',
                      applicationVersion: '1.1.0',
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    radius: 16,
                    child: Icon(Icons.storage, size: 18,
                        color: theme.colorScheme.tertiary),
                  ),
                  title: const Text('清空缓存'),
                  subtitle: const Text('清除本地章节缓存'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('清空缓存'),
                        content: const Text('确定删除所有本地章节缓存？书籍和书源配置不受影响。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('缓存已清理')),
                              );
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
