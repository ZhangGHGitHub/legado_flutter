import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'package:legado_flutter/domain/book/book.dart';
import '../models/book_source.dart';
import 'package:legado_flutter/domain/book/chapter.dart';
import '../services/source_login_prefs.dart';
import '../src/rust/api.dart' as rust_api;
import '../src/rust/api/network.dart' as network_api;
import '../src/rust/frb_generated.dart';

/// Rust 书源引擎桥接层
class LegadoEngineBridge {
  static bool _initialized = false;
  static bool _available = false;

  static bool get isAvailable => _available;

  static Future<void> tryInit() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Platform.isWindows || Platform.isLinux) {
        final lib = await _loadExternalLibrary();
        await LegadoEngine.init(externalLibrary: lib);
      } else {
        // iOS / macOS / Android：Cargokit 静态链接 Rust，使用进程内符号
        await LegadoEngine.init();
      }
      rust_api.initEngine();
      _available = true;
      _startHttpRequestTrace();
      debugPrint('[Engine] Rust 书源引擎 v${engineVersion()} 已加载');
    } catch (e) {
      _available = false;
      debugPrint('[Engine] Rust 引擎不可用: $e');
    }
  }

  /// 书源 JSON + 登录头合并进 `header`（EN-08，对齐 Jingshiro AnalyzeUrl）
  static Future<String> _sourceJson(BookSource source) async {
    final loginHeader =
        await SourceLoginPrefs.loadHeader(source.bookSourceUrl) ?? '';
    // 预热 Rust 登录头缓存，供 loginCheckJs / ajax 使用
    if (loginHeader.trim().isNotEmpty) {
      try {
        rust_api.seedLoginHeader(
          sourceUrl: source.bookSourceUrl,
          header: loginHeader,
        );
      } catch (_) {}
    }
    return SourceLoginPrefs.mergeLoginHeaderIntoSourceJson(
      source.toEngineJson(),
      loginHeader,
    );
  }

  /// loginCheckJs `putLoginHeader` → SharedPreferences
  static Future<void> _syncLoginHeaders() async {
    if (!_available) return;
    try {
      final raw = rust_api.drainLoginHeaderUpdates();
      if (raw.isEmpty || raw == '{}') return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final e in decoded.entries) {
        final url = e.key.toString();
        final header = e.value?.toString() ?? '';
        if (url.isEmpty || header.isEmpty) continue;
        await SourceLoginPrefs.saveHeader(url, header);
      }
    } catch (e) {
      debugPrint('[Engine] sync login headers: $e');
    }
  }

  /// 仅 debug 采样 Rust 实际 HTTP 请求；release 不启用轨迹，避免积累 URL 元数据。
  static void _startHttpRequestTrace() {
    if (!kDebugMode || !_available) return;
    try {
      network_api.startHttpRequestTrace();
    } catch (e) {
      debugPrint('[Engine] start HTTP trace failed: $e');
    }
  }

  static void _drainHttpRequestTrace(String operation) {
    if (!kDebugMode || !_available) return;
    try {
      final raw = network_api.drainHttpRequestTrace();
      if (raw.isNotEmpty && raw != '[]') {
        debugPrint('[Engine][HTTP][$operation] $raw');
      }
      _startHttpRequestTrace();
    } catch (e) {
      debugPrint('[Engine] drain HTTP trace failed: $e');
    }
  }

  static Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    if (!_available) throw StateError('Rust engine not available');
    try {
      final items = await rust_api.search(
        sourceJson: await _sourceJson(source),
        keyword: keyword,
      );
      await _syncLoginHeaders();
      return items
          .map(
            (item) => {
              'name': item.name,
              'author': item.author,
              'url': item.bookUrl,
              'coverUrl': item.coverUrl,
              'kind': item.kind,
              'note': item.note,
            },
          )
          .toList();
    } finally {
      _drainHttpRequestTrace('search');
    }
  }

  static Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async {
    if (!_available) throw StateError('Rust engine not available');
    try {
      final items = await rust_api.explore(
        sourceJson: await _sourceJson(source),
        exploreUrl: exploreUrl,
        page: page,
      );
      await _syncLoginHeaders();
      return items
          .map(
            (item) => {
              'name': item.name,
              'author': item.author,
              'url': item.bookUrl,
              'coverUrl': item.coverUrl,
              'kind': item.kind,
              'note': item.note,
            },
          )
          .toList();
    } finally {
      _drainHttpRequestTrace('explore');
    }
  }

  static Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    if (!_available) throw StateError('Rust engine not available');
    try {
      final info = await rust_api.getBookInfo(
        sourceJson: await _sourceJson(source),
        bookUrl: bookUrl,
      );
      await _syncLoginHeaders();
      return {
        'name': info.name,
        'author': info.author,
        'coverUrl': info.coverUrl,
        'intro': info.intro,
        'kind': info.kind,
        'lastChapter': info.lastChapter,
        'tocUrl': info.tocUrl,
      };
    } finally {
      _drainHttpRequestTrace('bookInfo');
    }
  }

  static Future<List<Chapter>> getToc(BookSource source, Book book) async {
    if (!_available) throw StateError('Rust engine not available');
    try {
      final items = await rust_api.getToc(
        sourceJson: await _sourceJson(source),
        bookUrl: book.sourceUrl,
      );
      await _syncLoginHeaders();
      return items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Chapter(
          id: Chapter.idFor(bookId: book.id, url: item.url, index: i),
          bookId: book.id,
          title: item.title,
          index: i,
          url: item.url,
          isVolume: item.isVolume,
          isVip: item.isVip,
          isPay: item.isPay,
          tag: item.tag,
          baseUrl: item.baseUrl,
        );
      }).toList();
    } finally {
      _drainHttpRequestTrace('toc');
    }
  }

  static Future<String> getContent(BookSource source, String chapterUrl) async {
    if (!_available) throw StateError('Rust engine not available');
    try {
      final body = await rust_api.getContent(
        sourceJson: await _sourceJson(source),
        chapterUrl: chapterUrl,
      );
      await _syncLoginHeaders();
      return body;
    } finally {
      _drainHttpRequestTrace('content');
    }
  }

  static Future<rust_api.SourceValidation> validateSource(
    BookSource source, {
    String keyword = '测试',
  }) async {
    if (!_available) throw StateError('Rust engine not available');

    return rust_api.validateSource(
      sourceJson: await _sourceJson(source),
      keyword: keyword,
    );
  }

  static List<({String title, String content})> parseTxtChapters(
    String content,
  ) {
    if (!_available) throw StateError('Rust engine not available');
    return rust_api
        .parseTxtChapters(content: content)
        .map((c) => (title: c.title, content: c.content))
        .toList();
  }

  static ({
    String title,
    String author,
    List<({String title, String content})> chapters,
  })
  parseEpub(List<int> data) {
    if (!_available) throw StateError('Rust engine not available');
    final info = rust_api.parseEpub(data: data);
    return (
      title: info.title,
      author: info.author,
      chapters: info.chapters
          .map((c) => (title: c.title, content: c.content))
          .toList(),
    );
  }

  static String engineVersion() => rust_api.engineVersion();

  static void recordReading({
    required String bookId,
    required String bookName,
    required int chars,
    required int durationSeconds,
  }) {
    if (!_available) return;
    rust_api.recordReading(
      bookId: bookId,
      bookName: bookName,
      chars: chars,
      durationSeconds: durationSeconds,
    );
  }

  static rust_api.ReadingStats? getReadingStats(String range) {
    if (!_available) return null;
    try {
      return rust_api.getReadingStats(range: range);
    } catch (_) {
      return null;
    }
  }

  static String? exportReadingRecords(String format) {
    if (!_available) return null;
    try {
      return rust_api.exportReadingRecords(format: format);
    } catch (_) {
      return null;
    }
  }

  static Future<rust_api.WebApiStatus> startWebApi({
    required int port,
    required String token,
  }) async {
    if (!_available) throw StateError('Rust engine not available');
    return rust_api.startWebApi(port: port, token: token);
  }

  static Future<void> stopWebApi() async {
    if (!_available) return;
    await rust_api.stopWebApi();
  }

  static rust_api.WebApiStatus? webApiStatus() {
    if (!_available) return null;
    try {
      return rust_api.webApiStatus();
    } catch (_) {
      return null;
    }
  }

  static Future<rust_api.DebugResult> debugSearch(
    BookSource source,
    String keyword,
  ) async {
    if (!_available) throw StateError('Rust engine not available');
    return rust_api.debugSearch(
      sourceJson: await _sourceJson(source),
      keyword: keyword,
    );
  }

  static Future<rust_api.DebugResult> debugToc(
    BookSource source,
    String bookUrl,
  ) async {
    if (!_available) throw StateError('Rust engine not available');
    return rust_api.debugToc(
      sourceJson: await _sourceJson(source),
      bookUrl: bookUrl,
    );
  }

  static Future<String> httpFetch(
    String url, {
    String method = 'GET',
    String? referer,
    String charset = 'UTF-8',
    BookSource? source,
  }) async {
    if (!_available) throw StateError('Rust engine not available');
    return rust_api.httpFetch(
      url: url,
      method: method,
      charset: charset,
      referer: referer,
      sourceUrl: source?.bookSourceUrl,
      concurrentRate: null,
    );
  }

  static Future<ExternalLibrary> _loadExternalLibrary() async {
    if (kIsWeb) {
      throw UnsupportedError('Web 平台不支持 Rust 引擎');
    }

    final name = Platform.isWindows
        ? 'legado_engine.dll'
        : Platform.isMacOS
        ? 'liblegado_engine.dylib'
        : 'liblegado_engine.so';

    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      '$exeDir${Platform.pathSeparator}$name',
      'rust${Platform.pathSeparator}target${Platform.pathSeparator}release${Platform.pathSeparator}$name',
      'rust${Platform.pathSeparator}target${Platform.pathSeparator}debug${Platform.pathSeparator}$name',
      'rust${Platform.pathSeparator}legado_engine${Platform.pathSeparator}target${Platform.pathSeparator}release${Platform.pathSeparator}$name',
      'rust${Platform.pathSeparator}legado_engine${Platform.pathSeparator}target${Platform.pathSeparator}debug${Platform.pathSeparator}$name',
    ];

    for (final path in candidates) {
      if (await File(path).exists()) {
        debugPrint('[Engine] 加载 $path');
        return ExternalLibrary.open(path);
      }
    }

    throw StateError(
      '未找到 $name。请运行: .\\scripts\\build_rust.ps1 或 flutter run（Cargokit 自动编译）',
    );
  }
}
