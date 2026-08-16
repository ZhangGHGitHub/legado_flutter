import 'package:legado_flutter/domain/source/book_source.dart';

/// 书源市场数据读取端口。
abstract interface class SourceMarketPort {
  Future<List<BookSource>> loadSources();
}
