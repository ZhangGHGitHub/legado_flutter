import '../../bridge/legado_db_bridge.dart';
import '../../src/rust/api/db.dart' as rust_db;
import 'rust_database_port.dart';

/// FRB/Rust SQLite 的基础设施适配器。
class FrbRustDatabasePort implements RustDatabasePort {
  @override
  void requireReady() => LegadoDbBridge.requireReady();

  @override
  void insertBook({required String bookJson}) {
    rust_db.dbInsertBook(bookJson: bookJson);
  }

  @override
  List<String> getBooks() => rust_db.dbGetBooks();

  @override
  void deleteBook({required String bookId}) {
    rust_db.dbDeleteBook(bookId: bookId);
  }

  @override
  void updateBookProgress({
    required String bookId,
    required double progress,
    String? chapter,
    required int pageIndex,
  }) {
    rust_db.dbUpdateBookProgress(
      bookId: bookId,
      progress: progress,
      chapter: chapter,
      pageIndex: pageIndex,
    );
  }

  @override
  void updateBookCover({required String bookId, required String coverUrl}) {
    rust_db.dbUpdateBookCover(bookId: bookId, coverUrl: coverUrl);
  }

  @override
  void updateBookCustomCover({
    required String bookId,
    required String customCoverUrl,
  }) {
    rust_db.dbUpdateBookCustomCover(
      bookId: bookId,
      customCoverUrl: customCoverUrl,
    );
  }

  @override
  void updateBookDetails(
    String bookId,
    String name,
    String author,
    String description,
  ) {
    rust_db.dbUpdateBookDetails(
      bookId: bookId,
      name: name,
      author: author,
      description: description,
    );
  }

  @override
  void updateBookGroup({required String bookId, required String group}) {
    rust_db.dbUpdateBookGroup(bookId: bookId, group: group);
  }

  @override
  void upsertSource({required String sourceJson}) {
    rust_db.dbUpsertSource(sourceJson: sourceJson);
  }

  @override
  List<String> getSources({required bool enabledOnly}) {
    return rust_db.dbGetSources(enabledOnly: enabledOnly);
  }

  @override
  void toggleSource({required String url, required bool enabled}) {
    rust_db.dbToggleSource(url: url, enabled: enabled);
  }

  @override
  void deleteSource({required String url}) {
    rust_db.dbDeleteSource(url: url);
  }

  @override
  void insertChapters({required String chaptersJson}) {
    rust_db.dbInsertChapters(chaptersJson: chaptersJson);
  }

  @override
  List<String> getChapters({required String bookId}) {
    return rust_db.dbGetChapters(bookId: bookId);
  }

  @override
  String? getChapterContent({required String chapterId}) {
    return rust_db.dbGetChapterContent(chapterId: chapterId);
  }

  @override
  void saveChapterContent({
    required String chapterId,
    required String content,
  }) {
    rust_db.dbSaveChapterContent(chapterId: chapterId, content: content);
  }

  @override
  void upsertReplaceRule({required String ruleJson}) {
    rust_db.dbUpsertReplaceRule(ruleJson: ruleJson);
  }

  @override
  List<String> getReplaceRules() => rust_db.dbGetReplaceRules();

  @override
  void toggleReplaceRule({required String id, required bool enabled}) {
    rust_db.dbToggleReplaceRule(id: id, enabled: enabled);
  }

  @override
  void deleteReplaceRule({required String id}) {
    rust_db.dbDeleteReplaceRule(id: id);
  }

  @override
  void clearReplaceRules() => rust_db.dbClearReplaceRules();
}
