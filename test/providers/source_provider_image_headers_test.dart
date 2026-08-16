import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/source_login/source_login_page_port_adapter.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/book_source_service_test_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('image headers expose the source custom header', () async {
    SharedPreferences.setMockInitialValues({});
    final source = BookSource.fromJson({
      'bookSourceUrl': 'https://example.com/source',
      'bookSourceName': 'fixture',
      'header': {'User-Agent': 'fixture-reader', 'Cookie': 'source=1'},
    });

    final headers = await SourceProvider(
      repository: SourceDao(),
      validationPort: FrbBookSourceValidationPort(),
      sourceService: createTestBookSourceService(),
    ).imageHeadersForSource(source);

    expect(headers, {'User-Agent': 'fixture-reader', 'Cookie': 'source=1'});
  });

  test(
    'login headers override source headers through the login port',
    () async {
      SharedPreferences.setMockInitialValues({});
      const loginPort = SourceLoginPagePortAdapter();
      const sourceUrl = 'https://example.com/source';
      await loginPort.saveHeader(
        sourceUrl,
        jsonEncode({'Cookie': 'login=1', 'X-Login': 'yes'}),
      );
      final source = BookSource.fromJson({
        'bookSourceUrl': sourceUrl,
        'bookSourceName': 'fixture',
        'header': {'Cookie': 'source=1', 'User-Agent': 'fixture-reader'},
      });

      final headers = await SourceProvider(
        repository: SourceDao(),
        validationPort: FrbBookSourceValidationPort(),
        sourceService: createTestBookSourceService(),
        loginPort: loginPort,
      ).imageHeadersForSource(source);

      expect(headers, {
        'Cookie': 'login=1',
        'User-Agent': 'fixture-reader',
        'X-Login': 'yes',
      });
    },
  );

  test('image style is read from ruleContent', () {
    final source = BookSource.fromJson({
      'bookSourceUrl': 'https://example.com/source',
      'bookSourceName': 'fixture',
      'ruleContent': {'imageStyle': 'single'},
    });

    expect(source.ruleContentImageStyle, 'single');
  });
}
