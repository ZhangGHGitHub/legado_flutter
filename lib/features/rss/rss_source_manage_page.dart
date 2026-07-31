import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../../providers/rss_provider.dart';
import 'package:legado_flutter/application/rss/rss_source_transfer_port.dart';
import '../../theme/legado_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/legado_popup_menu.dart';
import '../sources/qrcode_capture_page.dart';
import 'rss_source_edit_page.dart';

/// 订阅源管理 — 对齐 Jingshiro [RssSourceActivity] /
/// `activity_rss_source.xml` + `item_rss_source.xml` + `menu/rss_source.xml`
class RssSourceManagePage extends StatefulWidget {
  const RssSourceManagePage({super.key, this.transfer});

  final RssSourceTransferPort? transfer;

  @override
  State<RssSourceManagePage> createState() => _RssSourceManagePageState();
}

class _RssSourceManagePageState extends State<RssSourceManagePage> {
  final _searchController = TextEditingController();
  final _selected = <String>{};
  final _selectBarKey = GlobalKey();
  late final RssSourceTransferPort _transfer;

  /// all | enabled | disabled | login | null_group | group:xxx
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _transfer = widget.transfer ?? context.read<RssSourceTransferPort>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RssSource> _visible(RssProvider p) =>
      p.managedSources(searchKey: _searchController.text, filter: _filter);

  TextStyle _uiText({
    required Color color,
    double size = 14,
    FontWeight weight = FontWeight.w400,
  }) {
    final font = context.read<ReaderFontPort>();
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
      fontFamily: font.platformSansFamily(),
      fontFamilyFallback: font.cjkFallbackFamilies(),
    );
  }

  Widget _buildSearchField(ColorScheme scheme) {
    final onBar = scheme.onPrimary;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(_selected.clear),
        style: _uiText(color: onBar),
        cursorColor: onBar,
        decoration: InputDecoration(
          hintText: '搜索订阅源',
          hintStyle: _uiText(color: onBar.withValues(alpha: 0.72)),
          isDense: true,
          filled: true,
          fillColor: onBar.withValues(alpha: 0.10),
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: onBar.withValues(alpha: 0.85),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: onBar.withValues(alpha: 0.85),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: onBar.withValues(alpha: 0.10),
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(
              color: onBar.withValues(alpha: 0.22),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
      _selected.clear();
    });
  }

  Future<void> _onGroupMenu(String value) async {
    switch (value) {
      case 'manage':
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('「分组管理」暂未实现')));
      case 'enabled':
        _setFilter('enabled');
      case 'disabled':
        _setFilter('disabled');
      case 'login':
        _setFilter('login');
      case 'null_group':
        _setFilter('null_group');
      case 'all':
        _setFilter('all');
      default:
        if (value.startsWith('group:')) _setFilter(value);
    }
  }

  Future<void> _onOverflow(String value) async {
    switch (value) {
      case 'add':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RssSourceEditPage()),
        );
      case 'import_local':
        await _importLocal();
      case 'import_online':
        await _importOnline();
      case 'import_qr':
        await _importQr();
      case 'import_default':
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('「导入默认规则」暂未实现')));
      case 'help':
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('「帮助」暂未实现')));
      case 'paste':
        await _importPaste();
    }
  }

  Future<void> _importLocal() async {
    try {
      final jsonText = await _transfer.pickImportText();
      if (jsonText == null) return;
      if (!mounted) return;
      final ok = await context.read<RssProvider>().importSources(jsonText);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ok ? '导入成功' : '导入失败，请检查文件内容')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  Future<void> _importOnline() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('网络导入'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '订阅源 JSON URL…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final url = controller.text.trim();
    if (url.isEmpty) return;
    final success = await context.read<RssProvider>().importSourcesFromUrl(url);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success ? '导入成功' : '导入失败，请检查 URL')));
  }

  Future<void> _importQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrCodeCapturePage()),
    );
    if (result == null || result.isEmpty || !mounted) return;
    final success = await context.read<RssProvider>().importSources(result);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success ? '导入成功' : '导入失败')));
  }

  Future<void> _importPaste() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('粘贴导入'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '粘贴 RSS 源 JSON…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final success = await context.read<RssProvider>().importSources(
      controller.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '导入成功' : '导入失败，请检查 JSON 格式')),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除'),
        content: Text('确定删除选中的 ${_selected.length} 个订阅源？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await context.read<RssProvider>().deleteSources(_selected);
    setState(() => _selected.clear());
  }

  Future<void> _onBottomMore(String value) async {
    final provider = context.read<RssProvider>();
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择订阅源')));
      return;
    }
    switch (value) {
      case 'enable':
        await provider.setEnabledMany(_selected, true);
      case 'disable':
        await provider.setEnabledMany(_selected, false);
      case 'top':
        await provider.topSources(_selected);
      case 'export':
        final list = provider.sources
            .where((s) => _selected.contains(s.sourceUrl))
            .map((s) => s.toJson())
            .toList();
        final text = const JsonEncoder.withIndent('  ').convert(list);
        await _transfer.copyText(text);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已复制选中源到剪贴板')));
      default:
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该批量操作暂未实现')));
    }
  }

  void _showItemMenu(RssSource source, Offset anchor) {
    final provider = context.read<RssProvider>();
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        anchor.dx,
        anchor.dy,
        anchor.dx,
        anchor.dy,
      ),
      items: [
        const PopupMenuItem(value: 'top', child: Text('置顶')),
        const PopupMenuItem(value: 'edit', child: Text('编辑')),
        PopupMenuItem(
          value: 'toggle',
          child: Text(source.enabled ? '禁用' : '启用'),
        ),
        const PopupMenuItem(value: 'del', child: Text('删除')),
      ],
    ).then((action) async {
      if (action == null || !mounted) return;
      switch (action) {
        case 'top':
          await provider.topSource(source);
        case 'edit':
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RssSourceEditPage(source: source),
            ),
          );
        case 'toggle':
          await provider.setEnabled(source, !source.enabled);
        case 'del':
          final yes = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('删除'),
              content: Text('确定删除\n${source.sourceName}？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('删除'),
                ),
              ],
            ),
          );
          if (yes == true) {
            await provider.deleteSource(source);
            _selected.remove(source.sourceUrl);
            if (mounted) setState(() {});
          }
      }
    });
  }

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String label,
    String value,
    ColorScheme scheme,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurface),
          const SizedBox(width: 12),
          Text(label, style: _uiText(color: scheme.onSurface)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _buildSearchField(scheme),
        ),
        actions: [
          Consumer<RssProvider>(
            builder: (context, provider, _) {
              final groups = provider.allGroups();
              return PopupMenuButton<String>(
                offset: legadoAppBarPopupOffset(context),
                tooltip: '分组',
                icon: const Icon(Icons.hub_outlined),
                onSelected: _onGroupMenu,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'manage',
                    child: Text(
                      '分组管理',
                      style: _uiText(color: scheme.onSurface),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'enabled',
                    child: Text('已启用', style: _uiText(color: scheme.onSurface)),
                  ),
                  PopupMenuItem(
                    value: 'disabled',
                    child: Text('已禁用', style: _uiText(color: scheme.onSurface)),
                  ),
                  PopupMenuItem(
                    value: 'login',
                    child: Text(
                      '需要登录',
                      style: _uiText(color: scheme.onSurface),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'null_group',
                    child: Text('未分组', style: _uiText(color: scheme.onSurface)),
                  ),
                  if (groups.isNotEmpty) const PopupMenuDivider(),
                  ...groups.map(
                    (g) => PopupMenuItem(
                      value: 'group:$g',
                      child: Text(g, style: _uiText(color: scheme.onSurface)),
                    ),
                  ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            offset: legadoAppBarPopupOffset(context),
            tooltip: '更多',
            icon: const Icon(Icons.more_vert),
            onSelected: _onOverflow,
            itemBuilder: (_) => [
              _menuItem(Icons.add, '新建订阅源', 'add', scheme),
              _menuItem(
                Icons.file_download_outlined,
                '本地导入',
                'import_local',
                scheme,
              ),
              _menuItem(
                Icons.cloud_download_outlined,
                '网络导入',
                'import_online',
                scheme,
              ),
              _menuItem(Icons.qr_code_scanner, '二维码导入', 'import_qr', scheme),
              _menuItem(Icons.rule, '导入默认规则', 'import_default', scheme),
              _menuItem(Icons.help_outline, '帮助', 'help', scheme),
              _menuItem(Icons.content_paste, '粘贴导入', 'paste', scheme),
            ],
          ),
        ],
      ),
      body: Consumer<RssProvider>(
        builder: (context, provider, _) {
          final visible = _visible(provider);
          if (provider.sources.isEmpty) {
            return EmptyState(
              icon: Icons.subscriptions_outlined,
              title: '暂无订阅源',
              subtitle: '右上角菜单可新建或导入',
              actionLabel: '粘贴导入',
              onAction: _importPaste,
            );
          }
          if (visible.isEmpty) {
            return Center(
              child: Text(
                '没有匹配的订阅源',
                style: _uiText(color: scheme.onSurfaceVariant),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (ctx, i) {
                    final s = visible[i];
                    final checked = _selected.contains(s.sourceUrl);
                    return Material(
                      color: scheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: LegadoTokens.spacingMd,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                value: checked,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selected.add(s.sourceUrl);
                                    } else {
                                      _selected.remove(s.sourceUrl);
                                    }
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: Text(
                                  s.sourceName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _uiText(
                                    color: scheme.onSurface,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                            Switch(
                              value: s.enabled,
                              activeThumbColor: Colors.white,
                              activeTrackColor: accent,
                              onChanged: (v) => provider.setEnabled(s, v),
                            ),
                            IconButton(
                              tooltip: '编辑',
                              icon: Icon(
                                Icons.open_in_new,
                                size: 20,
                                color: scheme.onSurface,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RssSourceEditPage(source: s),
                                ),
                              ),
                            ),
                            Builder(
                              builder: (tileCtx) => IconButton(
                                tooltip: '更多',
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: scheme.onSurface,
                                ),
                                onPressed: () {
                                  final box =
                                      tileCtx.findRenderObject() as RenderBox?;
                                  final offset =
                                      box?.localToGlobal(Offset.zero) ??
                                      Offset.zero;
                                  _showItemMenu(s, offset);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildSelectActionBar(scheme, visible),
            ],
          );
        },
      ),
    );
  }

  ButtonStyle _selectBarButtonStyle(ColorScheme scheme) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      foregroundColor: scheme.onSurface,
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  /// 对齐 `view_select_action_bar.xml`：全选 / 反选 / 删除 / 更多
  Widget _buildSelectActionBar(ColorScheme scheme, List<RssSource> visible) {
    final total = visible.length;
    final selectedCount = visible
        .where((s) => _selected.contains(s.sourceUrl))
        .length;
    final allSelected = total > 0 && selectedCount == total;
    final hasSelection = selectedCount > 0;

    final bottomBg =
        Theme.of(context).bottomAppBarTheme.color ?? scheme.surface;
    return Material(
      key: _selectBarKey,
      elevation: 2,
      color: bottomBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: allSelected ? true : (selectedCount > 0 ? null : false),
              tristate: true,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (_) {
                setState(() {
                  if (allSelected) {
                    for (final s in visible) {
                      _selected.remove(s.sourceUrl);
                    }
                  } else {
                    for (final s in visible) {
                      _selected.add(s.sourceUrl);
                    }
                  }
                });
              },
            ),
            Expanded(
              child: Text(
                '全选 ($selectedCount/$total)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _uiText(color: scheme.onSurface, size: 14),
              ),
            ),
            OutlinedButton(
              style: _selectBarButtonStyle(scheme),
              onPressed: total == 0
                  ? null
                  : () {
                      setState(() {
                        for (final s in visible) {
                          if (_selected.contains(s.sourceUrl)) {
                            _selected.remove(s.sourceUrl);
                          } else {
                            _selected.add(s.sourceUrl);
                          }
                        }
                      });
                    },
              child: Text('反选', style: _uiText(color: scheme.onSurface)),
            ),
            const SizedBox(width: 6),
            OutlinedButton(
              style: _selectBarButtonStyle(scheme),
              onPressed: hasSelection ? _deleteSelected : null,
              child: Text(
                '删除',
                style: _uiText(
                  color: hasSelection
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
            LegadoBottomBarPopupButton<String>(
              barKey: _selectBarKey,
              onSelected: (v) => _onBottomMore(v),
              icon: Icon(Icons.more_vert, color: scheme.onSurface, size: 22),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'enable',
                  child: Text('启用所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'disable',
                  child: Text('禁用所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'top',
                  child: Text('置顶所选', style: _uiText(color: scheme.onSurface)),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Text('导出所选', style: _uiText(color: scheme.onSurface)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
