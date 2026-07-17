import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/book_provider.dart';
import '../../services/app_log.dart';
import '../../services/bookshelf_list_io.dart';
import 'add_book_url_dialog.dart';
import 'app_log_dialog.dart';
import 'bookshelf_overflow_menu.dart';
import 'import_bookshelf_dialog.dart';
import 'remote_book_page.dart';

/// 书架溢出菜单中 UI-BS 项的统一处理，供 style1/style2 复用。
abstract final class BookshelfMenuActions {
  static Future<bool> handle(BuildContext context, String action) async {
    switch (action) {
      case BookshelfOverflowMenu.addUrl:
        await AddBookUrlDialog.show(context);
        return true;
      case BookshelfOverflowMenu.exportList:
        await _exportList(context);
        return true;
      case BookshelfOverflowMenu.importList:
        await ImportBookshelfDialog.show(context);
        return true;
      case BookshelfOverflowMenu.log:
        await AppLogDialog.show(context);
        return true;
      case BookshelfOverflowMenu.remoteBook:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RemoteBookPage()),
        );
        return true;
      default:
        return false;
    }
  }

  static Future<void> _exportList(BuildContext context) async {
    final books = context.read<BookProvider>().books;
    if (books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('书架为空，无需导出')),
      );
      return;
    }
    try {
      final path = await BookshelfListIo.exportBooks(books);
      if (path == null) return;
      await AppLog.i('导出书单 ${books.length} 本 → $path');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 ${books.length} 本\n$path')),
        );
      }
    } catch (e) {
      await AppLog.e('导出书单失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
