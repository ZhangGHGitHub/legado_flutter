import '../domain/ports/book_source_debug_port.dart';

/// 将调试结果格式化为日志文本
String formatDebugLog(BookSourceDebugSnapshot snapshot) {
  final buf = StringBuffer();
  buf.writeln('── 请求 ──');
  buf.writeln('${snapshot.requestMethod} ${snapshot.requestUrl}');
  if (snapshot.responseStatus.isNotEmpty) {
    buf.writeln(
      '状态: ${snapshot.responseStatus}  编码: ${snapshot.responseCharset}  '
      '大小: ${snapshot.responseSize} bytes',
    );
  }
  buf.writeln();
  buf.writeln('── 规则步骤 ──');
  for (final step in snapshot.ruleSteps) {
    final mark = step.ok ? '✅' : '❌';
    buf.writeln('$mark [${step.step}] ${step.rule}');
    buf.writeln('   → ${step.result}');
  }
  buf.writeln();
  buf.writeln('── 结果 (${snapshot.results.length}) ──');
  for (var i = 0; i < snapshot.results.length && i < 10; i++) {
    final item = snapshot.results[i];
    buf.writeln('${i + 1}. ${item.name}');
    if (item.author.isNotEmpty) buf.writeln('   作者: ${item.author}');
    if (item.bookUrl.isNotEmpty) buf.writeln('   链接: ${item.bookUrl}');
  }
  if (snapshot.results.length > 10) {
    buf.writeln('... 还有 ${snapshot.results.length - 10} 条');
  }
  if (snapshot.responseBodyPreview.isNotEmpty) {
    buf.writeln();
    buf.writeln('── 响应预览 ──');
    buf.writeln(snapshot.responseBodyPreview);
  }
  return buf.toString();
}
