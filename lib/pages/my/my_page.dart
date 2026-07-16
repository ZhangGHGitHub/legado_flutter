import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bridge/legado_db_bridge.dart';
import '../../bridge/legado_engine_bridge.dart';
import '../../services/backup_service.dart';
import '../../services/web_api_prefs.dart';
import '../../services/web_api_service.dart';
import '../../services/webdav_prefs.dart';
import '../../theme/app_theme.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/legado_card.dart';
import '../../widgets/legado_list_tile.dart';
import '../../widgets/quick_action_button.dart';
import '../ai/ai_config_dialog.dart';
import '../book/bookmark_page.dart';
import '../cache/cache_book_page.dart';
import '../config/config_page.dart';
import '../obsidian/obsidian_export_dialog.dart';
import '../reader/ai_chat_page.dart';
import '../replace/replace_page.dart';
import '../sources/sources_page.dart';
import '../about/donate_page.dart';
import '../dict/dict_rule_page.dart';
import '../txt_toc/txt_toc_rule_page.dart';
import 'file_manage_page.dart';
import 'read_record_page.dart';
import 'reading_skill_page.dart';

/// 我的 Tab — 对齐 Jingshiro [MyFragment](https://github.com/Jingshiro/legado/blob/main/app/src/main/java/io/legado/app/ui/main/my/MyFragment.kt)
class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with WidgetsBindingObserver {
  bool _webServiceOn = false;
  String _webServiceUrl = '';
  bool _localBackupBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWebService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWebService();
    }
  }

  Future<void> _loadWebService() async {
    final config = await WebApiPrefs.load();
    final status = WebApiService.currentStatus();
    final running = config.enabled && (status?.running ?? false);
    if (!mounted) return;
    setState(() {
      _webServiceOn = running;
      _webServiceUrl = running ? (status?.baseUrl ?? '') : '';
    });
  }

  Future<void> _localBackup() async {
    if (_localBackupBusy) return;
    if (!LegadoEngineBridge.isAvailable || !LegadoDbBridge.isReady) {
      _snack('Rust 引擎或数据库未就绪');
      return;
    }
    setState(() => _localBackupBusy = true);
    try {
      final file = await BackupService().backupToLocalFile();
      if (!mounted) return;
      _snack('本地备份完成：${file.uri.pathSegments.last}');
    } catch (e) {
      if (mounted) _snack('本地备份失败: $e');
    } finally {
      if (mounted) setState(() => _localBackupBusy = false);
    }
  }

  Future<void> _webServiceLongPress() async {
    await _loadWebService();
    if (!_webServiceOn || _webServiceUrl.isEmpty) {
      _snack('请先开启 Web 服务');
      return;
    }
    final url = _webServiceUrl;
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(url, style: Theme.of(ctx).textTheme.bodySmall),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('复制地址'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('浏览器打开'),
              onTap: () => Navigator.pop(ctx, 'browser'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) _snack('已复制 $url');
      case 'browser':
        final uri = Uri.tryParse(url);
        if (uri == null) {
          _snack('地址无效');
          return;
        }
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok && mounted) _snack('无法打开浏览器');
    }
  }

  Future<void> _toggleWebService() async {
    if (!LegadoEngineBridge.isAvailable || !LegadoDbBridge.isReady) {
      _snack('Rust 引擎或数据库未就绪');
      return;
    }
    final config = await WebApiPrefs.load();
    final next = !config.enabled;
    final status = await WebApiService.setEnabled(next);
    await _loadWebService();
    if (!mounted) return;
    _snack(
      next
          ? 'Web API 已启动 ${status?.baseUrl ?? ''}'
          : 'Web API 已停止',
    );
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    await _loadWebService();
  }

  Future<void> _openConfig(int tab) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConfigPage(initialTab: tab)),
    );
    await _loadWebService();
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
    final presetLabel = context.watch<ThemeModeController>().presetLabel;
    final webLabel = _webServiceOn ? '已开启' : 'Web服务';

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
                  // 对齐 MyFragment：短按云端备份页，长按一键本地备份
                  onLongPress: _localBackupBusy ? null : _localBackup,
                ),
                QuickActionButton(
                  icon: Icons.cloud_outlined,
                  label: 'WebDAV',
                  onTap: _showWebDavDialog,
                ),
                QuickActionButton(
                  icon: Icons.wifi,
                  label: webLabel,
                  onTap: _toggleWebService,
                  // 对齐 MyFragment：运行中长按 → 复制地址 / 浏览器打开
                  onLongPress: _webServiceLongPress,
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
                  onTap: () => _openPage(const SourcesPage()),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.article_outlined,
                  title: 'TXT 目录规则',
                  subtitle: '配置 TXT 目录规则',
                  onTap: () => _openPage(const TxtTocRulePage()),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.download_for_offline_outlined,
                  title: '离线缓存',
                  subtitle: '按书管理缓存并下载章节',
                  onTap: () => _openPage(const CacheBookPage()),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.cleaning_services_outlined,
                  title: '替换净化',
                  subtitle: '配置替换净化规则',
                  onTap: () => _openPage(const ReplacePage()),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.menu_book_outlined,
                  title: '字典规则',
                  subtitle: '配置字典规则',
                  onTap: () => _openPage(const DictRulePage()),
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
                  subtitle: '配色：$presetLabel',
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
                  subtitle: '管理私有文件夹中的文件',
                  onTap: () => _openPage(const FileManagePage()),
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
                  icon: Icons.tune_outlined,
                  title: 'AI 配置',
                  subtitle: 'API / 模型 / 人设 / 记忆',
                  onTap: () async {
                    await AiConfigDialog.show(context);
                  },
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.outbox_outlined,
                  title: '导出到 Obsidian',
                  subtitle: 'REST API 或本地仓库',
                  onTap: () => ObsidianExportDialog.show(context),
                ),
                const LegadoListDivider(),
                LegadoListTile(
                  icon: Icons.volunteer_activism_outlined,
                  title: '捐赠',
                  subtitle: '您的支持是我更新的动力',
                  onTap: () => _openPage(const DonatePage()),
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
