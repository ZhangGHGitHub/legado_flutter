import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:legado_flutter/infrastructure/source_login/source_login_cookie_clear_port_adapter.dart';
import 'package:legado_flutter/services/source_login_cookie_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SourceLoginCookieService.resetPort();
  });

  tearDown(SourceLoginCookieService.resetPort);

  test('adapter preserves the service cookie clearing contract', () async {
    const sourceUrl = 'https://source.example';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'source_login_cookie_${Uri.encodeComponent(sourceUrl)}',
      'sid=1',
    );

    await const SourceLoginCookieClearPortAdapter().clear(sourceUrl);

    expect(
      prefs.getString('source_login_cookie_${Uri.encodeComponent(sourceUrl)}'),
      isNull,
    );
  });
}
