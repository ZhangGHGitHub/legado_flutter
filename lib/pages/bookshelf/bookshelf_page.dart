import 'package:flutter/material.dart';

import '../../services/bookshelf_prefs.dart';
import 'bookshelf_style1_page.dart';
import 'bookshelf_style2_page.dart';

/// 书架 Tab — 按 bookGroupStyle 切换 style1 / style2
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<BookshelfPage> createState() => BookshelfPageState();
}

class BookshelfPageState extends State<BookshelfPage> {
  int _groupStyle = 0;

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final style = await BookshelfPrefs.loadGroupStyle();
    if (mounted) setState(() => _groupStyle = style);
  }

  Future<void> _setStyle(int style) async {
    await BookshelfPrefs.saveGroupStyle(style);
    if (mounted) setState(() => _groupStyle = style);
  }

  /// 外部刷新布局（如从 ConfigPage 返回后）
  void reloadLayout() => _loadStyle();

  @override
  Widget build(BuildContext context) {
    if (_groupStyle == 1) {
      return BookshelfStyle2Page(
        scrollController: widget.scrollController,
        onSwitchToList: () => _setStyle(0),
      );
    }
    return BookshelfStyle1Page(
      scrollController: widget.scrollController,
      onSwitchToGrid: () => _setStyle(1),
    );
  }
}
