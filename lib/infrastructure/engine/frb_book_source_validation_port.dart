import '../../bridge/legado_engine_bridge.dart';
import '../../domain/ports/book_source_validation_port.dart';
import '../../models/book_source.dart';

/// Rust/FRB 书源校验适配器。
class FrbBookSourceValidationPort implements BookSourceValidationPort {
  @override
  bool get isAvailable => LegadoEngineBridge.isAvailable;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  }) async {
    if (!isAvailable) {
      throw StateError('Rust 引擎未加载，请编译 legado_engine 后重试');
    }
    final value = await LegadoEngineBridge.validateSource(
      source,
      keyword: keyword,
    );
    return BookSourceValidationSnapshot(
      searchOk: value.searchOk,
      discoveryOk: value.discoveryOk,
      tocOk: value.tocOk,
      contentOk: value.contentOk,
      searchTimeMs: value.searchTimeMs.toInt(),
      errors: List<String>.from(value.errors),
    );
  }
}
