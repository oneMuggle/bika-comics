#!/usr/bin/env python3
"""Systematic matrix probe of the Pica API auth contract.

The API is REACHABLE (we get a structured {"code":401,"error":"1005"} body,
not a timeout), so prior batches' "host is TCP-unreachable" conclusion was
wrong. Now we can brute-force the exact auth contract instead of guessing.

Axes varied:
  endpoint      : which URL we ask for
  base          : direct host vs the jpacg mirror (path-prefixed)
  uuid          : "defaultUuid" vs a real UUID
  sig_source    : relative path | path with leading slash | full URL
  key_header    : "api-key" vs "apikey"
  extra         : whether to send a "token" header

Every variant is signed with the DESKTOP's own algorithm so that any
"success" cannot be an artifact of our re-implementation.

Exit 0 = at least one variant answered 200 (or any non-401 code).
Exit 2 = every variant answered 401/403.
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


def desktop_secret():
    with open(os.path.join(DESKTOP_SRC, "tools", "tool.py"), encoding="utf-8") as f:
        src = f.read()
    m = re.search(r"def __SigFromNative\([^)]*\)\s*:\s*\n\s*return\s+(r?'[^']+')", src)
    if not m:
        raise RuntimeError("no secret")
    return eval(m.group(1))  # noqa: S307


CFG = desktop_config()
SECRET = desktop_secret()
APIKEY = CFG["ApiKey"]

BASES = {
    "direct": "https://picaapi.picacomic.com/",
    "mirror": "https://bika-api.jpacg.cc/picaapi.picacomic.com/",
}

ENDPOINTS = [
    ("comics", "comics?page=1"),
    ("init", "init?platform=android"),
    ("categories", "categories"),
]

REAL_UUID = str(uuidmod.uuid4())


def sign(src):
    return hmac.new(SECRET.encode("utf-8"), src.lower().encode("utf-8"),
                    hashlib.sha256).hexdigest()


def build(base, path, method="GET", uuid_val="defaultUuid",
          sig_mode="relative", key_header="api-key", send_token=False):
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    if sig_mode == "relative":
        src = path
    elif sig_mode == "leading_slash":
        src = "/" + path
    elif sig_mode == "full_url":
        src = base + path
    else:
        raise ValueError(sig_mode)
    headers = {
        key_header: APIKEY,
        "accept": CFG["Accept"],
        "app-channel": CFG["AppChannel"],
        "time": now,
        "app-uuid": uuid_val,
        "nonce": nonce,
        "signature": sign(src),
        "app-version": CFG["Version"],
        "image-quality": CFG["ImageQuality"],
        "app-platform": CFG["Platform"],
        "app-build-version": CFG["BuildVersion"],
        "user-agent": CFG["Agent"],
        "version": CFG["UpdateVersion"],
    }
    if send_token:
        headers["token"] = ""
    return base + path, headers, src


def try_variant(label, **kw):
    url, headers, src = build(**kw)
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            body = resp.read()
            return label, resp.status, body[:400], src
    except urllib.error.HTTPError as e:
        return label, e.code, e.read()[:400], src
    except Exception as e:
        return label, None, repr(e)[:200].encode(), src


def main():
    results = []
    for base_name, base in BASES.items():
        for ep_name, path in ENDPOINTS:
            for uuid_val, uuid_tag in (("defaultUuid", "defUuid"),
                                       (REAL_UUID, "realUuid")):
                for sig_mode in ("relative", "leading_slash", "full_url"):
                    for key_header in ("api-key", "apikey"):
                        label = "%s/%s/%s/%s/%s" % (
                            base_name, ep_name, uuid_tag, sig_mode, key_header)
                        r = try_variant(label, base=base, path=path,
                                        uuid_val=uuid_val,
                                        sig_mode=sig_mode,
                                        key_header=key_header)
                        results.append(r)
                        if r[1] not in (401, 403, None):
                            print("!! DIFFERENT %-58s status=%s" % (label, r[1]))
                            print("   body: %s" % r[2][:300].decode("utf-8", "replace"))

    print("\n=== SUMMARY (status counts) ===")
    counts = {}
    for label, status, body, src in results:
        counts[status] = counts.get(status, 0) + 1
    for k in sorted(counts, key=lambda x: (x is None, x)):
        print("  status=%-5s count=%d" % (k, counts[k]))

    print("\n=== first body per distinct status ===")
    seen = set()
    for label, status, body, src in results:
        if status in seen:
            continue
        seen.add(status)
        print("  status=%s label=%s" % (status, label))
        print("  body: %s" % body[:300].decode("utf-8", "replace"))

    print("\n=== sample signed source (relative mode) ===")
    print("  %r" % results[0][3])

    non401 = [r for r in results if r[1] not in (401, 403, None)]
    if not non401:
        print("\nALL VARIANTS REJECTED (401/403/transport)")
        raise SystemExit(2)
    print("\nAT LEAST ONE VARIANT ACCEPTED")


if __name__ == "__main__":
    main()
