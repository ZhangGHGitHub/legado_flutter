/// 章节模型
class Chapter {
  final String id;
  final String bookId;
  final String title;
  final int index; // 章节顺序
  final String url; // 章节链接
  final bool isDownloaded; // 是否已下载
  final String? content; // 正文内容

  Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.index,
    required this.url,
    this.isDownloaded = false,
    this.content,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      index: json['index'] as int,
      url: json['url'] as String? ?? '',
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'title': title,
      'index': index,
      'url': url,
      'isDownloaded': isDownloaded,
      'content': content,
    };
  }
}
