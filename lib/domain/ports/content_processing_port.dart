import 'package:freezed_annotation/freezed_annotation.dart';

import '../content/replace_rule.dart';

part 'content_processing_port.freezed.dart';

/// 正文处理用例的领域端口。
///
/// 端口只描述正文清洗输入和输出，不负责中文断行、分页或章节边界。
/// 这样替换具体处理器时，阅读链路仍接收完全相同的正文字符串。
abstract interface class ContentProcessingPort {
  void loadRules(List<ReplaceRule> rules);

  String applyWithRules(String raw, List<ReplaceRule> rules);

  String getContent(String raw);

  String process(String raw, {ContentProcessingSourceRules? sourceRules});

  String processForReading(
    String raw, {
    String chapterTitle,
    String bookName,
    bool includeTitle,
    bool useReplace,
    String paragraphIndent,
    bool reSegment,
    ContentProcessingSourceRules? sourceRules,
  });
}

/// 书源级正文替换规则的纯 Dart 表示。
@freezed
class ContentProcessingSourceRules with _$ContentProcessingSourceRules {
  const factory ContentProcessingSourceRules({
    @Default('') String contentReplace,
    @Default('') String contentReplaceTo,
  }) = _ContentProcessingSourceRules;
}
