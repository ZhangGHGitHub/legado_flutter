/// Readiness state exposed by the database infrastructure boundary.
abstract interface class DatabaseStatusPort {
  bool get isReady;
}
