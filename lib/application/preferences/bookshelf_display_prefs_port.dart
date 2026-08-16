/// 书架显示偏好端口，不暴露 SharedPreferences 实现。
abstract interface class BookshelfDisplayPrefsPort {
  Future<BookshelfDisplayPrefs> load();

  Future<bool> saveGrouped(bool value);

  Future<bool> savePinned(Iterable<String> ids);
}

final class BookshelfDisplayPrefs {
  const BookshelfDisplayPrefs({
    this.showGrouped = false,
    this.pinnedIds = const {},
  });

  final bool showGrouped;
  final Set<String> pinnedIds;
}
