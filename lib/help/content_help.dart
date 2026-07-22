import 'dart:math' as math;

/// 段落重排 — 对齐 Legado `ContentHelp.kt`
abstract final class ContentHelp {
  ContentHelp._();

  static const _markSentencesEnd = '？。！?!~';
  static const _markSentencesEndP = '.？。！?!~';
  static const _markSentencesMid = '.，、,—…';
  static const _markSentencesSay = '问说喊唱叫骂道着答';
  static const _markQuotationBefore = '，：,:';
  static const _markQuotation = '"“”';
  static const _markQuotationRight = '"”';
  static const _wordMaxLength = 16;

  static final _paragraphDialog = RegExp(r'^["“”][^"“”]+["“”]$');
  static final _reColonQuotes = RegExp('[:：][\\\'\\"\u2018\u201c\u201d]+');
  static final _random = math.Random();

  /// 段落重排算法入口。把整篇内容输入，连接错误的分段，再把每个段落调用其他方法重新切分
  static String reSegment(String content, String chapterName) {
    var content1 = content;
    final dict = _makeDict(content1);
    List<String> p = content1
        .replaceAll('&quot;', '“')
        .replaceAll(_reColonQuotes, '：“')
        .replaceAll(RegExp(r'["”“]+\s*["”“][\s"”“]*'), '”\n“')
        .split(RegExp(r'\n(\s*)'));

    var buffer = StringBuffer();
    buffer.write('  ');
    if (chapterName.trim() != p[0].trim()) {
      buffer.write(p[0].replaceAll(RegExp(r'[\u3000\s]+'), ''));
    }

    for (var i = 1; i < p.length; i++) {
      if (_match(_markSentencesEnd, _lastChar(buffer)) ||
          (_match(_markQuotationRight, _lastChar(buffer)) &&
              _match(_markSentencesEnd, _charAt(buffer, buffer.length - 2)))) {
        buffer.write('\n');
      }
      buffer.write(p[i].replaceAll(RegExp(r'[\u3000\s]'), ''));
    }

    p = buffer
        .toString()
        .replaceAll(RegExp(r'["”“]+\s*["”“]+'), '”\n“')
        .replaceAllMapped(
          RegExp(r'["”“]+(？。！?!~)[""”]+'),
          (match) => '”${match.group(1)}\n“',
        )
        .replaceAllMapped(
          RegExp(r'["”“]+(？。！?!~)([^"”“])'),
          (match) => '”${match.group(1)}\n${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([问说喊唱叫骂道着答])[\.。]'),
          (match) => '${match.group(1)}。\n',
        )
        .split('\n');

    buffer = StringBuffer();
    for (final s in p) {
      buffer.write('\n');
      buffer.write(_findNewLines(s, dict));
    }
    buffer = _reduceLength(buffer);
    content1 = buffer
        .toString()
        .replaceFirst(RegExp(r'^\s+'), '')
        .replaceAll(RegExp(r'\s*["”“]+\s*["”“][\s"”“]*'), '”\n“')
        .replaceAll(RegExp(r'[:：][”“"\s]+'), '：“')
        .replaceAllMapped(
          RegExp(r'\n["“”]([^\n"“”]+)([,:，：]["”“])([^\n"“”]+)'),
          (match) => '\n${match.group(1)}：“${match.group(3)}',
        )
        .replaceAll(RegExp(r'\n(\s*)'), '\n');
    return content1;
  }

  static StringBuffer _reduceLength(StringBuffer str) {
    final p = str.toString().split('\n');
    final l = p.length;
    final b = List<bool>.filled(l, false);
    for (var i = 0; i < l; i++) {
      b[i] = _paragraphDialog.hasMatch(p[i]);
    }
    var dialogue = 0;
    for (var i = 0; i < l; i++) {
      if (b[i]) {
        if (dialogue < 0) {
          dialogue = 1;
        } else if (dialogue < 2) {
          dialogue++;
        }
      } else {
        if (dialogue > 1) {
          p[i] = _splitQuote(p[i]);
          dialogue--;
        } else if (dialogue > 0 && i < l - 2) {
          if (b[i + 1]) p[i] = _splitQuote(p[i]);
        }
      }
    }
    final string = StringBuffer();
    for (var i = 0; i < l; i++) {
      string.write('\n');
      string.write(p[i]);
    }
    return string;
  }

  static String _splitQuote(String str) {
    final length = str.length;
    if (length < 3) return str;
    if (_match(_markQuotation, str[0])) {
      final i = _seekIndex(str, _markQuotation, 1, length - 2, true) + 1;
      if (i > 1) {
        if (!_match(_markQuotationBefore, str[i - 1])) {
          return '${str.substring(0, i)}\n${str.substring(i)}';
        }
      }
    } else if (_match(_markQuotation, str[length - 1])) {
      final i =
          length - 1 - _seekIndex(str, _markQuotation, 1, length - 2, false);
      if (i > 1) {
        if (!_match(_markQuotationBefore, str[i - 1])) {
          return '${str.substring(0, i)}\n${str.substring(i)}';
        }
      }
    }
    return str;
  }

  static List<int> _forceSplit(
    String str,
    int offset,
    int min,
    int gain,
    int tigger,
  ) {
    final result = <int>[];
    final arrayEnd = _seekIndexes(
      str,
      _markSentencesEndP,
      0,
      str.length - 2,
      true,
    );
    final arrayMid = _seekIndexes(
      str,
      _markSentencesMid,
      0,
      str.length - 2,
      true,
    );
    if (arrayEnd.length < tigger && arrayMid.length < tigger * 3) {
      return result;
    }
    var j = 0;
    var i = min;
    while (i < arrayEnd.length) {
      var k = 0;
      while (j < arrayMid.length) {
        if (arrayMid[j] < arrayEnd[i]) k++;
        j++;
      }
      if (_random.nextDouble() * gain < 0.8 + k / 2.5) {
        result.add(arrayEnd[i] + offset);
        i = math.max(i + min, i);
      }
      i++;
    }
    return result;
  }

  static String _findNewLines(String str, List<String> dict) {
    final stringChars = str.split('');
    final arrayQuote = <int>[];
    var insN = <int>[];
    final mod = List<int>.filled(str.length, 0);
    var waitClose = false;

    for (var i = 0; i < str.length; i++) {
      final c = str[i];
      if (_match(_markQuotation, c)) {
        final size = arrayQuote.length;

        if (size > 0) {
          final quotePre = arrayQuote[size - 1];
          if (i - quotePre == 2) {
            var remove = false;
            if (waitClose) {
              if (_match(',，、/', str[i - 1])) {
                remove = true;
              }
            } else if (_match(',，、/和与或', str[i - 1])) {
              remove = true;
            }
            if (remove) {
              stringChars[i] = '“';
              stringChars[i - 2] = '”';
              arrayQuote.removeAt(size - 1);
              mod[size - 1] = 1;
              mod[size] = -1;
              continue;
            }
          }
        }
        arrayQuote.add(i);

        if (i > 1) {
          final charB1 = str[i - 1];
          var charB2 = '';
          if (_match(_markQuotationBefore, charB1)) {
            if (arrayQuote.length > 1) {
              final lastQuote = arrayQuote[arrayQuote.length - 2];
              var p = 0;
              if (charB1 == ',' || charB1 == '，') {
                if (arrayQuote.length > 2) {
                  p = arrayQuote[arrayQuote.length - 3];
                  if (p > 0) {
                    charB2 = str[p - 1];
                  }
                }
              }
              if (_match(_markSentencesEndP, charB2)) {
                insN.add(p - 1);
              } else if (!_match('的', charB2)) {
                final lastEnd = _seekLast(str, _markSentencesEnd, i, lastQuote);
                if (lastEnd > 0) {
                  insN.add(lastEnd);
                } else {
                  insN.add(lastQuote);
                }
              }
            }
            waitClose = true;
            mod[size] = 1;
            if (size > 0) {
              mod[size - 1] = -1;
              if (size > 1) {
                mod[size - 2] = 1;
              }
            }
          } else if (waitClose) {
            waitClose = false;
            insN.add(i);
          }
        }
      }
    }

    final size = arrayQuote.length;
    var opend = false;
    if (size > 0) {
      for (var i = 0; i < size; i++) {
        if (mod[i] > 0) {
          opend = true;
        } else if (mod[i] < 0) {
          if (!opend) {
            if (i > 0) mod[i] = 3;
          }
          opend = false;
        } else {
          opend = !opend;
          if (opend) {
            mod[i] = 2;
          } else {
            mod[i] = -2;
          }
        }
      }
      if (opend) {
        if (arrayQuote[size - 1] - stringChars.length > -3) {
          if (size > 1) mod[size - 2] = 4;
          mod[size - 1] = -4;
        } else if (!_match(
          _markSentencesSay,
          stringChars[stringChars.length - 2],
        )) {
          stringChars.add('”');
        }
      }

      var loop2Mod1 = -1;
      var i = 0;
      var j = arrayQuote[0] - 1;
      if (j < 0) {
        i = 1;
        loop2Mod1 = 0;
      }
      while (i < size) {
        j = arrayQuote[i] - 1;
        final loop2Mod2 = mod[i];
        if (loop2Mod1 < 0 && loop2Mod2 > 0) {
          if (_match(_markSentencesEnd, stringChars[j])) insN.add(j);
        }
        loop2Mod1 = loop2Mod2;
        i++;
      }
    }

    final insN1 = <int>[];
    for (final i in insN) {
      if (_match('"\'”“', stringChars[i])) {
        final start = _seekLast(str, '"\'”“', i - 1, i - _wordMaxLength);
        if (start > 0) {
          final word = str.substring(start + 1, i);
          if (dict.contains(word)) {
            continue;
          } else {
            if (_match('的地得', str[start])) {
              continue;
            }
          }
        }
      }
      insN1.add(i);
    }
    insN = insN1;

    insN = insN.toSet().toList()..sort();
    {
      var progress = 0;
      var nextLine = -1;
      var j = 0;
      if (insN.isNotEmpty) nextLine = insN[j];
      var gain = 3;
      var min = 0;
      var trigger = 2;
      for (var i = 0; i < arrayQuote.length; i++) {
        final qutoe = arrayQuote[i];
        if (qutoe > 0) {
          gain = 4;
          min = 2;
          trigger = 4;
        } else {
          gain = 3;
          min = 0;
          trigger = 2;
        }

        while (j < insN.length) {
          if (nextLine >= qutoe) break;
          nextLine = insN[j];
          if (progress < nextLine) {
            final subs = stringChars.join().substring(progress, nextLine);
            insN.addAll(_forceSplit(subs, progress, min, gain, trigger));
            progress = nextLine + 1;
          }
          j++;
        }
        if (progress < qutoe) {
          final subs = stringChars.join().substring(progress, qutoe + 1);
          insN.addAll(_forceSplit(subs, progress, min, gain, trigger));
          progress = qutoe + 1;
        }
      }
      while (j < insN.length) {
        nextLine = insN[j];
        if (progress < nextLine) {
          final subs = stringChars.join().substring(progress, nextLine);
          insN.addAll(_forceSplit(subs, progress, min, gain, trigger));
          progress = nextLine + 1;
        }
        j++;
      }
      if (progress < stringChars.length) {
        final subs = stringChars.join().substring(progress);
        insN.addAll(_forceSplit(subs, progress, min, gain, trigger));
      }
    }

    final insQuote = List<bool>.filled(size, false);
    opend = false;
    for (var i = 0; i < size; i++) {
      final p = arrayQuote[i];
      if (mod[i] > 0) {
        stringChars[p] = '“';
        if (opend) insQuote[i] = true;
        opend = true;
      } else if (mod[i] < 0) {
        stringChars[p] = '”';
        opend = false;
      } else {
        opend = !opend;
        if (opend) {
          stringChars[p] = '“';
        } else {
          stringChars[p] = '”';
        }
      }
    }
    insN = insN.toSet().toList()..sort();

    final string = stringChars.join();
    final buffer = StringBuffer();
    var j = 0;
    var progress = 0;
    var nextLine = -1;
    if (insN.isNotEmpty) nextLine = insN[j];
    for (var i = 0; i < arrayQuote.length; i++) {
      final quote = arrayQuote[i];

      while (j < insN.length) {
        if (nextLine >= quote) break;
        nextLine = insN[j];
        buffer.write(string.substring(progress, nextLine + 1));
        buffer.write('\n');
        progress = nextLine + 1;
        j++;
      }
      if (progress < quote) {
        buffer.write(string.substring(progress, quote + 1));
        progress = quote + 1;
      }
      if (insQuote[i] && buffer.length > 2) {
        final bufStr = buffer.toString();
        if (bufStr[bufStr.length - 1] == '\n') {
          buffer.write('“');
        } else {
          buffer
            ..clear()
            ..write(bufStr.substring(0, bufStr.length - 1))
            ..write('”\n')
            ..write(bufStr[bufStr.length - 1]);
        }
      }
    }
    while (j < insN.length) {
      nextLine = insN[j];
      if (progress <= nextLine) {
        buffer.write(string.substring(progress, nextLine + 1));
        buffer.write('\n');
        progress = nextLine + 1;
      }
      j++;
    }
    if (progress < string.length) {
      buffer.write(string.substring(progress));
    }
    return buffer.toString();
  }

  static List<String> _makeDict(String str) {
    final pattern = RegExp(r'''(?<=["'“”])([^\n]{1,16})(?=["'“”])''');
    final cache = <String>[];
    final dict = <String>[];
    for (final match in pattern.allMatches(str)) {
      final word = match.group(0)!;
      if (word.runes.any(_isUnicodePunctuation)) continue;
      if (cache.contains(word)) {
        if (!dict.contains(word)) dict.add(word);
      } else {
        cache.add(word);
      }
    }
    return dict;
  }

  static bool _isUnicodePunctuation(int codePoint) {
    return (codePoint >= 0x21 && codePoint <= 0x2f) ||
        (codePoint >= 0x3a && codePoint <= 0x40) ||
        (codePoint >= 0x5b && codePoint <= 0x60) ||
        (codePoint >= 0x7b && codePoint <= 0x7e) ||
        (codePoint >= 0x2000 && codePoint <= 0x206f) ||
        (codePoint >= 0x2e00 && codePoint <= 0x2eff) ||
        (codePoint >= 0x3000 && codePoint <= 0x303f) ||
        (codePoint >= 0xfe10 && codePoint <= 0xfe6f) ||
        (codePoint >= 0xff01 && codePoint <= 0xff65);
  }

  static List<int> _seekIndexes(
    String str,
    String key,
    int from,
    int to,
    bool inOrder,
  ) {
    final list = <int>[];
    if (str.length - from < 1) return list;
    var i = 0;
    if (from > 0) i = from;
    var t = str.length;
    if (to > 0) t = math.min(t, to);
    while (i < t) {
      final c = inOrder ? str[i] : str[str.length - i - 1];
      if (key.indexOf(c) != -1) {
        if (list.isNotEmpty && i - list.last == 1) {
          list[list.length - 1] = i;
        } else {
          list.add(i);
        }
      }
      i++;
    }
    return list;
  }

  static int _seekLast(String str, String key, int from, int to) {
    if (str.length - from < 1) return -1;
    var i = str.length - 1;
    if (from < i && i > 0) i = from;
    var t = 0;
    if (to > 0) t = to;
    while (i > t) {
      final c = str[i];
      if (key.indexOf(c) != -1) {
        return i;
      }
      i--;
    }
    return -1;
  }

  static int _seekIndex(
    String str,
    String key,
    int from,
    int to,
    bool inOrder,
  ) {
    if (str.length - from < 1) return -1;
    var i = 0;
    if (from > 0) i = from;
    var t = str.length;
    if (to > 0) t = math.min(t, to);
    while (i < t) {
      final c = inOrder ? str[i] : str[str.length - i - 1];
      if (key.indexOf(c) != -1) {
        return i;
      }
      i++;
    }
    return -1;
  }

  static bool _match(String rule, String chr) {
    return rule.indexOf(chr) != -1;
  }

  static String _lastChar(StringBuffer buffer) {
    final s = buffer.toString();
    return s[s.length - 1];
  }

  static String _charAt(StringBuffer buffer, int index) {
    return buffer.toString()[index];
  }
}
