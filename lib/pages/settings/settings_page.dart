import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../replace/replace_page.dart';

/// 设置页面 - 仿 Legado "我的" 风格
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
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
      _defaultFontSize = prefs.getDouble('defaultFontSize') ?? 18;
    });
  }

  Future<void> _setSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          // ── 书源管理 ──
          _SettingTile(
            icon: Icons.rss_feed_rounded,
            iconColor: Colors.orange,
            title: '书源管理',
            subtitle: '新建、导入、编辑或管理书源',
            onTap: () => Navigator.pushNamed(context, '/sources'),
          ),
          _divider(),

          // ── TXT目录规则 ──
          _SettingTile(
            icon: Icons.description_outlined,
            iconColor: Colors.blue,
            title: 'TXT目录规则',
            subtitle: '配置TXT目录规则',
            onTap: () => _notImplemented('TXT目录规则'),
          ),
          _divider(),

          // ── 替换净化 ──
          _SettingTile(
            icon: Icons.auto_fix_high_outlined,
            iconColor: Colors.teal,
            title: '替换净化',
            subtitle: '配置替换净化规则',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReplacePage()),
            ),
          ),
          _divider(),

          // ── 字典规则 ──
          _SettingTile(
            icon: Icons.translate,
            iconColor: Colors.indigo,
            title: '字典规则',
            subtitle: '配置字典规则',
            onTap: () => _notImplemented('字典规则'),
          ),
          _divider(),

          // ── 主题模式 ──
          _SettingTile(
            icon: Icons.palette_outlined,
            iconColor: Colors.pink,
            title: '主题模式',
            subtitle: _darkMode ? '当前：深色模式' : '当前：浅色模式',
            trailing: Switch(
              value: _darkMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (v) {
                setState(() => _darkMode = v);
                _setSetting('darkMode', v);
              },
            ),
            onTap: () => _notImplemented('主题模式'),
          ),
          _divider(),

          // ── Web服务 ──
          _SettingTile(
            icon: Icons.language,
            iconColor: Colors.green,
            title: 'Web服务',
            subtitle: '用浏览器写书源或看书',
            onTap: () => _notImplemented('Web服务'),
          ),
          _divider(),

          // ── 备份与恢复 ──
          _SettingTile(
            icon: Icons.backup_rounded,
            iconColor: Colors.amber.shade700,
            title: '备份与恢复',
            subtitle: 'WebDav设置/导入旧版本数据',
            onTap: () => _notImplemented('备份与恢复'),
          ),
          _divider(),

          // ── 主题设置 ──
          _SettingTile(
            icon: Icons.dashboard_customize_outlined,
            iconColor: Colors.purple,
            title: '主题设置',
            subtitle: '与界面/颜色相关的一些设置',
            onTap: () => _notImplemented('主题设置'),
          ),
          _divider(),

          // ── 其他设置 ──
          _SettingTile(
            icon: Icons.settings_outlined,
            iconColor: Colors.grey.shade600,
            title: '其他设置',
            subtitle: '与功能相关的一些设置',
            onTap: () => _notImplemented('其他设置'),
          ),
          _divider(),

          // ── 书签 ──
          _SettingTile(
            icon: Icons.bookmark_outline_rounded,
            iconColor: Colors.red.shade400,
            title: '书签',
            subtitle: '所有书签',
            onTap: () => _notImplemented('书签'),
          ),
          _divider(),

          // ── 阅读记录 ──
          _SettingTile(
            icon: Icons.history_rounded,
            iconColor: Colors.blueGrey,
            title: '阅读记录',
            subtitle: '阅读事件记录',
            onTap: () => _notImplemented('阅读记录'),
          ),
          _divider(),

          // ── 关于 ──
          _SettingTile(
            icon: Icons.info_outline_rounded,
            iconColor: Colors.grey.shade500,
            title: '关于',
            subtitle: '版本 1.0.0',
            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: () => _notImplemented('关于'),
          ),
          _divider(),

          // ── 退出 ──
          _SettingTile(
            icon: Icons.exit_to_app_rounded,
            iconColor: Colors.red.shade400,
            title: '退出',
            subtitle: '',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退出'),
                  content: const Text('确定退出应用？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        exit(0);
                      },
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('退出'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16);

  void _notImplemented(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name（待实现）')),
    );
  }
}

/// 单个设置项（图标 + 标题 + 副标题）
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
