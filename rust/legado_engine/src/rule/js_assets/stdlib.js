var legadoResult = null;
var baseUrl = '';

var cache = {
  _mem: {},
  _ttl: {},
  putMemory: function(k, v) { cache._mem[String(k)] = String(v); },
  getFromMemory: function(k) { return cache._mem[String(k)] || ''; },
  deleteMemory: function(k) {
    delete cache._mem[String(k)];
    delete cache._ttl[String(k)];
  },
  put: function(k, v, seconds) {
    var key = String(k);
    cache._mem[key] = String(v);
    if (seconds && seconds > 0) {
      cache._ttl[key] = Date.now() + (seconds * 1000);
    } else {
      delete cache._ttl[key];
    }
  },
  get: function(k) {
    var key = String(k);
    var exp = cache._ttl[key];
    if (exp && Date.now() > exp) {
      delete cache._mem[key];
      delete cache._ttl[key];
      return '';
    }
    return cache._mem[key] || '';
  }
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

/** Legado Rhino `java.*` 子集 — 对称加密对齐 Hutool createSymmetricCrypto */
function _SymmetricCrypto(transformation, key, iv) {
  this.transformation = String(transformation || 'AES/CBC/PKCS5Padding');
  this.key = String(key == null ? '' : key);
  this.iv = String(iv == null ? '' : iv);
}
_SymmetricCrypto.prototype.encryptBase64 = function(data) {
  return __legado_aes_encrypt_b64(
    this.transformation,
    this.key,
    this.iv,
    String(data == null ? '' : data)
  );
};
_SymmetricCrypto.prototype.decryptStr = function(data) {
  return __legado_aes_decrypt_str(
    this.transformation,
    this.key,
    this.iv,
    String(data == null ? '' : data)
  );
};
_SymmetricCrypto.prototype.encrypt = function(data) {
  return this.encryptBase64(data);
};
_SymmetricCrypto.prototype.decrypt = function(data) {
  return this.decryptStr(data);
};

var java = {
  createSymmetricCrypto: function(transformation, key, iv) {
    return new _SymmetricCrypto(transformation, key, iv);
  },
  getWebViewUA: function() {
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  },
  timeToDateString: function(time) {
    try {
      var d = new Date(Number(time));
      return d.toISOString();
    } catch (e) {
      return String(time);
    }
  }
};
