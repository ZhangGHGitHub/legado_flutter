import '../../application/source_management/source_management_prefs_port.dart';
import '../../services/check_source_prefs.dart';
import '../../services/import_url_history_store.dart';
import '../../services/source_group_tags.dart';
import '../../services/source_manage_help_prefs.dart';

/// 委托既有 SharedPreferences 和分组规则实现的适配器。
final class SourceManagementPrefsPortAdapter
    implements SourceManagementPrefsPort {
  const SourceManagementPrefsPortAdapter();

  @override
  Future<void> addImportUrlHistory(String url) =>
      ImportUrlHistoryStore.add(url);

  @override
  bool hasGroup(String raw, String tag) => sourceHasGroupTag(raw, tag);

  @override
  Future<List<String>> loadImportUrlHistory() => ImportUrlHistoryStore.load();

  @override
  Future<void> markHelpShown() => SourceManageHelpPrefs.markShown();

  @override
  Future<void> removeImportUrlHistory(String url) =>
      ImportUrlHistoryStore.remove(url);

  @override
  Future<bool> shouldAutoShowHelp() => SourceManageHelpPrefs.shouldAutoShow();

  @override
  Future<bool> showDebugMessage() => CheckSourcePrefs.showDebugMessage();

  @override
  List<String> splitGroups(String raw) => splitSourceGroups(raw);
}
