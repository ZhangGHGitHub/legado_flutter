import 'package:flutter/material.dart';

import '../../services/bookshelf_prefs.dart';
import 'bookshelf_style1_page.dart';
import 'bookshelf_style2_page.dart';

/// 书架 Tab — `bookGroupStyle`：0=Tab(style1) / 1=Folder(style2)
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key, this.scrollController, this.onConfigChanged});

  final ScrollController? scrollController;

  /// 布局 Dialog 保存后通知主壳（待更新角标等）
  final ValueChanged<BookshelfConfig>? onConfigChanged;

  @override
  State<BookshelfPage> createState() => BookshelfPageState();
}

class BookshelfPageState extends State<BookshelfPage> {
  BookshelfConfig _config = const BookshelfConfig();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final cfg = await BookshelfPrefs.load();
    if (mounted) {
      setState(() {
        _config = cfg;
        _ready = true;
      });
    }
  }

  Future<void> _applyConfig(BookshelfConfig cfg) async {
    setState(() => _config = cfg);
    widget.onConfigChanged?.call(cfg);
  }

  /// 外部刷新布局（配置页 / Dialog 返回后）
  void reloadLayout() => _loadStyle();

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_config.bookGroupStyle == 1) {
      return BookshelfStyle2Page(
        scrollController: widget.scrollController,
        config: _config,
        onConfigChanged: _applyConfig,
      );
    }
    return BookshelfStyle1Page(
      scrollController: widget.scrollController,
      config: _config,
      onConfigChanged: _applyConfig,
    );
  }
}
