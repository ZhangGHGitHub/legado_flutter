import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/bridge/legado_engine_bridge.dart';
import 'package:legado_flutter/infrastructure/engine/frb_source_login_cookie_port.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FRB source login Cookie set and clear reach the release DLL', () async {
    if (!Platform.isWindows) return;

    await LegadoEngineBridge.tryInit();
    expect(LegadoEngineBridge.isAvailable, isTrue);

    const port = FrbSourceLoginCookiePort();
    expect(
      () => port.setCookie(
        sourceUrl: 'https://reader.example.co.uk',
        cookie: 'sid=frb; token=1',
      ),
      returnsNormally,
    );
    expect(
      () => port.clearCookie('https://www.example.co.uk'),
      returnsNormally,
    );
  });
}
