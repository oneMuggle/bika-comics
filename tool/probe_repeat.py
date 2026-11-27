#!/usr/bin/env python3
"""Repeat-measurement: is the direct host really unreachable, or flaky?

Evidence so far:
  * direct picaapi.picacomic.com -> mostly "Network is unreachable" (egress)
    but in ONE run (probe_auth_matrix) it returned HTTP 200 for 36 variants.
  * the jpacg mirror always answers, but the desktop-conformant signature
    (signed over the RELATIVE path) yields 401 while a signature over the
    FULL URL yields 200-with-empty-body.

Two things must be separated:
  (a) transport reachability of the direct host (may be flaky/rotating)
  (b) WHICH signed source the upstream accepts

For (b) the decisive experiment is to send the SAME absolute URL with
    - Host: picaapi.picacomic.com   (mirror forwards as if direct)
    - signed source = relative path
    - signed source = full URL
and to do it on BOTH the direct host and the mirror, several times, so a
flaky answer cannot be mistaken for a verdict.

For (a) we simply retry the direct host N times and count successes.

Exit 0 = a stable, repeated verdict was reached.
Exit 2 = results were inconsistent across repeats (report which).
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

DIRECT = "https://picaapi.picacomic.com/"
MIRROR = "https://bika-api.jpacg.cc/picaapi.picacomic.com/"
PATH = "comics?page=1"
REPEATS = 3


def hmac_hex(text):
    return hmac.new(MATERIAL.encode("utf-8"), text.lower().encode("utf-8"),
                    hashlib.sha256).hexdigest()


def headers(signed_source, now, nonce, extra=None):
    h = {
        "api-key": KEY,
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
    if extra:
        h.update(extra)
    return h


def fire(url, hdrs):
    req = urllib.request.Request(url, headers=hdrs)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read()[:200]
    except urllib.error.HTTPError as e:
        return e.code, e.read()[:200]
    except Exception as e:
        return None, repr(e)[:90].encode()


def tag(status, body):
    if status is None:
        return "UNREACHABLE"
    try:
        j = json.loads(body.decode("utf-8", "replace"))
        if isinstance(j, dict):
            code = j.get("code")
            err = j.get("error")
            has_data = "data" in j
            return "code=%s%s%s" % (code,
                                    (" err=" + str(err)) if err else "",
                                    " HAS_DATA" if has_data else " NO_DATA")
    except Exception:
        pass
    return "HTTP-%s" % status


def trial(label, url, signed_source, extra=None):
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    status, body = fire(url, headers(signed_source, now, nonce, extra))
    return tag(status, body), status, body


def main():
    print("=== (a) direct host reachability, %d repeats ===" % REPEATS)
    direct_counts = Counter()
    for i in range(REPEATS):
        t, status, _ = trial("direct", DIRECT + PATH, PATH)
        direct_counts[t] += 1
        print("  attempt %d: %s" % (i + 1, t))
        time.sleep(1)
    print("  direct-host verdicts: %s" % dict(direct_counts))

    print("\n=== (b) signed-source axis, %d repeats each ===" % REPEATS)
    cases = [
        ("MIRROR + relative-path-signature", MIRROR, PATH, None),
        ("MIRROR + full-url-signature", MIRROR, MIRROR + PATH, None),
        ("MIRROR + Host override + relative", MIRROR, PATH,
         {"Host": "picaapi.picacomic.com"}),
        ("MIRROR + Host override + full-url", MIRROR, MIRROR + PATH,
         {"Host": "picaapi.picacomic.com"}),
        ("DIRECT + relative-path-signature", DIRECT, PATH, None),
        ("DIRECT + full-url-signature", DIRECT, DIRECT + PATH, None),
    ]
    summary = {}
    for label, url, signed, extra in cases:
        results = []
        for i in range(REPEATS):
            t, status, body = trial(label, url, signed, extra)
            results.append(t)
            time.sleep(1)
        counts = Counter(results)
        stable = len(counts) == 1
        summary[label] = (counts, stable)
        print("  %-40s %s %s" % (label, dict(counts),
                                "STABLE" if stable else "*** UNSTABLE ***"))

    print("\n=== (c) any body with a data key? ===")
    found = []
    for label, url, signed, extra in cases:
        for i in range(REPEATS):
            t, status, body = trial(label, url, signed, extra)
            try:
                j = json.loads(body.decode("utf-8", "replace"))
                if isinstance(j, dict) and "data" in j:
                    found.append((label, t, list(j.get("data", {}).keys())
                                  if isinstance(j.get("data"), dict) else "list"))
            except Exception:
                pass
            time.sleep(0.5)
    if found:
        for f in found:
            print("  DATA FOUND: %s" % (f,))
    else:
        print("  NO response carried a 'data' key")

    unstable = [k for k, (_, s) in summary.items() if not s]
    if unstable:
        print("\nRESULT: UNSTABLE across repeats for %s" % unstable)
        raise SystemExit(2)
    print("\nRESULT: all verdicts stable across repeats")


if __name__ == "__main__":
    main()
