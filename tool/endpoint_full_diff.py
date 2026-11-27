#!/usr/bin/env python3
"""Full-surface endpoint diff: desktop request classes vs EVERY url literal in mobile lib/.

Why this exists (batch #62): `tool/endpoint_diff.py` compares desktop endpoints
against `api_constants.dart` ONLY. A repository that hardcodes its URL string
(e.g. `friend_repository.dart` uses '/posts', `comic_repository.dart` uses
'/comments/$id') looks like a MISSING feature when it is in fact implemented.
That produces false gaps AND false confidence.

This script scans ALL of lib/ for url-ish string literals, normalises both
sides to a comparable shape, and reports the symmetric difference.

Hard-fails (exit 2) on zero samples, per pitfall #35.
"""
import os
import re
import sys
from collections import defaultdict

DESKTOP = "/home/ubuntu/project/picacg-qt-temp"
MOBILE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# First path segment of every known remote-API family. Used to recognise a
# relative-path endpoint literal ('auth/signin') without matching Dart
# imports, asset paths or route keys.
_API_ROOTS = {
    "auth",
    "comics",
    "comments",
    "users",
    "user",
    "categories",
    "collections",
    "games",
    "keywords",
    "chat",
    "room",
    "message",
    "tags",
    "speed",
    "my",
    "init",
    "pica-apps",
}


def _talks_to_api(src):
    """True when the file performs remote API calls.

    The call site is usually `_dio().get(...)` or `_api.get(...)` - a bare
    `\\b(dio|_api)\\s*\\.` pattern misses the `()` form entirely, which made
    chat_repository.dart invisible and produced 5 FALSE gaps in the first run
    (auth/signin, room/list, user/profile, message/send-*).
    """
    if not re.search(r"\.(get|post|put|delete|patch)\s*\(", src):
        return False
    return bool(re.search(r"\b(dio|_api|client|http|ApiClient)\b", src, re.IGNORECASE))


def read(p):
    with open(p, "r", encoding="utf-8", errors="replace") as fh:
        return fh.read()


def normalise(path):
    """Normalise an endpoint shape to a comparable form.

    - drop leading/trailing slashes
    - collapse {id}/{comicId}/$id/<int> placeholders to {x}
    - drop query strings (compare the path skeleton)
    """
    p = path.strip().strip("'\"")
    p = p.split("?")[0].split("#")[0]
    p = p.rstrip("/")
    p = re.sub(r"\$\{?\w+\}?", "{x}", p)
    p = re.sub(r"\{[^}]*\}", "{x}", p)
    p = re.sub(r"/\d+", "/{x}", p)
    p = re.sub(r"/+", "/", p)
    return p.lstrip("/")


def desktop_endpoints():
    """Extract endpoint shapes from desktop req.py (config.Url + "..." patterns)."""
    req = os.path.join(DESKTOP, "src", "server", "req.py")
    src = read(req)
    found = {}
    for m in re.finditer(r'url\s*=\s*(?:config\.\w+\s*\+\s*)?"([^"]+)"', src):
        raw = m.group(1)
        if "{" not in raw and raw.count("/") == 0:
            continue
        norm = normalise(raw)
        found.setdefault(norm, []).append(raw)
    # also the format()-style templates
    for m in re.finditer(r'url\s*=\s*config\.\w+\s*\+\s*"([^"]+)"\.format\([^)]*\)', src):
        raw = m.group(1)
        norm = normalise(raw)
        found.setdefault(norm, []).append(raw)
    return found


def mobile_endpoints():
    """Scan ALL dart files in lib/ for url-ish literals.

    Three shapes must all be captured, or the diff produces false gaps:

    1. absolute path   '/comics/123/eps?page=1'
       -> the query string MUST be part of the matched literal, otherwise the
          closing quote is never reached and the endpoint is silently missed.
          (This is exactly how `episodePages` disappeared from the first run.)
    2. relative path   'auth/signin'  (used against a baseUrl)
    3. full url        'https://host/path'

    App route names ('/home', '/login', ...) are NOT endpoints - they are
    Navigator route keys. Excluding app.dart removes that noise, but we still
    scan every other file so that a repository which hardcodes its URL is
    counted as implemented.
    """
    lib = os.path.join(MOBILE, "lib")
    found = defaultdict(list)
    for dirpath, _, files in os.walk(lib):
        for f in files:
            if not f.endswith(".dart"):
                continue
            p = os.path.join(dirpath, f)
            rel = os.path.relpath(p, MOBILE)
            if os.path.basename(rel) == "app.dart":
                continue
            src = read(p)
            # shape 1+3: quoted literal that starts with '/' or 'http'
            for m in re.finditer(
                r"['\"]((?:/|https?://)[A-Za-z0-9_\-/{}$.?=&%:~]{2,120})['\"]", src
            ):
                raw = m.group(1)
                norm = normalise(raw)
                if norm:
                    found[norm].append(rel)
            # shape 2: quoted relative path (no leading slash) that looks like
            # an api path segment - only in files that talk to a remote API.
            if _talks_to_api(src):
                for m in re.finditer(
                    r"['\"]([A-Za-z][A-Za-z0-9_\-]*(?:/[A-Za-z0-9_\-{}$.?=&%]+)+)['\"]",
                    src,
                ):
                    raw = m.group(1)
                    if raw.split("/")[0] in _API_ROOTS:
                        norm = normalise(raw)
                        if norm:
                            found[norm].append(rel)
    return found


def main():
    d = desktop_endpoints()
    m = mobile_endpoints()
    if not d:
        print("FATAL: parsed 0 desktop endpoints - diff would be vacuous")
        raise SystemExit(2)
    if not m:
        print("FATAL: parsed 0 mobile url literals - diff would be vacuous")
        raise SystemExit(2)
    print(f"desktop endpoint shapes: {len(d)}")
    print(f"mobile url shapes in lib/: {len(m)}")

    d_only = sorted(set(d) - set(m))
    m_only = sorted(set(m) - set(d))
    shared = sorted(set(d) & set(m))

    print(f"\n=== desktop-only ({len(d_only)}) ===")
    for k in d_only:
        print(f"  {k:34s} desktop raw: {d[k][0]}")
    if not d_only:
        print("  (none)")

    print(f"\n=== mobile-only ({len(m_only)}) ===")
    for k in m_only:
        locs = sorted(set(m[k]))[:2]
        print(f"  {k:34s} {locs}")
    if not m_only:
        print("  (none)")

    print(f"\nSHARED: {len(shared)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
