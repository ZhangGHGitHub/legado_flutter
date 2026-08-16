import '../../services/bookshelf_prefs.dart' show BookshelfConfig;

export '../../services/bookshelf_prefs.dart' show BookshelfConfig;

/// 书架配置对话框的持久化端口。
///
/// 对话框通过该端口读取初始配置，并只在用户确认后保存完整配置。
/// [BookshelfConfig] 继续复用既有书架配置模型，保持原有键名和默认值。
abstract interface class BookshelfConfigDialogPort {
  Future<BookshelfConfig> load();

  Future<void> save(BookshelfConfig config);
}
