import 'package:freezed_annotation/freezed_annotation.dart';

part 'rss_article.freezed.dart';

/// RSS 文章领域实体，对齐 Legado `RssArticle`。
@freezed
class RssArticle with _$RssArticle {
  const RssArticle._();

  const factory RssArticle({
    required String origin,
    @Default('') String sort,
    required String title,
    required String link,
    String? pubDate,
    String? description,
    String? content,
    String? image,
    @Default('默认分组') String group,
    @Default(false) bool read,
    @Default(0) int type,
    @Default(0) int durPos,
  }) = _RssArticle;
}
