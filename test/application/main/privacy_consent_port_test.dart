import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/main/privacy_consent_port.dart';

void main() {
  test('unavailable privacy consent port uses safe fallbacks', () async {
    const port = UnavailablePrivacyConsentPort();

    expect(await port.isAccepted(), isFalse);
    expect(await port.saveAccepted(), isFalse);
  });
}
