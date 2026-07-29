import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../application/book/book_group_policy.dart';
import '../domain/book/book_group.dart';
import '../services/book_group_store.dart';
import 'book_cover.dart';
import 'legado_dialog_title_bar.dart';

/// 编辑/添加分组 — 对齐 Jingshiro [GroupEditDialog] + `dialog_book_group_edit.xml`
Future<BookGroup?> showBookGroupEditDialog(
  BuildContext context, {
  BookGroup? group,
}) {
  return showDialog<BookGroup>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BookGroupEditDialog(initial: group),
  );
}

class _BookGroupEditDialog extends StatefulWidget {
  const _BookGroupEditDialog({this.initial});

  final BookGroup? initial;

  @override
  State<_BookGroupEditDialog> createState() => _BookGroupEditDialogState();
}

class _BookGroupEditDialogState extends State<_BookGroupEditDialog> {
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus;
  late int _bookSort;
  late bool _enableRefresh;
  late bool _onlyUpdateRead;
  String? _cover;

  bool get _isAdd => widget.initial == null;

  @override
  void initState() {
    super.initState();
    final g = widget.initial;
    _nameCtrl = TextEditingController(text: g?.groupName ?? '');
    _nameFocus = FocusNode()..addListener(() => setState(() {}));
    _bookSort = g?.bookSort ?? -1;
    if (_bookSort + 1 < 0 ||
        _bookSort + 1 >= BookGroupPolicy.sortLabels.length) {
      _bookSort = -1;
    }
    _enableRefresh = g?.enableRefresh ?? true;
    _onlyUpdateRead = g?.onlyUpdateRead ?? false;
    _cover = g?.cover;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    if (_cover != null && _cover!.isNotEmpty) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('选择图片'),
                onTap: () => Navigator.pop(ctx, 'pick'),
              ),
              ListTile(
                title: const Text('删除'),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        ),
      );
      if (action == 'delete') {
        setState(() => _cover = null);
        return;
      }
      if (action != 'pick') return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null && mounted) setState(() => _cover = path);
  }

  Future<void> _onOk() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分组名称不能为空')));
      return;
    }
    if (_isAdd) {
      if (!await BookGroupStore.canAddGroup()) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('分组已达上限(64个)')));
        return;
      }
      final id = await BookGroupStore.unusedId();
      final order = (await BookGroupStore.maxOrder()) + 1;
      final created = BookGroup(
        groupId: id,
        groupName: name,
        cover: _cover,
        bookSort: _bookSort,
        enableRefresh: _enableRefresh,
        onlyUpdateRead: _onlyUpdateRead,
        order: order,
        show: true,
      );
      await BookGroupStore.update(created);
      if (!mounted) return;
      Navigator.pop(context, created);
      return;
    }
    final updated = widget.initial!.copyWith(
      groupName: name,
      cover: _cover,
      clearCover: _cover == null || _cover!.isEmpty,
      bookSort: _bookSort,
      enableRefresh: _enableRefresh,
      onlyUpdateRead: _onlyUpdateRead,
    );
    await BookGroupStore.update(updated);
    if (!mounted) return;
    Navigator.pop(context, updated);
  }

  Future<void> _onDelete() async {
    final g = widget.initial;
    if (g == null || !g.isCustom) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除'),
        content: const Text('确定删除？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await BookGroupStore.delete(g);
    if (!mounted) return;
    Navigator.pop(context, g.copyWith(groupName: ''));
  }

  String get _sortLabel {
    final i = _bookSort + 1;
    if (i < 0 || i >= BookGroupPolicy.sortLabels.length) {
      return BookGroupPolicy.sortLabels.first;
    }
    return BookGroupPolicy.sortLabels[i];
  }

  Widget _buildCover(ColorScheme scheme) {
    final hasFile =
        _cover != null && _cover!.isNotEmpty && File(_cover!).existsSync();
    return GestureDetector(
      onTap: _pickCover,
      child: SizedBox(
        width: 90,
        height: 126,
        child: hasFile
            ? ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.file(File(_cover!), fit: BoxFit.cover),
              )
            : BookCover(coverUrl: '', width: 90, height: 126, radius: 2),
      ),
    );
  }

  /// 对齐 TextInputLayout：标签上浮后，输入文字贴底线显示
  Widget _buildNameField(ColorScheme scheme, Color accent) {
    return TextField(
      controller: _nameCtrl,
      focusNode: _nameFocus,
      maxLines: 1,
      textAlignVertical: TextAlignVertical.bottom,
      style: TextStyle(fontSize: 16, color: scheme.onSurface, height: 1.25),
      cursorColor: accent,
      decoration: InputDecoration(
        labelText: '分组名称',
        alignLabelWithHint: true,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        labelStyle: TextStyle(
          color: accent.withValues(alpha: 0.85),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        isDense: true,
        // 上留空给浮动标签，文字贴近底部分割线
        contentPadding: const EdgeInsets.only(top: 18, bottom: 2),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// 对齐 AppCompatSpinner：左侧「排序」强调色 + 当前值 + 右下角三角
  Widget _buildSortRow(ColorScheme scheme, Color accent) {
    return PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 28),
      onSelected: (v) => setState(() => _bookSort = v),
      itemBuilder: (_) => [
        for (var i = 0; i < BookGroupPolicy.sortLabels.length; i++)
          PopupMenuItem(
            value: i - 1,
            child: Text(BookGroupPolicy.sortLabels[i]),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              '排序',
              style: TextStyle(
                fontSize: 13,
                color: accent,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 14, bottom: 2),
                    child: Text(
                      _sortLabel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CustomPaint(
                      size: const Size(8, 6),
                      painter: _CornerTrianglePainter(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheck(
    Color accent,
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Checkbox(
                value: value,
                activeColor: accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;
    // 对齐 Jingshiro Dialog 白底，去掉主题粉色 surface 底色
    const panelBg = Colors.white;

    return Dialog(
      backgroundColor: panelBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: LegadoDialogTitleBar.dialogShape(),
      child: ColoredBox(
        color: panelBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LegadoDialogTitleBar(title: _isAdd ? '添加分组' : '编辑分组'),
            // 拉高内容区，对齐 Jingshiro WRAP_CONTENT 视觉比例（封面 90×126 + 边距）
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 168),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCover(scheme),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNameField(scheme, accent),
                          const SizedBox(height: 14),
                          _buildSortRow(scheme, accent),
                          const SizedBox(height: 10),
                          _buildCheck(
                            accent,
                            '允许下拉刷新',
                            _enableRefresh,
                            (v) => setState(() => _enableRefresh = v ?? true),
                          ),
                          _buildCheck(
                            accent,
                            '仅更新已读完',
                            _onlyUpdateRead,
                            (v) => setState(() => _onlyUpdateRead = v ?? false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Row(
                children: [
                  if (!_isAdd && (widget.initial?.isCustom ?? false))
                    TextButton(
                      onPressed: _onDelete,
                      child: Text('删除', style: TextStyle(color: accent)),
                    ),
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
    );
  }
}

/// Spinner 右下角指示三角 — 对齐 Jingshiro AppCompatSpinner 外观
class _CornerTrianglePainter extends CustomPainter {
  _CornerTrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CornerTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
