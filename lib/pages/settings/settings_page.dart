import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../replace/replace_page.dart';
import '../sources/sources_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;

  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _darkMode = p.getBool('darkMode') ?? false);
  }
  Future<void> _toggle(bool v) async {
    setState(() => _darkMode = v);
    (await SharedPreferences.getInstance()).setBool('darkMode', v);
  }

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // ── Logo area ──
          Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
              child: Icon(Icons.auto_stories, size: 36, color: theme.colorScheme.primary)),
            const SizedBox(height: 10),
            const Text('Legado Flutter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text('Flutter 复刻版阅读', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]))),

          const SizedBox(height: 8),

          // ── 4 icon buttons ──
          Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _IconBtn(Icons.backup_outlined, '备份管理', () {}),
              _IconBtn(Icons.cloud_outlined, 'WebDAV', () {}),
              _IconBtn(Icons.wifi, 'Web服务', () {}),
              _IconBtn(Icons.history, '阅读记录', () {}),
            ],
          ))),

          const SizedBox(height: 8),

          // ── 【设置】section ──
          _SectionHeader('设置'),
          Card(child: Column(children: [
            _Row(Icons.rss_feed, '书源管理', '新建、导入、编辑或管理书源', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SourcesPage()))),
            _Div(),
            _Row(Icons.article_outlined, 'TXT 目录规则', '配置 TXT 目录规则'),
            _Div(),
            _Row(Icons.cleaning_services_outlined, '替换净化', '配置替换净化规则', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReplacePage()))),
            _Div(),
            _Row(Icons.menu_book_outlined, '字典规则', '配置字典规则'),
            _Div(),
            _Row(Icons.palette_outlined, '主题模式', '浅色 / 深色模式切换', trailing: Switch(value: _darkMode, onChanged: _toggle)),
            _Div(),
            _Row(Icons.backup_outlined, '备份与恢复', '备份书源、书架、设置'),
          ])),

          const SizedBox(height: 8),

          // ── 【其他】section ──
          _SectionHeader('其他'),
          Card(child: Column(children: [
            _Row(Icons.bookmark_outline, '书签', '管理阅读书签'),
            _Div(),
            _Row(Icons.file_upload_outlined, '导出到 Obsidian', '一键导出笔记到 Obsidian'),
            _Div(),
            _Row(Icons.folder_open, '文件管理', '管理本地书籍文件'),
            _Div(),
            _Row(Icons.terminal, 'Legado Skill', '安装社区技能扩展'),
            _Div(),
            _Row(Icons.smart_toy_outlined, 'AI 助手', '大模型智能辅助'),
            _Div(),
            _Row(Icons.info_outline, '关于', 'v1.0.0'),
            _Div(),
            _Row(Icons.logout, '退出', '关闭应用', onTap: () => exit(0)),
          ])),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
    child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
  );
}

class _Row extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final Widget? trailing; final VoidCallback? onTap;
  const _Row(this.icon, this.title, this.subtitle, {this.trailing, this.onTap});
  @override Widget build(BuildContext c) => ListTile(
    leading: Icon(icon, size: 22),
    title: Text(title, style: const TextStyle(fontSize: 14)),
    subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
    onTap: onTap,
  );
}

class _Div extends StatelessWidget {
  @override Widget build(BuildContext c) => const Divider(height: 1, indent: 56);
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _IconBtn(this.icon, this.label, this.onTap);
  @override Widget build(BuildContext c) => GestureDetector(
    onTap: onTap,
    child: SizedBox(width: 64, child: Column(children: [
      Icon(icon, size: 28, color: Theme.of(c).colorScheme.primary), const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ])),
  );
}
