/// 书源管理页的偏好、导入历史和分组规则边界。
abstract interface class SourceManagementPrefsPort {
  Future<bool> showDebugMessage();

  Future<bool> shouldAutoShowHelp();

  Future<void> markHelpShown();

  Future<List<String>> loadImportUrlHistory();

  Future<void> addImportUrlHistory(String url);

  Future<void> removeImportUrlHistory(String url);

  List<String> splitGroups(String raw);

  bool hasGroup(String raw, String tag);
}
