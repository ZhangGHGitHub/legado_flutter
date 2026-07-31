/// Privacy consent persistence boundary for the application layer.
abstract interface class PrivacyConsentPort {
  Future<bool> isAccepted();

  Future<bool> saveAccepted();
}

/// Application-only fallback used before the composition root supplies storage.
final class UnavailablePrivacyConsentPort implements PrivacyConsentPort {
  const UnavailablePrivacyConsentPort();

  @override
  Future<bool> isAccepted() => Future.value(false);

  @override
  Future<bool> saveAccepted() => Future.value(false);
}
