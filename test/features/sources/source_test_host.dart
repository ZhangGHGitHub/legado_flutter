import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart';

import 'package:legado_flutter/application/reader/reader_font_port.dart';
import 'package:legado_flutter/application/source_management/source_controller.dart';
import 'package:legado_flutter/application/source_management/source_group_catalog_port.dart';
import 'package:legado_flutter/application/source_management/source_management_book_source_port.dart';
import 'package:legado_flutter/application/source_management/source_management_prefs_port.dart';
import 'package:legado_flutter/application/source_management/source_notifier.dart';
import 'package:legado_flutter/application/source_validation/source_validation_store_port.dart';
import 'package:legado_flutter/domain/book/book.dart';
import 'package:legado_flutter/domain/ports/book_source_validation_port.dart';
import 'package:legado_flutter/domain/repositories/book_source_repository.dart';
import 'package:legado_flutter/domain/source/book_source.dart';
import 'package:legado_flutter/domain/source/source_validation_result.dart';

import '../../helpers/fake_reader_font_port.dart';

final class InMemorySourceRepository implements BookSourceRepository {
  InMemorySourceRepository([Iterable<BookSource> initial = const []])
    : sources = List<BookSource>.of(initial);

  final List<BookSource> sources;

  @override
  Future<void> upsert(BookSource source) async {
    final index = sources.indexWhere(
      (item) => item.bookSourceUrl == source.bookSourceUrl,
    );
    if (index < 0) {
      sources.add(source);
    } else {
      sources[index] = source;
    }
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
  Future<List<BookSource>> getAll() async => List<BookSource>.of(sources);

  @override
  Future<List<BookSource>> getEnabled() async =>
      List<BookSource>.of(sources.where((source) => source.enabled));

  @override
  Future<void> toggle(String url, bool enabled) async {
    final index = sources.indexWhere((source) => source.bookSourceUrl == url);
    if (index >= 0) sources[index] = sources[index].copyWith(enabled: enabled);
  }

  @override
  Future<void> delete(String url) async {
    sources.removeWhere((source) => source.bookSourceUrl == url);
  }
}

final class InMemorySourceGroupCatalog implements SourceGroupCatalogPort {
  InMemorySourceGroupCatalog([Iterable<String> initial = const []])
    : _names = initial
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toSet();

  final Set<String> _names;

  @override
  List<String> get names => _names.toList()..sort();

  @override
  Future<void> load() async {}

  @override
  Future<void> mergeFromSources(Iterable<String> fromSources) async {
    for (final raw in fromSources) {
      _names.addAll(splitGroups(raw));
    }
  }

  @override
  Future<bool> add(String name) async => _names.add(name.trim());

  @override
  Future<void> rename(String oldName, String newName) async {
    _names.remove(oldName);
    if (newName.trim().isNotEmpty) _names.add(newName.trim());
  }

  @override
  Future<void> remove(String name) async {
    _names.remove(name);
  }

  @override
  List<String> splitGroups(String raw) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in raw.split(RegExp(r'[,，]'))) {
      final group = value.trim();
      if (group.isNotEmpty && seen.add(group)) result.add(group);
    }
    return result;
  }

  @override
  String addGroupTag(String raw, String tag) {
    return _joinGroups([...splitGroups(raw), tag]);
  }

  @override
  String removeGroupTag(String raw, String tag) {
    return _joinGroups(splitGroups(raw).where((group) => group != tag.trim()));
  }

  @override
  String renameGroupTag(String raw, String from, String to) {
    return _joinGroups(
      splitGroups(raw).map((group) => group == from.trim() ? to.trim() : group),
    );
  }

  @override
  bool hasGroupTag(String raw, String tag) =>
      splitGroups(raw).contains(tag.trim());

  String _joinGroups(Iterable<String> groups) {
    final seen = <String>{};
    return groups
        .map((group) => group.trim())
        .where((group) => group.isNotEmpty && seen.add(group))
        .join(',');
  }
}

final class TestSourceManagementPrefs implements SourceManagementPrefsPort {
  final List<String> importHistory = [];

  @override
  Future<bool> showDebugMessage() async => false;

  @override
  Future<bool> shouldAutoShowHelp() async => false;

  @override
  Future<void> markHelpShown() async {}

  @override
  Future<List<String>> loadImportUrlHistory() async =>
      List<String>.of(importHistory);

  @override
  Future<void> addImportUrlHistory(String url) async {
    importHistory.remove(url);
    importHistory.insert(0, url);
  }

  @override
  Future<void> removeImportUrlHistory(String url) async {
    importHistory.remove(url);
  }

  @override
  List<String> splitGroups(String raw) => raw
      .split(RegExp(r'[,，]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  @override
  bool hasGroup(String raw, String tag) => splitGroups(raw).contains(tag);
}

final class TestSourceService implements SourceManagementBookSourcePort {
  List<BookSource> urlSources = const [];

  @override
  Future<List<BookSource>> fetchSourcesFromUrl(String url) async =>
      List<BookSource>.of(urlSources);

  @override
  Future<List<Map<String, String>>> search(BookSource source, String keyword) =>
      Future.value(const []);

  @override
  List<Book> resultsToBooks(
    List<Map<String, String>> results,
    String sourceUrl,
  ) => const [];
}

final class TestValidationPort implements BookSourceValidationPort {
  BookSourceValidationSnapshot snapshot = const BookSourceValidationSnapshot(
    searchOk: true,
    discoveryOk: true,
    tocOk: true,
    contentOk: true,
    searchTimeMs: 0,
  );

  @override
  bool get isAvailable => true;

  @override
  Future<BookSourceValidationSnapshot> validateSource(
    BookSource source, {
    required String keyword,
  }) async => snapshot;
}

final class TestValidationStore implements SourceValidationStorePort {
  TestValidationStore([Map<String, SourceValidationResult>? initial])
    : values = Map<String, SourceValidationResult>.of(initial ?? {});

  final Map<String, SourceValidationResult> values;

  @override
  Future<Map<String, SourceValidationResult>> load() async =>
      Map<String, SourceValidationResult>.of(values);

  @override
  Future<void> put(String sourceUrl, SourceValidationResult result) async {
    values[sourceUrl] = result;
  }

  @override
  Future<void> remove(String sourceUrl) async {
    values.remove(sourceUrl);
  }
}

final class TestReaderFontPort extends FakeReaderFontPort {
  const TestReaderFontPort();
}

final class SourceTestHost {
  SourceTestHost({
    Iterable<BookSource> initialSources = const [],
    Iterable<String> initialGroups = const [],
    Map<String, SourceValidationResult>? validationResults,
  }) : repository = InMemorySourceRepository(initialSources),
       groups = InMemorySourceGroupCatalog(initialGroups),
       prefs = TestSourceManagementPrefs(),
       sourceService = TestSourceService(),
       validationPort = TestValidationPort(),
       validationStore = TestValidationStore(validationResults) {
    controller = SourceController(
      repository: repository,
      validationPort: validationPort,
      sourceService: sourceService,
      sourceGroupPort: groups,
      validationStorePort: validationStore,
    );
  }

  final InMemorySourceRepository repository;
  final InMemorySourceGroupCatalog groups;
  final TestSourceManagementPrefs prefs;
  final TestSourceService sourceService;
  final TestValidationPort validationPort;
  final TestValidationStore validationStore;
  late final SourceController controller;
  final ReaderFontPort font = const TestReaderFontPort();

  Future<void> load() => controller.loadSources();

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        Provider<SourceManagementPrefsPort>.value(value: prefs),
        Provider<ReaderFontPort>.value(value: font),
      ],
      child: riverpod.ProviderScope(
        overrides: [sourceControllerProvider.overrideWithValue(controller)],
        child: MaterialApp(home: child),
      ),
    );
  }
}
