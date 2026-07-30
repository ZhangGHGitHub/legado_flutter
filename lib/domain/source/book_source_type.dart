import 'book_source.dart';

extension BookSourceTypeSemantics on BookSource {
  /// 书源类型为图片/漫画（兼容 Legado 的数值和文本表示）。
  bool get isImageSource {
    final type = bookSourceType.trim().toLowerCase();
    return type == '2' || type == 'image' || type == '漫画' || type == '图片';
  }
}
