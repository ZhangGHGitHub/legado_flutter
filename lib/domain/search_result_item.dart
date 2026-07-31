/// Search result model shared by the Flutter contract and Rust adapter.
class SearchResultItem {
  const SearchResultItem({
    required this.name,
    required this.author,
    required this.bookUrl,
    this.coverUrl = '',
    this.kind = '',
    this.note = '',
  });

  final String name;
  final String author;
  final String bookUrl;
  final String coverUrl;
  final String kind;
  final String note;

  factory SearchResultItem.fromMap(Map<String, String> map) {
    return SearchResultItem(
      name: map['name'] ?? '',
      author: map['author'] ?? '',
      bookUrl: map['bookUrl'] ?? map['book_url'] ?? '',
      coverUrl: map['coverUrl'] ?? map['cover_url'] ?? '',
      kind: map['kind'] ?? '',
      note: map['note'] ?? '',
    );
  }

  Map<String, String> toMap() => {
    'name': name,
    'author': author,
    'bookUrl': bookUrl,
    'coverUrl': coverUrl,
    'kind': kind,
    'note': note,
  };
}
