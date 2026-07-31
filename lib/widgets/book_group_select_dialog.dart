import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/bookshelf/book_group_management_port.dart';
import '../domain/book/book_group.dart';
import 'book_group_edit_dialog.dart';
import 'legado_dialog_title_bar.dart';

/// 选择分组结果（自定义分组名列表，空表示未分组）
class BookGroupSelectResult {
  const BookGroupSelectResult(this.groupNames);

  final List<String> groupNames;

  /// 移入分组：取选中的第一个自定义名；无选中则为空（未分组）
  String get primaryName => groupNames.isEmpty ? '' : groupNames.first;
}

/// 选择分组 — 对齐 Jingshiro [GroupSelectDialog] + `dialog_book_group_picker.xml`
Future<BookGroupSelectResult?> showBookGroupSelectDialog(
  BuildContext context, {
  String? currentGroupName,
  BookGroupManagementPort? port,
}) {
  final resolvedPort = port ?? context.read<BookGroupManagementPort>();
  return showDialog<BookGroupSelectResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BookGroupSelectDialog(
      currentGroupName: currentGroupName,
      port: resolvedPort,
    ),
  );
}

class _BookGroupSelectDialog extends StatefulWidget {
  const _BookGroupSelectDialog({this.currentGroupName, required this.port});

  final String? currentGroupName;
  final BookGroupManagementPort port;

  @override
  State<_BookGroupSelectDialog> createState() => _BookGroupSelectDialogState();
}

class _BookGroupSelectDialogState extends State<_BookGroupSelectDialog> {
  List<BookGroup> _groups = [];
  final _checked = <int>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await widget.port.loadSelectGroups();
    if (!mounted) return;
    setState(() {
      _groups = list;
      _loading = false;
      _checked.clear();
      final cur = widget.currentGroupName;
      if (cur != null && cur.isNotEmpty) {
        for (final g in list) {
          if (g.groupName == cur) _checked.add(g.groupId);
        }
      }
    });
  }

  Future<void> _add() async {
    if (!await widget.port.canAddGroup()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分组已达上限(64个)')));
      return;
    }
    if (!mounted) return;
    await showBookGroupEditDialog(context, port: widget.port);
    await _reload();
  }

  Future<void> _edit(BookGroup g) async {
    await showBookGroupEditDialog(context, group: g, port: widget.port);
    await _reload();
  }

  void _onOk() {
    final names = _groups
        .where((g) => _checked.contains(g.groupId))
        .map((g) => g.groupName)
        .toList();
    Navigator.pop(context, BookGroupSelectResult(names));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;
    final size = MediaQuery.sizeOf(context);
    const panelBg = Colors.white;

    return Dialog(
      backgroundColor: panelBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.05,
      ),
      clipBehavior: Clip.antiAlias,
      shape: LegadoDialogTitleBar.dialogShape(),
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.75,
        child: ColoredBox(
          color: panelBg,
          child: Column(
            children: [
              LegadoDialogTitleBar(
                title: '选择分组',
                actions: [
                  IconButton(
                    tooltip: '添加',
                    icon: Icon(Icons.add, color: scheme.onPrimary, size: 26),
                    onPressed: _add,
                  ),
                ],
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _groups.isEmpty
                    ? Center(
                        child: Text(
                          '暂无自定义分组，点右上角 + 添加',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _groups.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: scheme.outline.withValues(alpha: 0.25),
                        ),
                        itemBuilder: (context, index) {
                          final g = _groups[index];
                          final checked = _checked.contains(g.groupId);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(g.groupName),
                                    value: checked,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _checked.add(g.groupId);
                                        } else {
                                          _checked.remove(g.groupId);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _edit(g),
                                  child: Text(
                                    '编辑',
                                    style: TextStyle(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('取消', style: TextStyle(color: accent)),
                    ),
                    TextButton(
                      onPressed: _onOk,
                      child: Text('确认', style: TextStyle(color: accent)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
