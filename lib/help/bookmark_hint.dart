/// 从书签文案「书签 · 第3/10页」解析 0-based 页索引；无法解析时返回 null。
int? bookmarkPageIndexFromNote(String noteContent) {
  final m = RegExp(r'第(\d+)').firstMatch(noteContent);
  if (m == null) return null;
  final n = int.tryParse(m.group(1)!);
  if (n == null || n < 1) return null;
  return n - 1;
}
