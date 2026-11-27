#!/usr/bin/env python3
"""Probe candidate API base URLs to find a REACHABLE one.

Prior batch left `probe_api_shape.py` pointing at `https://bika-api.jpacg.cc/`
which returns HTTP 404 -- the mirror is up, but it expects the upstream host
as a path prefix (`/picaapi.picacomic.com`), exactly as the mobile
`ApiSignature.normalizeSignedPath` doc comment describes for the proxy case.

This script enumerates candidate base URLs, signs each request with the
DESKTOP's own algorithm (read live from picacg-qt-temp), and reports the
HTTP status + first bytes of the body so we can tell "unreachable" from
"reachable but wrong path" from "reachable and answered".

Exit 0 = at least one candidate answered with a JSON body containing a
"data" key. Exit 2 = nothing answered usefully.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from probe_api_shape import api_get  # noqa: E402  (reuse the signing code)

CANDIDATES = [
    "https://bika-api.jpacg.cc/",
    "https://bika-api.jpacg.cc/picaapi.picacomic.com/",
    "https://bika2-api.jpacg.cc/",
    "https://bika2-api.jpacg.cc/picaapi.picacomic.com/",
    "https://picaapi.picacomic.com/",
    "http://picaapi.picacomic.com/",
    "https://api.picacomic.com/",
    "https://bika-api.jpacg.cc/api/",
]


def main():
    winners = []
    for base in CANDIDATES:
        sys.stdout.write("[try] %-58s " % base)
        sys.stdout.flush()
        try:
            r = api_get(base, "comics", {"page": 1})
        except Exception as e:
            msg = repr(e)
            # keep it short: status code if HTTP error, else transport error
            if "HTTP " in msg:
                print("HTTP-ERR %s" % msg[msg.index("HTTP "):msg.index("HTTP ") + 40])
            else:
                print("TRANSPORT-ERR %s" % msg[:60])
            continue
        code = r.get("code")
        has_data = isinstance(r.get("data"), dict)
        print("OK code=%s data=%s keys=%s"
              % (code, has_data, sorted(r.get("data", {}).keys())[:6]
                 if has_data else "-"))
        if has_data:
            winners.append((base, r))

    if not winners:
        print("\nNO CANDIDATE ANSWERED WITH A JSON data OBJECT")
        raise SystemExit(2)

    base, r = winners[0]
    d = r.get("data", {})
    comics = d.get("comics") or []
    print("\nWINNER: %s  comics=%d" % (base, len(comics)))
    if not comics:
        print("WINNER RETURNED ZERO COMICS")
        raise SystemExit(2)
    c = comics[0]
    print("comic keys: %s" % sorted(c.keys()))
    print(json.dumps(c, ensure_ascii=False, indent=2)[:1500])
    print("\nPROBE COMPLETED OK")


if __name__ == "__main__":
    main()
