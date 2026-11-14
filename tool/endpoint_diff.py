#!/usr/bin/env python3
"""Normalized endpoint diff: desktop (picacg-qt-temp) vs mobile (bika-comics).

Reads desktop endpoint templates from src/server/req.py and mobile endpoints
from lib/shared/constants/api_constants.dart, normalizes placeholders, and
reports the set difference in both directions.

Guards against vacuous results: exits non-zero if either side yields zero
endpoints.
"""
import re
import sys
from pathlib import Path

DESKTOP = Path("/home/ubuntu/project/picacg-qt-temp/src/server/req.py")
MOBILE = Path("/home/ubuntu/project/bika-comics/lib/shared/constants/api_constants.dart")

PLACEHOLDER = re.compile(r"\{[^}]*\}|\$\{?[A-Za-z_][A-Za-z0-9_]*\}?|%s|\{[0-9]+\}")


def normalize(path: str) -> str:
    """Strip host/scheme, collapse placeholders to {id}, drop query/fragment."""
    p = path.strip().strip('"').strip("'")
    # strip scheme://host
    p = re.sub(r"^[a-zA-Z][a-zA-Z0-9+.-]*://[^/]*", "", p)
    # drop query + fragment
    p = p.split("?")[0].split("#")[0]
    # collapse placeholders
    p = PLACEHOLDER.sub("{id}", p)
    # collapse repeated slashes
    p = re.sub(r"/{2,}", "/", p)
    if not p.startswith("/"):
        p = "/" + p
    # trailing slash (but keep "/")
    if len(p) > 1:
        p = p.rstrip("/")
    return p.lower()


def desktop_endpoints(text: str):
    found = set()
    # config.Url + "path"  and  "https://..." patterns
    patterns = [
        r'config\.Url\s*\+\s*[fr]?["\']([^"\']+)["\']',
        r'f?["\']((?:https?://)[^"\']*?)["\']',
        r'["\'](/[a-zA-Z][^"\']*)["\']',
    ]
    for pat in patterns:
        for m in re.finditer(pat, text):
            raw = m.group(1)
            # skip obvious non-API paths
            if raw.startswith(("http://localhost", "https://cdn", "data:")):
                continue
            found.add(raw)
    return {normalize(x) for x in found}


def mobile_endpoints(text: str):
    found = set()
    # static const String name = '/path';
    for m in re.finditer(r"static\s+const\s+String\s+\w+\s*=\s*(?:r?['\"])([^'\"]+)['\"]", text):
        raw = m.group(1)
        if not raw.startswith("/") and "://" not in raw:
            continue
        found.add(raw)
    # static String name(...) => '/path/$id/...';
    for m in re.finditer(r"static\s+String\s+\w+\s*\([^)]*\)\s*=>\s*(?:r?['\"])([^'\"]+)['\"]", text):
        found.add(m.group(1))
    return {normalize(x) for x in found}


# CDN asset paths are not API endpoints -- they are static image URLs
# referenced from JSON payloads. Excluding them keeps the diff meaningful.
NOISE = re.compile(
    r"^/(static|media|images?|assets?|img|thumb|cover)/",
    re.IGNORECASE,
)
# Non-API endpoints that still exist on the desktop for other reasons.
BENIGN = re.compile(r"^/(config\.txt|version(_pre)?\.txt)$", re.IGNORECASE)


def main() -> int:
    if not DESKTOP.exists():
        print(f"FATAL: desktop file missing: {DESKTOP}")
        return 2
    if not MOBILE.exists():
        print(f"FATAL: mobile file missing: {MOBILE}")
        return 2

    dtext = DESKTOP.read_text(encoding="utf-8", errors="replace")
    mtext = MOBILE.read_text(encoding="utf-8", errors="replace")

    d = {x for x in desktop_endpoints(dtext) if not NOISE.match(x) and not BENIGN.match(x)}
    m = {x for x in mobile_endpoints(mtext) if not NOISE.match(x) and not BENIGN.match(x)}

    print(f"desktop unique endpoints: {len(d)}")
    print(f"mobile  unique endpoints: {len(m)}")

    if not d:
        print("FATAL: desktop endpoint extraction returned ZERO samples")
        return 2
    if not m:
        print("FATAL: mobile endpoint extraction returned ZERO samples")
        return 2

    only_desktop = sorted(d - m)
    only_mobile = sorted(m - d)

    print()
    print(f"=== desktop-only ({len(only_desktop)}) ===")
    for x in only_desktop:
        print(f"  {x}")
    print()
    print(f"=== mobile-only ({len(only_mobile)}) ===")
    for x in only_mobile:
        print(f"  {x}")

    print()
    print(f"SHARED: {len(d & m)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
