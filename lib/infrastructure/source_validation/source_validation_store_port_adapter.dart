import '../../application/source_validation/source_validation_store_port.dart';
import '../../domain/source/source_validation_result.dart';
import '../../services/source_validation_store.dart';

/// Adapts the existing SharedPreferences validation cache to the application port.
final class SourceValidationStorePortAdapter
    implements SourceValidationStorePort {
  const SourceValidationStorePortAdapter();

  @override
  Future<Map<String, SourceValidationResult>> load() =>
      SourceValidationStore.load();

  @override
  Future<void> put(String sourceUrl, SourceValidationResult result) =>
      SourceValidationStore.put(sourceUrl, result);

  @override
  Future<void> remove(String sourceUrl) =>
      SourceValidationStore.remove(sourceUrl);
}
