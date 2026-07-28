import '../../models/rss_source.dart';

abstract interface class RssSortUrlJsPort {
  bool get isAvailable;

  String evaluate({required RssSource source, required String script});
}
