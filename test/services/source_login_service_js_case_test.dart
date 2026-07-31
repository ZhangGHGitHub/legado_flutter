import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/services/source_login_service.dart';

void main() {
  group('SourceLoginService @js: handling', () {
    test('extractScript accepts ASCII case variants', () {
      expect(SourceLoginService.extractScript('@JS: login();'), 'login();');
      expect(SourceLoginService.extractScript('@Js: login();'), 'login();');
      expect(SourceLoginService.extractScript('@jS: login();'), 'login();');
    });

    test('isJsUrl accepts ASCII case variants', () {
      expect(SourceLoginService.isJsUrl('@JS: login();'), isTrue);
      expect(SourceLoginService.isJsUrl('@Js: login();'), isTrue);
      expect(SourceLoginService.isJsUrl('@jS: login();'), isTrue);
    });

    test('keeps js tag handling unchanged', () {
      expect(
        SourceLoginService.extractScript('<js> login(); </js>'),
        'login();',
      );
      expect(
        SourceLoginService.extractScript('<JS> login(); </JS>'),
        'login();',
      );
      expect(SourceLoginService.isJsUrl('<js> login(); </js>'), isTrue);
      expect(SourceLoginService.isJsUrl('<JS> login(); </JS>'), isTrue);
      expect(SourceLoginService.isJsUrl('<Js> login(); </jS>'), isTrue);
    });
  });
}
