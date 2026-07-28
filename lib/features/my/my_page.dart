import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/backup_service.dart';
import '../../services/database_status_service.dart';
import '../../services/engine_status_service.dart';
import '../../services/web_api_prefs.dart';
import '../../services/web_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/legado_list_tile.dart';
import '../../widgets/quick_action_button.dart';
import '../../pages/ai/ai_config_dialog.dart';
import '../../features/book/bookmark_page.dart';
import '../../providers/book_provider.dart';
import '../cache/cache_book_page.dart';
import '../../features/settings/config_page.dart';
import '../../pages/obsidian/obsidian_export_dialog.dart';
import '../../features/reader/ai_chat_page.dart';
import '../../pages/replace/replace_page.dart';
import '../../features/sources/sources_page.dart';
import '../../pages/about/donate_page.dart';
import '../../pages/dict/dict_rule_page.dart';
import '../../pages/txt_toc/txt_toc_rule_page.dart';
import 'file_manage_page.dart';
import 'read_record_page.dart';
import 'reading_skill_page.dart';
import 'webdav_config_dialog.dart';

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
    if (!EngineStatusService.isAvailable || !DatabaseStatusService.isReady) {
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
    if (!EngineStatusService.isAvailable || !DatabaseStatusService.isReady) {
      _snack('Rust 引擎或数据库未就绪');
      return;
    }
    final config = await WebApiPrefs.load();
    final next = !config.enabled;
    final status = await WebApiService.setEnabled(next);
    await _loadWebService();
    if (!mounted) return;
    _snack(next ? 'Web API 已启动 ${status?.baseUrl ?? ''}' : 'Web API 已停止');
  }

  Future<void> _showWebDavDialog() async {
    final saved = await WebDavConfigDialog.show(context);
    if (saved != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('WebDAV 配置已保存')));
    }
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
        content: RadioGroup<int>(
          groupValue: current,
          onChanged: (v) async {
            if (v == null) return;
            await controller.setMode(modes[v]);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(labels.length, (i) {
              return RadioListTile<int>(title: Text(labels[i]), value: i);
            }),
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    final engine = EngineStatusService.isAvailable
        ? 'Rust 引擎 v${EngineStatusService.engineVersion}'
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
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // 顶部品牌卡 — fragment_my_config：logo 64 / 标题 22sp bold / 副标 14sp
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'legado',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '开源阅读',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 快捷四格 — padding 12 / 标签 12sp
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  QuickActionButton(
                    icon: Icons.backup_outlined,
                    label: '备份管理',
                    onTap: () => _openConfig(0),
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
          ),
          // 设置列表 — 行高 56 / 标题 16sp / 副标 12sp
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                LegadoListTile(
                  icon: Icons.rss_feed,
                  title: '书源管理',
                  subtitle: '新建、导入、编辑或管理书源',
                  onTap: () => _openPage(const SourcesPage()),
                ),
                LegadoListTile(
                  icon: Icons.article_outlined,
                  title: 'TXT 目录规则',
                  subtitle: '配置 TXT 目录规则',
                  onTap: () => _openPage(const TxtTocRulePage()),
                ),
                LegadoListTile(
                  icon: Icons.download_for_offline_outlined,
                  title: '离线缓存',
                  subtitle: '按书管理缓存并下载章节',
                  onTap: () => _openPage(
                    CacheBookPage(
                      contentCache: context.read<BookProvider>().contentCache,
                    ),
                  ),
                ),
                LegadoListTile(
                  icon: Icons.cleaning_services_outlined,
                  title: '替换净化',
                  subtitle: '配置替换净化规则',
                  onTap: () => _openPage(const ReplacePage()),
                ),
                LegadoListTile(
                  icon: Icons.menu_book_outlined,
                  title: '字典规则',
                  subtitle: '配置字典规则',
                  onTap: () => _openPage(const DictRulePage()),
                ),
                LegadoListTile(
                  icon: Icons.palette_outlined,
                  title: '主题模式',
                  subtitle: themeLabel,
                  onTap: _showThemeModeDialog,
                ),
                LegadoListTile(
                  icon: Icons.backup_outlined,
                  title: '备份与恢复',
                  subtitle: '备份书源、书架、设置',
                  onTap: () => _openConfig(0),
                ),
                LegadoListTile(
                  icon: Icons.color_lens_outlined,
                  title: '主题设置',
                  subtitle: '配色：$presetLabel',
                  onTap: () => _openConfig(1),
                ),
                LegadoListTile(
                  icon: Icons.tune,
                  title: '其它设置',
                  subtitle: '更多偏好与行为',
                  onTap: () => _openConfig(2),
                ),
                LegadoListTile(
                  icon: Icons.bookmark_outline,
                  title: '书签与想法',
                  subtitle: '阅读批注与书签',
                  onTap: () => _openPage(const BookmarkPage()),
                ),
                LegadoListTile(
                  icon: Icons.folder_open,
                  title: '文件管理',
                  subtitle: '管理私有文件夹中的文件',
                  onTap: () => _openPage(const FileManagePage()),
                ),
                LegadoListTile(
                  icon: Icons.terminal,
                  title: '阅读 Skill',
                  subtitle: '安装社区技能扩展',
                  onTap: () => _openPage(const ReadingSkillPage()),
                ),
                LegadoListTile(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI 助手',
                  subtitle: '大模型智能辅助',
                  onTap: () => _openPage(const AiChatPage(isStandalone: true)),
                ),
                LegadoListTile(
                  icon: Icons.tune_outlined,
                  title: 'AI 配置',
                  subtitle: 'API / 模型 / 人设 / 记忆',
                  onTap: () async {
                    await AiConfigDialog.show(context);
                  },
                ),
                LegadoListTile(
                  icon: Icons.outbox_outlined,
                  title: '导出到 Obsidian',
                  subtitle: 'REST API 或本地仓库',
                  onTap: () => ObsidianExportDialog.show(context),
                ),
                LegadoListTile(
                  icon: Icons.volunteer_activism_outlined,
                  title: '捐赠',
                  subtitle: '您的支持是我更新的动力',
                  onTap: () => _openPage(const DonatePage()),
                ),
                LegadoListTile(
                  icon: Icons.info_outline,
                  title: '关于',
                  onTap: _showAbout,
                ),
                LegadoListTile(
                  icon: Icons.logout,
                  title: '退出',
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
