/// 首页（书架）— 目录对齐 structure.md `pages/home/`。
///
/// 实现委托功能域 `features/bookshelf/`，保留首页兼容入口。
library;

import '../../features/bookshelf/bookshelf_page.dart';

export '../../features/bookshelf/bookshelf_page.dart'
    show BookshelfPage, BookshelfPageState;

/// 目标命名别名（与 BookshelfPage 同一实现）
typedef HomePage = BookshelfPage;
typedef HomePageState = BookshelfPageState;
