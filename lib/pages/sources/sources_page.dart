import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/book_source.dart';
import '../../providers/source_provider.dart';
import '../../providers/book_provider.dart';
import '../../services/local_book_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/source_status_dot.dart';
import '../../widgets/source_validation_sheet.dart';
import 'source_editor_page.dart';
import 'source_login_page.dart';
import 'source_market_page.dart';

enum _SourceSort { group, name, enabled }

/// 书源管理页面 + 本地导入入口
class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  _SourceSort _sort = _SourceSort.group;
  bool _selectionMode = false;
  final Set<String> _selectedUrls = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedUrls.clear();
    });
  }

  void _enterSelection(String? firstUrl) {
    setState(() {
      _selectionMode = true;
      _selectedUrls.clear();
      if (firstUrl != null) _selectedUrls.add(firstUrl);
    });
  }

  void _toggleSelected(String url) {
    setState(() {
      if (_selectedUrls.contains(url)) {
        _selectedUrls.remove(url);
        if (_selectedUrls.isEmpty) _selectionMode = false;
      } else {
        _selectedUrls.add(url);
      }
    });
  }

  List<BookSource> _visibleSources(List<BookSource> all) {
    var list = List<BookSource>.from(all);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.bookSourceName.toLowerCase().contains(q) ||
                s.bookSourceUrl.toLowerCase().contains(q) ||
                s.bookSourceGroup.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (_sort) {
      case _SourceSort.name:
        list.sort(
          (a, b) => a.bookSourceName.toLowerCase().compareTo(
                b.bookSourceName.toLowerCase(),
              ),
        );
      case _SourceSort.enabled:
        list.sort((a, b) {
          final byEnabled = (b.enabled ? 1 : 0).compareTo(a.enabled ? 1 : 0);
          if (byEnabled != 0) return byEnabled;
          return a.bookSourceName.toLowerCase().compareTo(
                b.bookSourceName.toLowerCase(),
              );
        });
      case _SourceSort.group:
        list.sort((a, b) {
          final ga = a.bookSourceGroup.isEmpty ? '未分组' : a.bookSourceGroup;
          final gb = b.bookSourceGroup.isEmpty ? '未分组' : b.bookSourceGroup;
          final byGroup = ga == '未分组'
              ? (gb == '未分组' ? 0 : 1)
              : (gb == '未分组' ? -1 : ga.compareTo(gb));
          if (byGroup != 0) return byGroup;
          return a.bookSourceName.toLowerCase().compareTo(
                b.bookSourceName.toLowerCase(),
              );
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: '取消多选',
                onPressed: _exitSelection,
              )
            : null,
        title: Text(
          _selectionMode ? '已选 ${_selectedUrls.length}' : '书源',
        ),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: '全选可见书源',
              onPressed: () {
                final provider = context.read<SourceProvider>();
                final urls =
                    _visibleSources(provider.sources).map((s) => s.bookSourceUrl);
                setState(() => _selectedUrls
                  ..clear()
                  ..addAll(urls));
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist_rtl),
              tooltip: '多选',
              onPressed: () => _enterSelection(null),
            ),
            PopupMenuButton<_SourceSort>(
              icon: const Icon(Icons.sort),
              tooltip: '排序',
              initialValue: _sort,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: _SourceSort.group,
                  child: Text('按分组'),
                ),
                PopupMenuItem(
                  value: _SourceSort.name,
                  child: Text('按名称'),
                ),
                PopupMenuItem(
                  value: _SourceSort.enabled,
                  child: Text('按启用状态'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: '校验已启用书源',
              onPressed: () => _validateAllEnabled(context),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'import_json') {
                  _importFromJsonFile(context);
                } else if (v == 'paste_json') {
                  _showPasteDialog(context);
                } else if (v == 'import_url') {
                  _showImportUrlDialog(context);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'import_json',
                  child: ListTile(
                    leading: Icon(Icons.file_open, size: 20),
                    title: Text('从JSON文件导入'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'paste_json',
                  child: ListTile(
                    leading: Icon(Icons.content_paste, size: 20),
                    title: Text('粘贴JSON代码'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'import_url',
                  child: ListTile(
                    leading: Icon(Icons.cloud_download, size: 20),
                    title: Text('从URL导入'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.store),
              tooltip: '书源市场',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SourceMarketPage()),
              ),
            ),
          ],
        ],
      ),
      body: Consumer<SourceProvider>(
        builder: (context, provider, _) {
          final sources = provider.sources;

          if (provider.isLoading && sources.isEmpty && provider.loadError == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.loadError != null && sources.isEmpty) {
            return ErrorView(
              message: provider.loadError!,
              onRetry: () => provider.loadSources(),
            );
          }

          if (sources.isEmpty) {
            return _buildEmptyState(context);
          }

          final visible = _visibleSources(sources);

          return Column(
            children: [
              if (!_selectionMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: theme.colorScheme.surfaceContainerLow,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.store, size: 18),
                          label: const Text('书源市场'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SourceMarketPage(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_open, size: 18),
                          label: const Text('导入本地'),
                          onPressed: () => _importLocalBook(context),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索书源名称 / 分组 / URL',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              if (visible.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      '没有匹配的书源',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                Expanded(
                  child: _GroupedSourceList(
                    sources: visible,
                    selectionMode: _selectionMode,
                    selectedUrls: _selectedUrls,
                    onValidate: (s) => _validateOne(context, s),
                    onToggleSelect: _toggleSelected,
                    onEnterSelection: _enterSelection,
                  ),
                ),
              if (_selectionMode)
                _BatchActionBar(
                  selectedCount: _selectedUrls.length,
                  onEnable: () => _batchEnable(context, true),
                  onDisable: () => _batchEnable(context, false),
                  onGroup: () => _batchSetGroup(context),
                  onValidate: () => _batchValidateSelected(context),
                  onDelete: () => _batchDelete(context),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rss_feed,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text('还没有书源', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '去书源市场一键导入，或从JSON文件导入',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('打开书源市场'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SourceMarketPage()),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.file_open),
            label: const Text('从JSON文件导入'),
            onPressed: () => _importFromJsonFile(context),
          ),
        ],
      ),
    );
  }

  Future<void> _batchEnable(BuildContext context, bool enabled) async {
    if (_selectedUrls.isEmpty) return;
    final provider = context.read<SourceProvider>();
    await provider.setSourcesEnabled(_selectedUrls, enabled);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? '已启用 ${_selectedUrls.length} 个书源'
              : '已禁用 ${_selectedUrls.length} 个书源',
        ),
      ),
    );
    _exitSelection();
  }

  Future<void> _batchDelete(BuildContext context) async {
    if (_selectedUrls.isEmpty) return;
    final count = _selectedUrls.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除书源'),
        content: Text('确定删除选中的 $count 个书源？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<SourceProvider>().deleteSources(_selectedUrls);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除 $count 个书源')),
    );
    _exitSelection();
  }

  Future<void> _batchSetGroup(BuildContext context) async {
    if (_selectedUrls.isEmpty) return;
    final provider = context.read<SourceProvider>();
    final existing = <String>{};
    for (final s in provider.sources) {
      if (s.bookSourceGroup.isNotEmpty) existing.add(s.bookSourceGroup);
    }
    final groups = existing.toList()..sort();
    final controller = TextEditingController();

    final group = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('设置分组'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '输入分组名（空=未分组）',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              if (groups.isNotEmpty) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '已有分组',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final g in groups)
                        ListTile(
                          dense: true,
                          title: Text(g),
                          onTap: () => Navigator.pop(ctx, g),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('清除分组'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (group == null || !context.mounted) return;
    final count = _selectedUrls.length;
    await provider.setSourcesGroup(_selectedUrls, group);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          group.isEmpty
              ? '已清除 $count 个书源分组'
              : '已将 $count 个书源移至「$group」',
        ),
      ),
    );
    _exitSelection();
  }

  Future<void> _batchValidateSelected(BuildContext context) async {
    if (_selectedUrls.isEmpty) return;
    final provider = context.read<SourceProvider>();
    final selected = provider.sources
        .where((s) => _selectedUrls.contains(s.bookSourceUrl))
        .toList();
    if (selected.isEmpty) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchValidateDialog(
        provider: provider,
        sources: selected,
      ),
    );
    _exitSelection();
  }

  /// 从JSON文件导入书源
  Future<void> _importFromJsonFile(BuildContext context) async {
    final provider = context.read<SourceProvider>();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonText = await file.readAsString();
      final success = await provider.importSources(jsonText);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ 书源导入成功' : '❌ 导入失败，请检查文件内容'),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ 导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// 粘贴JSON代码
  void _showPasteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('粘贴书源JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '粘贴 legado 书源 JSON，或书源订阅 URL...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              Navigator.pop(ctx);
              if (text.isEmpty) return;
              final provider = context.read<SourceProvider>();
              final success = await provider.importSources(text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? '✅ 书源导入成功'
                          : (provider.statusMessage.isNotEmpty
                              ? '❌ ${provider.statusMessage}'
                              : '❌ 导入失败'),
                    ),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 从 URL 导入书源
  void _showImportUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('从URL导入书源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '输入书源JSON的URL...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '示例：\n'
              'https://www.yckceo.com/yuedu/shuyuan/json/id/7497.json\n'
              'https://www.yckceo.com/yuedu/shuyuan/json/id/7565.json',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.cloud_download, size: 18),
            label: const Text('获取并导入'),
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              final provider = context.read<SourceProvider>();
              final success = await provider.importSourcesFromUrl(url);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  success
                      ? const SnackBar(content: Text('✅ 书源导入成功'))
                      : const SnackBar(
                          content: Text('❌ 导入失败，请检查URL'),
                          backgroundColor: Colors.red,
                        ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importLocalBook(BuildContext context) async {
    try {
      final b = await context.read<BookProvider>().importLocalBook();
      if (b != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入: ${b.name}')),
        );
      }
    } on LocalBookImportException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _validateAllEnabled(BuildContext context) async {
    final provider = context.read<SourceProvider>();
    if (!provider.sources.any((s) => s.enabled)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有已启用的书源可校验')),
      );
      return;
    }

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _BatchValidateDialog(provider: provider),
    );
  }

  Future<void> _validateOne(BuildContext context, BookSource source) async {
    final provider = context.read<SourceProvider>();
    final result = await provider.validateSource(source);
    if (!context.mounted || result == null) return;
    await SourceValidationSheet.show(
      context,
      sourceName: source.bookSourceName,
      result: result,
    );
  }
}

class _BatchActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onEnable;
  final VoidCallback onDisable;
  final VoidCallback onGroup;
  final VoidCallback onValidate;
  final VoidCallback onDelete;

  const _BatchActionBar({
    required this.selectedCount,
    required this.onEnable,
    required this.onDisable,
    required this.onGroup,
    required this.onValidate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = selectedCount > 0;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BatchAction(
                icon: Icons.check_circle_outline,
                label: '启用',
                onTap: enabled ? onEnable : null,
              ),
              _BatchAction(
                icon: Icons.block,
                label: '禁用',
                onTap: enabled ? onDisable : null,
              ),
              _BatchAction(
                icon: Icons.folder_outlined,
                label: '分组',
                onTap: enabled ? onGroup : null,
              ),
              _BatchAction(
                icon: Icons.fact_check_outlined,
                label: '校验',
                onTap: enabled ? onValidate : null,
              ),
              _BatchAction(
                icon: Icons.delete_outline,
                label: '删除',
                color: Colors.red,
                onTap: enabled ? onDelete : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _BatchAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = onTap == null
        ? theme.disabledColor
        : (color ?? theme.colorScheme.onSurface);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: c)),
          ],
        ),
      ),
    );
  }
}

/// 按 bookSourceGroup 分组的书源列表
class _GroupedSourceList extends StatelessWidget {
  final List<BookSource> sources;
  final bool selectionMode;
  final Set<String> selectedUrls;
  final void Function(BookSource source) onValidate;
  final void Function(String url) onToggleSelect;
  final void Function(String url) onEnterSelection;

  const _GroupedSourceList({
    required this.sources,
    required this.selectionMode,
    required this.selectedUrls,
    required this.onValidate,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  Map<String, List<BookSource>> _grouped() {
    final map = <String, List<BookSource>>{};
    for (final s in sources) {
      final g = s.bookSourceGroup.isNotEmpty ? s.bookSourceGroup : '未分组';
      map.putIfAbsent(g, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _grouped();
    final keys = groups.keys.toList()
      ..sort((a, b) => a == '未分组' ? 1 : b == '未分组' ? -1 : a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: keys.length,
      itemBuilder: (_, gi) {
        final groupName = keys[gi];
        final items = groups[groupName]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader('$groupName (${items.length})'),
            ...items.map(
              (s) => Column(
                children: [
                  _SourceTile(
                    source: s,
                    selectionMode: selectionMode,
                    selected: selectedUrls.contains(s.bookSourceUrl),
                    onValidate: () => onValidate(s),
                    onToggleSelect: () => onToggleSelect(s.bookSourceUrl),
                    onEnterSelection: () => onEnterSelection(s.bookSourceUrl),
                  ),
                  const Divider(height: 1, indent: 72),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 单个书源 Tile
class _SourceTile extends StatelessWidget {
  final BookSource source;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onValidate;
  final VoidCallback onToggleSelect;
  final VoidCallback onEnterSelection;

  const _SourceTile({
    required this.source,
    required this.selectionMode,
    required this.selected,
    required this.onValidate,
    required this.onToggleSelect,
    required this.onEnterSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<SourceProvider>(
      builder: (context, provider, _) {
        final validating =
            provider.isValidating &&
            provider.validatingSourceUrl == source.bookSourceUrl;
        final validation = provider.validationOf(source.bookSourceUrl);

        return ListTile(
          selected: selectionMode && selected,
          leading: selectionMode
              ? Checkbox(
                  value: selected,
                  onChanged: (_) => onToggleSelect(),
                )
              : CircleAvatar(
                  backgroundColor: source.enabled
                      ? theme.colorScheme.primaryContainer
                      : Colors.grey[200],
                  radius: 18,
                  child: validating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.rss_feed,
                          size: 20,
                          color: source.enabled
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                ),
          title: Row(
            children: [
              SourceStatusDot(source: source, validation: validation),
              Expanded(
                child: Text(
                  source.bookSourceName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: source.enabled ? null : Colors.grey,
                  ),
                ),
              ),
              SourceValidationBadge(result: validation),
            ],
          ),
          subtitle: Text(
            source.bookSourceGroup.isNotEmpty
                ? '${source.bookSourceGroup} | ${source.bookSourceUrl}'
                : source.bookSourceUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
          trailing: selectionMode
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (source.hasLoginConfig)
                      IconButton(
                        tooltip: '登录',
                        icon: const Icon(Icons.login, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SourceLoginPage(source: source),
                            ),
                          );
                        },
                      ),
                    Switch(
                      value: source.enabled,
                      onChanged: (v) =>
                          provider.toggleSource(source.bookSourceUrl, v),
                    ),
                  ],
                ),
          onLongPress: selectionMode ? null : onEnterSelection,
          onTap: () {
            if (selectionMode) {
              onToggleSelect();
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: provider,
                  child: SourceEditorPage(source: source),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BatchValidateDialog extends StatefulWidget {
  final SourceProvider provider;
  final List<BookSource>? sources;

  const _BatchValidateDialog({
    required this.provider,
    this.sources,
  });

  @override
  State<_BatchValidateDialog> createState() => _BatchValidateDialogState();
}

class _BatchValidateDialogState extends State<_BatchValidateDialog> {
  int _done = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    final targets = widget.sources ??
        widget.provider.sources.where((s) => s.enabled).toList();
    _total = targets.length;
    widget.provider
        .validateSources(
          targets,
          onProgress: (done, total) {
            if (mounted) {
              setState(() {
                _done = done;
                _total = total;
              });
            }
          },
        )
        .then((passed) {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.maybeOf(context);
          Navigator.pop(context);
          messenger?.showSnackBar(
            SnackBar(content: Text('校验完成：$passed/$_total 书源可用')),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('书源校验'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text('正在校验 $_done / $_total …'),
          const SizedBox(height: 8),
          Text(
            '测试搜索、发现、目录与正文',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
