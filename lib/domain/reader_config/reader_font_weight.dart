/// 字重存储值，对齐 legado textBold：0 正常、1 粗体、2 细体。
enum ReaderFontWeight {
  normal(0),
  bold(1),
  light(2);

  const ReaderFontWeight(this.code);

  final int code;

  static ReaderFontWeight fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return ReaderFontWeight.normal;
  }
}
