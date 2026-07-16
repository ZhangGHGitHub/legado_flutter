/// 首页（书架）— 目录对齐 structure.md `pages/home/`。
///
/// 实现仍委托历史 `pages/bookshelf/`，避免一次性搬迁破坏导入与测试。
library;

import '../bookshelf/bookshelf_page.dart';

export '../bookshelf/bookshelf_page.dart' show BookshelfPage, BookshelfPageState;

/// 目标命名别名（与 BookshelfPage 同一实现）
typedef HomePage = BookshelfPage;
typedef HomePageState = BookshelfPageState;
