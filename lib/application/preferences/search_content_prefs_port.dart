/// 正文搜索设置的应用层持久化边界。
abstract interface class SearchContentPrefsPort {
  Future<SearchContentPrefs> load();

  Future<void> save(SearchContentPrefs prefs);
}

/// 正文搜索当前生效的设置。
final class SearchContentPrefs {
  static const scopeCurrent = 'current';
  static const scopeCurrentAndCached = 'current_and_cached';
  static const scopeCurrentAndNetwork = 'current_and_network';

  const SearchContentPrefs({
    this.enableReplace = true,
    this.enableRegex = false,
    this.scope = scopeCurrentAndCached,
  });

  final bool enableReplace;
  final bool enableRegex;
  final String scope;

  SearchContentPrefs copyWith({
    bool? enableReplace,
    bool? enableRegex,
    String? scope,
  }) {
    return SearchContentPrefs(
      enableReplace: enableReplace ?? this.enableReplace,
      enableRegex: enableRegex ?? this.enableRegex,
      scope: scope ?? this.scope,
    );
  }
}
