import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/book/book_group_policy.dart';
import '../application/bookshelf/book_group_management_port.dart';
import '../domain/book/book_group.dart';
import 'book_group_edit_dialog.dart';
import 'legado_dialog_title_bar.dart';

/// 分组管理 — 对齐 Jingshiro [GroupManageDialog] + `item_book_group_manage.xml`
Future<void> showBookGroupManageDialog(
  BuildContext context, {
  BookGroupManagementPort? port,
}) {
  final resolvedPort = port ?? context.read<BookGroupManagementPort>();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BookGroupManageDialog(port: resolvedPort),
  );
}

class _BookGroupManageDialog extends StatefulWidget {
  const _BookGroupManageDialog({required this.port});

  final BookGroupManagementPort port;

  @override
  State<_BookGroupManageDialog> createState() => _BookGroupManageDialogState();
}

class _BookGroupManageDialogState extends State<_BookGroupManageDialog> {
  List<BookGroup> _groups = [];
  bool _loading = true;

  /// 对齐 Jingshiro Dialog 白底内容区（去掉主题 surface 粉色底色）
  static const _panelBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await widget.port.load();
    if (!mounted) return;
    setState(() {
      _groups = list;
      _loading = false;
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

  Future<void> _toggleShow(BookGroup g, bool show) async {
    await widget.port.update(g.copyWith(show: show));
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: _panelBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.05,
        vertical: size.height * 0.05,
      ),
      clipBehavior: Clip.antiAlias,
      shape: LegadoDialogTitleBar.dialogShape(),
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.9,
        child: ColoredBox(
          color: _panelBg,
          child: Column(
            children: [
              LegadoDialogTitleBar(
                title: '分组管理',
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
                    : ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final g = _groups[index];
                          return ColoredBox(
                            color: _panelBg,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          g.manageName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.75,
                                            ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _edit(g),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          '编辑',
                                          style: TextStyle(
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.65,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: g.show,
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: accent,
                                        onChanged: (v) => _toggleShow(g, v),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: scheme.outline.withValues(alpha: 0.25),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              ColoredBox(
                color: _panelBg,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('确认', style: TextStyle(color: accent)),
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
