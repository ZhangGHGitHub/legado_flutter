/// 从书签文案「书签 · 第3/10页」解析 0-based 页索引；无法解析时返回 null。
/// 仅作旧数据 fallback；新书签以 [NoteDto.chapterPos] 为准。
int? bookmarkPageIndexFromNote(String noteContent) {
  final m = RegExp(r'第(\d+)').firstMatch(noteContent);
  if (m == null) return null;
  final n = int.tryParse(m.group(1)!);
  if (n == null || n < 1) return null;
  return n - 1;
}

/// 在分页结果中定位包含 [chapterPos] 的页（对齐 Jingshiro TextPage.containPos）。
/// [pages] 为按顺序切分的正文页；返回 0-based 页索引。
int pageIndexForChapterPos(List<String> pages, int chapterPos) {
  if (pages.isEmpty) return 0;
  if (chapterPos <= 0) return 0;
  var offset = 0;
  for (var i = 0; i < pages.length; i++) {
    final end = offset + pages[i].length;
    if (chapterPos < end || i == pages.length - 1) {
      return i;
    }
    offset = end;
  }
  return pages.length - 1;
}

/// 横翻当前页在整章正文中的起始字符偏移。
int chapterPosForPageIndex(List<String> pages, int pageIndex) {
  if (pages.isEmpty || pageIndex <= 0) return 0;
  var offset = 0;
  final last = pageIndex.clamp(0, pages.length - 1);
  for (var i = 0; i < last; i++) {
    offset += pages[i].length;
  }
  return offset;
}
