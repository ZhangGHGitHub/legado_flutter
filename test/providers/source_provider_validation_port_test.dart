import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_rules/check_source_prefs_port.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBookSourceValidationPort implements BookSourceValidationPort {
  BookSource? source;
  String? keyword;

  @override
  bool get isAvailable => true;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource value, {
    required String keyword,
  }) async {
    source = value;
    this.keyword = keyword;
    return const BookSourceValidationSnapshot(
      searchOk: true,
      discoveryOk: false,
      tocOk: true,
      contentOk: false,
      searchTimeMs: 0,
      errors: ['发现失败', '正文失败'],
    );
  }
}

final class _FakeCheckSourcePrefsPort implements CheckSourcePrefsPort {
  _FakeCheckSourcePrefsPort({
    required this.timeout,
    required this.search,
    required this.discovery,
    required this.toc,
    required this.content,
    required this.keyword,
  });

  final int timeout;
  final bool search;
  final bool discovery;
  final bool toc;
  final bool content;
  String keyword;
  String? savedKeyword;

  @override
  Future<int> timeoutSec() async => timeout;

  @override
  Future<void> setTimeoutSec(int value) async {}

  @override
  Future<bool> checkSearch() async => search;

  @override
  Future<void> setCheckSearch(bool value) async {}

  @override
  Future<bool> checkDiscovery() async => discovery;

  @override
  Future<void> setCheckDiscovery(bool value) async {}

  @override
  Future<bool> checkToc() async => toc;

  @override
  Future<void> setCheckToc(bool value) async {}

  @override
  Future<bool> checkContent() async => content;

  @override
  Future<void> setCheckContent(bool value) async {}

  @override
  Future<bool> showDebugMessage() async => true;

  @override
  Future<void> setShowDebugMessage(bool value) async {}

  @override
  Future<String> lastKeyword() async => keyword;

  @override
  Future<void> setLastKeyword(String value) async {
    savedKeyword = value;
    keyword = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'SourceProvider validateSource uses the injected validation port',
    () async {
      SharedPreferences.setMockInitialValues({});
      final port = _FakeBookSourceValidationPort();
      final provider = SourceProvider(
        repository: SourceDao(),
        validationPort: port,
        sourceService: createTestBookSourceService(),
      );
      final source = BookSource(
        bookSourceUrl: 'https://source.example',
        bookSourceName: '测试书源',
      );

      final result = await provider.validateSource(source, keyword: '关键词');

      expect(port.source, same(source));
      expect(port.keyword, '关键词');
      expect(result?.searchOk, isTrue);
      expect(result?.discoveryOk, isFalse);
      expect(result?.errors, ['发现失败', '正文失败']);
      expect(provider.validationOf(source.bookSourceUrl), same(result));
    },
  );

  test(
    'SourceProvider uses the injected source-check preferences port',
    () async {
      SharedPreferences.setMockInitialValues({});
      final validationPort = _FakeBookSourceValidationPort();
      final prefs = _FakeCheckSourcePrefsPort(
        timeout: 7,
        search: true,
        discovery: false,
        toc: true,
        content: false,
        keyword: '',
      );
      final provider = SourceProvider(
        repository: SourceDao(),
        validationPort: validationPort,
        sourceService: createTestBookSourceService(),
        checkSourcePrefsPort: prefs,
      );
      final source = BookSource(
        bookSourceUrl: 'https://source.example',
        bookSourceName: '测试书源',
      );

      final result = await provider.validateSource(source, keyword: '  关键词  ');

      expect(validationPort.keyword, '关键词');
      expect(prefs.savedKeyword, '关键词');
      expect(result?.searchOk, isTrue);
      expect(result?.discoveryOk, isTrue);
      expect(result?.tocOk, isTrue);
      expect(result?.contentOk, isTrue);
    },
  );
}
