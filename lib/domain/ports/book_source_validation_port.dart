import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';

export 'package:legado_flutter/domain/source/source_validation_result.dart'
    show BookSourceValidationSnapshot;

/// 书源校验用例所需的引擎端口。
abstract interface class BookSourceValidationPort {
  bool get isAvailable;

  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  });
}
