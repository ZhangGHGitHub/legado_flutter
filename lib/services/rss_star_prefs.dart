import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rss/rss_article.dart';

/// RSS 收藏 — 对齐 Jingshiro [RssStar]（本地 SharedPreferences）
class RssStarPrefs {
  static const _key = 'legado_rss_stars';

  static Future<List<RssArticle>> loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => _fromMap(Map<String, dynamic>.from(e)))
          .where((a) => a.link.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<RssArticle> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(list.map(_toMap).toList()));
  }

  static Future<bool> isStarred(String origin, String link) async {
    final all = await loadAll();
    return all.any((a) => a.origin == origin && a.link == link);
  }

  static Future<bool> toggle(RssArticle article) async {
    final all = await loadAll();
    final i = all.indexWhere(
      (a) => a.origin == article.origin && a.link == article.link,
    );
    if (i >= 0) {
      all.removeAt(i);
      await _saveAll(all);
      return false;
    }
    all.insert(0, article.copyWith(read: article.read));
    await _saveAll(all);
    return true;
  }

  static Future<void> remove(String origin, String link) async {
    final all = await loadAll();
    all.removeWhere((a) => a.origin == origin && a.link == link);
    await _saveAll(all);
  }

  static Map<String, dynamic> _toMap(RssArticle a) => {
    'origin': a.origin,
    'sort': a.sort,
    'title': a.title,
    'link': a.link,
    'pubDate': a.pubDate,
    'description': a.description,
    'content': a.content,
    'image': a.image,
    'group': a.group,
    'type': a.type,
    'durPos': a.durPos,
    'starTime': DateTime.now().millisecondsSinceEpoch,
  };

  static RssArticle _fromMap(Map<String, dynamic> m) => RssArticle(
    origin: m['origin']?.toString() ?? '',
    sort: m['sort']?.toString() ?? '',
    title: m['title']?.toString() ?? '',
    link: m['link']?.toString() ?? '',
    pubDate: m['pubDate']?.toString(),
    description: m['description']?.toString(),
    content: m['content']?.toString(),
    image: m['image']?.toString(),
    group: m['group']?.toString() ?? '默认分组',
    type: int.tryParse(m['type']?.toString() ?? '') ?? 0,
    durPos: int.tryParse(m['durPos']?.toString() ?? '') ?? 0,
  );
}
