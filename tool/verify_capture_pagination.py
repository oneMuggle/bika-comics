#!/usr/bin/env python3
"""Quantify, against RECORDED REAL API DATA, what the batch-62 changes matter.

Capture: /home/ubuntu/extract_db/book.db  (the desktop's own SQLite, 150,574
rows of real pica API responses).  Per pitfall #41, claims must be validated
against recorded real data rather than a mental model.

IMPORTANT CORRECTION (recorded here so it is not re-derived wrongly):
`book.pages` is a COMIC-LEVEL field, not a per-chapter count.
Evidence: `DbBook.CopyFromJson` (src/server/sql_server.py:46-48) copies
fields straight off the comic API doc, and `DbBook.pages` is documented as
"页数" (src/server/sql_server.py:32).  Proof from the capture: comics with
epsCount == 1 have pages up to 4,896 -- a single chapter with 4,896 images
is real, but 150K comics each having 4,896 images would be absurd, and
`pages` scales with neither epsCount nor chapter count.

So this script asks the RIGHT question for image pagination:
  how many images can ONE chapter contain?
  -> bound by `pages` (comic total) / `epsCount` (chapters), which is an
     UPPER bound on the largest chapter, and for epsCount==1 comics it is
     EXACT (the single chapter holds all the pages).

Q1. Episode-list pagination: mobile fetched only `?page=1`. How many real
    comics have more episodes than one episode-page holds (limit 200)?

Q2. Chapter-image pagination: mobile fetches only `?page=1` of the image
    list (limit 200 per group). How many real chapters exceed 200 images?

Q3. The largest single chapter observed (epsCount==1 => pages == that
    chapter's image count).

Hard-fails (exit 2) on zero samples (pitfall #35).
"""
import os
import sqlite3

DB = os.environ.get("PICA_DB", "/home/ubuntu/extract_db/book.db")
EPS_PAGE_LIMIT = 200
PIC_PAGE_LIMIT = 200

if not os.path.exists(DB):
    print(f"FATAL: capture DB not found at {DB}")
    raise SystemExit(2)

con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
cur = con.cursor()
total = cur.execute("select count(*) from book").fetchone()[0]
if not total:
    print("FATAL: zero rows in capture")
    raise SystemExit(2)

print("=" * 74)
print(f"REAL API CAPTURE: {total:,} comics  ({DB})")
print("=" * 74)

# ------------------------------------------------------------------ Q1 ----
eps = [r[0] for r in cur.execute(
    "select epsCount from book where epsCount is not null")]
over_eps = [e for e in eps if e > EPS_PAGE_LIMIT]
print("\nQ1: EPISODE-LIST pagination (eps endpoint, server page limit = 200)")
print(f"    comics with epsCount > 1       : {sum(1 for e in eps if e > 1):>7,}"
      f"  ({sum(1 for e in eps if e > 1)/total*100:.2f}%)")
print(f"    comics with epsCount > 200     : {len(over_eps):>7,}"
      f"  ({len(over_eps)/total*100:.3f}%)")
print(f"    max epsCount observed          : {max(eps)}")
print(f"    -> {len(over_eps)} comics had chapters 201+ that the old")
print(f"       page-1-only mobile fetch made INVISIBLE (and undownloadable).")

# ------------------------------------------------------------------ Q2 ----
# For epsCount==1 the single chapter holds ALL of the comic's pages.
one = [r[0] for r in cur.execute(
    "select pages from book where epsCount = 1 and pages > 0")]
print("\nQ2: CHAPTER-IMAGE pagination (pages endpoint, group limit = 200)")
print(f"    single-chapter comics (epsCount=1) examined: {len(one):,}")
over_one = [p for p in one if p > PIC_PAGE_LIMIT]
print(f"    of those, chapters with > 200 images       : {len(over_one):>7,}"
      f"  ({len(over_one)/max(len(one),1)*100:.2f}% of single-chapter comics)")
if one:
    print(f"    max images in a SINGLE chapter observed    : {max(one)}")
    print(f"    99th pct single-chapter images            : "
          f"{sorted(one)[int(len(one)*0.99)]}")
    print(f"    99.9th pct single-chapter images          : "
          f"{sorted(one)[int(len(one)*0.999)]}")

# --------------------------------------------------------------- Q3 ------
print("\nQ3: LARGEST single chapter (exact, from epsCount==1 rows)")
top = cur.execute(
    "select title, pages from book where epsCount = 1 and pages > 0 "
    "order by pages desc limit 8").fetchall()
for title, p in top:
    print(f"    {p:>7,} images : {str(title)[:46]}")

print("\n    upper bound per chapter for multi-chapter comics")
print("    (pages / epsCount, rounded up):")
for e in (2, 5, 10, 50, 100):
    vals = [r[0] for r in cur.execute(
        "select pages from book where epsCount = ? and pages > 0", (e,))]
    if vals:
        avg = sum(vals) / len(vals)
        print(f"      epsCount={e:<4} n={len(vals):>7,}  avg images/chapter="
              f"{avg:>8.1f}  max={max(vals):>7,}")

print("\n" + "=" * 74)
print("SUMMARY")
print("=" * 74)
print(f"Episode pagination : REAL GAP -- {len(over_eps)} comics "
      f"({len(over_eps)/total*100:.3f}%) had hidden chapters.")
print(f"Image pagination   : REAL GAP -- at least {len(over_one):,} "
      f"single-chapter comics hold > {PIC_PAGE_LIMIT} images in ONE chapter,")
print(f"                     i.e. their image list spans >1 page-group.")
print(f"                     max single chapter observed: {max(one):,} images")
print(f"                     = {max(one)/PIC_PAGE_LIMIT:.0f} page-groups of 200.")
