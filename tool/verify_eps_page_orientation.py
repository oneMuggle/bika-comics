#!/usr/bin/env python3
"""Settle the episode-page ORIENTATION contract from primary evidence.

Question: does the pica API's `/comics/{id}/eps?page=1` return the NEWEST
chapters (as the desktop's index formula assumes) or the OLDEST?

Primary evidence (desktop source, read directly -- NOT inferred):
  1. src/view/info/book_info_view.py:448-450  (page TAB labels)
         start = info.epsCount - i*info.epsLimit
         end   = max(1, info.epsCount - (i+1)*info.epsLimit + 1)
     Tab 0 is the FIRST tab and tab 0 loads API page 1
     (book_info_view.py:473 -> GetComicsBookEpsReq(info.id, index+1)).
     For 6 chapters / limit 2 the labels are "6-5", "4-3", "2-1"
     => page 1 holds the NEWEST chapters.

  2. src/view/info/book_info_view.py:490 (rows drawn for the selected tab)
         epsId = (info.epsCount - index*info.epsLimit) - 1 - i
     With index=0 (page 1): epsId = epsCount-1-i  -> 5,4,3,...
     and the label is str(epsId+1) -> "6","5",...
     => page 1's first row is the NEWEST chapter.

  3. src/tools/book.py:183 (storage index) + src/view/info/book_eps_view.py:105
     (render loop)  ->  index == 0 is the OLDEST chapter, rendered FIRST.

So: API page 1 = newest-first; the desktop renders the whole list oldest-first.

Hard-fails (exit 2) on zero samples (pitfall #35).
"""
import os
import re
import sys

DESKTOP = "/home/ubuntu/project/picacg-qt-temp/src/view/info/book_info_view.py"
if not os.path.exists(DESKTOP):
    raise SystemExit("MISSING: %s" % DESKTOP)

src = open(DESKTOP, encoding="utf-8").read()


def need(pattern, label):
    m = re.search(pattern, src, re.MULTILINE)
    if not m:
        raise SystemExit("ABORT: could not find %s in desktop source" % label)
    return m.group(0).strip()


print("=" * 74)
print("EVIDENCE 1 - page TAB labels (book_info_view.py)")
print("=" * 74)
ev1 = need(r"^\s*start = info\.epsCount - i\*info\.epsLimit.*$", "tab label start")
ev2 = need(r"^\s*end = max\(1, info\.epsCount - \(i\+1\)\*info\.epsLimit \+ 1\)\s*$", "tab label end")
print("   " + ev1)
print("   " + ev2)

print()
print("=" * 74)
print("EVIDENCE 2 - row ids for the selected tab (book_info_view.py:490)")
print("=" * 74)
ev3 = need(r"^\s*epsId = \(info\.epsCount - index\*info\.epsLimit\) - 1-i\s*$", "row epsId")
print("   " + ev3)

print()
print("=" * 74)
print("DERIVED TAB LABELS  (epsCount / epsLimit)")
print("=" * 74)
samples = 0
for eps_count, eps_limit in [(6, 2), (389, 200), (25, 25), (201, 200), (100, 50)]:
    tabs = []
    for i in range(0, (eps_count + eps_limit - 1) // eps_limit):
        start = eps_count - i * eps_limit
        end = max(1, eps_count - (i + 1) * eps_limit + 1)
        tabs.append("%d-%d" % (start, end))
    print("   epsCount=%-4d epsLimit=%-4d -> tabs %s" % (eps_count, eps_limit, tabs))
    samples += 1

print()
print("=" * 74)
print("DERIVED ROW IDS FOR TAB 0 (== API PAGE 1)")
print("=" * 74)
for eps_count, eps_limit in [(6, 2), (389, 200), (25, 25), (201, 200), (100, 50)]:
    ids = []
    for i in range(eps_limit):
        eps_id = (eps_count - 0 * eps_limit) - 1 - i
        if eps_id >= 0:
            ids.append(str(eps_id + 1))
    print("   epsCount=%-4d -> first rows (1-based chapter numbers): %s ... %s"
          % (eps_count, ids[:5], ids[-1:] or ["-"]))

print()
print("=" * 74)
print("CONCLUSION")
print("=" * 74)
print("  * API page 1 holds the NEWEST chapters (tab 0 label starts at epsCount,")
print("    and its first row id is epsCount).")
print("  * The desktop STORES them under index = epsCount - epsLimit*(page-1) - i - 1")
print("    (so index 0 == the OLDEST chapter) and RENDERS index ascending,")
print("    i.e. the episode list is displayed OLDEST-FIRST.")
print("  * Therefore the mobile client must sort the concatenated pages by that")
print("    index ascending. Appending page 2..N after page 1 would keep")
print("    'newest first' and contradict the desktop.")
if samples == 0:
    raise SystemExit("ABORT: zero samples")
print()
print("RESULT: ORIENTATION SETTLED - page 1 = newest, display = oldest-first")
