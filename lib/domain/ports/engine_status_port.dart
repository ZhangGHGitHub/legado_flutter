/// Application-facing status exposed by the book-source engine.
///
/// Pages use this small contract instead of depending on the FRB bridge.
abstract interface class EngineStatusPort {
  bool get isAvailable;

  String get engineVersion;
}
