import 'package:legado_flutter/domain/rss/rss_source.dart';

abstract interface class RssSortUrlJsPort {
  bool get isAvailable;

  String evaluate({required RssSource source, required String script});
}
