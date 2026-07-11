import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../bridge/legado_engine_bridge.dart';
import '../../services/webdav_prefs.dart';
import '../../theme/app_theme.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/legado_card.dart';
import '../../widgets/legado_list_tile.dart';
import '../../widgets/quick_action_button.dart';
import '../book/bookmark_page.dart';
import '../config/config_page.dart';
import '../config/feature_placeholder_page.dart';
import '../reader/ai_chat_page.dart';
import '../replace/replace_page.dart';
import '../sources/sources_page.dart';
import 'read_record_page.dart';
import 'reading_skill_page.dart';

/// 我的 Tab — 对齐 Jingshiro [MyFragment](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/my/MyFragment.kt)
class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool _webServiceOn = false;

  @override
  void initState() {
    super.initState();
    _loadWebService();
  }

  Future<void> _loadWebService() async {
    final on = await WebDavPrefs.loadWebServiceOn();
    if (mounted) setState(() => _webServiceOn = on);
  }

  Future<void> _showWebDavDialog() async {
    final config = await WebDavPrefs.load();
    final urlCtl = TextEditingController(text: config.url);
    final accountCtl = TextEditingController(text: config.account);
    final passwordCtl = TextEditingController(text: config.password);
    final dirCtl = TextEditingController(text: config.dir);
    final deviceCtl = TextEditingController(text: config.device);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('WebDAV 配置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: urlCtl,
                decoration: const InputDecoration(
                  labelText: '服务器 URL',
                  hintText: 'https://dav.example.com',
                ),
              ),
              TextField(
                controller: accountCtl,
                decoration: const InputDecoration(labelText: '账号'),
              ),
              TextField(
                controller: passwordCtl,
                obscureText: true,
                decoration: const InputDecoration(labelText: '密码'),
              ),
              TextField(
                controller: dirCtl,
                decoration: const InputDecoration(labelText: '目录'),
              ),
              TextField(
                controller: deviceCtl,
                decoration: const InputDecoration(labelText: '设备名'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await WebDavPrefs.save(
                WebDavConfig(
                  url: urlCtl.text.trim(),
                  account: accountCtl.text.trim(),
                  password: passwordCtl.text,
                  dir: dirCtl.text.trim().isEmpty ? '/legado' : dirCtl.text.trim(),
                  device: deviceCtl.text.trim().isEmpty
                      ? 'Legado Flutter'
                      : deviceCtl.text.trim(),
                ),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('WebDAV 配置已保存')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    urlCtl.dispose();
    accountCtl.dispose();
    passwordCtl.dispose();
    dirCtl.dispose();
    deviceCtl.dispose();
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openConfig(int tab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConfigPage(initialTab: tab)),
    );
  }

  Future<void> _showThemeModeDialog() async {
    final controller = context.read<ThemeModeController>();
    const labels = ['跟随系统', '浅色模式', '深色模式'];
    final modes = LegadoThemeMode.values;
    final current = modes.indexOf(controller.mode);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (i) {
            return RadioListTile<int>(
              title: Text(labels[i]),
              value: i,
              groupValue: current,
              onChanged: (v) async {
                if (v == null) return;
                await controller.setMode(modes[v]);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }),
        ),
      ),
    );
  }

  void _showAbout() {
    final engine = LegadoEngineBridge.isAvailable
        ? 'Rust 引擎 v${LegadoEngineBridge.engineVersion()}'
        : 'Rust 引擎未加载';
    showAboutDialog(
      context: context,
      applicationName: 'Legado Flutter',
      applicationVersion: '1.0.0',
      applicationLegalese: '对齐 Jingshiro/Legado 的 Flutter 复刻版\n$engine',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeLabel = switch (context.watch<ThemeModeController>().mode) {
      LegadoThemeMode.system => '跟随系统',
      LegadoThemeMode.light => '浅色模式',
      LegadoThemeMode.dark => '深色模式',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: LegadoTokens.spacingSm,
          vertical: LegadoTokens.spacingSm,
        ),
        children: [
          LegadoCard(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Legado Flutter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '对齐 Jingshiro Legado',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          LegadoCard(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                QuickActionButton(
                  icon: Icons.backup_outlined,
                  label: '备份恢复',
                  onTap: () => _openConfig(0),
                  onLongPress: () => _openConfig(0),
                ),
                QuickActionButton(
                  icon: Icons.cloud_outlined,
                  label: 'WebDAV',
                  onTap: _showWebDavDialog,
                ),
                QuickActionButton(
                  icon: Icons.wifi,
                  label: _webServiceOn ? '已开启' : 'Web服务',
                  onTap: () async {
                    final next = !_webServiceOn;
                    await WebDavPrefs.saveWebServiceOn(next);
                    if (mounted) setState(() => _webServiceOn = next);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            next
                                ? 'Web 服务 UI 占位：已开启（服务未实现）'
                                : 'Web 服务已关闭',
                          ),
                        ),
                      );
                    }
                  },
                ),
                QuickActionButton(
                  icon: Icons.history,
                  label: '阅读记录',
                  onTap: () => _openPage(const ReadRecordPage()),
                ),
              ],
            ),
          ),
          LegadoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                LegadoListTile(
                  icon: Icons.rss_feed,
                  title: '书源管理',
                  subtitle: '新建、导入、编辑或管理书源',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SourcesPage()),
                  ),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.article_outlined,
                  title: 'TXT 目录规则',
                  subtitle: '配置 TXT 目录规则',
                  onTap: () => _openPage(
                    const FeaturePlaceholderPage(
                      title: 'TXT 目录规则',
                      subtitle: '将支持本地 TXT 文件的目录识别规则配置',
                      icon: Icons.article_outlined,
                    ),
                  ),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.cleaning_services_outlined,
                  title: '替换净化',
                  subtitle: '配置替换净化规则',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReplacePage()),
                  ),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.menu_book_outlined,
                  title: '字典规则',
                  subtitle: '配置字典规则',
                  onTap: () => _openPage(
                    const FeaturePlaceholderPage(
                      title: '字典规则',
                      subtitle: '将支持阅读字典与释义规则',
                      icon: Icons.menu_book_outlined,
                    ),
                  ),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.palette_outlined,
                  title: '主题模式',
                  subtitle: themeLabel,
                  onTap: _showThemeModeDialog,
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.backup_outlined,
                  title: '备份与恢复',
                  subtitle: '备份书源、书架、设置',
                  onTap: () => _openConfig(0),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.color_lens_outlined,
                  title: '主题设置',
                  subtitle: '阅读与应用主题',
                  onTap: () => _openConfig(1),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.tune,
                  title: '其它设置',
                  subtitle: '更多偏好与行为',
                  onTap: () => _openConfig(2),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.bookmark_outline,
                  title: '书签与想法',
                  subtitle: '阅读批注与书签',
                  onTap: () => _openPage(const BookmarkPage()),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.folder_open,
                  title: '文件管理',
                  subtitle: '管理本地书籍文件',
                  onTap: () => _openPage(
                    const FeaturePlaceholderPage(
                      title: '文件管理',
                      subtitle: '将支持浏览与管理本地导入书籍',
                      icon: Icons.folder_open,
                    ),
                  ),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.terminal,
                  title: '阅读 Skill',
                  subtitle: '安装社区技能扩展',
                  onTap: () => _openPage(const ReadingSkillPage()),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI 助手',
                  subtitle: '大模型智能辅助',
                  onTap: () => _openPage(const AiChatPage(isStandalone: true)),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.info_outline,
                  title: '关于',
                  subtitle: '版本与引擎信息',
                  onTap: _showAbout,
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.logout,
                  title: '退出',
                  subtitle: '关闭应用',
                  onTap: () => SystemNavigator.pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
