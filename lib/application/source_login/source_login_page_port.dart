import '../../domain/source/book_source.dart';

/// 书源登录页的表单、脚本与 Cookie 会话边界。
abstract interface class SourceLoginPagePort {
  Future<Map<String, String>> load(String sourceUrl);

  Future<void> save(String sourceUrl, Map<String, String> info);

  Future<void> clear(String sourceUrl);

  Future<String?> loadHeader(String sourceUrl);

  Future<void> saveHeader(String sourceUrl, String header);

  Future<void> clearHeader(String sourceUrl);

  Map<String, String> parseLoginHeader(String loginHeader);

  Future<void> captureCookie({
    required String sourceUrl,
    required String cookie,
  });

  Future<void> clearCookie(String sourceUrl);

  bool isHttpUrl(String url);

  bool isJsUrl(String url);

  List<Map<String, dynamic>> evalLoginUi(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  });

  SourceLoginScriptResult evalLoginScript(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  });

  SourceLoginScriptResult evalButtonAction(
    BookSource source,
    Map<String, String> loginInfo,
    String actionScript, {
    String loginHeader = '',
  });
}

/// 组合根尚未提供登录实现时的无副作用降级端口。
final class UnavailableSourceLoginPagePort implements SourceLoginPagePort {
  const UnavailableSourceLoginPagePort();

  @override
  Future<Map<String, String>> load(String sourceUrl) => Future.value({});

  @override
  Future<void> save(String sourceUrl, Map<String, String> info) async {}

  @override
  Future<void> clear(String sourceUrl) async {}

  @override
  Future<String?> loadHeader(String sourceUrl) => Future.value(null);

  @override
  Future<void> saveHeader(String sourceUrl, String header) async {}

  @override
  Future<void> clearHeader(String sourceUrl) async {}

  @override
  Map<String, String> parseLoginHeader(String loginHeader) => {};

  @override
  Future<void> captureCookie({
    required String sourceUrl,
    required String cookie,
  }) async {}

  @override
  Future<void> clearCookie(String sourceUrl) async {}

  @override
  bool isHttpUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  @override
  bool isJsUrl(String url) => url.trimLeft().startsWith('<js>');

  @override
  List<Map<String, dynamic>> evalLoginUi(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  }) => const [];

  @override
  SourceLoginScriptResult evalLoginScript(
    BookSource source,
    Map<String, String> loginInfo, {
    String loginHeader = '',
  }) => const SourceLoginScriptResult(output: '', commands: []);

  @override
  SourceLoginScriptResult evalButtonAction(
    BookSource source,
    Map<String, String> loginInfo,
    String actionScript, {
    String loginHeader = '',
  }) => const SourceLoginScriptResult(output: '', commands: []);
}

class SourceLoginCommand {
  const SourceLoginCommand({
    required this.operation,
    this.text = '',
    this.url = '',
    this.html = '',
    this.data,
  });

  final String operation;
  final String text;
  final String url;
  final String html;
  final Map<String, dynamic>? data;
}

class SourceLoginScriptResult {
  const SourceLoginScriptResult({
    required this.output,
    required this.commands,
    this.loginInfo = const {},
  });

  final String output;
  final List<SourceLoginCommand> commands;
  final Map<String, String> loginInfo;
}
