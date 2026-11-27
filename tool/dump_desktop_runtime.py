#!/usr/bin/env python3
"""Print the DESKTOP's RUNTIME signing/header constants (not a re-read of source).

Every value here is obtained by executing the desktop's own code path:
  - the app secret via the literal in tool.py (the desktop's __SigFromNative)
  - the header constants via config/config.py (the desktop's config module)

Purpose: diff these against the mobile's runtime constants to find any
byte-level drift (e.g. escape sequences) that source-reading would hide.
"""
import hashlib
import json
import os
import sys

DESKTOP_SRC = "/home/ubuntu/project/picacg-qt-temp/src"

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__))))
from probe_api_shape import CFG, load_desktop_secret  # noqa: E402

secret = load_desktop_secret()
print("== desktop app secret ==")
print("  repr      : %r" % secret)
print("  length    : %d" % len(secret))
print("  backslashes: %d" % secret.count("\\"))
print("  sha256    : %s" % hashlib.sha256(secret.encode()).hexdigest())

print("\n== desktop config constants ==")
for k in sorted(CFG):
    if k in ("ApiKey", "Accept", "AppChannel", "Uuid", "Version",
             "ImageQuality", "Platform", "BuildVersion", "Agent",
             "UpdateVersion", "Url"):
        print("  %-16s %r" % (k, CFG[k]))

print("\n== desktop config.py raw lines (for escape inspection) ==")
with open(os.path.join(DESKTOP_SRC, "config", "config.py"), encoding="utf-8") as f:
    for i, line in enumerate(f, 1):
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        name = s.split("=", 1)[0].strip()
        if name and name[0].isupper() and any(
                t in name for t in ("Api", "Accept", "App", "Uuid", "Version",
                                    "Image", "Platform", "Build", "Agent",
                                    "Update", "Url")):
            print("  %4d | %s" % (i, line.rstrip()))

print("\n== tool.py secret line (raw, shows escapes) ==")
with open(os.path.join(DESKTOP_SRC, "tools", "tool.py"), encoding="utf-8") as f:
    for i, line in enumerate(f, 1):
        if "__SigFromNative" in line or (i > 125 and i < 135 and "return" in line):
            print("  %4d | %s" % (i, line.rstrip()))

print("\nDESKTOP_RUNTIME_JSON " + json.dumps({
    "secret": secret,
    "secret_len": len(secret),
    "secret_backslashes": secret.count("\\"),
    "secret_sha256": hashlib.sha256(secret.encode()).hexdigest(),
    "config": {k: CFG[k] for k in ("ApiKey", "Accept", "AppChannel", "Uuid",
                                   "Version", "ImageQuality", "Platform",
                                   "BuildVersion", "Agent", "UpdateVersion",
                                   "Url") if k in CFG},
}))
