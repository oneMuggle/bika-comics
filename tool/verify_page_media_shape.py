#!/usr/bin/env python3
"""Verify the batch-62 download fix against RECORDED REAL DATA.

Claim under test
----------------
The mobile downloader passed the WHOLE page doc to `mediaUrlFrom(page)`.
`mediaUrlFrom` only reads top-level `fileServer` / `path` / `url` keys, but the
pica page doc is a WRAPPER:

    { "_id": "...", "media": { "fileServer": "...", "path": "...", ... } }

so the downloader got '' for every page and skipped 100% of the images, while
the reader (which correctly reads `p['media']`) kept working.

This script answers, from the recorded API capture only:
  Q1. What is the real shape of a page doc?            (keys of `media`)
  Q2. How often does a page doc carry fileServer/path at the TOP level?
      -> expected: 0 times (that is the bug)
  Q3. How often does it carry them under `media`?       -> expected: many
  Q4. For each recorded page doc, does `mediaUrlFrom(doc)` differ from
      `mediaUrlFrom(doc['media'])`?                    -> expected: always

It also re-derives the desktop join for both shapes so the fix is auditable,
and HARD-FAILS on zero samples (a vacuous "everything matches" is not a pass).

Usage:  python3 tool/verify_page_media_shape.py
"""
import json
import os
import re
import sqlite3
from collections import Counter

DB = os.environ.get("PICA_DB", "/home/ubuntu/extract_db/book.db")


def desktop_get_real_url(url, path):
    """Byte-for-byte mirror of desktop ToolUtil.GetRealUrl(url, path)."""
    if path:
        if url[-7:] != "static/":
            return url + "/static/" + path
        return url + path
    return url


def mobile_media_url_from(raw):
    """Mirror of mobile mediaUrlFrom (lib/core/utils/media_url.dart)."""
    if raw is None:
        return ""
    if isinstance(raw, str):
        return raw
    if not isinstance(raw, dict):
        return ""
    file_server = str(raw.get("fileServer") or "")
    path = str(raw.get("path") or "")
    url = raw.get("url")
    url = None if url is None else str(url)
    if not file_server and not path and url is not None:
        return url
    return desktop_get_real_url(file_server, path)


def main():
    if not os.path.exists(DB):
        raise SystemExit(f"ABORT: real DB not found: {DB}")

    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    cur = con.cursor()

    cols = [r[1] for r in cur.execute("PRAGMA table_info(book)")]
    print(f"### book columns: {cols}")

    # The captured page/eps payload lives in the JSON columns. Find every
    # column that stores a JSON blob so we can mine real page docs from it.
    json_cols = [c for c in cols if c not in ("id", "title", "path", "fileServer")]
    blobs = []
    for c in json_cols:
        try:
            rows = list(cur.execute(
                f'select "{c}" from book where "{c}" is not null and "{c}" != \'\' limit 4000'))
        except sqlite3.OperationalError:
            continue
        for (v,) in rows:
            if isinstance(v, (str, bytes)) and v.strip():
                blobs.append((c, v))
    print(f"### json-ish columns scanned: {json_cols}")
    print(f"### blobs scanned: {len(blobs)}")
    if not blobs:
        raise SystemExit("ABORT: 0 blobs -> cannot decide the page-doc shape")

    page_docs = []
    for col, v in blobs:
        text = v.decode("utf-8", "ignore") if isinstance(v, bytes) else v
        if '"media"' not in text:
            continue
        try:
            d = json.loads(text)
        except Exception:
            continue
        stack = [d]
        while stack:
            node = stack.pop()
            if isinstance(node, dict):
                if "media" in node and isinstance(node.get("media"), dict):
                    page_docs.append(node)
                stack.extend(node.values())
            elif isinstance(node, list):
                stack.extend(node)

    # Zero-sample guard: never report a vacuous pass.
    if not page_docs:
        raise SystemExit("ABORT: 0 page docs with a 'media' object -> cannot verify")

    print(f"### real page docs sampled: {len(page_docs)}")

    top_level = 0
    nested = 0
    shapes = Counter()
    differ = 0
    both_nonempty = 0
    old_empty = 0
    new_empty = 0
    sample_old = None
    sample_new = None

    for doc in page_docs:
        media = doc.get("media") or {}
        if doc.get("fileServer") or doc.get("path"):
            top_level += 1
        if media.get("fileServer") or media.get("path"):
            nested += 1
        shapes[tuple(sorted(media.keys()))] += 1

        old = mobile_media_url_from(doc)
        new = mobile_media_url_from(media)
        if old != new:
            differ += 1
        if old == "" and new != "":
            old_empty += 1
            if sample_old is None:
                sample_old = doc
        if new == "" and old != "":
            new_empty += 1
        if old and new:
            both_nonempty += 1
        if sample_new is None and new:
            sample_new = (doc, old, new)

    print(f"Q1 media object key shapes: {dict(shapes)}")
    print(f"Q2 page docs with TOP-LEVEL fileServer/path : {top_level}")
    print(f"Q3 page docs with NESTED media.fileServer/path: {nested}")
    print(f"Q4 mediaUrlFrom(doc) != mediaUrlFrom(doc['media']): {differ} / {len(page_docs)}")
    print(f"   old='' new!='' (old code skipped the page) : {old_empty}")
    print(f"   old!='' new=='' (new code would break)      : {new_empty}")
    print(f"   both non-empty (ambiguous)                  : {both_nonempty}")

    if sample_old is not None:
        print(f"\n### sample doc that OLD code dropped:")
        print(f"   doc keys : {sorted(sample_old.keys())}")
        print(f"   media    : {json.dumps(sample_old.get('media'), ensure_ascii=False)[:220]}")
    if sample_new is not None:
        doc, old, new = sample_new
        print(f"\n### sample both-non-empty:")
        print(f"   old -> {old}")
        print(f"   new -> {new}")

    # ---- assertions: this is a regression guard, not a report ----
    if nested == 0:
        raise SystemExit("ABORT: no nested media.fileServer found -> claim unverifiable")
    if top_level != 0:
        print(f"\nWARN: {top_level} docs DO carry top-level fileServer/path")
    if old_empty == 0:
        raise SystemExit(
            "ABORT: 0 docs where the old code produced '' -> the claimed bug "
            "does not appear in recorded data; fix may be wrong")
    if new_empty != 0:
        raise SystemExit(
            f"ABORT: {new_empty} docs where the NEW code produces '' -> the fix "
            "would break a case the old code handled")

    print(f"\nVERIFIED: {old_empty}/{len(page_docs)} recorded page docs were "
          "dropped by the old call and are recovered by reading doc['media'].")
    print("DONE")


if __name__ == "__main__":
    main()
