import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/book/book.dart';
import '../../domain/source/book_source.dart';
import '../../domain/source/source_validation_result.dart';

part 'source_state.freezed.dart';

/// 书源管理的不可变状态快照。
@freezed
class SourceState with _$SourceState {
  const factory SourceState({
    @Default(<BookSource>[]) List<BookSource> sources,
    @Default(<String, List<Book>>{}) Map<String, List<Book>> searchResults,
    @Default(<String, SourceValidationResult>{})
    Map<String, SourceValidationResult> validationResults,
    @Default(<String, String>{}) Map<String, String> validationProgress,
    @Default(false) bool isLoading,
    @Default(false) bool isValidating,
    String? validatingSourceUrl,
    @Default('') String statusMessage,
    String? loadError,
  }) = _SourceState;
}
