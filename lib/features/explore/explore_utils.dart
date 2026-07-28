import 'dart:convert';

import '../../models/book_source.dart';

/// 发现分类条目（exploreUrl JSON 数组元素）
class ExploreCategory {
  final String title;
  final String url;

  const ExploreCategory({required this.title, required this.url});

  bool get isHeader => url.isEmpty;

  factory ExploreCategory.fromJson(Map<String, dynamic> json) {
    return ExploreCategory(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

/// 发现分区（按空 url 标题项分组）
class ExploreSection {
  final String title;
  final List<ExploreCategory> categories;

  const ExploreSection({required this.title, required this.categories});
}

/// 从书源 raw JSON 读取 exploreUrl 字符串
String exploreUrlOf(BookSource source) {
  if (source.rawSourceJson.isEmpty) return '';
  try {
    final obj = jsonDecode(source.rawSourceJson) as Map<String, dynamic>;
    final url = obj['exploreUrl'];
    if (url is String) return url;
  } catch (_) {}
  return '';
}

bool hasExploreUrl(BookSource source) => exploreUrlOf(source).trim().isNotEmpty;

bool isExploreEnabled(BookSource source) => source.enabledExplore;

/// 书源是否可用于发现 Tab
bool sourceHasExplore(BookSource source) =>
    source.enabled && hasExploreUrl(source) && isExploreEnabled(source);

List<ExploreCategory> parseExploreCategories(String exploreUrlJson) {
  if (exploreUrlJson.trim().isEmpty) return [];
  try {
    final decoded = jsonDecode(exploreUrlJson);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => ExploreCategory.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.title.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

List<ExploreSection> groupExploreSections(List<ExploreCategory> categories) {
  final sections = <ExploreSection>[];
  var currentTitle = '';
  var items = <ExploreCategory>[];

  void flush() {
    if (items.isEmpty) return;
    sections.add(
      ExploreSection(title: currentTitle, categories: List.of(items)),
    );
    items = [];
  }

  for (final c in categories) {
    if (c.isHeader) {
      flush();
      currentTitle = c.title;
    } else {
      items.add(c);
    }
  }
  flush();
  return sections;
}
