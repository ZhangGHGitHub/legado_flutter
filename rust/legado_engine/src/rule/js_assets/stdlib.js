var legadoResult = null;
var baseUrl = '';

var cache = {
  _mem: {},
  putMemory: function(k, v) { cache._mem[String(k)] = String(v); },
  getFromMemory: function(k) { return cache._mem[String(k)] || ''; }
};

function base64Decode(str) {
  try {
    var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
    var output = '';
    var bytes = [];
    for (var i = 0; i < str.length; i++) {
      var c = str.charAt(i);
      if (c === '=') break;
      var idx = chars.indexOf(c);
      if (idx === -1) continue;
      bytes.push(idx);
    }
    var buf = [];
    for (var i = 0; i < bytes.length; i += 4) {
      var b1 = bytes[i], b2 = bytes[i+1]||0, b3 = bytes[i+2]||0, b4 = bytes[i+3]||0;
      buf.push((b1 << 2) | (b2 >> 4));
      if (b3 !== 0) buf.push(((b2 & 0xF) << 4) | (b3 >> 2));
      if (b4 !== 0) buf.push(((b3 & 0x3) << 6) | b4);
    }
    for (var i = 0; i < buf.length; i++) output += String.fromCharCode(buf[i]);
    return output;
  } catch(e) { return ''; }
}

function javaTimeNow() { return new Date().getTime(); }
function currentTime() { return javaTimeNow(); }

function replaceRegex(str, pattern, replacement) {
  try {
    var flags = 'gm';
    if (pattern.startsWith('/')) {
      var end = pattern.lastIndexOf('/');
      if (end > 0) {
        flags = pattern.substring(end + 1) || 'gm';
        pattern = pattern.substring(1, end);
      }
    }
    return String(str).replace(new RegExp(pattern, flags), replacement);
  } catch(e) { return String(str); }
}

function getDomain(url) {
  try {
    var m = String(url).match(/https?:\/\/([^\/]+)/);
    return m ? m[1] : '';
  } catch(e) { return ''; }
}

function baseUrlFn(url) {
  try {
    var m = String(url).match(/^(https?:\/\/[^\/]+)/);
    return m ? m[1] : '';
  } catch(e) { return ''; }
}

function parseUrl(url, base) {
  if (String(url).startsWith('http')) return String(url);
  var b = baseUrlFn(base);
  if (String(url).startsWith('/')) return b + url;
  return b + '/' + url;
}
