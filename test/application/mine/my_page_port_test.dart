import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/mine/my_page_port.dart';

void main() {
  test('web service is active only when enabled and running', () {
    const active = MyPageWebServiceStatus(
      enabled: true,
      running: true,
      baseUrl: 'http://127.0.0.1:1122',
    );
    const stopped = MyPageWebServiceStatus(enabled: true, running: false);
    const disabled = MyPageWebServiceStatus(enabled: false, running: true);

    expect(active.isActive, isTrue);
    expect(stopped.isActive, isFalse);
    expect(disabled.isActive, isFalse);
  });
}
