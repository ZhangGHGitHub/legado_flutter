import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/domain/web_api_status.dart';

void main() {
  test('WebApiStatus keeps value semantics and copyWith', () {
    const status = WebApiStatus(
      running: true,
      port: 1234,
      token: 'token',
      baseUrl: 'http://127.0.0.1:1234',
    );

    expect(status, equals(status.copyWith()));
    expect(status.copyWith(running: false).running, isFalse);
    expect(status.port, 1234);
  });
}
