#!/usr/bin/env python3
"""RAW body dump + Host-header test against the reachable mirrors.

What we know so far:
  * direct  https://picaapi.picacomic.com/   -> Network unreachable (egress block)
  * wikawika                                 -> HTTP 521
  * mirror  https://bika-api.jpacg.cc/picaapi.picacomic.com/ -> HTTP 200
        body summary was: {"code":200,"message":"success"}   (NO "data" key)

An API that answers 200 with no payload is suspicious. Three hypotheses:

  H1  The body really has no data (server needs something else).
  H2  The response body is gzip/br-encoded and urllib didn't decode it
      (but then json.loads would have failed, and we DID parse code=200).
  H3  The mirror routes by the HTTP Host header. We sent Host:
      bika-api.jpacg.cc, but the upstream expects Host: picaapi.picacomic.com.
      The mirror forwards and the upstream answers "success" with an empty
      body because it did not recognise the route.

H3 is the most likely and is directly testable: send the same request with
an explicit `Host: picaapi.picacomic.com` header.

This script prints the RAW body (repr, so nothing is hidden) for every
variant, so we can see exactly what the server sent back.
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

MIRROR = "https://bika-api.jpacg.cc/picaapi.picacomic.com/"
PATH = "comics?page=1"


def hmac_hex(text):
    return hmac.new(MATERIAL.encode("utf-8"), text.lower().encode("utf-8"),
                    hashlib.sha256).hexdigest()


def build(signed_source, extra_headers=None, key_name="api-key"):
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    h = {
        key_name: KEY,
        "accept": CFG["Accept"],
        "app-channel": CFG["AppChannel"],
        "time": now,
        "app-uuid": CFG["Uuid"],
        "nonce": nonce,
        "signature": hmac_hex(signed_source),
        "app-version": CFG["Version"],
        "image-quality": CFG["ImageQuality"],
        "app-platform": CFG["Platform"],
        "app-build-version": CFG["BuildVersion"],
        "user-agent": CFG["Agent"],
        "version": CFG["UpdateVersion"],
    }
    if extra_headers:
        h.update(extra_headers)
    return h


def fire(label, url, headers):
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            body = resp.read()
            print("%-42s status=%s len=%d" % (label, resp.status, len(body)))
            print("    RAW: %r" % body[:700])
            return resp.status, body
    except urllib.error.HTTPError as e:
        body = e.read()
        print("%-42s status=%s len=%d" % (label, e.code, len(body)))
        print("    RAW: %r" % body[:500])
        return e.code, body
    except Exception as e:
        print("%-42s TRANSPORT-FAIL %r" % (label, repr(e)[:120]))
        return None, b""


def main():
    url = MIRROR + PATH

    print("### A. desktop-conformant signature, no extra headers")
    fire("desktop_full", url, build(PATH + "NOW", None))

    # The desktop signs path+time+nonce+method+apiKey. We must rebuild that
    # exactly, so build() needs the same time/nonce it signs with.
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    desktop_src = PATH + now + nonce + "GET" + KEY
    h = {
        "api-key": KEY,
        "accept": CFG["Accept"],
        "app-channel": CFG["AppChannel"],
        "time": now,
        "app-uuid": CFG["Uuid"],
        "nonce": nonce,
        "signature": hmac_hex(desktop_src),
        "app-version": CFG["Version"],
        "image-quality": CFG["ImageQuality"],
        "app-platform": CFG["Platform"],
        "app-build-version": CFG["BuildVersion"],
        "user-agent": CFG["Agent"],
        "version": CFG["UpdateVersion"],
    }
    print("\n### B. TRUE desktop algorithm (path+time+nonce+GET+key)")
    fire("desktop_true", url, h)

    print("\n### C. same but with explicit Host: picaapi.picacomic.com")
    h2 = dict(h)
    h2["Host"] = "picaapi.picacomic.com"
    fire("desktop_true+Host", url, h2)

    print("\n### D. signature over path only + explicit Host")
    h3 = build(PATH, {"Host": "picaapi.picacomic.com"})
    fire("path_only+Host", url, h3)

    print("\n### E. no signature header at all + explicit Host")
    h4 = build(PATH, {"Host": "picaapi.picacomic.com"})
    h4.pop("signature", None)
    fire("no_signature+Host", url, h4)

    print("\n### F. add 'token' header (desktop sends token only when logged in)")
    h5 = build(PATH, {"Host": "picaapi.picacomic.com", "token": ""})
    fire("with_token+Host", url, h5)

    print("\n### G. endpoint that certainly returns data: /categories")
    url2 = MIRROR + "categories"
    h6 = build("categories", {"Host": "picaapi.picacomic.com"})
    fire("categories+Host", url2, h6)

    print("\n### H. init?platform=android (desktop's very first request)")
    url3 = MIRROR + "init?platform=android"
    h7 = build("init?platform=android", {"Host": "picaapi.picacomic.com"})
    fire("init+Host", url3, h7)


if __name__ == "__main__":
    main()
