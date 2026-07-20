import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/source_provider.dart';
import 'legado_dialog_title_bar.dart';

/// 书源分组管理 — 对齐 Jingshiro
/// `ui/book/source/manage/GroupManageDialog` + `item_group_manage.xml`
Future<void> showSourceGroupManageDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    // Windows 无系统返回键；允许点遮罩关闭，底部另有「确认」
    barrierDismissible: true,
    builder: (_) => const _SourceGroupManageDialog(),
  );
}

class _SourceGroupManageDialog extends StatefulWidget {
  const _SourceGroupManageDialog();

  @override
  State<_SourceGroupManageDialog> createState() =>
      _SourceGroupManageDialogState();
}

class _SourceGroupManageDialogState extends State<_SourceGroupManageDialog> {
  static const _panelBg = Colors.white;

  List<String> _groupsFrom(SourceProvider provider) => provider.knownGroups;

  Future<void> _add(SourceProvider provider) async {
    final name = await _promptGroupName(
      title: '添加分组',
      hint: '分组名称',
    );
    if (name == null || name.isEmpty || !mounted) return;
    final added = await provider.addGroup(name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? '已添加分组「$name」' : '分组「$name」已存在',
        ),
      ),
    );
  }

  Future<void> _edit(SourceProvider provider, String group) async {
    final name = await _promptGroupName(
      title: '编辑分组',
      hint: '分组名称',
      initial: group,
    );
    if (name == null || !mounted) return;
    // 空名 = 删除该分组标签（对齐 Jingshiro upGroup(old, null/empty)）
    if (name.isEmpty) {
      await provider.deleteGroup(group);
      return;
    }
    if (name == group) return;
    await provider.renameGroup(group, name);
  }

  Future<void> _delete(SourceProvider provider, String group) async {
    await provider.deleteGroup(group);
  }

  Future<String?> _promptGroupName({
    required String title,
    required String hint,
    String? initial,
  }) {
    final ctrl = TextEditingController(text: initial ?? '');
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final accent = Theme.of(ctx).colorScheme.secondary;
        return AlertDialog(
          backgroundColor: _panelBg,
          surfaceTintColor: Colors.transparent,
          title: Text(title),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hint,
              border: const UnderlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: accent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text('确定', style: TextStyle(color: accent)),
            ),
          ],
        );
      },
    );
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
                    icon: Icon(
                      Icons.add,
                      color: scheme.onPrimary,
                      size: 26,
                    ),
                    onPressed: () {
                      final provider = context.read<SourceProvider>();
                      _add(provider);
                    },
                  ),
                ],
              ),
              Expanded(
                child: Consumer<SourceProvider>(
                  builder: (context, provider, _) {
                    final groups = _groupsFrom(provider);
                    if (groups.isEmpty) {
                      return Center(
                        child: Text(
                          '暂无书源分组',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: scheme.outline.withValues(alpha: 0.25),
                      ),
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        // 对齐 item_group_manage.xml：名称 | 编辑 | 删除
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _edit(provider, g),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '编辑',
                                  style: TextStyle(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _delete(provider, g),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    12,
                                    8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '删除',
                                  style: TextStyle(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // 对齐书架 GroupManageDialog 底栏；桌面端无系统返回键
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
