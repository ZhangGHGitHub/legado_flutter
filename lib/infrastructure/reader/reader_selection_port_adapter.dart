import '../../application/reader/reader_selection_port.dart';
import '../../services/reader_selection_browser.dart';
import '../../services/reader_selection_share.dart';

/// 委托既有选区浏览和分享规范的适配器。
final class ReaderSelectionPortAdapter implements ReaderSelectionPort {
  const ReaderSelectionPortAdapter();

  @override
  Uri? browserUri(String selectedText) =>
      readerSelectionBrowserUri(selectedText);

  @override
  bool isAbsoluteWebUrl(String selectedText) =>
      readerSelectionIsAbsoluteWebUrl(selectedText);

  @override
  String get shareSubject => readerSelectionShareSubject;

  @override
  String? shareText(String selectedText) =>
      readerSelectionShareText(selectedText);

  @override
  Future<bool> tryNativeWebSearch(String selectedText) =>
      tryNativeReaderWebSearch(selectedText);
}
