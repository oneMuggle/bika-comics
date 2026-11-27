#!/usr/bin/env python3
"""Find a header combination the server actually accepts WITH DATA.

Established facts (batch 63):
  * The API host IS reachable (Cloudflare / nginx), contradicting every
    prior batch's "network unreachable" conclusion.
  * The server's own error body names the real blocker:
        code=400 error="必須更新！"  ("you must update")
        detail -> https://download.wikawika.xyz/apps/2.2.0.0.1.1.apk
    i.e. a CLIENT-VERSION gate, not a network problem and not (primarily)
    a signature problem.
  * The desktop and the mobile BOTH send app-version=2.2.1.3.3.4 /
    app-build-version=45 / version=v1.5.4.

This script sweeps the version-related headers against a matrix of plausible
values and prints every distinct (status, body) it sees, flagging any
response that carries a "data" key.

Exit 0 = at least one combination returned a data-bearing response.
Exit 2 = none did (the gate is not satisfiable with the tried values).
"""
import hashlib
import hmac
import itertools
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid as uuidmod
from collections import Counter

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

HOST = "https://picaapi.picacomic.com/"
PATH = "comics?page=1"

APP_VERSIONS = [
    "2.2.1.3.3.4",     # what desktop + mobile currently send
    "2.2.0.0.1.1",     # the APK the server's own error points at
    "2.2.1.3.3.5",
    "2.2.1.3.4.0",
    "2.2.1.3.3.4.1",
]

BUILD_VERSIONS = ["45", "1", "2"]

CLIENT_VERSIONS = ["v1.5.4", "v2.0.0"]


def hmac_hex(text):
    return hmac.new(MATERIAL.encode("utf-8"), text.lower().encode("utf-8"),
                    hashlib.sha256).hexdigest()


def fire(app_version, build_version, client_version, path=PATH):
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    src = path + now + nonce + "GET" + KEY
    headers = {
        "api-key": KEY,
        "accept": CFG["Accept"],
        "app-channel": CFG["AppChannel"],
        "time": now,
        "app-uuid": CFG["Uuid"],
        "nonce": nonce,
        "signature": hmac_hex(src),
        "app-version": app_version,
        "image-quality": CFG["ImageQuality"],
        "app-platform": CFG["Platform"],
        "app-build-version": build_version,
        "user-agent": CFG["Agent"],
        "version": client_version,
    }
    req = urllib.request.Request(HOST + path, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        return None, repr(e)[:120].encode()


def classify(body):
    try:
        j = json.loads(body.decode("utf-8", "replace"))
    except Exception:
        return "NON-JSON", None
    if not isinstance(j, dict):
        return "JSON-NONDICT", None
    code = j.get("code")
    err = j.get("error")
    has_data = "data" in j
    detail = j.get("detail") or ""
    tag = "code=%s" % code
    if err:
        tag += " err=%s" % err
    if has_data:
        d = j.get("data")
        tag += " HAS_DATA(%s)" % (list(d.keys())[:6] if isinstance(d, dict)
                                  else "list")
    else:
        tag += " NO_DATA"
    return tag, detail


def main():
    seen = Counter()
    with_data = []
    print("sweeping app-version x app-build-version x client-version")
    for av, bv, cv in itertools.product(APP_VERSIONS, BUILD_VERSIONS,
                                         CLIENT_VERSIONS):
        status, body = fire(av, bv, cv)
        tag, detail = classify(body)
        seen[(status, tag)] += 1
        if "HAS_DATA" in tag:
            with_data.append((av, bv, cv, status, tag))
            print("  *** DATA FOUND: app-version=%s build=%s version=%s -> %s"
                  % (av, bv, cv, tag))
            sys.stdout.flush()
        time.sleep(0.25)

    print("\n=== distinct outcomes ===")
    sys.stdout.flush()
    for (status, tag), n in seen.most_common():
        print("  %-5s %-60s x%d" % (status, tag, n))

    print("\n=== version detail from the server's own message ===")
    status, body = fire(APP_VERSIONS[0], BUILD_VERSIONS[0], CLIENT_VERSIONS[0])
    try:
        j = json.loads(body.decode("utf-8", "replace"))
        print(json.dumps(j, ensure_ascii=False, indent=2)[:1200])
    except Exception:
        print(body[:400])

    if not with_data:
        print("\nNO COMBINATION RETURNED DATA")
        raise SystemExit(2)
    print("\n%d COMBINATIONS RETURNED DATA" % len(with_data))


if __name__ == "__main__":
    main()
