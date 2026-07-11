import 'package:flutter/material.dart';

import '../../services/bookshelf_prefs.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/empty_state.dart';
import 'theme_config_page.dart';

/// 配置中心 — 对齐 ConfigActivity（F2 骨架）
class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key, this.initialTab = 0});

  /// 0=备份, 1=主题, 2=其它
  final int initialTab;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _bookGroupStyle = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final style = await BookshelfPrefs.loadGroupStyle();
    if (mounted) setState(() => _bookGroupStyle = style);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '备份'),
            Tab(text: '主题'),
            Tab(text: '其它'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _ConfigPlaceholder(
            icon: Icons.backup_outlined,
            title: '备份与恢复',
            subtitle: 'F3 将实现本地/WebDAV 备份书源、书架与设置',
          ),
          const ThemeConfigPage(),
          ListView(
            padding: const EdgeInsets.all(LegadoTokens.spacingMd),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text('书架网格布局'),
                  subtitle: Text(
                    _bookGroupStyle == 1 ? 'style2 封面墙' : 'style1 列表',
                  ),
                  value: _bookGroupStyle == 1,
                  onChanged: (v) async {
                    final style = v ? 1 : 0;
                    await BookshelfPrefs.saveGroupStyle(style);
                    if (mounted) setState(() => _bookGroupStyle = style);
                  },
                ),
              ),
              const SizedBox(height: 12),
              const _ConfigPlaceholder(
                icon: Icons.tune,
                title: '更多偏好',
                subtitle: '翻页模式、默认首页等设置将在后续版本提供',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ConfigPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(icon: icon, title: title, subtitle: subtitle);
  }
}
