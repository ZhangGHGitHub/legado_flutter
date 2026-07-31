import '../../application/reader/reader_session_prefs_port.dart';
import '../../services/reader_session_prefs.dart';

/// 保留替换净化开关默认值和持久化键的适配器。
final class ReaderSessionPrefsPortAdapter implements ReaderSessionPrefsPort {
  const ReaderSessionPrefsPortAdapter();

  @override
  Future<bool> loadEnableReplace() async =>
      (await ReaderSessionPrefs.load()).enableReplace;

  @override
  Future<void> saveEnableReplace(bool value) =>
      ReaderSessionPrefs(enableReplace: value).save();
}
