import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_row_ui.freezed.dart';

/// 登录行 UI - 对齐 legado `RowUi`。
enum LoginRowType { text, password, button, toggle, select, checkbox }

@freezed
class LoginRowUi with _$LoginRowUi {
  const LoginRowUi._();

  const factory LoginRowUi({
    required String name,
    required LoginRowType type,
    String? viewName,
    String? defaultValue,
    @Default(<String>[]) List<String> chars,
  }) = _LoginRowUi;

  String get label =>
      (viewName != null && viewName!.isNotEmpty) ? viewName! : name;

  static LoginRowType _parseType(dynamic raw) {
    final s = (raw?.toString() ?? 'text').toLowerCase();
    return switch (s) {
      'password' => LoginRowType.password,
      'button' => LoginRowType.button,
      'toggle' => LoginRowType.toggle,
      'select' || 'spinner' => LoginRowType.select,
      'checkbox' || 'bool' => LoginRowType.checkbox,
      _ => LoginRowType.text,
    };
  }

  factory LoginRowUi.fromJson(Map<String, dynamic> json) {
    final charsRaw = json['chars'];
    final chars = <String>[];
    if (charsRaw is List) {
      for (final c in charsRaw) {
        if (c != null) chars.add(c.toString());
      }
    }
    return LoginRowUi(
      name: json['name']?.toString() ?? '',
      type: _parseType(json['type']),
      viewName: json['viewName']?.toString() ?? json['hint']?.toString(),
      defaultValue: json['default']?.toString(),
      chars: chars,
    );
  }

  /// 解析 `loginUi`：JSON 数组，或 `@js:` / `<js>`（此时返回空，由调用方提示）。
  static List<LoginRowUi> parse(String loginUi) {
    final raw = loginUi.trim();
    if (raw.isEmpty) return [];
    if (raw.startsWith('@js:') ||
        raw.startsWith('<js>') ||
        raw.startsWith('<JS>')) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => LoginRowUi.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static bool isJsLoginUi(String loginUi) {
    final raw = loginUi.trim();
    return raw.startsWith('@js:') ||
        raw.startsWith('<js>') ||
        raw.startsWith('<JS>');
  }
}
