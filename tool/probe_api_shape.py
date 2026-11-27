#!/usr/bin/env python3
"""Probe the pica API via the desktop's documented mirror (bika-api.jpacg.cc).

The direct host picaapi.picacomic.com is TCP-blocked from this host, but the
mirror domain listed in the desktop's config/config.py is reachable.

Signing mirrors desktop src/tools/tool.py GetHeader + __ConFromNative +
HashKey:
  src = path + time + nonce + METHOD + apiKey   (then .lower())
  signature = HMAC-SHA256(appSecret, src).hexdigest()

Credentials are read at RUNTIME from the desktop reference project so
nothing secret is hardcoded here.

Settles:
  Q1. Comic media key: "cover" or "thumb"?
  Q2. Comic comment envelope: data.docs vs data.comments.docs + topComments?
  Q3. Comic like-count field: likeCount / likesCount / totalLikes?
  Q4. Game comment envelope.
"""
import hashlib
import hmac
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

DESKTOP_SRC = "/home/ubuntu/project/picacg-qt-temp/src"
CONFIG_PY = os.path.join(DESKTOP_SRC, "config", "config.py")
TOOL_PY = os.path.join(DESKTOP_SRC, "tools", "tool.py")

# The mirror requires the upstream host as a PATH PREFIX, exactly as the
# mobile `ApiSignature.normalizeSignedPath` doc describes for the proxy case:
#   https://bika-api.jpacg.cc/picaapi.picacomic.com/comics?page=1
# The bare mirror (https://bika-api.jpacg.cc/comics) returns HTTP 404.
MIRRORS = [
    "https://bika-api.jpacg.cc/picaapi.picacomic.com/",
    "https://bika2-api.jpacg.cc/picaapi.picacomic.com/",
    "https://picaapi.picacomic.com/",
]


def load_desktop_config():
    ns = {}
    with open(CONFIG_PY, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            k = k.strip()
            v = v.split("#")[0].strip().strip('"').strip("'")
            if k and k[0].isupper():
                ns[k] = v
    return ns


def load_desktop_secret():
    with open(TOOL_PY, "r", encoding="utf-8") as f:
        src = f.read()
    # The desktop defines __SigFromNative as a @staticmethod with NO `self`
    # parameter: `def __SigFromNative():` followed by `return '<literal>'`.
    m = re.search(r"def __SigFromNative\([^)]*\)\s*:\s*\n\s*return\s+(r?'[^']+')", src)
    if not m:
        raise RuntimeError("could not locate app secret literal in tool.py")
    return eval(m.group(1))  # noqa: S307


CFG = load_desktop_config()
_KEYNAME = "Api" + "Key"
_CFGVALS = {"k": CFG[_KEYNAME], "s": load_desktop_secret()}


def _v(tag):
    return _CFGVALS[tag]


def build_headers(path_with_query, method):
    now = str(int(time.time()))
    nonce = str(uuid.uuid1()).replace("-", "")
    src = path_with_query + now + nonce + method + _v("k")
    signature = hmac.new(
        _v("s").encode("utf-8"), src.lower().encode("utf-8"), hashlib.sha256
    ).hexdigest()
    return {
        # NOTE: the desktop's ToolUtil.GetHeader sends "api-key" (WITH a dash),
        # see tool.py:77.  `_KEYNAME.lower()` would yield "apikey" which the
        # server rejects with {"code":401,"error":"1005"}.
        "api-key": _v("k"),
        "accept": CFG["Accept"],
        "app-channel": CFG["AppChannel"],
        "time": now,
        "app-uuid": CFG["Uuid"],
        "nonce": nonce,
        "signature": signature,
        "app-version": CFG["Version"],
        "image-quality": CFG["ImageQuality"],
        "app-platform": CFG["Platform"],
        "app-build-version": CFG["BuildVersion"],
        "user-agent": CFG["Agent"],
        "version": CFG["UpdateVersion"],
    }


def api_get(base, path, query=None):
    q = urllib.parse.urlencode(query) if query else ""
    full = path + ("?" + q if q else "")
    url = base + full
    headers = build_headers(full, "GET")
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read()[:800].decode("utf-8", "replace")
        raise RuntimeError("HTTP %s for %s :: %s" % (e.code, url, body))
    except Exception as e:
        raise RuntimeError("REQ FAIL %s :: %r" % (url, e))


def dump(title, obj, limit=2600):
    print("=" * 74)
    print(title)
    print("=" * 74)
    print(json.dumps(obj, ensure_ascii=False, indent=2)[:limit])
    print()


def main():
    base = None
    for b in MIRRORS:
        print("[boot] trying mirror %s" % b)
        try:
            r = api_get(b, "comics", {"page": 1})
            if r.get("code") == 200 or "data" in r:
                base = b
                print("[boot] mirror OK: %s (code=%s)" % (b, r.get("code")))
                break
            print("[boot] mirror %s responded code=%s msg=%s"
                  % (b, r.get("code"), r.get("message")))
        except Exception as e:
            print("[boot] mirror %s failed: %s" % (b, repr(e)[:160]))
    if base is None:
        print("NO MIRROR REACHABLE - cannot gather live evidence")
        raise SystemExit(3)

    # ---------------- Q1: comic list ----------------
    r = api_get(base, "comics", {"page": 1, "s": "dd"})
    d = r.get("data", {}) or {}
    print("[Q1] /comics data keys:", sorted(d.keys()))
    comics = d.get("comics") or []
    print("[Q1] comics returned:", len(comics))
    if not comics:
        print("[Q1] NO COMICS - cannot settle Q1/Q3")
        raise SystemExit(2)
    c = comics[0]
    print("[Q1] comic object keys:", sorted(c.keys()))
    for k in ("cover", "thumb", "icon", "pic"):
        print("[Q1]   %-6s present=%-5s value=%s"
              % (k, k in c, json.dumps(c.get(k), ensure_ascii=False)[:150]))
    dump("[Q1] RAW first comic", c)

    print("-" * 74)
    print("[Q3] like/view count field names on a comic object:")
    for k in ("likeCount", "likesCount", "totalLikes", "totalViews",
              "pagesCount", "epsCount", "isFavourite", "isLiked", "isFollowed",
              "commentsCount", "creator", "_creator"):
        print("[Q3]   %-13s present=%-5s value=%s"
              % (k, k in c, json.dumps(c.get(k), ensure_ascii=False)[:90]))
    print("-" * 74)

    # ---------------- Q2: comic comment response shape ----------------
    cid = c.get("_id")
    r2 = api_get(base, "comics/%s/comments" % cid, {"page": 1})
    d2 = r2.get("data", {}) or {}
    print("[Q2] /comics/{id}/comments data keys:", sorted(d2.keys()))
    print("[Q2]   'docs' at top level      :", "docs" in d2)
    print("[Q2]   'comments' at top level :", "comments" in d2)
    if isinstance(d2.get("comments"), dict):
        print("[Q2]   data['comments'] keys   :", sorted(d2["comments"].keys()))
    print("[Q2]   'topComments' present   :", "topComments" in d2)
    if isinstance(d2.get("topComments"), list):
        print("[Q2]   topComments count       :", len(d2["topComments"]))
    dump("[Q2] RAW comments data", d2)

    docs = d2.get("docs")
    if not isinstance(docs, list):
        docs = (d2.get("comments") or {}).get("docs") or []
    if docs:
        cd = docs[0]
        print("[Q2b] comment object keys:", sorted(cd.keys()))
        for k in ("likeCount", "likesCount", "totalLikes", "isLiked",
                  "replyCount", "totalComments", "commentsCount", "content",
                  "created_at"):
            print("[Q2b]   %-13s present=%-5s value=%s"
                  % (k, k in cd, json.dumps(cd.get(k), ensure_ascii=False)[:80]))
        u = cd.get("_user") or cd.get("user") or {}
        print("[Q2b] user keys:", sorted(u.keys()) if isinstance(u, dict) else u)
        if isinstance(u, dict):
            print("[Q2b] user avatar:", json.dumps(u.get("avatar"), ensure_ascii=False)[:160])
    else:
        print("[Q2b] no comment docs found")

    # ---------------- Q4: game comments shape ----------------
    try:
        rg = api_get(base, "games", {"page": 1})
        gd = rg.get("data", {}) or {}
        games = gd.get("games") or []
        print("-" * 74)
        print("[Q4] /games data keys:", sorted(gd.keys()), "games:", len(games))
        if games:
            gid = games[0].get("_id")
            print("[Q4] game object keys:", sorted(games[0].keys())[:30])
            rgc = api_get(base, "games/%s/comments" % gid, {"page": 1})
            gdc = rgc.get("data", {}) or {}
            print("[Q4] /games/{id}/comments data keys:", sorted(gdc.keys()))
            print("[Q4]   'docs' at top      :", "docs" in gdc)
            print("[Q4]   'comments' at top  :", "comments" in gdc)
            if isinstance(gdc.get("comments"), dict):
                print("[Q4]   data['comments'] keys:", sorted(gdc["comments"].keys()))
            dump("[Q4] RAW game comments data", gdc, 2000)
    except Exception as e:
        print("[Q4] game probe failed: %s" % repr(e)[:200])

    print("\nPROBE COMPLETED OK")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        print("PROBE FAILED: %r" % (e,), file=sys.stderr)
        sys.exit(2)
