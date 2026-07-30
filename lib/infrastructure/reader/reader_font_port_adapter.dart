import '../../application/reader/reader_font_port.dart';
import '../../services/reader_font_loader.dart';

final class ReaderFontPortAdapter implements ReaderFontPort {
  const ReaderFontPortAdapter();

  @override
  String platformSansFamily() => ReaderFontLoader.platformSansFamily();

  @override
  List<String> cjkFallbackFamilies() => ReaderFontLoader.cjkFallbackFamilies();
}
