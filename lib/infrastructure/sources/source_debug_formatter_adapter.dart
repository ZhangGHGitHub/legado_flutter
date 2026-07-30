import '../../application/sources/source_debug_formatter_port.dart';
import '../../domain/ports/book_source_debug_port.dart';
import '../../services/source_debug_formatter.dart';

/// 现有书源调试日志格式化器的纯适配器。
final class SourceDebugFormatterAdapter implements SourceDebugFormatterPort {
  const SourceDebugFormatterAdapter();

  @override
  String format(BookSourceDebugSnapshot snapshot) => formatDebugLog(snapshot);
}
