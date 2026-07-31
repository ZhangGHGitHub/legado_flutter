import 'package:flutter_test/flutter_test.dart';
import 'package:legado_flutter/application/source_management/source_group_catalog_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/infrastructure/engine/frb_book_source_validation_port.dart';
import 'package:legado_flutter/providers/source_provider.dart';
import '../helpers/book_source_service_test_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBookSourceRepository implements BookSourceRepository {
  final List<BookSource> sources;

  _FakeBookSourceRepository(this.sources);

  @override
  Future<void> upsert(BookSource source) async {
    sources.removeWhere((item) => item.bookSourceUrl == source.bookSourceUrl);
    sources.add(source);
  }

  @override
  Future<void> upsertAll(List<BookSource> values) async {
    for (final source in values) {
      await upsert(source);
    }
  }

  @override
  Future<void> update(BookSource source) => upsert(source);

  @override
  Future<List<BookSource>> getAll() async => List.unmodifiable(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((source) => source.enabled).toList();

  @override
  Future<void> toggle(String url, bool enabled) async {
    final source = sources.firstWhere((item) => item.bookSourceUrl == url);
    await upsert(source.copyWith(enabled: enabled));
  }

  @override
  Future<void> delete(String url) async {
    sources.removeWhere((source) => source.bookSourceUrl == url);
  }
}

final class _FakeSourceGroupCatalogPort implements SourceGroupCatalogPort {
  _FakeSourceGroupCatalogPort(Iterable<String> initialNames)
    : _names = initialNames.toList();

  final List<String> _names;
  final _tagRules = const UnavailableSourceGroupCatalogPort();
  int loadCount = 0;
  final mergedValues = <String>[];

  @override
  List<String> get names => List.unmodifiable(_names);

  @override
  Future<void> load() async {
    loadCount++;
  }

  @override
  Future<void> mergeFromSources(Iterable<String> fromSources) async {
    for (final raw in fromSources) {
      mergedValues.add(raw);
      for (final name in splitGroups(raw)) {
        if (!_names.contains(name)) _names.add(name);
      }
    }
    _names.sort();
  }

  @override
  Future<bool> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _names.contains(trimmed)) return false;
    _names.add(trimmed);
    _names.sort();
    return true;
  }

  @override
  Future<void> rename(String oldName, String newName) async {
    final oldTrimmed = oldName.trim();
    final newTrimmed = newName.trim();
    _names.remove(oldTrimmed);
    if (newTrimmed.isNotEmpty && !_names.contains(newTrimmed)) {
      _names.add(newTrimmed);
    }
    _names.sort();
  }

  @override
  Future<void> remove(String name) async {
    _names.remove(name.trim());
  }

  @override
  List<String> splitGroups(String raw) => _tagRules.splitGroups(raw);

  @override
  String addGroupTag(String raw, String tag) => _tagRules.addGroupTag(raw, tag);

  @override
  String removeGroupTag(String raw, String tag) =>
      _tagRules.removeGroupTag(raw, tag);

  @override
  String renameGroupTag(String raw, String from, String to) =>
      _tagRules.renameGroupTag(raw, from, to);

  @override
  bool hasGroupTag(String raw, String tag) => _tagRules.hasGroupTag(raw, tag);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'SourceProvider loads and exposes trimmed sorted source groups',
    () async {
      final repository = _FakeBookSourceRepository([
        BookSource(
          bookSourceUrl: 'https://one.example',
          bookSourceName: '一',
          bookSourceGroup: ' B, A，B ',
        ),
        BookSource(
          bookSourceUrl: 'https://two.example',
          bookSourceName: '二',
          bookSourceGroup: '  ',
        ),
      ]);
      final groupPort = _FakeSourceGroupCatalogPort(['默认']);
      final provider = SourceProvider(
        repository: repository,
        validationPort: FrbBookSourceValidationPort(),
        sourceService: createTestBookSourceService(),
        sourceGroupPort: groupPort,
      );

      await provider.loadSources();

      expect(groupPort.loadCount, 1);
      expect(groupPort.mergedValues, [' B, A，B ', '  ']);
      expect(provider.knownGroups, ['A', 'B', '默认']);
    },
  );

  test(
    'SourceProvider preserves catalog CRUD and source tag semantics',
    () async {
      final repository = _FakeBookSourceRepository([
        BookSource(
          bookSourceUrl: 'https://one.example',
          bookSourceName: '一',
          bookSourceGroup: '默认, 其他',
        ),
        BookSource(bookSourceUrl: 'https://two.example', bookSourceName: '二'),
      ]);
      final groupPort = _FakeSourceGroupCatalogPort(['默认']);
      final provider = SourceProvider(
        repository: repository,
        validationPort: FrbBookSourceValidationPort(),
        sourceService: createTestBookSourceService(),
        sourceGroupPort: groupPort,
      );

      await provider.loadSources();
      BookSource sourceAt(String url) =>
          provider.sources.singleWhere((source) => source.bookSourceUrl == url);

      expect(await provider.addGroup(' 新组 '), isTrue);
      expect(sourceAt('https://one.example').bookSourceGroup, '默认, 其他');

      await provider.renameGroup(' 默认 ', ' 主力 ');
      expect(sourceAt('https://one.example').bookSourceGroup, '主力,其他');
      expect(groupPort.names, contains('主力'));
      expect(groupPort.names, isNot(contains('默认')));

      await provider.addGroupToSources(['https://two.example'], ' 新组 ');
      expect(sourceAt('https://two.example').bookSourceGroup, '新组');

      await provider.removeGroupTagFromSources(['https://one.example'], ' 其他 ');
      expect(sourceAt('https://one.example').bookSourceGroup, '主力');

      await provider.deleteGroup('主力');
      expect(sourceAt('https://one.example').bookSourceGroup, '');
      expect(groupPort.names, isNot(contains('主力')));
    },
  );
}
