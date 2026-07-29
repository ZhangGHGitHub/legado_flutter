import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/database/dao/source_dao.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/models/book_source.dart';
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
}
