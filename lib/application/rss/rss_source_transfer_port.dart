/// File and clipboard operations used by RSS source management.
abstract interface class RssSourceTransferPort {
  Future<String?> pickImportText();

  Future<void> copyText(String text);
}
