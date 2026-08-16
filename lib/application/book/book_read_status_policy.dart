/// 阅读轮次的中文展示策略。
abstract final class BookReadStatusPolicy {
  static String? labelForReadIteration(int readIteration) {
    if (readIteration <= 0) return null;
    if (readIteration == 1) return '读完';
    if (readIteration.isOdd) {
      return '${(readIteration + 1) ~/ 2}刷完';
    }
    return '${readIteration ~/ 2 + 1}刷';
  }
}
