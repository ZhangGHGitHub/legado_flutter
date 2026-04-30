import sys
with open('lib/services/rule_engine.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Step 1: Replace the empty check and split section
old = """    // 检测轴（保留 // 前缀让 step parser 处理）
    if (s.isEmpty) return steps;

    // 按 / 分割（但不分割 [] 内部）
    final parts = <String>[];
    int depth = 0;
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '[') depth++;
      if (ch == ']') depth--;
      if (ch == '/' && depth == 0) {
        parts.add(buf.toString());
        buf = StringBuffer();
      } else {
        buf.write(ch);
      }
    }
    parts.add(buf.toString());

    // 过滤空的部分并处理前缀 // 和 /
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      // 第一个非空部分之前的空部分数量决定 // 或 / 前缀
      // 但因为 // 被拆成了 ['', '', 'div...'], 第一个 '' 对应 /
      // 两个 '' 对应 //，所以检查前导空部分数量
      steps.add(_XPathStep.parse(part));
    }"""

new = """    // 检测轴
    String firstAxis = 'child';
    if (s.startsWith('//')) {
      firstAxis = 'descendant';
      s = s.substring(2);
    } else if (s.startsWith('/')) {
      s = s.substring(1);
    }
    if (s.isEmpty) return steps;

    // 按 / 分割（但不分割 [] 内部）
    final parts = <String>[];
    int depth = 0;
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '[') depth++;
      if (ch == ']') depth--;
      if (ch == '/' && depth == 0) {
        parts.add(buf.toString());
        buf = StringBuffer();
      } else {
        buf.write(ch);
      }
    }
    parts.add(buf.toString());

    for (final part in parts) {
      if (part.isEmpty) continue;
      steps.add(_XPathStep.parse(part));
    }"""

if old in content:
    content = content.replace(old, new)
    print('Step 1 OK')
else:
    print('Step 1 NOT_FOUND')
    idx = content.find('检测轴')
    print(repr(content[idx:idx+50]))

# Step 2: Fix queryAll to use firstAxis
old2 = """    // 检查最后一步是否为提取终端 (text(), @attr)
      final last = steps.last;
      if (last.isTerminal) {
        // 前 N-1 步定位元素
        List<dom.Element> current = [root];
        for (int i = 0; i < steps.length - 1; i++) {
          current = _applyStep(current, steps[i]);"""

new2 = """    // 检查最后一步是否为提取终端 (text(), @attr)
      final last = steps.last;
      if (last.isTerminal) {
        // 前 N-1 步定位元素
        List<dom.Element> current = [root];
        for (int i = 0; i < steps.length - 1; i++) {
          current = _applyStep(current, steps[i]);"""

# No change needed for Step 2 - wait, that's not in _parseSteps.
# Let me check queryAll in XPathParser

# Actually, I also need to make sure the first step's axis from _parseSteps
# is used. Let me add that before parsing.

# Step 2: After parsing steps, set first step's axis
old3 = """    for (final part in parts) {
      if (part.isEmpty) continue;
      steps.add(_XPathStep.parse(part));
    }

    return steps;
  }

  /// 对元素列表应用一个 XPath 步骤"""

new3 = """    for (final part in parts) {
      if (part.isEmpty) continue;
      final step = _XPathStep.parse(part);
      steps.add(step);
    }

    // 设置第一个步骤的轴
    if (steps.isNotEmpty && firstAxis != 'child') {
      final first = steps[0];
      steps[0] = _XPathStep(
        axis: firstAxis,
        tagName: first.tagName,
        predicates: first.predicates,
      );
    }

    return steps;
  }

  /// 对元素列表应用一个 XPath 步骤"""

if old3 in content:
    content = content.replace(old3, new3)
    print('Step 2 OK')
else:
    print('Step 2 NOT_FOUND')
    idx = content.find('parts.add(buf.toString())')
    print('Found at', idx)
    if idx >= 0:
        print(repr(content[idx:idx+300]))

with open('lib/services/rule_engine.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done')
