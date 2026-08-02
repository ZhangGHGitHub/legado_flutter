import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/content/replace_rule.dart';

part 'replace_state.freezed.dart';

/// 替换规则页面的不可变状态。
@freezed
class ReplaceState with _$ReplaceState {
  const factory ReplaceState({
    @Default(<ReplaceRule>[]) List<ReplaceRule> rules,
  }) = _ReplaceState;
}
