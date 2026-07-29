import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/ports/public_text_fetch_port.dart';
import '../models/book_source.dart';
import '../models/replace_rule.dart';
import '../models/rss_source.dart';
import '../models/rule_sub.dart';
import '../providers/replace_provider.dart';
import '../providers/rss_provider.dart';
import '../providers/source_provider.dart';
import '../utils/ssrf_guard.dart';
import 'book_source_service.dart';
import 'rule_sub_prefs.dart';

/// 规则订阅拉取/自动更新 — 对齐 Jingshiro [RuleUpdate] + Import*ViewModel
class RuleSubImportService {
  RuleSubImportService._();

  /// 非静默自动更新时缓存的待导入内容（对齐 cache*Map）
  static final Map<String, List<BookSource>> cacheBookSources = {};
  static final Map<String, List<RssSource>> cacheRssSources = {};
  static final Map<String, List<ReplaceRule>> cacheReplaceRules = {};

  static Future<String> fetchText(
    String url, {
    required PublicTextFetchPort fetchPort,
  }) async {
    SsrfGuard.assertPublicHttpUrl(url);
    var requestUrl = url;
    var userAgent = '';
    if (url.endsWith('#requestWithoutUA')) {
      requestUrl = url.substring(0, url.length - '#requestWithoutUA'.length);
      userAgent = 'null';
    }
    return fetchPort.fetch(requestUrl, userAgent: userAgent);
  }

  static List<BookSource> parseBookSources(String text) {
    final decoded = _decodeJson(text);
    final list = _asList(decoded);
    return list
        .whereType<Map>()
        .map((e) => BookSource.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.bookSourceUrl.isNotEmpty)
        .toList();
  }

  static List<RssSource> parseRssSources(String text) {
    final decoded = _decodeJson(text);
    final list = _asList(decoded);
    return list
        .whereType<Map>()
        .map((e) => RssSource.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.sourceUrl.isNotEmpty)
        .toList();
  }

  static List<ReplaceRule> parseReplaceRules(String text) {
    final decoded = _decodeJson(text);
    final list = _asList(decoded);
    return list.whereType<Map>().map(_replaceFromLegadoJson).toList();
  }

  static ReplaceRule _replaceFromLegadoJson(Map raw) {
    final json = Map<String, dynamic>.from(raw);
    final id = json['id'];
    return ReplaceRule(
      id: id == null ? DateTime.now().millisecondsSinceEpoch.toString() : '$id',
      name: json['name'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      replacement: json['replacement'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      isRegex: json['isRegex'] as bool? ?? true,
    );
  }

  static dynamic _decodeJson(String text) {
    final t = text.trim().replaceFirst('\uFEFF', '');
    return jsonDecode(t);
  }

  static List<dynamic> _asList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded.containsKey('bookSourceUrl') ||
          decoded.containsKey('sourceUrl') ||
          decoded.containsKey('pattern')) {
        return [decoded];
      }
      for (final key in ['data', 'sources', 'result', 'items', 'records']) {
        final val = decoded[key];
        if (val is List) return val;
      }
    }
    return const [];
  }

  /// 手动打开订阅：拉取并返回待导入项（优先用缓存）
  static Future<RuleSubFetched> fetchForImport(
    RuleSub sub, {
    required BookSourceService sourceService,
    required PublicTextFetchPort fetchPort,
  }) async {
    final url = sub.url;
    switch (sub.type) {
      case 0:
        final cached = cacheBookSources.remove(url);
        if (cached != null) {
          return RuleSubFetched.bookSources(cached);
        }
        final sources = await sourceService.fetchSourcesFromUrl(url);
        return RuleSubFetched.bookSources(sources);
      case 1:
        final cached = cacheRssSources.remove(url);
        if (cached != null) {
          return RuleSubFetched.rssSources(cached);
        }
        final text = await fetchText(url, fetchPort: fetchPort);
        return RuleSubFetched.rssSources(parseRssSources(text));
      case 2:
        final cached = cacheReplaceRules.remove(url);
        if (cached != null) {
          return RuleSubFetched.replaceRules(cached);
        }
        final text = await fetchText(url, fetchPort: fetchPort);
        return RuleSubFetched.replaceRules(parseReplaceRules(text));
      default:
        throw FormatException('未知订阅类型: ${sub.type}');
    }
  }

  /// 对齐 [RuleUpdate.cacheSource]：到期则拉取；
  /// 静默则直接写入；非静默有更新则缓存并返回 true（应打开导入 UI）。
  static Future<bool> cacheSource({
    required RuleSub ruleSub,
    required BookSourceService sourceService,
    required SourceProvider sourceProvider,
    required RssProvider rssProvider,
    required ReplaceProvider replaceProvider,
    required PublicTextFetchPort fetchPort,
    @visibleForTesting Future<String> Function(String url)? fetchTextOverride,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final intervalMs = ruleSub.updateInterval * 3600 * 1000;
    if (ruleSub.update + intervalMs > now) {
      return false;
    }

    final stamped = ruleSub.copyWith(update: now);
    await RuleSubPrefs.upsert(stamped);

    final url = stamped.url;
    final silent = stamped.silentUpdate;
    var needUi = false;
    final fetch =
        fetchTextOverride ?? (url) => fetchText(url, fetchPort: fetchPort);

    try {
      switch (stamped.type) {
        case 0:
          final lists = await sourceService.fetchSourcesFromUrl(url);
          if (lists.isEmpty) return false;
          for (final remote in lists) {
            final local = _findBook(sourceProvider, remote.bookSourceUrl);
            if (local == null || _bookNeedsUpdate(local, remote)) {
              if (silent) {
                await sourceProvider.importSources(
                  jsonEncode([remote.toJson()]),
                );
              } else {
                cacheBookSources[url] = lists;
                needUi = true;
                break;
              }
            }
          }
        case 1:
          final lists = parseRssSources(await fetch(url));
          if (lists.isEmpty) return false;
          for (final remote in lists) {
            final local = _findRss(rssProvider, remote.sourceUrl);
            if (local == null || _rssNeedsUpdate(local, remote)) {
              if (silent) {
                final source = local == null
                    ? remote
                    : remote.copyWith(sourceGroup: local.sourceGroup);
                await rssProvider.upsertSource(source);
              } else {
                cacheRssSources[url] = lists;
                needUi = true;
                break;
              }
            }
          }
        case 2:
          final lists = parseReplaceRules(await fetch(url));
          if (lists.isEmpty) return false;
          for (final remote in lists) {
            final old = _findReplace(replaceProvider, remote.id);
            if (old == null ||
                old.pattern != remote.pattern ||
                old.replacement != remote.replacement) {
              if (silent) {
                if (old == null) {
                  await replaceProvider.addRule(remote);
                } else {
                  await replaceProvider.updateRule(remote);
                }
              } else {
                cacheReplaceRules[url] = lists;
                needUi = true;
                break;
              }
            }
          }
      }
    } catch (e, st) {
      debugPrint('RuleSub autoUpdate failed (${stamped.name}): $e\n$st');
      return false;
    }
    return needUi;
  }

  /// 对齐 MainViewModel.ruleSubsUp
  static Future<List<RuleSub>> checkAutoUpdates({
    required BookSourceService sourceService,
    required SourceProvider sourceProvider,
    required RssProvider rssProvider,
    required ReplaceProvider replaceProvider,
    required PublicTextFetchPort fetchPort,
  }) async {
    final needUi = <RuleSub>[];
    final all = await RuleSubPrefs.load();
    for (final sub in all) {
      if (!sub.autoUpdate) continue;
      final openUi = await cacheSource(
        ruleSub: sub,
        sourceService: sourceService,
        sourceProvider: sourceProvider,
        rssProvider: rssProvider,
        replaceProvider: replaceProvider,
        fetchPort: fetchPort,
      );
      if (openUi) needUi.add(sub);
    }
    return needUi;
  }

  static BookSource? _findBook(SourceProvider p, String url) {
    for (final s in p.sources) {
      if (s.bookSourceUrl == url) return s;
    }
    return null;
  }

  static bool _bookNeedsUpdate(BookSource local, BookSource remote) {
    // Flutter BookSource 可能无 lastUpdateTime；无则仅在本地缺失时更新
    try {
      final localT = (local.toJson()['lastUpdateTime'] as num?)?.toInt() ?? 0;
      final remoteT = (remote.toJson()['lastUpdateTime'] as num?)?.toInt() ?? 0;
      if (remoteT > 0 && localT > 0) return localT < remoteT;
    } catch (_) {}
    return false;
  }

  static bool _rssNeedsUpdate(RssSource local, RssSource remote) =>
      local.lastUpdateTime < remote.lastUpdateTime;

  static RssSource? _findRss(RssProvider p, String url) {
    for (final s in p.sources) {
      if (s.sourceUrl == url) return s;
    }
    return null;
  }

  static ReplaceRule? _findReplace(ReplaceProvider p, String id) {
    for (final r in p.replaceRules) {
      if (r.id == id) return r;
    }
    return null;
  }
}

enum RuleSubFetchKind { bookSource, rssSource, replaceRule }

class RuleSubFetched {
  final RuleSubFetchKind kind;
  final List<BookSource> bookSources;
  final List<RssSource> rssSources;
  final List<ReplaceRule> replaceRules;

  const RuleSubFetched._({
    required this.kind,
    this.bookSources = const [],
    this.rssSources = const [],
    this.replaceRules = const [],
  });

  factory RuleSubFetched.bookSources(List<BookSource> list) =>
      RuleSubFetched._(kind: RuleSubFetchKind.bookSource, bookSources: list);

  factory RuleSubFetched.rssSources(List<RssSource> list) =>
      RuleSubFetched._(kind: RuleSubFetchKind.rssSource, rssSources: list);

  factory RuleSubFetched.replaceRules(List<ReplaceRule> list) =>
      RuleSubFetched._(kind: RuleSubFetchKind.replaceRule, replaceRules: list);

  int get count => switch (kind) {
    RuleSubFetchKind.bookSource => bookSources.length,
    RuleSubFetchKind.rssSource => rssSources.length,
    RuleSubFetchKind.replaceRule => replaceRules.length,
  };

  List<String> get labels => switch (kind) {
    RuleSubFetchKind.bookSource =>
      bookSources.map((e) => e.bookSourceName).toList(),
    RuleSubFetchKind.rssSource => rssSources.map((e) => e.sourceName).toList(),
    RuleSubFetchKind.replaceRule =>
      replaceRules.map((e) => e.name.isEmpty ? e.pattern : e.name).toList(),
  };
}
