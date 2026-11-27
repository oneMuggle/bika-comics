#!/usr/bin/env python3
"""Consumer audit: find ApiEndpoints constants defined but never consumed,
and screen-level files that exist but are not referenced anywhere.

Rationale (batch #62): the endpoint_diff only compares CONSTANTS. A constant
with no consumer is a feature that was never wired - the same blind spot as
a UI with no data path. This script finds both directions.

Hard-fails (exit 2) when it collects zero samples, per pitfall #35.
"""
import os
import re
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, "lib")
TEST = os.path.join(ROOT, "test")
CONST_FILE = os.path.join(LIB, "shared", "constants", "api_constants.dart")

def dart_files(base):
    out = []
    for dirpath, _, files in os.walk(base):
        for f in files:
            if f.endswith(".dart"):
                out.append(os.path.join(dirpath, f))
    return out

def read(path):
    with open(path, "r", encoding="utf-8") as fh:
        return fh.read()

def main():
    if not os.path.exists(CONST_FILE):
        print("FATAL: constants file missing:", CONST_FILE)
        raise SystemExit(2)

    const_src = read(CONST_FILE)
    # static const String name = ...  AND  static String name(...) => ...
    names = set(re.findall(r"static\s+const\s+String\s+(\w+)\s*=", const_src))
    names |= set(re.findall(r"static\s+String\s+(\w+)\s*\(", const_src))
    if not names:
        print("FATAL: parsed 0 endpoint constants")
        raise SystemExit(2)
    print(f"parsed {len(names)} endpoint constants from api_constants.dart")

    lib_files = dart_files(LIB)
    test_files = dart_files(TEST) if os.path.isdir(TEST) else []
    if not lib_files:
        print("FATAL: no dart files under lib/")
        raise SystemExit(2)

    lib_src = {p: read(p) for p in lib_files}
    test_src = {p: read(p) for p in test_files}

    # ---- Direction 1: constant with no consumer outside the constants file
    unconsumed = []
    for name in sorted(names):
        used_in_lib = False
        for p, src in lib_src.items():
            if p == CONST_FILE:
                continue
            if re.search(r"\b" + re.escape(name) + r"\b", src):
                used_in_lib = True
                break
        if not used_in_lib:
            used_in_test = any(
                re.search(r"\b" + re.escape(name) + r"\b", s) for s in test_src.values()
            )
            unconsumed.append((name, used_in_test))

    print("\n=== constants with NO consumer in lib/ ===")
    if unconsumed:
        for name, in_test in unconsumed:
            flag = "(referenced only in test/)" if in_test else "(DEAD - never referenced)"
            print(f"  {name:28s} {flag}")
    else:
        print("  (none)")

    # ---- Direction 2: presentation screen not referenced by any other dart file
    print("\n=== presentation files with NO consumer (navigation entry) ===")
    pres_files = [
        p for p in lib_files
        if os.sep + "presentation" + os.sep in p and p.endswith("_screen.dart")
    ]
    if not pres_files:
        print("FATAL: no presentation screens found - audit is vacuous")
        raise SystemExit(2)
    orphans = []
    for p in sorted(pres_files):
        base = os.path.basename(p)[:-5]  # strip .dart
        referenced = False
        for q, src in lib_src.items():
            if q == p:
                continue
            if base in src:
                referenced = True
                break
        if not referenced:
            orphans.append((p, base))
    if orphans:
        for p, base in orphans:
            print(f"  {base:34s} {os.path.relpath(p, ROOT)}")
    else:
        print("  (none)")

    # ---- Direction 3: stub markers in mobile source
    print("\n=== stub / not-implemented markers ===")
    stub_re = re.compile(
        r"(TODO|FIXME|未实现|待实现|not implemented|UnimplementedError|throw UnsupportedError)",
        re.IGNORECASE,
    )
    hits = []
    for p, src in lib_src.items():
        for i, line in enumerate(src.splitlines(), 1):
            if stub_re.search(line):
                hits.append((p, i, line.strip()[:110]))
    if hits:
        for p, i, line in hits:
            print(f"  {os.path.relpath(p, ROOT)}:{i}: {line}")
    else:
        print("  (none)")

    print(f"\nSUMMARY screens={len(pres_files)} constants={len(names)} "
          f"orphan_screens={len(orphans)} unconsumed_constants={len(unconsumed)} "
          f"stub_hits={len(hits)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
