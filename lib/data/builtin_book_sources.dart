import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/book_source.dart';

/// 内置推荐书源（来自 Legado 社区）
/// - https://www.yckceo.com/yuedu/shuyuan/json/id/7497.json
/// - https://www.yckceo.com/yuedu/shuyuan/json/id/7565.json
class BuiltinBookSources {
  static const _assetPaths = [
    'assets/builtin_sources/7497.json',
    'assets/builtin_sources/7565.json',
  ];

  static const _defaultGroup = '📚 推荐书源';

  static Future<List<BookSource>> load() async {
    final sources = <BookSource>[];
    for (final path in _assetPaths) {
      final text = await rootBundle.loadString(path);
      final list = jsonDecode(text) as List<dynamic>;
      for (final item in list) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        map.putIfAbsent('bookSourceGroup', () => _defaultGroup);
        sources.add(BookSource.fromJson(map));
      }
    }
    return sources;
  }
}
