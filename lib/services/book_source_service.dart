import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:html/parser.dart' show parse;
import 'package:charset_converter/charset_converter.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import 'rule_engine.dart';

/// 书源服务 - 基于书源规则进行搜索、目录、正文提取
class BookSourceService {
  late final Dio _dio;

  BookSourceService() {
    // 自定义 HttpClient，信任所有 SSL 证书（解决部分站点证书问题）
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      followRedirects: true,
      maxRedirects: 5,
      // 不限制状态码 — 很多小说站点返回 400/500 但附带有效内容
      validateStatus: (_) => true,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/131.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Upgrade-Insecure-Requests': '1',
        'Connection': 'keep-alive',
      },
    ))
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
  }

  /// 解析 Legado 书源的 JSON 格式 URL（支持 POST/GET/GBK）
  /// 格式1: 纯 URL — "https://example.com/search?key={{key}}"
  /// 格式2: URL + JSON — "/search.php,{"body":"key={{key}}","charset":"gbk","method":"POST"}"
  /// 格式3: 纯 JSON — {"body":"key={{key}}","charset":"gbk","method":"POST"}
  _RequestConfig _parseUrlConfig(String rawUrl, String keyword) {
    rawUrl = rawUrl.trim();

    String urlPart;
    String? jsonPart;

    // 格式2: URL + JSON（逗号分隔）
    if (!rawUrl.startsWith('{')) {
      final commaIdx = rawUrl.indexOf(',');
      if (commaIdx > 0 && rawUrl.indexOf('{', commaIdx) == commaIdx + 1) {
        urlPart = rawUrl.substring(0, commaIdx);
        jsonPart = rawUrl.substring(commaIdx + 1);
      } else {
        urlPart = rawUrl;
      }
    } else {
      // 格式3: 纯 JSON
      urlPart = '';
      jsonPart = rawUrl;
    }

    String method = 'GET';
    String charset = 'UTF-8';
    String? bodyStr;

    if (jsonPart != null) {
      try {
        final cfg = jsonDecode(jsonPart) as Map<String, dynamic>;
        method = (cfg['method'] as String?)?.toUpperCase() ?? 'GET';
        charset = ((cfg['charset'] as String?) ?? '').toUpperCase();
        bodyStr = cfg['body'] as String?;
      } catch (e) {
        debugPrint('  ⚠ 解析 ruleSearchUrl JSON 失败: $e');
      }
    }

    // 替换占位符
    String finalUrl = urlPart
        .replaceAll('{{key}}', Uri.encodeComponent(keyword))
        .replaceAll('{{page}}', '1')
        .replaceAll('{{limit}}', '20');

    if (bodyStr != null) {
      bodyStr = bodyStr
          .replaceAll('{{key}}', keyword)
          .replaceAll('{{page}}', '1')
          .replaceAll('{{limit}}', '20');
    }

    // 自动检测 charset：如果 body 含非 ASCII（如中文），默认用 GB2312
    if (charset.isEmpty) {
      if (bodyStr != null && _hasNonAscii(bodyStr)) {
        charset = '936';
      } else {
        charset = 'UTF-8';
      }
    }

    return _RequestConfig(
      url: finalUrl,
      method: method,
      body: bodyStr,
      charset: charset,
    );
  }

  /// 检测字符串是否含非 ASCII 字符（如中文）
  static bool _hasNonAscii(String s) {
    return s.codeUnits.any((c) => c > 127);
  }

  /// 将 charset 名称转为 CharsetConverter 可识别的编码名
  /// Windows 下 decode 支持 "gb2312"，但 encode 需要用代码页编号 "936"
  static String _normalizeCharset(String charset) {
    final lower = charset.toLowerCase();
    if (lower == 'gb2312' || lower == 'gbk' || lower == 'gb18030' || lower == '936') return '936';
    if (lower == 'utf-8' || lower == 'utf8') return 'utf-8';
    return charset;
  }

  /// 补齐相对 URL
  String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http')) return url;
    final base = _baseUrl(baseUrl);
    if (url.startsWith('/')) return '$base$url';
    return '$base/$url';
  }

  Options _buildOptions(BookSource source) => Options(
    responseType: ResponseType.bytes,
    headers: {
      'Accept-Encoding': 'gzip, deflate',
      ...source.customHeaders,
    },
  );

  /// 发送请求（支持 GET/POST），返回原始字节
  Future<Uint8List> _executeRequest(
    String resolvedUrl, {
    String method = 'GET',
    String? body,
    String charset = 'UTF-8',
    BookSource? source,
  }) async {
    final opts = Options(
      responseType: ResponseType.bytes,
      headers: {
        'Accept-Encoding': 'gzip, deflate',
        if (source != null) ...source.customHeaders,
      },
    );

    Response<List<int>> response;
    if (method == 'POST' && body != null) {
      // ... (unchanged)
      String encodedBody;

      if (charset.toUpperCase() != 'UTF-8' && charset.toUpperCase() != 'UTF8') {
        final charsetName = _normalizeCharset(charset);
        final parts = body.split('&');
        final encodedParts = <String>[];
        for (final pair in parts) {
          final eqIdx = pair.indexOf('=');
          if (eqIdx <= 0) {
            encodedParts.add(pair);
            continue;
          }
          final key = pair.substring(0, eqIdx);
          final val = pair.substring(eqIdx + 1);
          final valBytes = await CharsetConverter.encode(charsetName, val);
          final encodedVal = valBytes
              .map((b) => '%${b.toRadixString(16).padLeft(2, '0').toUpperCase()}')
              .join('');
          encodedParts.add('$key=$encodedVal');
        }
        encodedBody = encodedParts.join('&');
      } else {
        encodedBody = body
            .split('&')
            .map((pair) {
              final eqIdx = pair.indexOf('=');
              if (eqIdx <= 0) return pair;
              final key = pair.substring(0, eqIdx);
              final val = pair.substring(eqIdx + 1);
              return '$key=${Uri.encodeQueryComponent(val)}';
            })
            .join('&');
      }

      response = await _dio.post(
        resolvedUrl,
        data: encodedBody,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Accept-Encoding': 'gzip, deflate',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': resolvedUrl,
            if (source != null) ...source.customHeaders,
          },
        ),
      );
    } else {
      response = await _dio.get(resolvedUrl, options: opts);
    }

    final statusCode = response.statusCode ?? 0;
    List<int> rawBytes = response.data ?? [];

    if (rawBytes.length >= 2 && rawBytes[0] == 0x1F && rawBytes[1] == 0x8B) {
      rawBytes = gzip.decode(rawBytes);
    }

    return Uint8List.fromList(rawBytes);
  }

  /// 解码响应字节为字符串（支持 charset）
  Future<String> _decodeResponse(Uint8List rawBytes, {String charset = 'UTF-8'}) async {
    // 如果 charset 是 UTF-8，先尝试 UTF-8，失败后回退到其他 charset
    if (charset.toUpperCase() == 'UTF-8' || charset.toUpperCase() == 'UTF8') {
      try {
        return utf8.decode(rawBytes);
      } catch (e) {
        // UTF-8 失败，尝试常见中文 charset
      }
      for (final alias in ['gb2312', 'GB2312', 'GBK', 'cp936', '936', 'windows-936', 'gb18030']) {
        try {
          final result = await CharsetConverter.decode(alias, rawBytes);
          return result;
        } catch (_) {}
      }
      return utf8.decode(rawBytes);
    }

    // 尝试多个 charset 别名（Windows API 标签表用 "gb2312" 而非 "GBK"）
    final aliases = <String>{
      charset,
      if (charset == 'GBK' || charset == 'GB2312')
        ...['gb2312', 'GB2312', 'cp936', '936', 'windows-936', 'gb18030'],
      if (charset == 'gb18030' || charset == 'GB18030')
        ...['gb18030', 'gb2312', 'GB2312', 'cp936'],
    };

    for (final alias in aliases) {
      try {
        final result = await CharsetConverter.decode(alias, rawBytes);
        return result;
      } catch (_) {}
    }

    // 全部失败，回退 UTF-8
    debugPrint('  ⚠ 所有 charset 尝试失败，回退 UTF-8');
    return utf8.decode(rawBytes);
  }

  /// 搜索书籍
  Future<List<Map<String, String>>> search(BookSource source, String keyword) async {
    if (source.ruleSearchUrl.isEmpty) return [];

    try {
      // 解析 JSON 格式 ruleSearchUrl
      final cfg = _parseUrlConfig(source.ruleSearchUrl, keyword);
      String resolvedUrl = cfg.url;
      if (!resolvedUrl.startsWith('http')) {
        resolvedUrl = _resolveUrl(resolvedUrl, source.bookSourceUrl);
      }

      debugPrint('🔍 ${source.bookSourceName}: ${cfg.method} $resolvedUrl');
      // 发送请求
      final rawBytes = await _executeRequest(resolvedUrl,
          method: cfg.method, body: cfg.body, charset: cfg.charset, source: source);

      // charset 解码
      final body = await _decodeResponse(rawBytes, charset: cfg.charset);

      // 尝试 JSON 解析
      dynamic data;
      try {
        data = jsonDecode(body);
      } catch (e) {
        debugPrint('  ▸ JSON 解析失败: $e');
      }

      // 检测是否为 JSON API 书源
      if (data is Map || data is List) {
        if (source.isJsonApiSource) {
          final jsonStr = jsonEncode(data);
          final results = RuleEngine.parseJsonSearchResults(jsonStr, source: source);
          final baseUrl = _baseUrl(source.bookSourceUrl);

          return results.map((r) => {
            'name': r['name'] ?? '',
            'author': r['author'] ?? '',
            'url': RuleEngine.resolveUrl(r['url'] ?? '', baseUrl),
            'coverUrl': r['coverUrl'] ?? '',
            'kind': r['kind'] ?? '',
            'note': r['note'] ?? '',
          }).toList();
        }
        debugPrint('  ⚠ ${source.bookSourceName}: 返回 JSON 但无 JSON 规则');
        return [];
      }

      // HTML 页面 - CSS 选择器解析
      final document = parse(body);
      final results = RuleEngine.parseSearchResults(document, source: source);
      final baseUrl = _baseUrl(source.bookSourceUrl);

      return results.map((r) => {
        'name': r['name'] ?? '',
        'author': r['author'] ?? '',
        'url': RuleEngine.resolveUrl(r['url'] ?? '', baseUrl),
        'coverUrl': r['coverUrl'] ?? '',
        'kind': r['kind'] ?? '',
        'note': r['note'] ?? '',
      }).toList();
    } catch (e) {
      debugPrint('  ✗ ${source.bookSourceName} 搜索出错: $e');
      return [];
    }
  }

  /// 搜索结果转 Book 对象
  List<Book> resultsToBooks(List<Map<String, String>> results, String sourceUrl) {
    return results.map((r) => Book(
      id: '${sourceUrl}_${r['url'].hashCode}',
      name: r['name'] ?? '未知书名',
      author: r['author'] ?? '',
      sourceUrl: r['url'] ?? '',
      description: r['note'] ?? '',
      bookSourceUrl: sourceUrl,
    )).toList();
  }

  /// 获取章节列表
  Future<List<Chapter>> getChapters(Book book, {required BookSource source}) async {
    if (book.sourceUrl.isEmpty) return [];

    try {
      // ── JSON API 书源（尝试 JSON，失败则回退 HTML）──
      if (source.isJsonApiSource && source.ruleBookInfoTocUrl.isNotEmpty) {
        try {
          return await _getJsonApiChapters(book, source);
        } catch (e) {
          debugPrint('  ⚠ JSON API 章节获取失败，回退 HTML: $e');
        }
      }

      // ── HTML / CSS 书源 ──
      debugPrint('📖 获取章节: ${book.sourceUrl}');
      List<int> rawBytes = [];
      int retries = 0;
      const maxRetries = 3;
      while (retries < maxRetries) {
        final resp = await _dio.get(
          book.sourceUrl,
          options: _buildOptions(source),
        );
        final statusCode = resp.statusCode ?? 0;
        rawBytes = (resp.data as List<int>?) ?? [];
        if (statusCode == 503 && retries < maxRetries - 1) {
          retries++;
          debugPrint('  ⚠ 503，${retries * 2}秒后重试($retries/$maxRetries)...');
          await Future.delayed(Duration(seconds: retries * 2));
        } else {
          break;
        }
      }
      if (rawBytes.length >= 2 && rawBytes[0] == 0x1F && rawBytes[1] == 0x8B) {
        rawBytes = gzip.decode(rawBytes);
      }
      final body = await _decodeResponse(Uint8List.fromList(rawBytes));
      final document = parse(body);

      final results = RuleEngine.parseChapters(document, source: source);
      final baseUrl = _baseUrl(book.sourceUrl);

      return results.asMap().entries.map((entry) {
        final i = entry.key;
        final r = entry.value;
        return Chapter(
          id: '${book.id}_ch_$i',
          bookId: book.id,
          title: r['title'] ?? '第${i + 1}章',
          index: i,
          url: RuleEngine.resolveUrl(r['url'] ?? '', baseUrl),
        );
      }).toList();
    } catch (e) {
      debugPrint('获取章节列表出错: $e');
      return [];
    }
  }

  /// JSON API 书源的章节列表获取
  Future<List<Chapter>> _getJsonApiChapters(Book book, BookSource source) async {
    try {
      // 1. 获取书籍详情（提取 articleid）
      final detailResp = await _dio.get(
        book.sourceUrl,
        options: _buildOptions(source),
      );
      List<int> detailBytes = detailResp.data as List<int>;
      if (detailBytes.length >= 2 && detailBytes[0] == 0x1F && detailBytes[1] == 0x8B) {
        detailBytes = gzip.decode(detailBytes);
      }
      final detailStr = utf8.decode(detailBytes);
      final detailData = jsonDecode(detailStr);

      // 提取 articleid
      final articleId = JsonPath.resolveString(detailData, 'data.articleid');

      // 2. 构造章节列表 URL
      String tocUrl = source.ruleBookInfoTocUrl;
      if (tocUrl.contains('{{result.articleid}}')) {
        tocUrl = tocUrl.replaceAll('{{result.articleid}}', articleId);
      }
      if (!tocUrl.startsWith('http')) {
        final base = _baseUrl(source.bookSourceUrl);
        tocUrl = tocUrl.startsWith('/') ? '$base$tocUrl' : '$base/$tocUrl';
      }

      // 3. 获取章节列表
      final tocResp = await _dio.get(
        tocUrl,
        options: _buildOptions(source),
      );
      List<int> tocBytes = tocResp.data as List<int>;
      if (tocBytes.length >= 2 && tocBytes[0] == 0x1F && tocBytes[1] == 0x8B) {
        tocBytes = gzip.decode(tocBytes);
      }
      final tocStr = utf8.decode(tocBytes);
      final tocData = jsonDecode(tocStr);

      // 4. 用 JSONPath 解析章节列表
      final chapterListPath = source.ruleTocChapterList;
      final chapterNamePath = source.ruleTocChapterName;
      String chapterUrlTemplate = source.ruleTocChapterUrl;

      // 替换缓存模板: {{cache.getFromMemory('articleid')}} → 实际 articleid
      chapterUrlTemplate = chapterUrlTemplate.replaceAllMapped(
        RegExp(r'\{\{cache\.getFromMemory\([^)]+\)\}\}'),
        (_) => articleId,
      );

      dynamic chapters = JsonPath.resolve(tocData, chapterListPath);
      if (chapters == null) return [];
      if (chapters is! List) chapters = [chapters];

      final result = <Chapter>[];
      for (int i = 0; i < chapters.length; i++) {
        final item = chapters[i];
        final title = chapterNamePath.isNotEmpty
            ? JsonPath.resolveString(item, chapterNamePath)
            : '第${i + 1}章';
        if (title.isEmpty) continue;

        String url = chapterUrlTemplate;
        if (url.contains('{{')) {
          url = JsonPath.resolveTemplate(url, item);
        }

        result.add(Chapter(
          id: '${book.id}_ch_$i',
          bookId: book.id,
          title: title,
          index: i,
          url: url,
        ));
      }
      return result;
    } catch (e) {
      debugPrint('JSON API 获取章节出错: $e');
      return [];
    }
  }

  /// 获取章节正文
  Future<String> getChapterContent(String url, {required BookSource source}) async {
    try {
      // ── JSON API 书源（尝试 JSON，失败则回退 HTML）──
      if (source.isJsonApiSource && source.ruleContentPath.isNotEmpty) {
        try {
          return await _getJsonApiContent(url, source);
        } catch (e) {
          debugPrint('  ⚠ JSON API 正文获取失败，回退 HTML: $e');
        }
      }

      // ── HTML / CSS 书源 ──
      String contentUrl = url;
      if (source.ruleContentUrl.isNotEmpty) {
        contentUrl = source.ruleContentUrl.replaceAll('{{url}}', url);
      }

      debugPrint('📖 获取正文: $contentUrl');
      final response = await _dio.get(
        contentUrl,
        options: _buildOptions(source),
      );
      List<int> rawBytes = (response.data as List<int>?) ?? [];
      if (rawBytes.length >= 2 && rawBytes[0] == 0x1F && rawBytes[1] == 0x8B) {
        rawBytes = gzip.decode(rawBytes);
      }
      final body = await _decodeResponse(Uint8List.fromList(rawBytes));
      final document = parse(body);
      final content = RuleEngine.parseContent(document, source: source);
      return content.isNotEmpty ? content : '（此章节暂无内容）';
    } catch (e) {
      return '（加载失败: $e）';
    }
  }

  /// JSON API 书源的正文获取
  Future<String> _getJsonApiContent(String url, BookSource source) async {
    try {
      // 构造完整 URL（可能是相对路径）
      String contentUrl = url;
      if (!contentUrl.startsWith('http')) {
        final base = _baseUrl(source.bookSourceUrl);
        contentUrl = contentUrl.startsWith('/') ? '$base$contentUrl' : '$base/$contentUrl';
      }

      final resp = await _dio.get(
        contentUrl,
        options: _buildOptions(source),
      );
      List<int> bytes = resp.data as List<int>;
      if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
        bytes = gzip.decode(bytes);
      }
      final body = utf8.decode(bytes);
      final data = jsonDecode(body);

      final contentPath = source.ruleContentPath;
      if (contentPath.isEmpty) return '（无正文规则）';

      final content = JsonPath.resolveString(data, contentPath);
      return content.isNotEmpty ? content : '（此章节暂无内容）';
    } catch (e) {
      return '（加载失败: $e）';
    }
  }

  /// 获取 base URL
  String _baseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    return '${uri.scheme}://${uri.host}${uri.port == 80 || uri.port == 443 ? '' : ':${uri.port}'}';
  }

  /// 从 URL 获取书源 JSON 并解析
  static Future<List<BookSource>> fetchSourcesFromUrl(String url) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/131.0.0.0 Safari/537.36',
          'Accept': 'application/json, text/plain, */*',
        },
      ));
      // 信任所有 SSL 证书
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );

      final response = await dio.get(url);
      final data = response.data;

      // 兼容多种 JSON 格式:
      // 1. 直接是书源列表: [{...}, {...}]
      // 2. 嵌套在 data 字段: {"data": [{...}, {...}]}
      // 3. 嵌套在 sources 字段: {"sources": [...]}
      // 4. 包装在 result / items / records 字段
      List<dynamic>? sourceList;
      if (data is List) {
        sourceList = data;
      } else if (data is Map) {
        for (final key in ['data', 'sources', 'result', 'bookSources', 'items', 'records']) {
          final val = data[key];
          if (val is List) {
            sourceList = val;
            break;
          }
        }
      }

      if (sourceList == null || sourceList.isEmpty) {
        debugPrint('从 $url 获取书源: 未找到书源数据');
        return [];
      }

      final sources = <BookSource>[];
      for (final e in sourceList) {
        if (e is! Map) continue;
        try {
          final src = BookSource.fromJson(Map<String, dynamic>.from(e));
          sources.add(src);
        } catch (_) {}
      }
      debugPrint('从 $url 获取书源: 成功导入 ${sources.length}/${sourceList.length} 个');
      return sources;
    } catch (e) {
      debugPrint('从网络获取书源失败: $e');
      return [];
    }
  }

  // ── 书源市场（分组展示） ──

  /// 返回分组的内置书源（仅作格式示例，建议用户从社区导入实际可用书源）
  static Map<String, List<BookSource>> sourceMarket() {
    final sources = builtInSources();
    final market = <String, List<BookSource>>{};
    for (final s in sources) {
      market.putIfAbsent(s.bookSourceGroup, () => []).add(s);
    }
    // 添加"从社区获取"引导项
    market['📥 从社区导入'] = [];
    return market;
  }

  // ── 内置书源（示例/演示用，实际搜索请导入社区书源） ──

  static List<BookSource> builtInSources() {
    return [
      BookSource(
        bookSourceUrl: 'https://www.biquge.com.cn',
        bookSourceName: '📖 笔趣阁（示例）',
        bookSourceGroup: '📚 格式示例',
        ruleSearchUrl: 'https://www.biquge.com.cn/search.html?keyword={{key}}',
        ruleSearchList: '.result-item, .search-list li, .list-item',
        ruleSearchName: 'a',
        ruleSearchAuthor: '.author',
        ruleChapterList: '#list a, .chapter-list a',
        ruleContent: '#content, .chapter-content',
      ),
      BookSource(
        bookSourceUrl: 'https://www.69shu.com',
        bookSourceName: '📖 69书吧（示例）',
        bookSourceGroup: '📚 格式示例',
        ruleSearchUrl: 'https://www.69shu.com/search.php?keyword={{key}}',
        ruleSearchList: '.result-item, .search-list li, .list-item',
        ruleSearchName: 'a',
        ruleChapterList: '.chapter-list a, #list a',
        ruleContent: '#content, .chapter-content',
      ),
    ];
  }
}

/// Legado JSON 格式 URL 配置
class _RequestConfig {
  final String url;
  final String method;
  final String? body;
  final String charset;

  const _RequestConfig({
    required this.url,
    this.method = 'GET',
    this.body,
    this.charset = 'UTF-8',
  });
}
