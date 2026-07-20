import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/source_validation_result.dart';

Map<String, dynamic> resultToJson(SourceValidationResult r) => {
      'searchOk': r.searchOk,
      'discoveryOk': r.discoveryOk,
      'tocOk': r.tocOk,
      'contentOk': r.contentOk,
      'searchTimeMs': r.searchTimeMs,
      'errors': r.errors,
    };

SourceValidationResult resultFromJson(Map<String, dynamic> json) {
  return SourceValidationResult(
    searchOk: json['searchOk'] as bool? ?? false,
    discoveryOk: json['discoveryOk'] as bool? ?? false,
    tocOk: json['tocOk'] as bool? ?? false,
    contentOk: json['contentOk'] as bool? ?? false,
    searchTimeMs: (json['searchTimeMs'] as num?)?.toInt() ?? 0,
    errors: (json['errors'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
  );
}

/// 书源校验结果持久化 — key `source_validation_v1`
abstract final class SourceValidationStore {
  static const storeKey = 'source_validation_v1';

  static Future<Map<String, SourceValidationResult>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(storeKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, SourceValidationResult>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map) {
          out[entry.key.toString()] =
              resultFromJson(Map<String, dynamic>.from(value));
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveAll(Map<String, SourceValidationResult> map) async {
    final p = await SharedPreferences.getInstance();
    final encoded = map.map((url, r) => MapEntry(url, resultToJson(r)));
    await p.setString(storeKey, jsonEncode(encoded));
  }

  static Future<void> put(String url, SourceValidationResult r) async {
    final map = await load();
    map[url] = r;
    await saveAll(map);
  }

  static Future<void> remove(String url) async {
    final map = await load();
    if (map.remove(url) != null) {
      await saveAll(map);
    }
  }
}
