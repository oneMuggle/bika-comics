#!/usr/bin/env python3
"""Dump the FULL response body + the exact headers we sign/send.

The path-prefixed mirror returns HTTP 401 where the bare mirror returns 404,
so routing is right and the failure is auth-side. This prints the server's
own error message (which names the failing check) plus the request headers,
so we can diff them against the desktop's `ToolUtil.GetHeader` field by field.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from probe_api_shape import CFG, _CFGVALS, build_headers  # noqa: E402

BASES = [
    "https://bika-api.jpacg.cc/picaapi.picacomic.com/",
    "https://picaapi.picacomic.com/",
]


def raw_get(base, path, query=None):
    import urllib.parse
    q = urllib.parse.urlencode(query) if query else ""
    full = path + (("?" + q) if q else "")
    url = base + full
    headers = build_headers(full, "GET")
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            return resp.status, dict(resp.headers), resp.read()[:1200]
    except urllib.error.HTTPError as e:
        return e.code, dict(e.headers), e.read()[:1200]
    except Exception as e:
        return None, {}, repr(e)[:300].encode()


def main():
    for base in BASES:
        status, hdrs, body = raw_get(base, "comics", {"page": 1})
        print("=" * 74)
        print("BASE: %s   STATUS: %s" % (base, status))
        print("=" * 74)
        hdrs_out = build_headers("comics?page=1", "GET")
        print("REQUEST HEADERS (signed source = %r):" % "comics?page=1")
        for k in sorted(hdrs_out):
            v = hdrs_out[k]
            print("   %-22s %s" % (k, (v[:60] + "...") if len(v) > 60 else v))
        print("-" * 74)
        print("RESPONSE BODY:")
        try:
            print(json.dumps(json.loads(body.decode("utf-8", "replace")),
                             ensure_ascii=False, indent=2)[:900])
        except Exception:
            print(body.decode("utf-8", "replace")[:900])
        print()

    # Also try: same request but signed with the FULL url (desktop replace
    # semantics differ when base != config.Url).
    print("=" * 74)
    print("VARIANT: sign the FULL url instead of the relative path")
    print("=" * 74)
    import urllib.parse
    base = BASES[0]
    url = base + "comics?page=1"
    headers = build_headers(url, "GET")
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            print("STATUS", resp.status)
            print(resp.read()[:600].decode("utf-8", "replace"))
    except urllib.error.HTTPError as e:
        print("STATUS", e.code)
        print(e.read()[:600].decode("utf-8", "replace"))
    except Exception as e:
        print("TRANSPORT FAIL", repr(e)[:200])


if __name__ == "__main__":
    main()
