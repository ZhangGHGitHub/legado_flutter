/// Rust 数据库能力端口。
///
/// 业务层只依赖这些存储操作；FRB 生成代码由具体适配器实现，不向上层泄漏。
abstract interface class RustDatabasePort {
  void requireReady();

  void insertBook({required String bookJson});

  List<String> getBooks();

  void deleteBook({required String bookId});

  void updateBookProgress({
    required String bookId,
    required double progress,
    String? chapter,
    required int pageIndex,
  });

  void updateBookCover({required String bookId, required String coverUrl});

  void updateBookGroup({required String bookId, required String group});

  void upsertSource({required String sourceJson});

  List<String> getSources({required bool enabledOnly});

  void toggleSource({required String url, required bool enabled});

  void deleteSource({required String url});

  void insertChapters({required String chaptersJson});

  List<String> getChapters({required String bookId});

  String? getChapterContent({required String chapterId});

  void saveChapterContent({required String chapterId, required String content});

  void upsertReplaceRule({required String ruleJson});

  List<String> getReplaceRules();

  void toggleReplaceRule({required String id, required bool enabled});

  void deleteReplaceRule({required String id});

  void clearReplaceRules();
}
