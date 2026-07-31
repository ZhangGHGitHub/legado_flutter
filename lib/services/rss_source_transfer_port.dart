// Compatibility exports for callers that still use the former service path.
import '../application/rss/rss_source_transfer_port.dart';

export '../application/rss/rss_source_transfer_port.dart';
export '../infrastructure/rss/rss_source_transfer_port_adapter.dart';

typedef PlatformRssSourceTransfer = RssSourceTransferPort;
