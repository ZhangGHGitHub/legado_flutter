/// 书籍模型 - 对应 legado 的一本书
class Book {
  final String id;
  final String name;
  final String author;
  final String coverUrl;
  final String type; // 来源类型: local / online
  final double progress; // 阅读进度 0.0 ~ 1.0
  final String? currentChapter; // 已读到章节名
  final String? lastChapter; // 最新章节名（从书源获取的最新更新）
  final int currentPageIndex; // 当前章节内阅读到的页面索引
  final bool isFavorite;
  final String sourceUrl; // 书籍来源链接（如章节列表 URL）
  final String description; // 书籍简介
  final String bookSourceUrl; // 搜索到此书的书源 URL（用于匹配书源规则）

  Book({
    required this.id,
    required this.name,
    this.author = '未知作者',
    this.coverUrl = '',
    this.type = 'online',
    this.progress = 0.0,
    this.currentChapter,
    this.lastChapter,
    this.currentPageIndex = 0,
    this.isFavorite = false,
    this.sourceUrl = '',
    this.description = '',
    this.bookSourceUrl = '',
  });

  /// 复制并修改部分字段
  Book copyWith({
    String? id,
    String? name,
    String? author,
    String? coverUrl,
    String? type,
    double? progress,
    String? currentChapter,
    String? lastChapter,
    int? currentPageIndex,
    bool? isFavorite,
    String? sourceUrl,
    String? description,
    String? bookSourceUrl,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      currentChapter: currentChapter ?? this.currentChapter,
      lastChapter: lastChapter ?? this.lastChapter,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      description: description ?? this.description,
      bookSourceUrl: bookSourceUrl ?? this.bookSourceUrl,
    );
  }

  /// 从 JSON 创建
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      name: json['name'] as String,
      author: json['author'] as String? ?? '未知作者',
      coverUrl: json['coverUrl'] as String? ?? '',
      type: json['type'] as String? ?? 'online',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentChapter: json['currentChapter'] as String?,
      lastChapter: json['lastChapter'] as String?,
      currentPageIndex: (json['currentPageIndex'] as num?)?.toInt() ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      sourceUrl: json['sourceUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bookSourceUrl: json['bookSourceUrl'] as String? ?? '',
    );
  }

  /// 转为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'author': author,
      'coverUrl': coverUrl,
      'type': type,
      'progress': progress,
      'currentChapter': currentChapter,
      'lastChapter': lastChapter,
      'currentPageIndex': currentPageIndex,
      'isFavorite': isFavorite,
      'sourceUrl': sourceUrl,
      'description': description,
      'bookSourceUrl': bookSourceUrl,
    };
  }

  @override
  String toString() => 'Book($name - $author)';
}
