#!/usr/bin/env python3
"""Check whether each desktop-only endpoint exists ANYWHERE in the mobile lib/.

Greps the whole mobile tree (not just api_constants.dart) so that inline
endpoint strings are counted as present. Exits non-zero if a sample list is
empty (no vacuous pass).
"""
import re
import sys
from pathlib import Path

MOBILE_LIB = Path("/home/ubuntu/project/bika-comics/lib")

CANDIDATES = [
    "/comments",
    "/comments/{id}",
    "/games/{id}/comments",
    "/init",
    "/posts",
    "/posts/{id}/comments",
]


def main() -> int:
    if not CANDIDATES:
        print("FATAL: empty candidate list")
        return 2

    files = [p for p in MOBILE_LIB.rglob("*.dart")]
    if not files:
        print("FATAL: no dart files found under lib/")
        return 2

    blob = []
    for p in files:
        blob.append((p, p.read_text(encoding="utf-8", errors="replace")))
    total_bytes = sum(len(t) for _, t in blob)

    print(f"scanned {len(files)} dart files, {total_bytes} bytes")
    print()

    missing = []
    for ep in CANDIDATES:
        hits = []
        # Match the endpoint as a quoted literal, allowing a trailing
        # interpolation segment (e.g. '/comments/$id/childrens').
        pattern = re.compile(re.escape(ep).replace(r"\{id\}", r"\$(?:\{)?[A-Za-z_][A-Za-z0-9_]*\}?"))
        for p, text in blob:
            for m in pattern.finditer(text):
                line_no = text[: m.start()].count("\n") + 1
                hits.append(f"{p.relative_to(MOBILE_LIB.parent)}:{line_no}")
                break
        if hits:
            print(f"PRESENT  {ep:26s} {hits[0]}")
        else:
            print(f"MISSING  {ep:26s} (no occurrence anywhere in lib/)")
            missing.append(ep)

    print()
    print(f"true gaps: {len(missing)} / {len(CANDIDATES)}")
    for x in missing:
        print(f"  - {x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
