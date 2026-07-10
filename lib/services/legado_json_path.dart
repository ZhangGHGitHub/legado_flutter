import 'package:json_path/json_path.dart' as rfc;

/// Legado 兼容 JSONPath 解析（RFC 9535 + `||` 回退）
class LegadoJsonPath {
  static dynamic resolve(dynamic root, String path) {
    if (root == null || path.isEmpty) return null;

    if (path.contains('||')) {
      for (final part in path.split('||')) {
        final result = resolveSingle(root, part.trim());
        if (result != null) {
          if (result is List && result.isNotEmpty) return result;
          if (result is! List) return result;
        }
      }
      return null;
    }
    return resolveSingle(root, path);
  }

  static dynamic resolveSingle(dynamic root, String path) {
    if (root == null || path.isEmpty) return null;
    var p = path.trim();
    if (p.isEmpty) return null;

    // Legado 简写: data.items → $.data.items
    if (!p.startsWith('\$') && !p.startsWith('@')) {
      p = '\$.${p.startsWith('.') ? p.substring(1) : p}';
    }

    try {
      final matches = rfc.JsonPath(p).read(root);
      final values = matches.map((m) => m.value).toList();
      if (values.isEmpty) return null;
      if (values.length == 1) return values.first;
      return values;
    } catch (_) {
      return _resolveLegacy(root, p);
    }
  }

  /// 兼容旧版自写解析器（部分 Legado 书源使用非标准路径）
  static dynamic _resolveLegacy(dynamic root, String path) {
    String p = path;
    if (p.startsWith(r'$.')) p = p.substring(2);
    if (p.startsWith('.')) p = p.substring(1);

    dynamic current = root;
    final parts = p.split(RegExp(r'\.|(?=\[)'));
    for (final part in parts) {
      if (current == null) return null;
      final clean = part
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll("'", '')
          .replaceAll('"', '');
      if (clean.isEmpty) continue;

      int? idx;
      var key = clean;
      if (part.contains('[') && part.contains(']')) {
        final match = RegExp(r'\[(\d+)\]').firstMatch(part);
        if (match != null) idx = int.tryParse(match.group(1)!);
        key = part.replaceAll(RegExp(r'\[.*?\]'), '');
        if (key.isEmpty && current is List) continue;
      }

      if (current is Map) {
        current = current[key];
      } else if (current is List) {
        if (idx != null && idx < current.length) {
          current = current[idx];
        } else if (key.isNotEmpty) {
          return current.map((e) => e is Map ? e[key] : null).toList();
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  static String resolveString(dynamic root, String path) {
    final v = resolve(root, path);
    if (v == null) return '';
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .join(', ');
    }
    return v.toString();
  }

  static String resolveTemplate(String template, dynamic data) {
    return template.replaceAllMapped(
      RegExp(r'\{\{(.+?)\}\}'),
      (m) => resolveString(data, m.group(1)!.trim()),
    );
  }
}
