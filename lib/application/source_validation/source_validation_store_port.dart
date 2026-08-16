import '../../domain/source/source_validation_result.dart';

/// Application boundary for persisted source-validation results.
abstract interface class SourceValidationStorePort {
  Future<Map<String, SourceValidationResult>> load();

  Future<void> put(String sourceUrl, SourceValidationResult result);

  Future<void> remove(String sourceUrl);
}

/// Empty persistence used until the composition root supplies an adapter.
final class UnavailableSourceValidationStorePort
    implements SourceValidationStorePort {
  const UnavailableSourceValidationStorePort();

  @override
  Future<Map<String, SourceValidationResult>> load() => Future.value({});

  @override
  Future<void> put(String sourceUrl, SourceValidationResult result) async {}

  @override
  Future<void> remove(String sourceUrl) async {}
}
