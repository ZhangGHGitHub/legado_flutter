import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result_item.freezed.dart';
part 'search_result_item.g.dart';

/// Search result model shared by the Flutter contract and Rust adapter.
@freezed
sealed class SearchResultItem with _$SearchResultItem {
  const factory SearchResultItem({
    required String name,
    required String author,
    required String bookUrl,
    @Default('') String coverUrl,
    @Default('') String kind,
    @Default('') String note,
  }) = _SearchResultItem;

  const SearchResultItem._();

  factory SearchResultItem.fromJson(Map<String, dynamic> json) =>
      _$SearchResultItemFromJson(json);

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
