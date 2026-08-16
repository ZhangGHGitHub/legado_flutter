import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/book/book.dart';
import '../../domain/ports/book_source_search_port.dart';
import '../../domain/source/book_source.dart';
import '../reader/reader_source_access_port.dart';

enum ChangeCoverSearchState {
  idle,
  searchingCoverRule,
  continueWithSources,
  searchingSources,
}

@immutable
final class ChangeCoverCandidate {
  const ChangeCoverCandidate({
    required this.url,
    required this.sourceName,
    this.sourceOrder = 0,
    this.sourceUrl = '',
  });

  final String url;
  final String sourceName;
  final int sourceOrder;
  final String sourceUrl;
}

abstract interface class ChangeCoverRulePort {
  Future<String?> searchCover(Book book);
}

final class EmptyChangeCoverRulePort implements ChangeCoverRulePort {
  const EmptyChangeCoverRulePort();

  @override
  Future<String?> searchCover(Book book) async => null;
}

abstract interface class ChangeCoverCandidateCachePort {
  Future<List<ChangeCoverCandidate>> load(Book book);

  Future<void> save(Book book, ChangeCoverCandidate candidate);
}

final class EmptyChangeCoverCandidateCachePort
    implements ChangeCoverCandidateCachePort {
  const EmptyChangeCoverCandidateCachePort();

  @override
  Future<List<ChangeCoverCandidate>> load(Book book) async => const [];

  @override
  Future<void> save(Book book, ChangeCoverCandidate candidate) async {}
}

final class ChangeCoverController extends ChangeNotifier {
  ChangeCoverController({
    required this.book,
    required ReaderSourceAccessPort sourceAccessPort,
    required BookSourceSearchPort sourceSearchPort,
    ChangeCoverRulePort rulePort = const EmptyChangeCoverRulePort(),
    ChangeCoverCandidateCachePort cachePort =
        const EmptyChangeCoverCandidateCachePort(),
    this.maxConcurrency = 4,
    this.sourceTimeout = const Duration(seconds: 60),
    void Function(Object error, StackTrace stackTrace)? onDiagnostic,
  }) : _sourceAccessPort = sourceAccessPort,
       _sourceSearchPort = sourceSearchPort,
       _rulePort = rulePort,
       _cachePort = cachePort,
       _onDiagnostic = onDiagnostic,
       assert(maxConcurrency > 0);

  final Book book;
  final int maxConcurrency;
  final Duration sourceTimeout;
  final ReaderSourceAccessPort _sourceAccessPort;
  final BookSourceSearchPort _sourceSearchPort;
  final ChangeCoverRulePort _rulePort;
  final ChangeCoverCandidateCachePort _cachePort;
  final void Function(Object error, StackTrace stackTrace)? _onDiagnostic;

  final List<ChangeCoverCandidate> _candidates = [
    const ChangeCoverCandidate(
      url: legadoDefaultCoverMarker,
      sourceName: '默认封面',
      sourceOrder: -2,
    ),
  ];
  ChangeCoverSearchState _state = ChangeCoverSearchState.idle;
  Future<void>? _activeSourceBatch;
  int _generation = 0;
  bool _disposed = false;

  List<ChangeCoverCandidate> get candidates =>
      List<ChangeCoverCandidate>.unmodifiable(_candidates);

  ChangeCoverSearchState get state => _state;

  bool get isSearching =>
      _state == ChangeCoverSearchState.searchingCoverRule ||
      _state == ChangeCoverSearchState.searchingSources;

  String get actionLabel => switch (_state) {
    ChangeCoverSearchState.searchingCoverRule ||
    ChangeCoverSearchState.searchingSources => '停止',
    ChangeCoverSearchState.continueWithSources => '继续',
    ChangeCoverSearchState.idle => '刷新',
  };

  Future<void> initialize() async {
    try {
      final cached = await _cachePort.load(book);
      final enabledSourceUrls = _sourceAccessPort.availableSources
          .where((source) => source.enabled)
          .map((source) => source.bookSourceUrl)
          .toSet();
      for (final candidate in cached) {
        if (candidate.sourceUrl.isNotEmpty &&
            !enabledSourceUrls.contains(candidate.sourceUrl)) {
          continue;
        }
        _addCandidate(candidate, notify: false);
      }
    } catch (error, stackTrace) {
      _onDiagnostic?.call(error, stackTrace);
    }
    _notify();
    if (_candidates.length <= 2) await start();
  }

  Future<void> startOrStop() => isSearching ? stop() : start();

  Future<void> start() async {
    final continueWithSources =
        _state == ChangeCoverSearchState.continueWithSources;
    final generation = ++_generation;
    final previousBatch = _activeSourceBatch;

    if (continueWithSources) {
      _setState(ChangeCoverSearchState.searchingSources);
      if (previousBatch != null) await previousBatch;
      if (generation != _generation || _disposed) return;
      await _searchSources(generation);
      return;
    }

    _candidates.removeRange(1, _candidates.length);
    _setState(ChangeCoverSearchState.searchingCoverRule);
    if (previousBatch != null) await previousBatch;
    if (generation != _generation || _disposed) return;

    try {
      final coverUrl = (await _rulePort.searchCover(book))?.trim() ?? '';
      if (generation != _generation || _disposed) return;
      if (coverUrl.isNotEmpty) {
        _addCandidate(
          ChangeCoverCandidate(
            url: coverUrl,
            sourceName: '封面规则',
            sourceOrder: -1,
          ),
        );
        _setState(ChangeCoverSearchState.continueWithSources);
        return;
      }
    } catch (error, stackTrace) {
      _onDiagnostic?.call(error, stackTrace);
    }
    if (generation == _generation && !_disposed) {
      await _searchSources(generation);
    }
  }

  Future<void> stop() async {
    _generation++;
    _setState(ChangeCoverSearchState.idle);
  }

  Future<void> _searchSources(int generation) async {
    final sources =
        _sourceAccessPort.availableSources
            .where(
              (source) =>
                  source.enabled && source.ruleSearchCoverUrl.trim().isNotEmpty,
            )
            .toList()
          ..sort((a, b) => a.customOrder.compareTo(b.customOrder));
    if (sources.isEmpty) {
      _setState(ChangeCoverSearchState.idle);
      return;
    }

    _setState(ChangeCoverSearchState.searchingSources);
    var nextIndex = 0;
    Future<void> worker() async {
      while (generation == _generation && nextIndex < sources.length) {
        final source = sources[nextIndex++];
        final candidate = await _searchSource(source);
        if (generation != _generation || _disposed) return;
        if (candidate != null && _addCandidate(candidate)) {
          try {
            await _cachePort.save(book, candidate);
          } catch (error, stackTrace) {
            _onDiagnostic?.call(error, stackTrace);
          }
        }
      }
    }

    final workerCount = sources.length.clamp(1, maxConcurrency);
    final batch = Future.wait(List.generate(workerCount, (_) => worker()));
    _activeSourceBatch = batch;
    await batch;
    if (identical(_activeSourceBatch, batch)) _activeSourceBatch = null;
    if (generation == _generation && !_disposed) {
      _setState(ChangeCoverSearchState.idle);
    }
  }

  Future<ChangeCoverCandidate?> _searchSource(BookSource source) async {
    try {
      final results = await _sourceSearchPort
          .search(source, book.name)
          .timeout(sourceTimeout, onTimeout: () => const []);
      final expectedAuthor = normalizeAuthor(book.author);
      for (final result in results) {
        final coverUrl = (result['coverUrl'] ?? '').trim();
        if (coverUrl.isEmpty || (result['name'] ?? '').trim() != book.name) {
          continue;
        }
        if (normalizeAuthor(result['author'] ?? '') != expectedAuthor) continue;
        return ChangeCoverCandidate(
          url: coverUrl,
          sourceName: source.bookSourceName,
          sourceOrder: source.customOrder,
          sourceUrl: source.bookSourceUrl,
        );
      }
    } catch (error, stackTrace) {
      _onDiagnostic?.call(error, stackTrace);
    }
    return null;
  }

  static String normalizeAuthor(String value) =>
      value.replaceAll(RegExp(r'^\s*作\s*者[:：\s]+|\s+著'), '').trim();

  bool _addCandidate(ChangeCoverCandidate candidate, {bool notify = true}) {
    if (_candidates.any((item) => item.url == candidate.url)) return false;
    _candidates.add(candidate);
    _candidates.sort((a, b) => a.sourceOrder.compareTo(b.sourceOrder));
    if (notify) _notify();
    return true;
  }

  void _setState(ChangeCoverSearchState value) {
    _state = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
