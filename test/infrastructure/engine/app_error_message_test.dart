import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/infrastructure/engine/app_error_message.dart';
import 'package:legado_flutter/src/rust/api/error.dart';

void main() {
  test('keeps the original text for every Rust AppError variant', () {
    const message = '获取 RSS 失败: 连接超时';

    expect(appErrorMessage(AppError.network(message)), message);
    expect(appErrorMessage(AppError.parse(message)), message);
    expect(appErrorMessage(AppError.database(message)), message);
    expect(appErrorMessage(AppError.jsExecution(message)), message);
    expect(appErrorMessage(AppError.validation(message)), message);
    expect(appErrorMessage(AppError.unsupported(message)), message);
    expect(appErrorMessage(AppError.cancelled(message)), message);
    expect(appErrorMessage(AppError.unknown(message)), message);
  });

  test('leaves non-Rust errors for their existing error handling', () {
    expect(appErrorMessage(StateError('不可用')), isNull);
  });
}
