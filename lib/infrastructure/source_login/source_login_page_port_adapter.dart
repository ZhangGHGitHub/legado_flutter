import '../../application/source_login/source_login_page_port.dart';
import '../../domain/source/book_source.dart';
import '../../services/source_login_cookie_service.dart';
import '../../services/source_login_prefs.dart';
import '../../services/source_login_service.dart';

/// 保留既有登录存储、脚本和 Cookie 服务语义的适配器。
final class SourceLoginPagePortAdapter implements SourceLoginPagePort {
  const SourceLoginPagePortAdapter();

  @override
  Future<void> captureCookie({
    required String sourceUrl,
    required String cookie,
  }) => SourceLoginCookieService.capture(sourceUrl: sourceUrl, cookie: cookie);

  @override
  Future<void> clear(String sourceUrl) => SourceLoginPrefs.clear(sourceUrl);

  @override
  Future<void> clearCookie(String sourceUrl) =>
      SourceLoginCookieService.clear(sourceUrl);

  @override
  Future<void> clearHeader(String sourceUrl) =>
      SourceLoginPrefs.clearHeader(sourceUrl);

  @override
  SourceLoginScriptResult evalButtonAction(
    BookSource source,
    Map<String, String> loginInfo,
    String actionScript, {
    String loginHeader = '',
  }) => _result(
    SourceLoginService.evalButtonAction(
      source,
      loginInfo,
      actionScript,
      loginHeader: loginHeader,
    ),
  );

  @override
  List<Map<String, dynamic>> evalLoginUi(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  }) => SourceLoginService.evalLoginUi(
    source,
    loginInfo,
    loginHeader: loginHeader,
  );

  @override
  SourceLoginScriptResult evalLoginScript(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  }) => _result(
    SourceLoginService.evalLoginScript(
      source,
      loginInfo,
      loginHeader: loginHeader,
    ),
  );

  @override
  bool isHttpUrl(String url) => SourceLoginService.isHttpUrl(url);

  @override
  bool isJsUrl(String url) => SourceLoginService.isJsUrl(url);

  @override
  Future<Map<String, String>> load(String sourceUrl) =>
      SourceLoginPrefs.load(sourceUrl);

  @override
  Future<String?> loadHeader(String sourceUrl) =>
      SourceLoginPrefs.loadHeader(sourceUrl);

  @override
  Map<String, String> parseLoginHeader(String loginHeader) =>
      SourceLoginPrefs.parseLoginHeader(loginHeader);

  @override
  Future<void> save(String sourceUrl, Map<String, String> info) =>
      SourceLoginPrefs.save(sourceUrl, info);

  @override
  Future<void> saveHeader(String sourceUrl, String header) =>
      SourceLoginPrefs.saveHeader(sourceUrl, header);

  SourceLoginScriptResult _result(LoginJsResult result) =>
      SourceLoginScriptResult(
        output: result.output,
        loginInfo: result.loginInfo,
        commands: [
          for (final command in result.commands)
            SourceLoginCommand(
              operation: command.op,
              text: command.text,
              url: command.url,
              html: command.html,
              data: command.data,
            ),
        ],
      );
}
