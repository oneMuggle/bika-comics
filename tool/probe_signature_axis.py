#!/usr/bin/env python3
"""DECISIVE A/B: does the server validate the `signature` header at all?

Batch-63 finding: sending "api-key" (WITH dash) yields HTTP 200, sending
"apikey" yields 401.  But the two probes that disagreed also used DIFFERENT
signed sources:

  probe_api_shape.py    -> path + time + nonce + METHOD + apiKey  (desktop-conformant)
  probe_auth_matrix.py  -> path only                              (NOT desktop-conformant)

So the 200 might be attributable to the key-header name OR to the shorter
signed source.  This script isolates the two axes:

  axis 1: header name    "api-key" vs "apikey"
  axis 2: signed source  desktop_full | path_only | garbage | empty | absent

If `garbage` / `absent` also return 200, the server does NOT validate the
signature and only the key-header name matters (meaning the mobile's
desktop-conformant signature is harmless but unnecessary).

If `desktop_full` is the ONLY one that returns 200, then the mobile's
implementation is correct and the server does validate.

Exit 0 = a discriminating result was obtained.
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

BASES = {
    "direct": "https://picaapi.picacomic.com/",
    "mirror": "https://bika-api.jpacg.cc/picaapi.picacomic.com/",
}

PATH = "comics?page=1"


def hmac_hex(text):
    return hmac.new(MATERIAL.encode("utf-8"), text.lower().encode("utf-8"),
                    hashlib.sha256).hexdigest()


def make_headers(key_header, sig_mode):
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    headers = {
        key_header: KEY,
        "accept": CFG["Accept"],
        "app-channel": CFG["AppChannel"],
        "time": now,
        "app-uuid": CFG["Uuid"],
        "nonce": nonce,
        "app-version": CFG["Version"],
        "image-quality": CFG["ImageQuality"],
        "app-platform": CFG["Platform"],
        "app-build-version": CFG["BuildVersion"],
        "user-agent": CFG["Agent"],
        "version": CFG["UpdateVersion"],
    }
    if sig_mode == "desktop_full":
        headers["signature"] = hmac_hex(PATH + now + nonce + "GET" + KEY)
    elif sig_mode == "path_only":
        headers["signature"] = hmac_hex(PATH)
    elif sig_mode == "garbage":
        headers["signature"] = "0" * 64
    elif sig_mode == "empty":
        headers["signature"] = ""
    elif sig_mode == "absent":
        pass
    else:
        raise ValueError(sig_mode)
    return headers


def fetch(base, headers):
    url = base + PATH
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read()[:300]
    except urllib.error.HTTPError as e:
        return e.code, e.read()[:300]
    except Exception as e:
        return None, repr(e)[:160].encode()


def main():
    rows = []
    for base_name, base in BASES.items():
        for key_header in ("api-key", "apikey"):
            for sig_mode in ("desktop_full", "path_only", "garbage", "empty",
                             "absent"):
                headers = make_headers(key_header, sig_mode)
                status, body = fetch(base, headers)
                label = "%-6s %-8s %-13s" % (base_name, key_header, sig_mode)
                snippet = body.decode("utf-8", "replace").replace("\n", " ")
                snippet = " ".join(snippet.split())[:90]
                rows.append((label, status, snippet))
                print("%-30s -> %-5s %s" % (label, status, snippet))

    print("\n=== verdict matrix (status per row) ===")
    for label, status, _ in rows:
        print("  %-30s %s" % (label, status))

    print("\n=== discrimination ===")
    by = {}
    for label, status, _ in rows:
        by[label.strip()] = status

    d = by.get("direct api-key    desktop_full")
    g = by.get("direct api-key    garbage")
    a = by.get("direct api-key    absent")
    p = by.get("direct api-key    path_only")
    print("  direct+api-key  desktop_full = %s" % d)
    print("  direct+api-key  path_only    = %s" % p)
    print("  direct+api-key  garbage      = %s" % g)
    print("  direct+api-key  absent       = %s" % a)
    if g == 200 and a == 200:
        print("\n  => SERVER DOES NOT VALIDATE THE SIGNATURE at all.")
        print("     Only the header NAME 'api-key' matters.")
    elif d == 200 and g != 200:
        print("\n  => SERVER DOES VALIDATE THE SIGNATURE, and only the")
        print("     desktop-conformant signed source is accepted.")
    print("\nOK")


if __name__ == "__main__":
    main()
