import '../src/rust/api.dart' as rust_api;

/// 将调试结果格式化为日志文本
String formatDebugLog(rust_api.DebugResult result) {
  final buf = StringBuffer();
  buf.writeln('── 请求 ──');
  buf.writeln('${result.requestMethod} ${result.requestUrl}');
  if (result.responseStatus.isNotEmpty) {
    buf.writeln(
      '状态: ${result.responseStatus}  编码: ${result.responseCharset}  '
      '大小: ${result.responseSize} bytes',
    );
  }
  buf.writeln();
  buf.writeln('── 规则步骤 ──');
  for (final step in result.ruleSteps) {
    final mark = step.ok ? '✅' : '❌';
    buf.writeln('$mark [${step.step}] ${step.rule}');
    buf.writeln('   → ${step.result}');
  }
  buf.writeln();
  buf.writeln('── 结果 (${result.results.length}) ──');
  for (var i = 0; i < result.results.length && i < 10; i++) {
    final item = result.results[i];
    buf.writeln('${i + 1}. ${item.name}');
    if (item.author.isNotEmpty) buf.writeln('   作者: ${item.author}');
    if (item.bookUrl.isNotEmpty) buf.writeln('   链接: ${item.bookUrl}');
  }
  if (result.results.length > 10) {
    buf.writeln('... 还有 ${result.results.length - 10} 条');
  }
  if (result.responseBodyPreview.isNotEmpty) {
    buf.writeln();
    buf.writeln('── 响应预览 ──');
    buf.writeln(result.responseBodyPreview);
  }
  return buf.toString();
}
