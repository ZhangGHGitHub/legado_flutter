import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/rule_sub.dart';
import '../../domain/ports/public_text_fetch_port.dart';
import '../../providers/replace_provider.dart';
import '../../providers/rss_provider.dart';
import '../../providers/source_provider.dart';
import '../../services/rule_sub_import_service.dart';
import '../../services/rule_sub_prefs.dart';
import '../../services/book_source_service.dart';

/// 规则订阅 — 对齐 Jingshiro [RuleSubActivity] + `activity_rule_sub.xml`
class RuleSubPage extends StatefulWidget {
  const RuleSubPage({super.key});

  /// 供 MainShell / 自动更新打开导入 UI（对齐 openImportUi）
  static Future<void> openImport(BuildContext context, RuleSub sub) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final fetched = await RuleSubImportService.fetchForImport(
        sub,
        sourceService: context.read<BookSourceService>(),
        fetchPort: context.read<PublicTextFetchPort>(),
      );
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (fetched.count == 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未获取到可导入规则')));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _RuleSubImportDialog(sub: sub, fetched: fetched),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  State<RuleSubPage> createState() => _RuleSubPageState();
}

class _RuleSubPageState extends State<RuleSubPage> {
  List<RuleSub> _subs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(checkAuto: true);
  }

  Future<void> _load({bool checkAuto = false}) async {
    final list = await RuleSubPrefs.load();
    if (!mounted) return;
    setState(() {
      _subs = list;
      _loading = false;
    });
    if (checkAuto) {
      await _runDueAutoUpdates(openUi: true);
    }
  }

  Future<void> _runDueAutoUpdates({required bool openUi}) async {
    final needUi = await RuleSubImportService.checkAutoUpdates(
      sourceService: context.read<BookSourceService>(),
      sourceProvider: context.read<SourceProvider>(),
      rssProvider: context.read<RssProvider>(),
      replaceProvider: context.read<ReplaceProvider>(),
      fetchPort: context.read<PublicTextFetchPort>(),
    );
    await _load();
    if (!mounted || !openUi) return;
    for (final sub in needUi) {
      await _openSubscription(sub);
    }
  }

  Future<void> _add() async {
    final order = await RuleSubPrefs.maxOrder() + 1;
    if (!mounted) return;
    await _editSubscription(
      RuleSub(
        id: DateTime.now().millisecondsSinceEpoch,
        customOrder: order,
        update: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> _editSubscription(RuleSub ruleSub) async {
    final saved = await showDialog<RuleSub>(
      context: context,
      builder: (_) => _RuleSubEditDialog(ruleSub: ruleSub),
    );
    if (saved == null) return;

    if (saved.url.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL 为空')));
      return;
    }

    final existing = await RuleSubPrefs.findByUrl(saved.url.trim());
    if (existing != null && existing.id != saved.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('此 URL 已订阅(${existing.name})')));
      return;
    }

    await RuleSubPrefs.upsert(saved.copyWith(url: saved.url.trim()));
    await _load();
  }

  Future<void> _delete(RuleSub sub) async {
    await RuleSubPrefs.delete(sub);
    await _load();
  }

  Future<void> _openSubscription(RuleSub sub) =>
      RuleSubPage.openImport(context, sub);

  void _showItemMenu(RuleSub sub, Offset anchor) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        anchor.dx,
        anchor.dy,
        anchor.dx,
        anchor.dy,
      ),
      items: const [PopupMenuItem(value: 'del', child: Text('删除'))],
    ).then((v) {
      if (v == 'del') _delete(sub);
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _subs.removeAt(oldIndex);
      _subs.insert(newIndex, item);
      _subs = [
        for (var i = 0; i < _subs.length; i++)
          _subs[i].copyWith(customOrder: i + 1),
      ];
    });
    await RuleSubPrefs.save(_subs);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('规则订阅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加',
            onPressed: _add,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (_subs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '添加大佬们提供的规则导入地址\n添加后点击可导入规则',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _subs.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final sub = _subs[index];
                      return _RuleSubTile(
                        key: ValueKey(sub.id),
                        sub: sub,
                        accent: accent,
                        onOpen: () => _openSubscription(sub),
                        onEdit: () => _editSubscription(sub),
                        onMore: (anchor) => _showItemMenu(sub, anchor),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

/// item_rule_sub.xml
class _RuleSubTile extends StatelessWidget {
  const _RuleSubTile({
    super.key,
    required this.sub,
    required this.accent,
    required this.onOpen,
    required this.onEdit,
    required this.onMore,
  });

  final RuleSub sub;
  final Color accent;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final void Function(Offset anchor) onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(3),
                      child: Text(
                        sub.name.isEmpty ? '(未命名)' : sub.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            sub.typeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Text(
                              sub.url,
                              style: TextStyle(fontSize: 12, color: secondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(Icons.edit_outlined, size: 22),
                  tooltip: '编辑',
                  onPressed: onEdit,
                ),
              ),
              Builder(
                builder: (ctx) => SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.more_vert, size: 22),
                    tooltip: '更多',
                    onPressed: () {
                      final box = ctx.findRenderObject() as RenderBox?;
                      final offset =
                          box?.localToGlobal(Offset.zero) ?? Offset.zero;
                      onMore(offset);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// dialog_rule_sub_edit.xml
class _RuleSubEditDialog extends StatefulWidget {
  const _RuleSubEditDialog({required this.ruleSub});

  final RuleSub ruleSub;

  @override
  State<_RuleSubEditDialog> createState() => _RuleSubEditDialogState();
}

class _RuleSubEditDialogState extends State<_RuleSubEditDialog> {
  late int _type;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _intervalCtrl;
  late bool _autoUpdate;
  late bool _silentUpdate;

  @override
  void initState() {
    super.initState();
    final r = widget.ruleSub;
    _type = r.type.clamp(0, RuleSub.typeLabels.length - 1);
    _nameCtrl = TextEditingController(text: r.name);
    _urlCtrl = TextEditingController(text: r.url);
    _autoUpdate = r.autoUpdate;
    _silentUpdate = r.silentUpdate;
    _intervalCtrl = TextEditingController(text: r.updateInterval.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  void _onAutoChanged(bool? checked) {
    final isChecked = checked ?? false;
    setState(() {
      _autoUpdate = isChecked;
      if (isChecked && (int.tryParse(_intervalCtrl.text) ?? 0) == 0) {
        _intervalCtrl.text = '24';
      } else if (!isChecked) {
        _intervalCtrl.text = '0';
      }
      if (!isChecked) {
        _silentUpdate = false;
      }
    });
  }

  void _onIntervalChanged(String s) {
    final n = int.tryParse(s) ?? 0;
    setState(() {
      if (n == 0) {
        _silentUpdate = false;
        _autoUpdate = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final intervalEnabled = _autoUpdate;
    final silentEnabled =
        _autoUpdate && (int.tryParse(_intervalCtrl.text) ?? 0) != 0;

    return AlertDialog(
      title: const Text('规则订阅'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(
                    '类型：',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                DropdownButton<int>(
                  value: _type,
                  items: [
                    for (var i = 0; i < RuleSub.typeLabels.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(RuleSub.typeLabels[i]),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
              ],
            ),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '名称',
                border: UnderlineInputBorder(),
              ),
            ),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Url',
                border: UnderlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(value: _autoUpdate, onChanged: _onAutoChanged),
                    const Text('自动更新'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _silentUpdate,
                      onChanged: silentEnabled
                          ? (v) => setState(() => _silentUpdate = v ?? false)
                          : null,
                    ),
                    const Text('静默更新'),
                  ],
                ),
                const Text('间隔：'),
                SizedBox(
                  width: 48,
                  child: TextField(
                    controller: _intervalCtrl,
                    enabled: intervalEnabled,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '24',
                      isDense: true,
                    ),
                    onChanged: _onIntervalChanged,
                  ),
                ),
                const Text('小时'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final intervalText = _intervalCtrl.text;
            final interval = intervalText.isEmpty
                ? 0
                : int.tryParse(intervalText) ?? 0;
            Navigator.pop(
              context,
              widget.ruleSub.copyWith(
                type: _type,
                name: _nameCtrl.text,
                url: _urlCtrl.text,
                autoUpdate: _autoUpdate,
                silentUpdate: _silentUpdate,
                updateInterval: interval,
              ),
            );
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}

/// 对齐 ImportBookSource / ImportRssSource / ImportReplaceRule 选择导入
class _RuleSubImportDialog extends StatefulWidget {
  const _RuleSubImportDialog({required this.sub, required this.fetched});

  final RuleSub sub;
  final RuleSubFetched fetched;

  @override
  State<_RuleSubImportDialog> createState() => _RuleSubImportDialogState();
}

class _RuleSubImportDialogState extends State<_RuleSubImportDialog> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.fetched.count, true);
  }

  Future<void> _import() async {
    final indices = <int>[
      for (var i = 0; i < _selected.length; i++)
        if (_selected[i]) i,
    ];
    if (indices.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final sourceProvider = context.read<SourceProvider>();
    final rssProvider = context.read<RssProvider>();
    final replaceProvider = context.read<ReplaceProvider>();
    var imported = 0;

    switch (widget.fetched.kind) {
      case RuleSubFetchKind.bookSource:
        final list = [
          for (final i in indices) widget.fetched.bookSources[i].toJson(),
        ];
        final ok = await sourceProvider.importSources(jsonEncode(list));
        imported = ok ? list.length : 0;
      case RuleSubFetchKind.rssSource:
        final list = [
          for (final i in indices) widget.fetched.rssSources[i].toJson(),
        ];
        final ok = await rssProvider.importSources(jsonEncode(list));
        imported = ok ? list.length : 0;
      case RuleSubFetchKind.replaceRule:
        for (final i in indices) {
          final rule = widget.fetched.replaceRules[i];
          final existing = replaceProvider.replaceRules
              .where((r) => r.id == rule.id)
              .firstOrNull;
          if (existing == null) {
            await replaceProvider.addRule(rule);
          } else {
            await replaceProvider.updateRule(rule);
          }
          imported++;
        }
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          imported > 0 ? '已导入 $imported 条${widget.sub.typeLabel}' : '导入失败',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.fetched.labels;
    final title = switch (widget.fetched.kind) {
      RuleSubFetchKind.bookSource => '导入书源',
      RuleSubFetchKind.rssSource => '导入订阅源',
      RuleSubFetchKind.replaceRule => '导入替换规则',
    };

    return AlertDialog(
      title: Text('$title (${labels.length})'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: labels.length,
          itemBuilder: (_, i) => CheckboxListTile(
            dense: true,
            value: _selected[i],
            title: Text(
              labels[i],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onChanged: (v) => setState(() => _selected[i] = v ?? false),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              final all = _selected.every((e) => e);
              _selected = List.filled(_selected.length, !all);
            });
          },
          child: const Text('全选'),
        ),
        FilledButton(onPressed: _import, child: const Text('导入')),
      ],
    );
  }
}
