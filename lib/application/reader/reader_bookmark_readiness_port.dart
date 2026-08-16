/// Reader-facing application boundary for bookmark availability.
abstract interface class ReaderBookmarkReadinessPort {
  bool get isReady;
}
