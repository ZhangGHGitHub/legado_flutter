import '../../domain/rss/rss_source.dart';
import '../../domain/source/book_source.dart';

/// RSS 源进入既有登录流程时的应用层转换边界。
abstract interface class RssLoginPort {
  BookSource bookSourceForRss(RssSource source);
}
