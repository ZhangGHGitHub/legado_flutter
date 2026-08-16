import '../../domain/ports/book_source_debug_port.dart';

/// 书源调试日志格式化能力。
abstract interface class SourceDebugFormatterPort {
  String format(BookSourceDebugSnapshot snapshot);
}
