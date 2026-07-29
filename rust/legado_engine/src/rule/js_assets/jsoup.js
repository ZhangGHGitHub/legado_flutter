var Packages = {
  org: {
    jsoup: {
      Jsoup: {
        __javaName: 'Jsoup',
        parse: function(html) {
          return new _JsoupDocument(String(html || ''));
        }
      },
      nodes: { Element: Element },
      select: { Elements: _JsoupElements }
    }
  },
  com: {
    jayway: {
      jsonpath: {}
    }
  }
};
var org = Packages.org;

function _JsonPathDocument(value) {
  this._value = value;
}
_JsonPathDocument.prototype.read = function(path) {
  if (typeof __legado_jsonpath_read !== 'function') return null;
  path = String(path || '');
  var normalizedPath = _normalizeJaywayPath(path);
  if (normalizedPath.indexOf('..') >= 0) {
    return _readRecursiveJaywayPath(this._value, normalizedPath);
  }
  var raw = __legado_jsonpath_read(JSON.stringify(this._value), normalizedPath);
  try {
    var value = JSON.parse(raw);
    if (normalizedPath.indexOf('[*]') >= 0) {
      if (Array.isArray(value)) return value;
      return value == null ? [] : [value];
    }
    return value;
  } catch (_) {
    return null;
  }
};

function _normalizeJaywayPath(path) {
  return String(path || '').replace(/\](?=[A-Za-z_$])/g, '].');
}

function _simplePathTokens(path) {
  if (!path || path[0] !== '$' || path.indexOf('..') >= 0) return null;
  var tokens = [];
  var i = 1;
  while (i < path.length) {
    if (path[i] === '.') {
      i++;
      var propertyStart = i;
      while (i < path.length && path[i] !== '.' && path[i] !== '[') i++;
      if (propertyStart === i) return null;
      tokens.push({ type: 'property', value: path.substring(propertyStart, i) });
      continue;
    }
    if (path[i] === '[') {
      var end = path.indexOf(']', i + 1);
      if (end < 0) return null;
      var index = path.substring(i + 1, end).trim();
      if (index === '*') tokens.push({ type: 'wildcard' });
      else if (/^\d+$/.test(index)) tokens.push({ type: 'index', value: Number(index) });
      else return null;
      i = end + 1;
      continue;
    }
    return null;
  }
  return tokens;
}

function _simplePathValues(root, path) {
  var tokens = _simplePathTokens(path);
  if (tokens == null) return null;
  var values = [root];
  for (var i = 0; i < tokens.length; i++) {
    var token = tokens[i];
    var next = [];
    for (var k = 0; k < values.length; k++) {
      var value = values[k];
      if (token.type === 'property') {
        if (value != null && typeof value === 'object' &&
            Object.prototype.hasOwnProperty.call(value, token.value)) {
          next.push(value[token.value]);
        }
      } else if (token.type === 'index') {
        if (Array.isArray(value) && token.value < value.length) next.push(value[token.value]);
      } else if (token.type === 'wildcard' && Array.isArray(value)) {
        for (var n = 0; n < value.length; n++) next.push(value[n]);
      }
    }
    values = next;
  }
  return values;
}

function _collectRecursiveProperty(value, name, results) {
  if (value == null || typeof value !== 'object') return;
  if (!Array.isArray(value) && Object.prototype.hasOwnProperty.call(value, name)) {
    results.push(value[name]);
  }
  if (Array.isArray(value)) {
    for (var i = 0; i < value.length; i++) _collectRecursiveProperty(value[i], name, results);
  } else {
    for (var key in value) {
      if (Object.prototype.hasOwnProperty.call(value, key)) {
        _collectRecursiveProperty(value[key], name, results);
      }
    }
  }
}

function _readRecursiveJaywayPath(root, path) {
  var recursiveAt = path.indexOf('..');
  var prefix = path.substring(0, recursiveAt);
  var tail = path.substring(recursiveAt + 2);
  var propertyEnd = tail.search(/[.\[]/);
  var property = propertyEnd < 0 ? tail : tail.substring(0, propertyEnd);
  var suffix = propertyEnd < 0 ? '' : tail.substring(propertyEnd);
  var prefixValues = _simplePathValues(root, prefix);
  if (!property || prefixValues == null) return [];

  var recursiveValues = [];
  for (var i = 0; i < prefixValues.length; i++) {
    _collectRecursiveProperty(prefixValues[i], property, recursiveValues);
  }
  if (!suffix) return recursiveValues;

  var results = [];
  for (var k = 0; k < recursiveValues.length; k++) {
    var matches = _simplePathValues(recursiveValues[k], '$' + suffix);
    if (matches != null) {
      for (var n = 0; n < matches.length; n++) results.push(matches[n]);
    }
  }
  return results;
}

var _JsonPathPackage = Packages.com.jayway.jsonpath;
_JsonPathPackage.Option = { SUPPRESS_EXCEPTIONS: 'SUPPRESS_EXCEPTIONS' };
_JsonPathPackage.Configuration = {
  builder: function() {
    return {
      options: function() { return this; },
      build: function() { return {}; }
    };
  }
};
_JsonPathPackage.JsonPath = {
  using: function() {
    return {
      parse: function(value) {
        var parsed = typeof value === 'string' ? JSON.parse(value) : value;
        return new _JsonPathDocument(parsed);
      }
    };
  }
};

function JavaImporter() {
  if (!(this instanceof JavaImporter)) {
    var importer = Object.create(JavaImporter.prototype);
    JavaImporter.apply(importer, arguments);
    return importer;
  }
  for (var i = 0; i < arguments.length; i++) {
    var packageObject = arguments[i] || {};
    var className = packageObject.__javaName;
    if (className) {
      this[className] = packageObject;
      globalThis[className] = packageObject;
      continue;
    }
    for (var key in packageObject) {
      this[key] = packageObject[key];
      globalThis[key] = packageObject[key];
    }
  }
}

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
_JsoupDocument.prototype.html = function() {
  return _nodeInnerHtml(this._root);
};

function Element(nodeOrTag) {
  this._node = typeof nodeOrTag === 'string'
    ? _elementNode(nodeOrTag)
    : nodeOrTag;
}
Element.__javaName = 'Element';
Element.prototype.select = function(sel) {
  return new _JsoupElements(_selectAll(this._node, sel));
};
Element.prototype.selectFirst = function(sel) {
  var els = this.select(sel);
  return els.size() > 0 ? els.get(0) : null;
};
Element.prototype.text = function(value) {
  if (arguments.length > 0) {
    this._node.children = [];
    _appendNode(this._node, _textNode(String(value)));
    return this;
  }
  return _nodeText(this._node).trim();
};
Element.prototype.attr = function(name, value) {
  if (!this._node || !this._node.attrs) return '';
  if (arguments.length > 1) {
    this._node.attrs[String(name)] = String(value);
    return this;
  }
  return this._node.attrs[name] || this._node.attrs[name.toLowerCase()] || '';
};
/** Jsoup Element.html() → inner HTML（不含自身标签） */
Element.prototype.html = function() {
  return _nodeInnerHtml(this._node);
};
Element.prototype.remove = function() {
  _detachNode(this._node);
  return this;
};
Element.prototype.before = function(content) {
  _insertRelative(this._node, content, false);
  return this;
};
Element.prototype.after = function(content) {
  _insertRelative(this._node, content, true);
  return this;
};
Element.prototype.replaceWith = function(content) {
  _replaceNode(this._node, content);
  return this;
};
Element.prototype.appendChild = function(child) {
  if (child && child._node) _appendNode(this._node, child._node);
  return this;
};
Element.prototype.appendText = function(text) {
  _appendNode(this._node, _textNode(String(text)));
  return this;
};

function _JsoupElements(arr) {
  this._arr = arr || [];
}
_JsoupElements.__javaName = 'Elements';
_JsoupElements.prototype.size = function() { return this._arr.length; };
_JsoupElements.prototype.get = function(i) { return this._arr[i] || null; };
_JsoupElements.prototype.text = function() {
  return this._arr.map(function(item) { return item.text(); }).join(' ').trim();
};
_JsoupElements.prototype.html = function() {
  return this._arr.map(function(item) { return item.html(); }).join('');
};
_JsoupElements.prototype.remove = function() {
  this._arr.slice().forEach(function(item) { item.remove(); });
  return this;
};
_JsoupElements.prototype.before = function(content) {
  this._arr.slice().forEach(function(item) { item.before(content); });
  return this;
};
_JsoupElements.prototype.after = function(content) {
  this._arr.slice().forEach(function(item) { item.after(content); });
  return this;
};
_JsoupElements.prototype.replaceWith = function(content) {
  this._arr.slice().forEach(function(item) { item.replaceWith(content); });
  return this;
};
_JsoupElements.prototype[Symbol.iterator] = function() {
  return this._arr[Symbol.iterator]();
};

function _parseAttrs(str) {
  var attrs = {};
  var re = /([\w-]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|(\S+)))?/g;
  var m;
  while ((m = re.exec(str)) !== null) {
    attrs[m[1]] = m[2] !== undefined ? m[2] : (m[3] !== undefined ? m[3] : (m[4] || ''));
  }
  return attrs;
}

function _textNode(text) {
  return { tag: '#text', attrs: {}, children: [], text: text || '', parent: null };
}

function _elementNode(tag) {
  return {
    tag: String(tag || 'div').toLowerCase(),
    attrs: {},
    children: [],
    text: '',
    parent: null
  };
}

function _detachNode(node) {
  if (!node || !node.parent) return;
  var siblings = node.parent.children || [];
  var index = siblings.indexOf(node);
  if (index >= 0) siblings.splice(index, 1);
  node.parent = null;
}

function _appendNode(parent, node) {
  if (!parent || !node) return;
  _detachNode(node);
  parent.children = parent.children || [];
  parent.children.push(node);
  node.parent = parent;
}

function _contentNodes(content) {
  if (content && content._node) return [content._node];
  var html = String(content == null ? '' : content);
  if (html.indexOf('<') < 0) return [_textNode(html)];
  return _parseHtml(html).children.slice();
}

function _insertRelative(reference, content, after) {
  if (!reference || !reference.parent) return;
  var parent = reference.parent;
  var index = parent.children.indexOf(reference);
  if (index < 0) return;
  if (after) index++;
  var nodes = _contentNodes(content);
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    _detachNode(node);
    parent.children.splice(index++, 0, node);
    node.parent = parent;
  }
}

function _replaceNode(reference, content) {
  if (!reference || !reference.parent) return;
  var parent = reference.parent;
  var index = parent.children.indexOf(reference);
  if (index < 0) return;
  parent.children.splice(index, 1);
  reference.parent = null;
  var nodes = _contentNodes(content);
  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];
    _detachNode(node);
    parent.children.splice(index++, 0, node);
    node.parent = parent;
  }
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
    // children 按文档顺序混排元素与文本；勿再单独累加 node.text
    var node = { tag: tagName, attrs: _parseAttrs(attrStr), children: [], text: '', parent: null };
    if (selfClose || tagName === 'br' || tagName === 'img' || tagName === 'input' || tagName === 'hr' || tagName === 'meta' || tagName === 'link') {
      return node;
    }
    while (i < html.length) {
      if (html.substring(i, i + 2 + tagName.length).toLowerCase() === '</' + tagName) {
        var closeEnd = html.indexOf('>', i);
        i = closeEnd >= 0 ? closeEnd + 1 : html.length;
        break;
      }
      if (html[i] === '<') {
        var child = parseElement();
        if (child) _appendNode(node, child);
        else {
          // 非本标签的闭合/坏标签：跳过该 '<'，避免死循环
          var nextBad = html.indexOf('<', i + 1);
          if (nextBad < 0) {
            _appendNode(node, _textNode(html.substring(i)));
            i = html.length;
            break;
          }
          _appendNode(node, _textNode(html.substring(i, nextBad)));
          i = nextBad;
        }
      } else {
        var next = html.indexOf('<', i);
        if (next < 0) next = html.length;
        var text = html.substring(i, next);
        if (text) _appendNode(node, _textNode(text));
        i = next;
      }
    }
    return node;
  }
  var children = [];
  while (i < html.length) {
    skipWs();
    if (i >= html.length) break;
    if (html[i] === '<') {
      var el = parseElement();
      if (el) children.push(el);
      else i++;
    } else {
      var nextRoot = html.indexOf('<', i);
      if (nextRoot < 0) nextRoot = html.length;
      var rootText = html.substring(i, nextRoot);
      if (rootText) children.push(_textNode(rootText));
      i = nextRoot;
    }
  }
  var root = { tag: '#root', attrs: {}, children: [], text: '', parent: null };
  for (var k = 0; k < children.length; k++) _appendNode(root, children[k]);
  return root;
}

function _nodeText(node) {
  if (!node) return '';
  if (node.tag === '#text') return node.text || '';
  var t = '';
  for (var i = 0; i < (node.children || []).length; i++) {
    t += _nodeText(node.children[i]);
  }
  return t;
}

function _nodeInnerHtml(node) {
  if (!node) return '';
  var sb = '';
  for (var i = 0; i < (node.children || []).length; i++) {
    sb += _nodeOuterHtml(node.children[i]);
  }
  return sb;
}

function _nodeOuterHtml(node) {
  if (!node) return '';
  if (node.tag === '#text') return node.text || '';
  if (node.tag === '#root') return _nodeInnerHtml(node);
  var attrs = node.attrs || {};
  var attrStr = '';
  for (var k in attrs) attrStr += ' ' + k + '="' + attrs[k] + '"';
  var voidTags = { br: 1, img: 1, input: 1, hr: 1, meta: 1, link: 1 };
  if (voidTags[node.tag]) {
    return '<' + node.tag + attrStr + ' />';
  }
  return '<' + node.tag + attrStr + '>' + _nodeInnerHtml(node) + '</' + node.tag + '>';
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
  var step = { tag: '*', id: null, cls: null, attrs: [], has: null };
  var hasMatch = part.match(/:has\(([^()]*)\)/);
  if (hasMatch) {
    step.has = hasMatch[1].trim();
    part = part.replace(hasMatch[0], '');
  }
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
  if (!node || node.tag === '#text') return false;
  if (node.tag === '#root') return false;
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
  if (step.has && _selectAll(node, step.has).length === 0) return false;
  return true;
}

function _selectAll(node, sel) {
  var selectors = String(sel || '').split(',');
  var acc = [];
  function walk(n, depth, steps, groupAcc) {
    if (!n || n.tag === '#text') return;
    if (depth < steps.length) {
      var step = steps[depth];
      if (_matchStep(n, step)) {
        if (depth === steps.length - 1) {
          if (!groupAcc.some(function(item) { return item._node === n; })) {
            groupAcc.push(new Element(n));
          }
        } else {
          for (var i = 0; i < (n.children || []).length; i++) {
            walk(n.children[i], depth + 1, steps, groupAcc);
          }
        }
      }
      for (var k = 0; k < (n.children || []).length; k++) {
        walk(n.children[k], depth, steps, groupAcc);
      }
    }
  }
  for (var i = 0; i < selectors.length; i++) {
    var steps = _parseSelector(selectors[i]);
    if (steps.length) walk(node, 0, steps, acc);
  }
  return acc;
}
