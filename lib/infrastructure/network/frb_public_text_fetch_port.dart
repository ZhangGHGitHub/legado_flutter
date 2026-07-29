import '../../domain/ports/public_text_fetch_port.dart';
import '../../src/rust/api/network.dart' as network_api;

class FrbPublicTextFetchPort implements PublicTextFetchPort {
  const FrbPublicTextFetchPort();

  @override
  Future<String> fetch(String url, {String userAgent = ''}) {
    return network_api.fetchPublicText(url: url, userAgent: userAgent);
  }
}
