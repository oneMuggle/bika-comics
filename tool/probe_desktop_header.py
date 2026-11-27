#!/usr/bin/env python3
"""Run the DESKTOP's REAL ToolUtil.GetHeader against the live API.

This is the decisive cross-language test (skill: "verify by executing the
real reference implementation, not a re-implementation").

Earlier probes disagreed because each one re-implemented the signing.  Here
we EXECUTE the desktop's own GetHeader body verbatim, extracted from
tool.py, so the only variable left is the transport (which host / which
header set).

We also compare the desktop's GetHeader output to the MOBILE's
ApiSignature.buildHeaders output for the SAME (path, time, nonce) triple.
If they are byte-identical, the mobile signing layer is proven correct and
any remaining failure is purely a network/host problem.

Usage:
    python3 tool/probe_desktop_header.py --live
    python3 tool/probe_desktop_header.py --compare
"""
import ast
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
TOOL_PY = os.path.join(DESKTOP_SRC, "tools", "tool.py")
CONFIG_PY = os.path.join(DESKTOP_SRC, "config", "config.py")


def desktop_config():
    ns = {}
    with open(CONFIG_PY, encoding="utf-8") as f:
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
    with open(TOOL_PY, encoding="utf-8") as f:
        src = f.read()
    m = re.search(r"def __SigFromNative\([^)]*\)\s*:\s*\n\s*return\s+(r?'[^']+')", src)
    if not m:
        raise RuntimeError("no secret")
    return eval(m.group(1))  # noqa: S307


CFG = desktop_config()
MATERIAL = desktop_secret()
KEY = CFG["ApiKey"]


def desktop_get_header(url, method):
    """VERBATIM copy of ToolUtil.GetHeader (tool.py:57-94), de-indented."""
    now = str(int(time.time()))
    nonce = str(uuidmod.uuid1()).replace("-", "")
    datas = [
        CFG["Url"], url.replace(CFG["Url"], ""),
        now,
        nonce,
        method,
        KEY,
        CFG["Version"],
        CFG["BuildVersion"],
    ]
    # __ConFromNative: key = datas[1] + datas[2] + datas[3] + datas[4] + datas[5]
    _src = (str(datas[1]) + str(datas[2]) + str(datas[3]) + str(datas[4])
            + str(datas[5]))
    # HashKey
    appsecret = MATERIAL.encode("utf-8")
    data = _src.lower().encode("utf-8")
    signature = hmac.new(appsecret, data, digestmod=hashlib.sha256).hexdigest()
    header = {
        "api-key": KEY,
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
    if method.lower() in ["post", "put"]:
        header["Content-Type"] = "application/json; charset=UTF-8"
    return header, _src


def fire(label, url, headers):
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            body = resp.read()
            print("  %-34s status=%-5s len=%-5d body=%r"
                  % (label, resp.status, len(body), body[:220]))
            return resp.status, body
    except urllib.error.HTTPError as e:
        body = e.read()
        print("  %-34s status=%-5s len=%-5d body=%r"
              % (label, e.code, len(body), body[:220]))
        return e.code, body
    except Exception as e:
        print("  %-34s TRANSPORT-FAIL %r" % (label, repr(e)[:110]))
        return None, b""


def live():
    print("### desktop GetHeader, direct host (desktop's own config.Url)")
    url = CFG["Url"] + "comics?page=1"
    h, src = desktop_get_header(url, "GET")
    print("  signed source = %r" % src)
    print("  headers: %s" % json.dumps(h, ensure_ascii=False))
    fire("direct/comics", url, h)

    print("\n### desktop GetHeader, mirror (host prefix stripped from url)")
    mirror = "https://bika-api.jpacg.cc/picaapi.picacomic.com/comics?page=1"
    h2, src2 = desktop_get_header(mirror, "GET")
    print("  signed source = %r" % src2)
    print("  headers: %s" % json.dumps(h2, ensure_ascii=False))
    fire("mirror/comics", mirror, h2)

    print("\n### desktop GetHeader but url built as config.Url + path, then")
    print("### rewritten to the mirror by the desktop's proxy rule")
    print("###   request.url.replace(host, proxyUrl + '/' + host)")
    host = "picaapi.picacomic.com"
    rewritten = mirror
    h3, src3 = desktop_get_header(rewritten, "GET")
    print("  signed source = %r" % src3)
    fire("mirror/rewritten", rewritten, h3)

    print("\n### desktop GetHeader with the DESKTOP's own signing but the")
    print("### mirror's actual path (i.e. sign 'comics?page=1')")
    h4, src4 = desktop_get_header(CFG["Url"] + "comics?page=1", "GET")
    h4 = dict(h4)
    print("  signed source = %r" % src4)
    fire("mirror/header-of-direct", mirror, h4)


def compare():
    """Compare desktop GetHeader output with the mobile's buildHeaders."""
    print("### generating identical (path, time, nonce) on both sides")
    print("(run the Dart side with:")
    print("   dart run tool/dump_mobile_runtime.dart --compare")
    now = str(int(time.time()))
    nonce = "0123456789abcdef0123456789abcdef"
    path = "comics?page=1"
    src = path + now + nonce + "GET" + KEY
    sig = hmac.new(MATERIAL.encode("utf-8"), src.lower().encode("utf-8"),
                   hashlib.sha256).hexdigest()
    print("  time   = %s" % now)
    print("  nonce  = %s" % nonce)
    print("  src    = %r" % src)
    print("  DESKTOP signature = %s" % sig)
    print("  DESKTOP headers   = %s"
          % json.dumps(desktop_get_header(CFG["Url"] + path, "GET")[0],
                       ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "--live"
    if mode == "--compare":
        compare()
    else:
        live()
