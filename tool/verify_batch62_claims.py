#!/usr/bin/env python3
"""核查 in-flight 注释里的图片数声明。

DB /home/ubuntu/extract_db/book.db 的 book 表有 `pages` 列
（= 漫画总页数 pagesCount）与 `epsCount` 列（= 章节数）。

需要核实的两个声明：
  - "6,354 部单章漫画的一章图片数超过 200"
  - "最多的一章有 4,896 张 = 25 个分页组"

注意：单章漫画（epsCount==1）的总页数 == 该章图片数，
所以 `epsCount==1 AND pages>200` 就是"单章且一章图片数超 200"。
多章漫画则 pages 是全书页数，单章图片数 <= pages，故无法从
本 DB 精确得到"每章最大图片数"，只能给出上界与单章的精确值。
"""
import sqlite3
import os

DB = "/home/ubuntu/extract_db/book.db"
if not os.path.exists(DB):
    raise SystemExit("DB MISSING")

conn = sqlite3.connect("file:%s?mode=ro" % DB, uri=True)
cur = conn.cursor()

cols = [r[1] for r in cur.execute("PRAGMA table_info(book)").fetchall()]
print("BOOK COLS:", cols)

total = cur.execute("SELECT COUNT(*) FROM book").fetchone()[0]
max_eps = cur.execute("SELECT MAX(epsCount) FROM book").fetchone()[0]
max_pages = cur.execute("SELECT MAX(pages) FROM book").fetchone()[0]
single_over200 = cur.execute(
    "SELECT COUNT(*) FROM book WHERE epsCount=1 AND pages>200").fetchone()[0]
single_total = cur.execute(
    "SELECT COUNT(*) FROM book WHERE epsCount=1").fetchone()[0]
max_single_pages = cur.execute(
    "SELECT MAX(pages) FROM book WHERE epsCount=1").fetchone()[0]

print("TOTAL_RECORDS:", total)
print("MAX_EPS_COUNT:", max_eps)
print("MAX_PAGES_ALL:", max_pages)
print("SINGLE_EP_BOOKS:", single_total)
print("SINGLE_EP_OVER_200:", single_over200)
print("MAX_PAGES_SINGLE_EP:", max_single_pages)
print("PAGES_AT_200_FOR_MAX_SINGLE:",
      (max_single_pages + 199) // 200 if max_single_pages else None)

# 分布：单章漫画页数分桶
print("\nSINGLE-EP pages distribution (top buckets):")
for lo, hi in [(0,1),(1,50),(50,100),(100,200),(200,500),(500,1000),
               (1000,2000),(2000,5000),(5000,100000)]:
    n = cur.execute(
        "SELECT COUNT(*) FROM book WHERE epsCount=1 AND pages>=? AND pages<?",
        (lo, hi)).fetchone()[0]
    print("  pages[%d,%d): %d" % (lo, hi, n))

conn.close()

checks = [
    ("TOTAL_RECORDS", total, 150574),
    ("MAX_EPS_COUNT", max_eps, 389),
    ("SINGLE_EP_OVER_200", single_over200, 6354),
    ("MAX_PAGES_SINGLE_EP", max_single_pages, 4896),
]
print("\n=== CLAIM CHECK ===")
bad = []
for name, actual, claimed in checks:
    ok = actual == claimed
    print("%-24s actual=%-10s claimed=%-10s %s" % (
        name, actual, claimed, "MATCH" if ok else "MISMATCH"))
    if not ok:
        bad.append(name)

if bad:
    print("\nRESULT: MISMATCH on %s" % bad)
    raise SystemExit(2)
print("\nRESULT: ALL 4 CLAIMS MATCH")
