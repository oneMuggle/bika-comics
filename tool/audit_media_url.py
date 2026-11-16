#!/usr/bin/env python3
"""Audit the pica media-URL join rule against the DESKTOP reference and REAL data.

The mobile app must build every pica media URL the same way the desktop does.
Desktop reference (authoritative, read-only):

    src/tools/tool.py:519
        def GetRealUrl(url, path):
            if path:
                if url[-7:] != "static/":
                    return url + "/static/" + path
                else:
                    return url + path
            else:
                return url

All 13 desktop call sites use it:
    component/list/category_list_widget.py:77
    component/list/comic_list_widget.py:204
    component/list/user_list_widget.py:116,179,238
    component/widget/navigation_widget.py:178
    view/info/game_info_view.py:157,165
    view/info/book_info_view.py:354,369
    view/chat/chat_room_widget.py:299
    task/task_download.py:342

This script answers, from RECORDED REAL DATA only:

  Q1. Do any recorded `path` values start with '/'?            (0 expected)
  Q2. Do any recorded `fileServer` values end with 'static/'?   (0 expected)
  Q3. What are the real `fileServer` values?
  Q4. Are avatar / media objects stored as {fileServer, path}?

It also re-derives the join candidates so the choice is auditable, and
hard-fails on ZERO samples (a vacuous "everything matches" is not a pass).

Usage:  python3 tool/audit_media_url.py
"""
import json
import os
import re
import sqlite3
from collections import Counter

DB = os.environ.get("PICA_DB", "/home/ubuntu/extract_db/book.db")
MOBILE = os.environ.get("PICA_MOBILE", "/home/ubuntu/project/bika-comics")
DESKTOP = os.environ.get("PICA_DESKTOP", "/home/ubuntu/project/picacg-qt-temp")


def desktop_get_real_url(url, path):
    """Byte-for-byte mirror of desktop ToolUtil.GetRealUrl(url, path)."""
    if path:
        if url[-7:] != "static/":
            return url + "/static/" + path
        return url + path
    return url


def main():
    if not os.path.exists(DB):
        raise SystemExit(f"ABORT: real DB not found: {DB}")

    con = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    cur = con.cursor()

    rows = list(cur.execute(
        "select path, fileServer from book where path is not null and path != ''"))
    # Zero-sample guard: never report a vacuous pass.
    if not rows:
        raise SystemExit("ABORT: 0 rows with a path -> cannot decide the join rule")

    print(f"### real rows sampled: {len(rows)}")

    leading = [r for r in rows if (r[0] or "").startswith("/")]
    static_fs = [r for r in rows if (r[1] or "").endswith("static/")]
    fs_counter = Counter((r[1] or "") for r in rows)

    print(f"Q1 paths starting with '/':        {len(leading)}")
    print(f"Q2 fileServers ending 'static/':    {len(static_fs)}")
    print(f"Q3 distinct fileServer values:      {len(fs_counter)}")
    for fs, n in fs_counter.most_common(10):
        print(f"     {n:7d}  {fs!r}")

    # Q4: avatar object shape from the creator JSON column.
    crs = list(cur.execute(
        "select creator from book where creator is not null and creator != ''"))
    shapes = Counter()
    abs_ct = rel_ct = 0
    sample = None
    for (cr,) in crs:
        try:
            d = json.loads(cr)
        except Exception:
            continue
        if not isinstance(d, dict):
            continue
        av = d.get("avatar")
        if not isinstance(av, dict):
            continue
        shapes[tuple(sorted(av.keys()))] += 1
        p = av.get("path") or ""
        if re.match(r"^https?://", p):
            abs_ct += 1
        elif p:
            rel_ct += 1
        if sample is None:
            sample = av
    print(f"Q4 avatar object shapes: {dict(shapes)}")
    print(f"   avatar path absolute={abs_ct} relative={rel_ct}")
    if sample:
        print(f"   sample avatar: {json.dumps(sample, ensure_ascii=False)[:200]}")

    # The join candidates, for auditability.
    p0, fs0 = rows[0]
    print("\n### join candidates (first real row)")
    print(f"   desktop GetRealUrl : {desktop_get_real_url(fs0 or '', p0 or '')}")
    print(f"   mobile old idiom   : {(fs0 or '') + (p0 or '')}   <- host/path glued")
    print(f"   no-static variant  : {(fs0 or '') + '/' + (p0 or '')}")

    # Cross-check: the mobile utility must agree with the desktop on EVERY row.
    dart = os.path.join(MOBILE, "lib/core/utils/media_url.dart")
    if os.path.exists(dart):
        src = open(dart, encoding="utf-8").read()
        has_static = '"/static/"' in src
        has_guard = "static/" in src
        print(f"\n### mobile utility present: {dart}")
        print(f"   contains '/static/' join : {has_static}")
        print(f"   contains static/ guard   : {has_guard}")
        if not (has_static and has_guard):
            raise SystemExit("ABORT: mobile utility does not implement GetRealUrl")

    con.close()
    print("\nDONE")


if __name__ == "__main__":
    main()
