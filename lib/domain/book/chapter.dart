/// 章节领域实体。
class Chapter {
  final String id;
  final String bookId;
  final String title;
  final int index;
  final String url;
  final bool isVolume;
  final bool isVip;
  final bool isPay;
  final String tag;
  final String baseUrl;
  final bool isDownloaded;
  final String? content;

  Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.index,
    required this.url,
    this.isVolume = false,
    this.isVip = false,
    this.isPay = false,
    this.tag = '',
    this.baseUrl = '',
    this.isDownloaded = false,
    this.content,
  });

  static String idFor({
    required String bookId,
    required String url,
    required int index,
  }) {
    if (url.isEmpty) return '${bookId}_ch_$index';
    var hash = 2166136261;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return '${bookId}_url_${hash.toRadixString(16).padLeft(8, '0')}';
  }

  static List<Chapter> mergeWithLocal(
    List<Chapter> remote,
    List<Chapter> local,
  ) {
    final byUrl = <String, Chapter>{
      for (final chapter in local)
        if (chapter.url.isNotEmpty) chapter.url: chapter,
    };
    final byId = <String, Chapter>{
      for (final chapter in local) chapter.id: chapter,
    };

    return remote.map((chapter) {
      final old =
          (chapter.url.isNotEmpty ? byUrl[chapter.url] : null) ??
          byId[chapter.id];
      if (old == null) return chapter;
      return Chapter(
        id: old.id,
        bookId: chapter.bookId,
        title: chapter.title,
        index: chapter.index,
        url: chapter.url,
        isVolume: chapter.isVolume,
        isVip: chapter.isVip,
        isPay: chapter.isPay,
        tag: chapter.tag,
        baseUrl: chapter.baseUrl,
        isDownloaded:
            old.isDownloaded ||
            (old.content != null && old.content!.isNotEmpty),
        content: old.content ?? chapter.content,
      );
    }).toList();
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final idxVal = json['index'] ?? json['idx'];
    return Chapter(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      index: (idxVal is int) ? idxVal : int.tryParse('$idxVal') ?? 0,
      url: json['url'] as String? ?? '',
      isVolume: json['isVolume'] as bool? ?? false,
      isVip: json['isVip'] as bool? ?? false,
      isPay: json['isPay'] as bool? ?? false,
      tag: json['tag'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
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
      'isVolume': isVolume,
      'isVip': isVip,
      'isPay': isPay,
      'tag': tag,
      'baseUrl': baseUrl,
      'isDownloaded': isDownloaded,
      'content': content,
    };
  }
}
