# -*- coding: utf-8 -*-
import subprocess
from pathlib import Path

raw = subprocess.check_output(
    ["git", "show", "origin/cursor/s1-reader-content-fixes:lib/pages/reader/reader_page.dart"]
)
print("len", len(raw))
print("has utf8 bom", raw[:3] == b"\\xef\\xbb\\xbf")
# try encodings
for enc in ["utf-8", "gbk", "gb18030", "utf-8-sig"]:
    try:
        t = raw.decode(enc)
        ok = "加载中" in t or "翻页" in t or "本章" in t
        print(enc, "ok_markers", ok, "sample_line", [ln for ln in t.splitlines() if "_content" in ln][:1])
    except Exception as e:
        print(enc, "FAIL", e)

# Also check what encoding HEAD had before corruption - restore strategy:
# Take good Chinese from origin (correct encoding), apply structural diff from 86a4c4f

good_raw = raw
bad = Path("lib/pages/reader/reader_page.dart").read_bytes()
print("bad starts", bad[:80])
print("good starts", good_raw[:80])
