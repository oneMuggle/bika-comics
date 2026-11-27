#!/usr/bin/env python3
"""Reachability + response-shape survey across every API host we know of.

Hosts under test:
  * picaapi.picacomic.com   (desktop config.Url, and mobile defaultBaseUrl)
  * post-api.wikawika.xyz    (desktop config.ApiDomain[1])
  * bika-api.jpacg.cc       (desktop config.ProxyApiDomain, commented out)
  * bika2-api.jpacg.cc      (desktop config.ProxyApiDomain2, commented out)

For each (host x path-prefix x endpoint) we issue ONE request with the
DESKTOP's exact header set and record:
    status, body-snippet, and whether the body is JSON with a "data" key

The "code":200 responses we saw earlier carried NO "data" key, which means
the request was ACCEPTED but the endpoint returned nothing useful -- that is
still valuable: it proves auth passed.

Repeat each probe 2x so a flaky network does not masquerade as a verdict.

Exit 0 = at least one probe returned JSON with a "data" key.
Exit 2 = none did.
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid as uuidmod

DESKTOP_SRC = "/home/ubuntu/project/picacg-qt-temp/src"


def desktop_config():
    ns = {}
    with open(os.path.join(DESKTOP_SRC, "config", "config.py"), encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#") or "=" not in s:
                continue
            k, _, v = s.partition("=")
            k = k.strip()
            v = v.split("#")[0].strip().strip('"').strip("'")
            if k and k[0].isupper():
                ns[k] = v
    return ns


def desktop_signing_material():
    with open(os.path.join(DESKTOP_SRC, "tools", "tool.py"), encoding="utf-8") as f:
        src = f.read()
    m = re.search(r"def __SigFromNative\([^)]*\)\s*:\s*\n\s*return\s+(r?'[^']+')", src)
    if not m:
        raise RuntimeError("no secret")
    return eval(m.group(1))  # noqa: S307


CFG = desktop_config()
MATERIAL = desktop_signing_material()
KEY = CFG["ApiKey"]

HOSTS = [
    ("direct", "https://picaapi.picacomic.com/"),
    ("wikawika", "https://post-api.wikawika.xyz/"),
    ("jpacg1", "https://bika-api.jpacg.cc/picaapi.picacomic.com/"),
    ("jpacg2", "https://bika2-api.jpacg.cc/picaapi.picacomic.com/"),
    ("jpacg1bare", "https://bika-api.jpacg.cc/"),
]

ENDPOINTS = ["comics?page=1", "categories", "init?platform=android"]


def hmac_hex(text):
    import hashlib
    import hmac
    return hmac.new(MATERIAL.encode("utf-8"), text.lower().encode("utf-8"),
                    hashlib.sha256).hexdigest()


def headers_for(path):
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    return {
        "api-key": KEY,
        "accept": CFG["Accept"],
        "app-channel": CFG["AppChannel"],
        "time": now,
        "app-uuid": CFG["Uuid"],
        "nonce": nonce,
        "signature": hmac_hex(path + now + nonce + "GET" + KEY),
        "app-version": CFG["Version"],
        "image-quality": CFG["ImageQuality"],
        "app-platform": CFG["Platform"],
        "app-build-version": CFG["BuildVersion"],
        "user-agent": CFG["Agent"],
        "version": CFG["UpdateVersion"],
    }


def fetch(url):
    req = urllib.request.Request(url, headers=headers_for(
        url.split("//", 1)[1].split("/", 1)[1] if "//" in url else url))
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        return None, repr(e)[:200].encode()


def summarize(body):
    try:
        j = json.loads(body.decode("utf-8", "replace"))
    except Exception:
        txt = body.decode("utf-8", "replace")
        txt = " ".join(txt.split())[:70]
        return "NON-JSON: " + txt
    if not isinstance(j, dict):
        return "JSON non-dict"
    code = j.get("code")
    err = j.get("error")
    msg = j.get("message")
    out = "code=%s" % code
    if err:
        out += " error=%s" % err
    if msg:
        out += " msg=%s" % str(msg)[:40]
    d = j.get("data")
    if isinstance(d, dict):
        out += " data.keys=%s" % sorted(d.keys())[:6]
        for key in ("comics", "categories"):
            if isinstance(d.get(key), list):
                out += " %s=%d" % (key, len(d[key]))
    elif isinstance(d, list):
        out += " data=list(%d)" % len(d)
    return out


def main():
    with_data = []
    print("%-12s %-26s %-6s %-6s %s" % ("HOST", "PATH", "ATT", "STATUS", "SUMMARY"))
    for tag, base in HOSTS:
        for ep in ENDPOINTS:
            # The signed source is the path WITHOUT the host prefix.
            signed = ep
            url = base + signed
            for attempt in (1, 2):
                status, body = fetch(url)
                summ = summarize(body)
                if attempt == 2:
                    print("%-12s %-26s %-6s %-6s %s"
                          % (tag, signed, attempt, status, summ))
                if status == 200:
                    try:
                        j = json.loads(body.decode("utf-8", "replace"))
                        if isinstance(j.get("data"), (dict, list)):
                            with_data.append((tag, signed, status, summ))
                    except Exception:
                        pass
    print("\n=== probes returning JSON with a data key ===")
    if not with_data:
        print("  NONE")
        raise SystemExit(2)
    for row in with_data:
        print("  %s" % (row,))


if __name__ == "__main__":
    main()
