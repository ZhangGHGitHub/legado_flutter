import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/preferences/bookshelf_config_prefs_port.dart';
import '../../config/app_config.dart';
import '../../theme/legado_tokens.dart';
import '../../features/bookshelf/bookshelf_config_dialog.dart';
import 'backup_config_page.dart';
import 'other_settings_card.dart';
import 'theme_config_page.dart';
import 'web_api_settings_card.dart';

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
    final style = await context
        .read<BookshelfConfigPrefsPort>()
        .loadGroupStyle();
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
          const BackupConfigPage(),
          const ThemeConfigPage(),
          ListView(
            padding: const EdgeInsets.all(LegadoTokens.spacingMd),
            children: [
              const WebApiSettingsCard(),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('书架分组样式'),
                  subtitle: Text(
                    _bookGroupStyle == 1 ? 'Folder（侧栏）' : 'Tab（顶栏）',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final next = await BookshelfConfigDialog.show(context);
                    if (next != null && mounted) {
                      setState(() => _bookGroupStyle = next.bookGroupStyle);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              Consumer<AppConfig>(
                builder: (context, cfg, _) {
                  return Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('显示发现 Tab'),
                          subtitle: const Text('底栏「发现」入口，关闭后立即隐藏'),
                          value: cfg.showDiscovery,
                          onChanged: (v) => cfg.setShowDiscovery(v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('显示订阅 Tab'),
                          subtitle: const Text('底栏「订阅」入口，关闭后立即隐藏'),
                          value: cfg.showRSS,
                          onChanged: (v) => cfg.setShowRSS(v),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const OtherSettingsCard(),
            ],
          ),
        ],
      ),
    );
  }
}
