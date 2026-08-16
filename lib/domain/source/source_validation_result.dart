import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_validation_result.freezed.dart';

/// 书源校验结果在领域边界上的纯 Dart 快照。
@freezed
class BookSourceValidationSnapshot with _$BookSourceValidationSnapshot {
  const BookSourceValidationSnapshot._();

  const factory BookSourceValidationSnapshot({
    required bool searchOk,
    required bool discoveryOk,
    required bool tocOk,
    required bool contentOk,
    required int searchTimeMs,
    @Default([]) List<String> errors,
  }) = _BookSourceValidationSnapshot;

  bool get allOk => searchOk && discoveryOk && tocOk && contentOk;

  bool get pipelineOk => tocOk && contentOk;
}

/// 业务调用方沿用的历史结果名称。
typedef SourceValidationResult = BookSourceValidationSnapshot;
