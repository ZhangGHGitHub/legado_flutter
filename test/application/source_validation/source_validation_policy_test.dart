import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_validation/source_validation_policy.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';
import 'package:legado_flutter/models/source_validation_result.dart' as legacy;

void main() {
  test('validation result preserves aggregate status behavior', () {
    const result = SourceValidationResult(
      searchOk: false,
      discoveryOk: false,
      tocOk: true,
      contentOk: true,
      searchTimeMs: 120,
      errors: ['搜索失败'],
    );

    expect(result.allOk, isFalse);
    expect(result.pipelineOk, isTrue);
    expect(result.searchTimeMs, 120);
    expect(result.errors, ['搜索失败']);
  });

  test('default keyword keeps known-source and fallback mappings', () {
    expect(defaultValidationKeyword('7565书源', 'https://example.com'), '斗破');
    expect(defaultValidationKeyword('笔书', 'https://example.com'), '斗破');
    expect(defaultValidationKeyword('番茄', 'https://example.com'), '斗罗');
    expect(defaultValidationKeyword('普通书源', 'https://7497.example'), '斗罗');
    expect(defaultValidationKeyword('普通书源', 'https://example.com'), '测试');
  });

  test('legacy model path remains a compatibility export', () {
    const result = legacy.SourceValidationResult(
      searchOk: true,
      discoveryOk: true,
      tocOk: true,
      contentOk: true,
      searchTimeMs: 0,
    );

    expect(result, isA<SourceValidationResult>());
    expect(legacy.defaultValidationKeyword('番茄', ''), '斗罗');
  });
}
