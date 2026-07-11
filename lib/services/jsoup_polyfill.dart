/// Legado 书源 JS 中常用的 Jsoup API 兼容层（QuickJS 环境）
/// 与 rust/legado_engine/src/rule/js_assets/jsoup.js 保持同步
const String jsoupPolyfill = r'''
var Packages = {
  org: {
    jsoup: {
      Jsoup: {
        parse: function(html) {
          return new _JsoupDocument(String(html || ''));
        }
      }
    }
  }
};

function _JsoupDocument(html) {
  this._root = _parseHtml(html);
}
_JsoupDocument.prototype.select = function(sel) {
  return new _JsoupElements(_selectAll(this._root, sel));
};
_JsoupDocument.prototype.selectFirst = function(sel) {
  var els = this.select(sel);
  return els.size() > 0 ? els.get(0) : null;
};

function _JsoupElement(node) {
  this._node = node;
}
_JsoupElement.prototype.select = function(sel) {
  return new _JsoupElements(_selectAll(this._node, sel));
};
_JsoupElement.prototype.selectFirst = function(sel) {
  var els = this.select(sel);
  return els.size() > 0 ? els.get(0) : null;
};
_JsoupElement.prototype.text = function() {
  return _nodeText(this._node).trim();
};
_JsoupElement.prototype.attr = function(name) {
  if (!this._node || !this._node.attrs) return '';
  return this._node.attrs[name] || this._node.attrs[name.toLowerCase()] || '';
};
_JsoupElement.prototype.html = function() {
  return _nodeHtml(this._node);
};

function _JsoupElements(arr) {
  this._arr = arr || [];
}
_JsoupElements.prototype.size = function() { return this._arr.length; };
_JsoupElements.prototype.get = function(i) { return this._arr[i] || null; };

function _parseAttrs(str) {
  var attrs = {};
  var re = /([\w-]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|(\S+)))?/g;
  var m;
  while ((m = re.exec(str)) !== null) {
    attrs[m[1]] = m[2] !== undefined ? m[2] : (m[3] !== undefined ? m[3] : (m[4] || ''));
  }
  return attrs;
}

function _parseHtml(html) {
  html = html || '';
  var i = 0;
  function skipWs() {
    while (i < html.length && /\s/.test(html[i])) i++;
  }
  function parseElement() {
    skipWs();
    if (i >= html.length || html[i] !== '<') return null;
    var end = html.indexOf('>', i);
    if (end < 0) return null;
    var tagStr = html.substring(i + 1, end).trim();
    i = end + 1;
    if (tagStr.startsWith('!') || tagStr.startsWith('?')) return parseElement();
    if (tagStr.startsWith('/')) return null;
    var selfClose = tagStr.endsWith('/');
    if (selfClose) tagStr = tagStr.substring(0, tagStr.length - 1).trim();
    var sp = tagStr.indexOf(' ');
    var tagName = (sp > 0 ? tagStr.substring(0, sp) : tagStr).toLowerCase();
    var attrStr = sp > 0 ? tagStr.substring(sp + 1) : '';
    var node = { tag: tagName, attrs: _parseAttrs(attrStr), children: [], text: '' };
    if (selfClose || tagName === 'br' || tagName === 'img' || tagName === 'input') return node;
    while (i < html.length) {
      skipWs();
      if (html.substring(i, i + 2 + tagName.length).toLowerCase() === '</' + tagName) {
        var closeEnd = html.indexOf('>', i);
        i = closeEnd >= 0 ? closeEnd + 1 : html.length;
        break;
      }
      if (html[i] === '<') {
        var child = parseElement();
        if (child) node.children.push(child);
        else {
          var next = html.indexOf('<', i + 1);
          if (next < 0) { node.text += html.substring(i); break; }
          i++;
        }
      } else {
        var next = html.indexOf('<', i);
        if (next < 0) next = html.length;
        node.text += html.substring(i, next);
        i = next;
      }
    }
    return node;
  }
  var children = [];
  while (i < html.length) {
    skipWs();
    if (html[i] === '<') {
      var el = parseElement();
      if (el) children.push(el);
      else i++;
    } else {
      var next = html.indexOf('<', i);
      if (next < 0) break;
      i = next;
    }
  }
  return { tag: '#root', attrs: {}, children: children, text: '' };
}

function _nodeText(node) {
  if (!node) return '';
  var t = node.text || '';
  for (var i = 0; i < (node.children || []).length; i++) {
    t += _nodeText(node.children[i]);
  }
  return t;
}

function _nodeHtml(node) {
  if (!node) return '';
  if (node.tag === '#root') {
    var sb = '';
    for (var i = 0; i < (node.children || []).length; i++) {
      sb += _nodeHtml(node.children[i]);
    }
    return sb;
  }
  var attrs = node.attrs || {};
  var attrStr = '';
  for (var k in attrs) attrStr += ' ' + k + '="' + attrs[k] + '"';
  var inner = node.text || '';
  for (var j = 0; j < (node.children || []).length; j++) {
    inner += _nodeHtml(node.children[j]);
  }
  return '<' + node.tag + attrStr + '>' + inner + '</' + node.tag + '>';
}

function _parseAttrSelector(raw) {
  var m = raw.match(/^([^\]=]+)(\*=|=)(.+)$/);
  if (!m) return null;
  var val = m[3].trim();
  if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
    val = val.substring(1, val.length - 1);
  }
  return { name: m[1].trim(), op: m[2], value: val };
}

function _parseSelectorPart(part) {
  part = part.trim();
  if (!part) return null;
  var step = { tag: '*', id: null, cls: null, attrs: [] };
  var attrRe = /\[([^\]]+)\]/g;
  var am;
  while ((am = attrRe.exec(part)) !== null) {
    var attr = _parseAttrSelector(am[1]);
    if (attr) step.attrs.push(attr);
  }
  part = part.replace(/\[([^\]]+)\]/g, '');
  var hash = part.indexOf('#');
  if (hash >= 0) {
    var after = part.substring(hash + 1);
    var cut = after.search(/[.\[]/);
    step.id = cut >= 0 ? after.substring(0, cut) : after;
    part = part.substring(0, hash) + (cut >= 0 ? after.substring(cut) : '');
  }
  var dot = part.indexOf('.');
  if (dot >= 0) {
    var afterCls = part.substring(dot + 1);
    var cutCls = afterCls.search(/[.\[]/);
    step.cls = cutCls >= 0 ? afterCls.substring(0, cutCls) : afterCls;
    part = part.substring(0, dot);
  }
  part = part.trim();
  if (part && part !== '*') step.tag = part.toLowerCase();
  return step;
}

function _parseSelector(sel) {
  return sel.trim().split(/\s+/).map(_parseSelectorPart).filter(Boolean);
}

function _attrValue(node, name) {
  if (!node || !node.attrs) return '';
  return node.attrs[name] || node.attrs[name.toLowerCase()] || '';
}

function _matchStep(node, step) {
  if (!node || node.tag === '#root') {
    return step.tag === '*';
  }
  if (step.tag !== '*' && node.tag !== step.tag) return false;
  if (step.id && _attrValue(node, 'id') !== step.id) return false;
  if (step.cls) {
    var cls = (_attrValue(node, 'class') || '').split(/\s+/);
    if (cls.indexOf(step.cls) < 0) return false;
  }
  for (var i = 0; i < step.attrs.length; i++) {
    var a = step.attrs[i];
    var val = _attrValue(node, a.name);
    if (a.op === '=' && val !== a.value) return false;
    if (a.op === '*=' && val.indexOf(a.value) < 0) return false;
  }
  return true;
}

function _selectAll(node, sel) {
  var steps = _parseSelector(sel);
  if (!steps.length) return [];
  function walk(n, depth, acc) {
    if (!n) return;
    if (depth < steps.length) {
      var step = steps[depth];
      if (_matchStep(n, step)) {
        if (depth === steps.length - 1) {
          acc.push(new _JsoupElement(n));
        } else {
          for (var i = 0; i < (n.children || []).length; i++) {
            walk(n.children[i], depth + 1, acc);
          }
        }
      }
      if (step.tag === '*' || n.tag === '#root') {
        for (var j = 0; j < (n.children || []).length; j++) {
          walk(n.children[j], depth, acc);
        }
      } else {
        for (var k = 0; k < (n.children || []).length; k++) {
          walk(n.children[k], depth, acc);
        }
      }
    }
  }
  var acc = [];
  walk(node, 0, acc);
  return acc;
}
''';
