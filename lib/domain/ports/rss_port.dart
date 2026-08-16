import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:legado_flutter/domain/rss/rss_source.dart';
import '../rss/rss_article.dart';

part 'rss_port.freezed.dart';

@freezed
class RssArticlesResult with _$RssArticlesResult {
  const factory RssArticlesResult({
    required List<RssArticle> articles,
    String? nextUrl,
  }) = _RssArticlesResult;
}

class RssPortException implements Exception {
  const RssPortException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class RssPort {
  bool get isAvailable;

  Future<RssArticlesResult> getArticles({
    required RssSource source,
    required String sortName,
    required String sortUrl,
    required int page,
  });

  Future<String> getContent({
    required RssSource source,
    required RssArticle article,
  });
}
