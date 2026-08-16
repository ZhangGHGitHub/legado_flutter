import '../../application/rss/rss_login_port.dart';
import '../../domain/rss/rss_source.dart';
import '../../domain/source/book_source.dart';
import '../../services/source_login_service.dart';

/// 复用既有 SourceLoginService 的 RSS 登录目标适配器。
final class RssLoginPortAdapter implements RssLoginPort {
  const RssLoginPortAdapter();

  @override
  BookSource bookSourceForRss(RssSource source) =>
      SourceLoginService.bookSourceForRss(source);
}
