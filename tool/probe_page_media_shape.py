#!/usr/bin/env python3
"""Probe the REAL pica API response shape for /comics/{id}/order/{eid}/pages.

We cannot reach picaapi.picacomic.com from this host (network egress is
blocked), so this script reconstructs the shape from the DESKTOP reference
implementation, which parses the same endpoint:

    src/tools/book.py:243
        for i, data in enumerate(r.data['pages']['docs']):
            ...
            ToolUtil.ParseFromData(picInfo, data['media'])

i.e. the page doc is a WRAPPER whose media lives under the 'media' key.
`Picture` (src/tools/book.py:11) then receives fileServer/path/originalName.

This script prints the exact expected doc shape so the Dart side can be
checked against it, and asserts the two candidate accessors differ.
"""
import json
import sys

# Shape as produced by the pica API for /comics/{id}/order/{eid}/pages
PAGE_DOC = {
    "_id": "5f9c0a1b2c3d4e5f",
    "media": {
        "fileServer": "https://storage1.picacomic.com",
        "path": "tobeimg/gJ6Mi_xxx/aHR0cHM6Ly9zdG9yYWdlMS5waWNhY29taWMuY29tL3N0YXRpYy81YzdjNWNlMC0....jpg",
        "originalName": "0001.jpg",
    },
}

FILE_SERVER = PAGE_DOC["media"]["fileServer"]
PATH = PAGE_DOC["media"]["path"]


def get_real_url(url, path):
    """Desktop ToolUtil.GetRealUrl (src/tools/tool.py:519)."""
    if path:
        if url[-7:] != "static/":
            return url + "/static/" + path
        return url + path
    return url


def media_url_from(obj):
    """Mobile mediaUrlFrom semantics (lib/core/utils/media_url.dart)."""
    if not isinstance(obj, dict):
        return ""
    file_server = obj.get("fileServer", "") or ""
    path = obj.get("path", "") or ""
    url = obj.get("url")
    if not file_server and not path and url:
        return url
    if not path:
        return file_server
    if path.startswith("http://") or path.startswith("https://"):
        return path
    if not file_server:
        return path
    if file_server.endswith("static/"):
        return file_server + path.lstrip("/")
    return file_server.rstrip("/") + "/static/" + path.lstrip("/")


def main():
    print("=== expected page doc shape (from desktop parser) ===")
    print(json.dumps(PAGE_DOC, ensure_ascii=False, indent=2))

    expected = get_real_url(FILE_SERVER, PATH)

    # --- accessor A: what the READER does today (correct) ---
    reader_url = media_url_from(PAGE_DOC["media"])

    # --- accessor B: what the DOWNLOAD path does today (suspect) ---
    download_url = media_url_from(PAGE_DOC)

    print("\n=== accessor comparison ===")
    print("desktop expected :", expected)
    print("reader  media[]  :", reader_url)
    print("download (whole) :", download_url)

    if reader_url != expected:
        print("MISMATCH: reader accessor != desktop reference")
        raise SystemExit(2)
    if download_url == expected:
        print("OK: download accessor also matches")
        return 0

    print("\n>>> DEFECT CONFIRMED: download accessor differs from desktop reference")
    print("    download produces:", repr(download_url))
    print("    desktop produces:", repr(expected))
    print("    reason: the API nests media under doc['media']; passing the whole")
    print("            doc yields no fileServer/path, so mediaUrlFrom returns ''")
    print("            -> every page is skipped by `if (imageUrl.isEmpty) continue;`")
    print("            -> 0 images downloaded for every episode.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
