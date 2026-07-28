import 'package:flutter/material.dart';

import '../../services/reader_font_loader.dart';

/// 书架右上角溢出菜单 — 对齐 Jingshiro `menu_bookshelf_*` 文案与顺序。
abstract final class BookshelfOverflowMenu {
  static const updateToc = 'update_toc';
  static const addLocal = 'add_local';
  static const remoteBook = 'remote_book';
  static const addUrl = 'add_url';
  static const arrange = 'arrange';
  static const cacheExport = 'cache_export';
  static const groupMgmt = 'group_mgmt';
  static const layout = 'layout';
  static const exportList = 'export_list';
  static const importList = 'import_list';
  static const log = 'log';

  /// 尚无页面、仅占位的菜单项（UI-BS 已实现项已移出）
  static const stubActions = <String>{};

  static String stubLabel(String action) => switch (action) {
    addUrl => '添加网址',
    exportList => '导出书单',
    importList => '导入书单',
    log => '日志',
    _ => action,
  };

  /// 锁定同一 CJK 字体 + Regular，避免 Windows 默认 fallback 混字重。
  static TextStyle _labelStyle(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    return base.copyWith(
      fontFamily: ReaderFontLoader.platformSansFamily(),
      fontFamilyFallback: ReaderFontLoader.cjkFallbackFamilies(),
      fontWeight: FontWeight.w400,
      fontSize: base.fontSize ?? 14,
      height: 1.25,
    );
  }

  static List<PopupMenuEntry<String>> items(BuildContext context) {
    final style = _labelStyle(context);
    final iconColor = Theme.of(context).colorScheme.onSurface;
    PopupMenuItem<String> item(String value, IconData icon, String title) {
      return PopupMenuItem(
        value: value,
        child: _MenuRow(
          icon: icon,
          title: title,
          style: style,
          iconColor: iconColor,
        ),
      );
    }

    return [
      item(updateToc, Icons.refresh, '更新目录'),
      item(addLocal, Icons.add, '添加本地'),
      item(remoteBook, Icons.add_circle_outline, '远程书籍'),
      item(addUrl, Icons.travel_explore_outlined, '添加网址'),
      item(arrange, Icons.library_books_outlined, '书架管理'),
      item(cacheExport, Icons.download_for_offline_outlined, '缓存/导出'),
      item(groupMgmt, Icons.playlist_add_check, '分组管理'),
      item(layout, Icons.dashboard_customize_outlined, '书架布局'),
      item(exportList, Icons.ios_share_outlined, '导出书单'),
      item(importList, Icons.file_download_outlined, '导入书单'),
      item(log, Icons.info_outline, '日志'),
    ];
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final TextStyle style;
  final Color iconColor;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.style,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: iconColor.withValues(alpha: 0.87)),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          title,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
