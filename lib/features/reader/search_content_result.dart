/// 正文搜索命中（对齐 legado `SearchResult`）
class SearchContentResult {
  final String chapterTitle;
  final String query;
  final String resultText;
  final int chapterIndex;

  /// 关键词在章节正文中的起始下标
  final int queryIndexInChapter;
  final int resultCountWithinChapter;

  const SearchContentResult({
    required this.chapterTitle,
    required this.query,
    required this.resultText,
    required this.chapterIndex,
    required this.queryIndexInChapter,
    this.resultCountWithinChapter = 0,
  });
}

/// 从阅读器打开搜索页时的回传
class SearchContentNavigate {
  final List<SearchContentResult> results;
  final int index;

  const SearchContentNavigate({required this.results, required this.index});

  SearchContentResult get current => results[index];
}
