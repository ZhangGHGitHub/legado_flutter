import 'package:flutter/material.dart';

import '../../services/bookshelf_prefs.dart';

/// 书架布局 Dialog — 对齐 Jingshiro [dialog_bookshelf_config] /
/// [BaseBookshelfFragment.configBookshelf]。
class BookshelfConfigDialog extends StatefulWidget {
  const BookshelfConfigDialog({super.key, required this.initial});

  final BookshelfConfig initial;

  /// 返回保存后的配置；取消为 null。
  static Future<BookshelfConfig?> show(
    BuildContext context, {
    BookshelfConfig? initial,
  }) async {
    final cfg = initial ?? await BookshelfPrefs.load();
    if (!context.mounted) return null;
    return showDialog<BookshelfConfig>(
      context: context,
      builder: (_) => BookshelfConfigDialog(initial: cfg),
    );
  }

  @override
  State<BookshelfConfigDialog> createState() => _BookshelfConfigDialogState();
}

class _BookshelfConfigDialogState extends State<BookshelfConfigDialog> {
  late int _groupStyle;
  late int _layout;
  late int _sort;
  late bool _showUnread;
  late bool _showLastUpdate;
  late bool _showWaitUp;
  late bool _fastScroller;
  late bool _onlyUpdateRead;
  late int _showBookname;
  late double _margin;

  static const _layouts = [
    '列表',
    '紧凑列表',
    '网格二列',
    '网格三列',
    '网格四列',
    '网格五列',
    '网格六列',
  ];

  static const _sorts = [
    '按阅读时间',
    '按更新时间',
    '按书名',
    '手动排序',
    '综合排序',
    '按作者',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _groupStyle = c.bookGroupStyle.clamp(0, 1);
    _layout = c.bookshelfLayout.clamp(0, 6);
    _sort = c.bookshelfSort.clamp(0, 5);
    _showUnread = c.showUnread;
    _showLastUpdate = c.showLastUpdateTime;
    _showWaitUp = c.showWaitUpCount;
    _fastScroller = c.showBookshelfFastScroller;
    _onlyUpdateRead = c.onlyUpdateRead;
    _showBookname = c.showBookname.clamp(0, 2);
    _margin = c.bookshelfMargin.toDouble().clamp(0, 60);
  }

  Future<void> _save() async {
    final next = BookshelfConfig(
      bookGroupStyle: _groupStyle,
      bookshelfLayout: _layout,
      bookshelfSort: _sort,
      showUnread: _showUnread,
      showLastUpdateTime: _showLastUpdate,
      showWaitUpCount: _showWaitUp,
      showBookshelfFastScroller: _fastScroller,
      onlyUpdateRead: _onlyUpdateRead,
      showBookname: _showBookname,
      bookshelfMargin: _margin.round(),
      bookOrder: widget.initial.bookOrder,
    );
    await BookshelfPrefs.save(next);
    if (!mounted) return;
    Navigator.pop(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final showNameRow = _layout >= 2;

    return AlertDialog(
      title: const Text('书架布局'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('分组样式')),
                  DropdownButton<int>(
                    value: _groupStyle,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Tab')),
                      DropdownMenuItem(value: 1, child: Text('Folder')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _groupStyle = v);
                    },
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示未读标志'),
                subtitle: const Text('书架每本书右侧的未读章数角标'),
                value: _showUnread,
                onChanged: (v) => setState(() => _showUnread = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示上次更新时间'),
                value: _showLastUpdate,
                onChanged: (v) => setState(() => _showLastUpdate = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示等待更新数量'),
                subtitle: const Text('仅下拉/批量更新目录时，底栏「书架」上显示进行中数量；空闲时无角标'),
                value: _showWaitUp,
                onChanged: (v) => setState(() => _showWaitUp = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('仅更新已读'),
                subtitle: const Text('下拉刷新时只更新已读过的书；未读书不触发联网'),
                value: _onlyUpdateRead,
                onChanged: (v) => setState(() => _onlyUpdateRead = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('显示快速滚动条'),
                value: _fastScroller,
                onChanged: (v) => setState(() => _fastScroller = v),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '视图',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                        for (var i = 0; i < _layouts.length; i++)
                          RadioListTile<int>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(_layouts[i], style: const TextStyle(fontSize: 14)),
                            value: i,
                            groupValue: _layout,
                            onChanged: (v) {
                              if (v != null) setState(() => _layout = v);
                            },
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '排序',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                        for (var i = 0; i < _sorts.length; i++)
                          RadioListTile<int>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(_sorts[i], style: const TextStyle(fontSize: 14)),
                            value: i,
                            groupValue: _sort,
                            onChanged: (v) {
                              if (v != null) setState(() => _sort = v);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showNameRow) ...[
                Text(
                  '书名',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    for (final e in const [
                      (0, '显示'),
                      (1, '隐藏'),
                      (2, '叠加'),
                    ])
                      Expanded(
                        child: RadioListTile<int>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.$2, style: const TextStyle(fontSize: 13)),
                          value: e.$1,
                          groupValue: _showBookname,
                          onChanged: (v) {
                            if (v != null) setState(() => _showBookname = v);
                          },
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text('边距 ${_margin.round()}'),
              Slider(
                value: _margin,
                min: 0,
                max: 60,
                divisions: 60,
                label: '${_margin.round()}',
                onChanged: (v) => setState(() => _margin = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('确定'),
        ),
      ],
    );
  }
}
