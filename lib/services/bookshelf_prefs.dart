import 'package:shared_preferences/shared_preferences.dart';

import '../models/book.dart';

/// 书架布局/排序偏好 — 对齐 Jingshiro PreferKey / AppConfig
class BookshelfConfig {
  /// 0=Tab 1=Folder
  final int bookGroupStyle;

  /// 0列表 1紧凑 2–6 网格列数
  final int bookshelfLayout;

  /// 0阅读时间 1更新时间 2书名 3手动 4综合 5作者
  final int bookshelfSort;

  final bool showUnread;
  final bool showLastUpdateTime;
  final bool showWaitUpCount;
  final bool showBookshelfFastScroller;
  final bool onlyUpdateRead;

  /// 0显示 1隐藏 2叠加（仅网格）
  final int showBookname;

  /// 0–60
  final int bookshelfMargin;

  final List<String> bookOrder;

  const BookshelfConfig({
    this.bookGroupStyle = 0,
    this.bookshelfLayout = 0,
    this.bookshelfSort = 0,
    this.showUnread = true,
    this.showLastUpdateTime = false,
    this.showWaitUpCount = false,
    this.showBookshelfFastScroller = false,
    this.onlyUpdateRead = false,
    this.showBookname = 0,
    this.bookshelfMargin = 12,
    this.bookOrder = const [],
  });

  bool get isGrid => bookshelfLayout >= 2;
  int get gridColumns => isGrid ? bookshelfLayout.clamp(2, 6) : 3;
  bool get isCompactList => bookshelfLayout == 1;
}

/// 书架布局偏好（对齐 Legado bookGroupStyle / bookshelfLayout / bookshelfSort）
abstract final class BookshelfPrefs {
  static const bookGroupStyleKey = 'bookGroupStyle';
  static const bookshelfLayoutKey = 'bookshelfLayout';
  static const bookshelfSortKey = 'bookshelfSort';
  static const shelfBookOrderKey = 'shelf_book_order';
  /// 旧键，读时回退
  static const shelfSortModeKey = 'shelf_sort_mode';
  static const showUnreadKey = 'showUnread';
  static const showLastUpdateTimeKey = 'showLastUpdateTime';
  static const showWaitUpCountKey = 'showWaitUpCount';
  static const showBookshelfFastScrollerKey = 'showBookshelfFastScroller';
  static const onlyUpdateReadKey = 'onlyUpdateRead';
  static const showBooknameKey = 'showBooknameLayout';
  static const bookshelfMarginKey = 'bookshelfMargin';

  static BookshelfConfig? _cached;

  /// 最近一次 [load]/[save] 的快照（主框架角标等同步读）
  static BookshelfConfig get cached => _cached ?? const BookshelfConfig();

  static Future<void> migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(bookshelfLayoutKey)) {
      // 旧版 bookGroupStyle=1 表示网格页 → 默认三列网格
      final style = prefs.getInt(bookGroupStyleKey) ?? 0;
      await prefs.setInt(bookshelfLayoutKey, style == 1 ? 3 : 0);
    }
    if (!prefs.containsKey(bookshelfSortKey) &&
        prefs.containsKey(shelfSortModeKey)) {
      await prefs.setInt(
        bookshelfSortKey,
        prefs.getInt(shelfSortModeKey) ?? 0,
      );
    }
  }

  static Future<BookshelfConfig> load() async {
    await migrateIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    var groupStyle = prefs.getInt(bookGroupStyleKey) ?? 0;
    if (groupStyle < 0 || groupStyle > 1) groupStyle = 0;
    var layout = prefs.getInt(bookshelfLayoutKey) ?? 0;
    if (layout < 0 || layout > 6) layout = 0;
    var sort = prefs.getInt(bookshelfSortKey) ??
        prefs.getInt(shelfSortModeKey) ??
        0;
    if (sort < 0 || sort > 5) sort = 0;
    var showName = prefs.getInt(showBooknameKey) ?? 0;
    if (showName < 0 || showName > 2) showName = 0;
    var margin = prefs.getInt(bookshelfMarginKey) ?? 12;
    if (margin < 0) margin = 0;
    if (margin > 60) margin = 60;
    final cfg = BookshelfConfig(
      bookGroupStyle: groupStyle,
      bookshelfLayout: layout,
      bookshelfSort: sort,
      showUnread: prefs.getBool(showUnreadKey) ?? true,
      showLastUpdateTime: prefs.getBool(showLastUpdateTimeKey) ?? false,
      showWaitUpCount: prefs.getBool(showWaitUpCountKey) ?? false,
      showBookshelfFastScroller:
          prefs.getBool(showBookshelfFastScrollerKey) ?? false,
      onlyUpdateRead: prefs.getBool(onlyUpdateReadKey) ?? false,
      showBookname: showName,
      bookshelfMargin: margin,
      bookOrder: prefs.getStringList(shelfBookOrderKey) ?? const [],
    );
    _cached = cfg;
    return cfg;
  }

  static Future<void> save(BookshelfConfig c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(bookGroupStyleKey, c.bookGroupStyle.clamp(0, 1));
    await prefs.setInt(bookshelfLayoutKey, c.bookshelfLayout.clamp(0, 6));
    await prefs.setInt(bookshelfSortKey, c.bookshelfSort.clamp(0, 5));
    await prefs.setInt(shelfSortModeKey, c.bookshelfSort.clamp(0, 5));
    await prefs.setBool(showUnreadKey, c.showUnread);
    await prefs.setBool(showLastUpdateTimeKey, c.showLastUpdateTime);
    await prefs.setBool(showWaitUpCountKey, c.showWaitUpCount);
    await prefs.setBool(
      showBookshelfFastScrollerKey,
      c.showBookshelfFastScroller,
    );
    await prefs.setBool(onlyUpdateReadKey, c.onlyUpdateRead);
    await prefs.setInt(showBooknameKey, c.showBookname.clamp(0, 2));
    await prefs.setInt(bookshelfMarginKey, c.bookshelfMargin.clamp(0, 60));
    _cached = c;
  }

  /// 0 = Tab，1 = Folder
  static Future<int> loadGroupStyle() async {
    final c = await load();
    return c.bookGroupStyle;
  }

  static Future<void> saveGroupStyle(int style) async {
    final cur = await load();
    await save(
      BookshelfConfig(
        bookGroupStyle: style.clamp(0, 1),
        bookshelfLayout: cur.bookshelfLayout,
        bookshelfSort: cur.bookshelfSort,
        showUnread: cur.showUnread,
        showLastUpdateTime: cur.showLastUpdateTime,
        showWaitUpCount: cur.showWaitUpCount,
        showBookshelfFastScroller: cur.showBookshelfFastScroller,
        onlyUpdateRead: cur.onlyUpdateRead,
        showBookname: cur.showBookname,
        bookshelfMargin: cur.bookshelfMargin,
        bookOrder: cur.bookOrder,
      ),
    );
  }

  static Future<List<String>> loadBookOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(shelfBookOrderKey) ?? [];
  }

  static Future<void> saveBookOrder(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(shelfBookOrderKey, ids);
  }

  static Future<int> loadSortMode() async {
    final c = await load();
    return c.bookshelfSort;
  }

  static Future<void> saveSortMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(bookshelfSortKey, mode.clamp(0, 5));
    await prefs.setInt(shelfSortModeKey, mode.clamp(0, 5));
  }

  /// 将 [books] 按已保存顺序重排；未知书追加在末尾。
  static List<T> applyBookOrder<T>(
    List<T> books,
    List<String> orderIds,
    String Function(T) idOf,
  ) {
    if (orderIds.isEmpty) return books;
    final rank = <String, int>{};
    for (var i = 0; i < orderIds.length; i++) {
      rank[orderIds[i]] = i;
    }
    final sorted = [...books];
    sorted.sort((a, b) {
      final ra = rank[idOf(a)] ?? 1 << 20;
      final rb = rank[idOf(b)] ?? 1 << 20;
      return ra.compareTo(rb);
    });
    return sorted;
  }

  /// 按 bookshelfSort 排序（置顶 ID 始终优先）。
  static List<Book> sortBooks(
    List<Book> books, {
    required int sortMode,
    required List<String> orderIds,
    Set<String> pinnedIds = const {},
  }) {
    final pinned = <Book>[];
    final rest = <Book>[];
    for (final b in books) {
      if (pinnedIds.contains(b.id)) {
        pinned.add(b);
      } else {
        rest.add(b);
      }
    }
    List<Book> sortRest(List<Book> list) {
      final out = [...list];
      switch (sortMode) {
        case 0: // 阅读时间 — updatedAt 降序
        case 1: // 更新时间 — 暂共用 updatedAt 降序
          out.sort((a, b) => _updatedMs(b).compareTo(_updatedMs(a)));
        case 2: // 书名
          out.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        case 3: // 手动
          return applyBookOrder(out, orderIds, (b) => b.id);
        case 4: // 综合 — 书名
          out.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
        case 5: // 作者
          out.sort(
            (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()),
          );
        default:
          out.sort((a, b) => _updatedMs(b).compareTo(_updatedMs(a)));
      }
      return out;
    }

    return [...sortRest(pinned), ...sortRest(rest)];
  }

  static int _updatedMs(Book b) {
    final raw = b.updatedAt?.trim() ?? '';
    if (raw.isEmpty) return 0;
    final dt = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    return dt?.millisecondsSinceEpoch ?? 0;
  }
}
