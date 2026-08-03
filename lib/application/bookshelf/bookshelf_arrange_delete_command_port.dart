/// 书架整理页的删除命令边界。
abstract interface class BookshelfArrangeDeleteCommandPort {
  Future<void> removeBook(String bookId);

  Future<void> removeBooks(Iterable<String> bookIds);
}
