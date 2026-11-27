#!/usr/bin/env python3
"""Cross-language check of the episode ORDERING fix (batch #62).

Compares:
  A. The DESKTOP's own index formula, executed from the desktop's real source
     (src/tools/book.py:183)  ->  ground truth
  B. The MOBILE's sortEpisodesByDesktopOrder equivalent (re-implemented here
     in Python exactly as the Dart does it)  -> must agree with A

We do NOT trust a hand-written "reference" of the formula: we import the
desktop module's arithmetic by re-reading the real line and evaluating it.

Hard-fails on zero samples (pitfall #35).
"""
import re
import os

DESKTOP_BOOK = "/home/ubuntu/project/picacg-qt-temp/src/tools/book.py"

if not os.path.exists(DESKTOP_BOOK):
    raise SystemExit("MISSING: %s" % DESKTOP_BOOK)

with open(DESKTOP_BOOK, encoding="utf-8") as f:
    book_src = f.read()

# Extract the real formula line from the desktop source.
m = re.search(
    r"^\s*index\s*=\s*(info\.epsCount\s*-\s*info\.epsLimit\s*\*\s*\(page-1\)\s*-\s*i\s*-\s*1)\s*$",
    book_src,
    re.MULTILINE,
)
if not m:
    raise SystemExit("ABORT: could not extract the desktop index formula")
formula_src = m.group(1)
print("desktop formula (src/tools/book.py:183):")
print("    index = %s" % formula_src)


def desktop_index(eps_count, eps_limit, page, i):
    """Evaluate the EXACT desktop expression."""
    info = type("I", (), {})()
    info.epsCount = eps_count
    info.epsLimit = eps_limit
    return eval(formula_src, {"info": info}, {"page": page, "i": i})


def mobile_sort(episodes, eps_count, eps_limit):
    """Mirror of ComicRepository.sortEpisodesByDesktopOrder (Dart)."""
    if eps_count <= 0 or eps_limit <= 0:
        return list(episodes)
    indexed = []
    page = 1
    consumed = 0
    for ep in episodes:
        i = consumed
        consumed += 1
        idx = eps_count - eps_limit * (page - 1) - i - 1
        indexed.append((idx, ep))
        if consumed == eps_limit:
            consumed = 0
            page += 1
    indexed.sort(key=lambda t: t[0])
    return [ep for _, ep in indexed]


def desktop_render_order(eps_count, eps_limit, pages):
    """Desktop builds epsDict by index, then renders ASCENDING index."""
    eps_dict = {}
    for page in range(1, pages + 1):
        for i in range(eps_limit):
            idx = desktop_index(eps_count, eps_limit, page, i)
            if 0 <= idx < eps_count:
                eps_dict[idx] = (page, i)
    return [eps_dict[k] for k in sorted(eps_dict.keys())]


def mobile_render_order(eps_count, eps_limit, pages):
    """Mobile: API returns page1=newest..; sort by index then render."""
    raw = []
    for page in range(1, pages + 1):
        for i in range(eps_limit):
            if (page - 1) * eps_limit + i < eps_count:
                raw.append((page, i))
    ids = list(range(len(raw)))
    ordered = mobile_sort(ids, eps_count, eps_limit)
    return [raw[k] for k in ordered]


CASES = [
    # (eps_count, eps_limit, pages)  -- 389 = max epsCount in the real capture
    (389, 200, 2),
    (6, 2, 3),
    (100, 50, 2),
    (25, 25, 1),
    (1, 1, 1),
    (201, 200, 2),
]

print("\n" + "=" * 74)
print("EPISODE ORDER: desktop render order vs mobile sortEpisodesByDesktopOrder")
print("=" * 74)

samples = 0
failures = []

for eps_count, eps_limit, pages in CASES:
    d = desktop_render_order(eps_count, eps_limit, pages)
    m = mobile_render_order(eps_count, eps_limit, pages)
    ok = d == m
    samples += 1
    print("\n--- eps_count=%d eps_limit=%d pages=%d ---" % (eps_count, eps_limit, pages))
    print("  desktop first 4: %s" % d[:4])
    print("  mobile  first 4: %s" % m[:4])
    print("  IDENTICAL: %s" % ok)
    if not ok:
        failures.append((eps_count, eps_limit, pages, d[:6], m[:6]))

print("\n" + "=" * 74)
print("START-READ SEMANTICS (the defect this fixes)")
print("=" * 74)
for eps_count, eps_limit, pages in CASES:
    m = mobile_render_order(eps_count, eps_limit, pages)
    d = desktop_render_order(eps_count, eps_limit, pages)
    # desktop StartRead() -> OpenReadIndex(0) -> epsId == 0 -> OLDEST chapter
    desktop_starts_at = d[0]
    mobile_starts_at = m[0]
    print("  eps_count=%-4d desktop index0 -> page=%d i=%d | mobile index0 -> page=%d i=%d"
          % (eps_count, desktop_starts_at[0], desktop_starts_at[1],
             mobile_starts_at[0], mobile_starts_at[1]))
    if desktop_starts_at != mobile_starts_at:
        failures.append(("start_read", eps_count, desktop_starts_at, mobile_starts_at))

print("\n" + "=" * 74)
if samples == 0:
    raise SystemExit("ABORT: zero samples")
if failures:
    print("RESULT: %d MISMATCH(ES)" % len(failures))
    for f in failures:
        print("   %s" % (f,))
    raise SystemExit(2)
print("RESULT: ALL %d CASES MATCH THE DESKTOP" % samples)
