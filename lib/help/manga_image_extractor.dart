/// 从章节正文提取漫画图片 URL — 对齐 Jingshiro 图片章节内容形态
///（`<img>` / Markdown / 纯 URL 行 / 常见图片后缀裸链）。
class MangaImageExtractor {
  MangaImageExtractor._();

  static final _imgSrc = RegExp(
    r'''<img\b[^>]*?\bsrc\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _imgDataSrc = RegExp(
    r'''<img\b[^>]*?\bdata-src\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );
  static final _mdImage = RegExp(r'''!\[[^\]]*]\(([^)\s]+)\)''');
  static final _bareImageUrl = RegExp(
    r'''https?://[^\s<>"'`\]]+\.(?:jpe?g|png|webp|gif|bmp)(?:\?[^\s<>"'`]*)?''',
    caseSensitive: false,
  );
  static final _lineUrl = RegExp(r'''^https?://\S+$''', caseSensitive: false);

  /// 解析正文中的图片地址；可选 [baseUrl] 用于相对路径拼接。
  static List<String> extract(String content, {String? baseUrl}) {
    if (content.trim().isEmpty) return const [];

    final seen = <String>{};
    final out = <String>[];

    void add(String? raw) {
      if (raw == null) return;
      var url = raw.trim();
      if (url.isEmpty || url.startsWith('data:')) return;
      if (baseUrl != null && baseUrl.isNotEmpty) {
        url = _resolve(baseUrl, url);
      }
      if (seen.add(url)) out.add(url);
    }

    for (final m in _imgSrc.allMatches(content)) {
      add(m.group(1));
    }
    for (final m in _imgDataSrc.allMatches(content)) {
      add(m.group(1));
    }
    for (final m in _mdImage.allMatches(content)) {
      add(m.group(1));
    }
    for (final m in _bareImageUrl.allMatches(content)) {
      add(m.group(0));
    }

    // 每行一个 URL（无扩展名也可，漫画源偶发 CDN 无后缀）
    if (out.isEmpty) {
      for (final line in content.split(RegExp(r'[\r\n]+'))) {
        final t = line.trim();
        if (_lineUrl.hasMatch(t)) add(t);
      }
    }

    return out;
  }

  /// 正文是否更像漫画页（图片主导）。
  static bool looksLikeManga(String content) {
    final imgs = extract(content);
    if (imgs.isEmpty) return false;
    final textOnly = content
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'\s+'), '');
    return imgs.isNotEmpty && textOnly.length < 80;
  }

  static String _resolve(String base, String relative) {
    final r = relative.trim();
    if (r.startsWith('http://') || r.startsWith('https://')) return r;
    try {
      return Uri.parse(base).resolve(r).toString();
    } catch (_) {
      return r;
    }
  }
}
