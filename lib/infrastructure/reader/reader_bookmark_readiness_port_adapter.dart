import '../../application/reader/reader_bookmark_readiness_port.dart';
import '../../services/bookmark_service.dart';

/// Exposes the existing bookmark service readiness through the reader port.
final class ReaderBookmarkReadinessPortAdapter
    implements ReaderBookmarkReadinessPort {
  const ReaderBookmarkReadinessPortAdapter();

  @override
  bool get isReady => BookmarkService.isReady;
}
