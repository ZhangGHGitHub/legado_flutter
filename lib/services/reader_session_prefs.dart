import 'package:shared_preferences/shared_preferences.dart';

/// 阅读会话选项（对齐 legado 阅读内「替换净化」运行时开关）
class ReaderSessionPrefs {
  static const _kEnableReplace = 'reader_session_enable_replace';

  bool enableReplace;

  ReaderSessionPrefs({this.enableReplace = true});

  static Future<ReaderSessionPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return ReaderSessionPrefs(
      enableReplace: p.getBool(_kEnableReplace) ?? true,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnableReplace, enableReplace);
  }
}
