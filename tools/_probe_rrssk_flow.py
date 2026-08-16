"""Probe 可乐小说: AES search -> book -> toc -> content."""
from __future__ import annotations

import base64
import re
import time

import requests
import urllib3
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad

urllib3.disable_warnings()

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)
HDR = {
    "User-Agent": UA,
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "zh-CN,zh;q=0.9",
}


def aes_search_enc(keyword: str) -> str:
    key_str = b"lzxHpH8PLGXcrCIQ"
    key32 = key_str + b"\x00" * (32 - len(key_str))
    cipher = AES.new(key32, AES.MODE_CBC, key_str)
    enc = cipher.encrypt(pad(keyword.encode("utf-8"), 16))
    return base64.b64encode(enc).decode()


def is_challenge(html: str) -> bool:
    return "var cpk" in html or "X-GE-UA-Step" in html or "人人书云" in html


def compute_sum(cookie_value: str, nonce: int) -> int:
    total = 0
    for i, ch in enumerate(cookie_value):
        if ch.isalnum() and ch.isascii():
            total += ord(ch) * (nonce + i)
    return total


def pass_ge_ua(s: requests.Session, url: str, html: str) -> None:
    cookie = s.cookies.get("ge_ua_p")
    if not cookie:
        # requests may decode; try raw from jar
        for c in s.cookies:
            if c.name == "ge_ua_p":
                cookie = c.value
                break
    nonce = int(re.search(r"var nonce\s*=\s*(\d+)", html).group(1))
    step_m = re.search(r'var step\s*=\s*"([^"]+)"', html)
    step = step_m.group(1) if step_m else "prev"
    ssum = compute_sum(cookie, nonce)
    origin = "{uri.scheme}://{uri.netloc}".format(uri=requests.utils.urlparse(url))
    print(f"  GE-UA cookie={cookie!r} nonce={nonce} sum={ssum}")
    r2 = s.post(
        url,
        data={"sum": ssum, "nonce": nonce},
        headers={
            **HDR,
            "Content-Type": "application/x-www-form-urlencoded",
            "X-GE-UA-Step": step,
            "Origin": origin,
            "Referer": origin + "/",
            "Accept": "*/*",
            "Cookie": f"ge_ua_p={cookie}",
        },
        verify=False,
        timeout=30,
    )
    print("  GE-UA POST", r2.text[:120], "cookies", dict(s.cookies))
    time.sleep(0.8)


def get(s: requests.Session, url: str, referer: str | None = None) -> requests.Response:
    h = dict(HDR)
    if referer:
        h["Referer"] = referer
    r = s.get(url, headers=h, verify=False, timeout=30)
    if is_challenge(r.text):
        print(f"  challenge on {url}")
        pass_ge_ua(s, url, r.text)
        r = s.get(url, headers=h, verify=False, timeout=30)
    return r


def main() -> int:
    s = requests.Session()
    kw = "重生之"
    enc = aes_search_enc(kw)
    search_url = f"https://www.rrssk.com/k-{enc}.html"
    print("1 SEARCH", search_url)
    r = get(s, search_url)
    print("  status", r.status_code, "len", len(r.text), "challenge", is_challenge(r.text))
    print("  head:", r.text[:300].replace("\n", " "))
    ids = re.findall(r"upclick\('([^']+)'\)", r.text)
    print("  ids", len(ids), ids[:3])
    if not ids:
        # try other patterns
        ids = re.findall(r"/book/([A-Za-z0-9]+)\.html", r.text)
        print("  book ids fallback", ids[:5])
    if not ids:
        print("FAIL no book id")
        open("tools/_probe_search.html", "w", encoding="utf-8").write(r.text)
        return 1

    book_id = ids[0]
    book_url = f"https://www.kelexs.com/book/{book_id}.html"
    toc_url = f"https://www.kelexs.com/chapter/{book_id}.html"
    print("2 BOOK", book_url)
    rb = get(s, book_url, referer="https://www.rrssk.com/")
    print("  status", rb.status_code, "len", len(rb.text), "challenge", is_challenge(rb.text))
    print("  head:", rb.text[:400].replace("\n", " "))
    open("tools/_probe_book.html", "w", encoding="utf-8").write(rb.text)

    print("3 TOC", toc_url)
    rt = get(s, toc_url, referer=book_url)
    print("  status", rt.status_code, "len", len(rt.text), "challenge", is_challenge(rt.text))
    print("  head:", rt.text[:400].replace("\n", " "))
    open("tools/_probe_toc.html", "w", encoding="utf-8").write(rt.text)
    chap_links = re.findall(r'href="(/read/[^"]+)"', rt.text)
    print("  /read links", len(chap_links), chap_links[:3])
    li_count = len(re.findall(r"<li[\s>]", rt.text))
    print("  li count", li_count)
    chap_list = "chapList" in rt.text
    print("  has chapList", chap_list)

    if not chap_links:
        # from JSON style
        chap_links = re.findall(r'"chapterurl":"([^"]+)"', rt.text)
        print("  json chapterurl", len(chap_links), chap_links[:3])

    if chap_links:
        href = chap_links[0]
        if not href.startswith("http"):
            content_url = "https://www.kelexs.com" + href
        else:
            content_url = href
        print("4 CONTENT", content_url)
        rc = get(s, content_url, referer=toc_url)
        print("  status", rc.status_code, "len", len(rc.text), "challenge", is_challenge(rc.text))
        print("  head:", rc.text[:400].replace("\n", " "))
        open("tools/_probe_content.html", "w", encoding="utf-8").write(rc.text)
        has_content = 'class="content"' in rc.text or "content" in rc.text
        paras = re.findall(r"<p[^>]*>([^<]{10,})</p>", rc.text)
        print("  has content class", has_content, "p samples", len(paras), paras[:2])

    print("cookies", dict(s.cookies))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
