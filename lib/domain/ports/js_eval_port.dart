/// 书源登录脚本执行所需的最小 JS 引擎端口。
abstract interface class JsEvalPort {
  bool get isAvailable;

  String eval({
    required String script,
    required String jsLib,
    required String baseUrl,
  });
}
