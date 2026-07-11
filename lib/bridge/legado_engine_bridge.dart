import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import '../config/engine_config.dart';
import '../models/book.dart';
import '../models/book_source.dart';
import '../models/chapter.dart';
import '../src/rust/api.dart' as rust_api;
import '../src/rust/frb_generated.dart';

/// Rust 书源引擎桥接层
class LegadoEngineBridge {
  static bool _initialized = false;
  static bool _available = false;

  static bool get isAvailable => _available;

  static Future<void> tryInit() async {
    if (_initialized) return;
    _initialized = true;

    if (!EngineConfig.useRust) {
      debugPrint('[Engine] Rust 引擎已禁用（设置）');
      return;
    }

    try {
      final lib = await _loadExternalLibrary();
      await LegadoEngine.init(externalLibrary: lib);
      rust_api.initEngine();
      _available = true;
      debugPrint('[Engine] Rust 书源引擎 v${engineVersion()} 已加载');
    } catch (e) {
      _available = false;
      debugPrint('[Engine] Rust 引擎不可用: $e');
    }
  }

  static String _sourceJson(BookSource source) =>
      source.rawSourceJson.isNotEmpty
          ? source.rawSourceJson
          : jsonEncode(source.toJson());

  static Future<List<Map<String, String>>> search(
    BookSource source,
    String keyword,
  ) async {
    if (!_available) throw StateError('Rust engine not available');

    final items = await rust_api.search(
      sourceJson: _sourceJson(source),
      keyword: keyword,
    );
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
  }

  static Future<List<Map<String, String>>> explore(
    BookSource source,
    String exploreUrl, {
    int page = 1,
  }) async {
    if (!_available) throw StateError('Rust engine not available');

    final items = await rust_api.explore(
      sourceJson: _sourceJson(source),
      exploreUrl: exploreUrl,
      page: page,
    );
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
  }

  static Future<Map<String, String>> getBookInfo(
    BookSource source,
    String bookUrl,
  ) async {
    if (!_available) throw StateError('Rust engine not available');

    final info = await rust_api.getBookInfo(
      sourceJson: _sourceJson(source),
      bookUrl: bookUrl,
    );
    return {
      'name': info.name,
      'author': info.author,
      'coverUrl': info.coverUrl,
      'intro': info.intro,
      'kind': info.kind,
      'lastChapter': info.lastChapter,
      'tocUrl': info.tocUrl,
    };
  }

  static Future<List<Chapter>> getToc(BookSource source, Book book) async {
    if (!_available) throw StateError('Rust engine not available');

    final items = await rust_api.getToc(
      sourceJson: _sourceJson(source),
      bookUrl: book.sourceUrl,
    );
    return items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      return Chapter(
        id: '${book.id}_ch_$i',
        bookId: book.id,
        title: item.title,
        index: i,
        url: item.url,
      );
    }).toList();
  }

  static Future<String> getContent(
    BookSource source,
    String chapterUrl,
  ) async {
    if (!_available) throw StateError('Rust engine not available');

    return rust_api.getContent(
      sourceJson: _sourceJson(source),
      chapterUrl: chapterUrl,
    );
  }

  static String engineVersion() => rust_api.engineVersion();

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
