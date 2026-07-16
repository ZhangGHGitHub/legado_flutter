/// RSS 文章 — 对齐 Jingshiro [RssArticle.kt]
class RssArticle {
  final String origin;
  final String sort;
  final String title;
  final String link;
  final String? pubDate;
  final String? description;
  final String? content;
  final String? image;
  final String group;
  final bool read;
  final int type;
  final int durPos;

  const RssArticle({
    required this.origin,
    this.sort = '',
    required this.title,
    required this.link,
    this.pubDate,
    this.description,
    this.content,
    this.image,
    this.group = '默认分组',
    this.read = false,
    this.type = 0,
    this.durPos = 0,
  });

  RssArticle copyWith({bool? read, String? content, int? durPos}) {
    return RssArticle(
      origin: origin,
      sort: sort,
      title: title,
      link: link,
      pubDate: pubDate,
      description: description,
      content: content ?? this.content,
      image: image,
      group: group,
      read: read ?? this.read,
      type: type,
      durPos: durPos ?? this.durPos,
    );
  }
}
