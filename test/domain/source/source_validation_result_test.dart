import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';

void main() {
  group('BookSourceValidationSnapshot Freezed contract', () {
    test('keeps defaults and derived status semantics', () {
      const result = BookSourceValidationSnapshot(
        searchOk: true,
        discoveryOk: true,
        tocOk: true,
        contentOk: true,
        searchTimeMs: 120,
      );

      expect(result.errors, isEmpty);
      expect(result.allOk, isTrue);
      expect(result.pipelineOk, isTrue);

      const SourceValidationResult aliasResult = BookSourceValidationSnapshot(
        searchOk: true,
        discoveryOk: true,
        tocOk: true,
        contentOk: true,
        searchTimeMs: 120,
      );
      expect(aliasResult, equals(result));
    });

    test('keeps allOk and pipelineOk independent', () {
      const result = BookSourceValidationSnapshot(
        searchOk: false,
        discoveryOk: true,
        tocOk: true,
        contentOk: true,
        searchTimeMs: 120,
      );

      expect(result.allOk, isFalse);
      expect(result.pipelineOk, isTrue);
    });

    test('has value equality and copyWith semantics', () {
      const first = BookSourceValidationSnapshot(
        searchOk: true,
        discoveryOk: false,
        tocOk: true,
        contentOk: false,
        searchTimeMs: 120,
        errors: ['discovery failed'],
      );
      const second = BookSourceValidationSnapshot(
        searchOk: true,
        discoveryOk: false,
        tocOk: true,
        contentOk: false,
        searchTimeMs: 120,
        errors: ['discovery failed'],
      );

      expect(first, equals(second));
      expect(first.copyWith(discoveryOk: true, contentOk: true).allOk, isTrue);
      expect(first.copyWith(searchTimeMs: 240).searchTimeMs, 240);
    });

    test('keeps errors list immutable', () {
      const result = BookSourceValidationSnapshot(
        searchOk: true,
        discoveryOk: true,
        tocOk: true,
        contentOk: true,
        searchTimeMs: 120,
        errors: ['warning'],
      );

      expect(
        () => result.errors.add('another warning'),
        throwsUnsupportedError,
      );
    });
  });
}
