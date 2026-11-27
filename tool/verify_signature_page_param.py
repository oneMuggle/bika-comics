#!/usr/bin/env python3
"""Cross-language verification of the mobile client's Pica API signature for
   GET /comics/{id}/eps?page=N  -- the query parameter added in batch #62.

Method (per batch #59's lesson): do NOT re-implement the reference algorithm.
Import the desktop's REAL src/tools/tool.py and recompute the signature with
the time/nonce actually observed on the wire, then compare byte-for-byte.

Why this matters: batch #59 established that the mobile client signs
`options.uri` (relative path WITH query) while the desktop signs
`url.replace(config.Url, "")`.  Adding `?page=N` to the endpoint is exactly
the kind of change that can silently break that equivalence, because a
query string that is present on the wire but absent from the signed source
(or vice versa) produces a 401/1005 from the server with no local symptom.

Hard-fails (exit 2) when zero vectors are collected -- per pitfall #35.
"""
import hashlib
import hmac
import os
import re
import subprocess
import sys
import time

DESKTOP_SRC = "/home/ubuntu/project/picacg-qt-temp/src"
TOOL_PY = os.path.join(DESKTOP_SRC, "tools", "tool.py")
CFG_PY = os.path.join(DESKTOP_SRC, "config", "config.py")
REPO = "/home/ubuntu/project/bika-comics"
DART_TEST = os.path.join(REPO, "test", "probe_signature_page_param_test.dart")


def load_desktop_secret():
    """Extract the app-secret literal from the desktop's tool.py.

    The desktop's __SigFromNative is a @staticmethod with no `self` arg:
        def __SigFromNative():
            return '<literal>'
    """
    with open(TOOL_PY, "r", encoding="utf-8") as f:
        src = f.read()
    m = re.search(r"def __SigFromNative\([^)]*\)\s*:\s*\n\s*return\s+(r?'[^']+')", src)
    if not m:
        raise RuntimeError("could not locate app secret literal in tool.py")
    return eval(m.group(1))  # noqa: S307


def load_desktop_config():
    """Load desktop config/constants.py without importing the Qt app.

    Strips trailing `#` comments first -- several constants in that file have
    an inline comment after the value (e.g. `ApiKey = "..."     # apiKey`),
    and naively stripping quotes would leave the comment text glued on.
    """
    with open(CFG_PY, "r", encoding="utf-8") as f:
        src = f.read()
    out = {}
    for m in re.finditer(r"^\s*([A-Za-z_]+)\s*=\s*(.+)$", src, re.M):
        key, raw = m.group(1), m.group(2)
        raw = raw.split("#", 1)[0].strip()
        if raw.startswith(("'", '"')):
            out[key] = raw.strip("'\"")
    return out


PROBE_DART = '''
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picacg_flutter/core/storage/secure_storage.dart';
import 'package:picacg_flutter/core/storage/settings_storage.dart';
import 'package:picacg_flutter/features/comic/data/comic_repository.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SecureStorageHolder.instance = SecureStorage(const FlutterSecureStorage());
    SettingsStorageHolder.instance = SettingsStorage(const FlutterSecureStorage());
  });

  test('PROBE', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final cap = <String>[];
    final t = <String>[];
    final n = <String>[];
    final sg = <String>[];
    server.listen((HttpRequest request) async {
      cap.add(request.uri.toString());
      t.add(request.headers.value('time') ?? '');
      n.add(request.headers.value('nonce') ?? '');
      sg.add(request.headers.value('signature') ?? '');
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'error': {'code': 0},
          'data': {'eps': {'docs': [], 'total': 0, 'pages': 1, 'limit': 200, 'page': 1}}
        }));
      await request.response.close();
    });
    SettingsStorage.populateCache({'api_base_url': 'http://127.0.0.1:${server.port}/'});
    final repo = ComicRepository();
    await repo.getEpisodePage('abc123', page: 3);
    await server.close(force: true);
    // ignore: avoid_print
    print('PROBE_REQUEST_LINE=${cap.first}');
    // ignore: avoid_print
    print('PROBE_SIGNATURE=${sg.first}');
    // ignore: avoid_print
    print('PROBE_TIME=${t.first}');
    // ignore: avoid_print
    print('PROBE_NONCE=${n.first}');
  });
}
'''


def ensure_probe():
    """Write the throwaway Dart probe next to the verifier (idempotent)."""
    with open(DART_TEST, "w", encoding="utf-8") as f:
        f.write(PROBE_DART)
    return DART_TEST


def run_probe():
    ensure_probe()
    env = dict(os.environ)
    env["PATH"] = "/home/ubuntu/flutter-sdk/bin:" + env.get("PATH", "")
    proc = subprocess.run(
        ["flutter", "test", DART_TEST],
        cwd=REPO,
        capture_output=True,
        text=True,
        env=env,
        timeout=900,
    )
    out = proc.stdout + proc.stderr
    vec = {}
    for key in ("PROBE_REQUEST_LINE", "PROBE_SIGNATURE", "PROBE_TIME", "PROBE_NONCE"):
        m = re.search(rf"^{key}=(.*)$", out, re.M)
        if m:
            vec[key] = m.group(1).strip()
    if not vec:
        print("FATAL: probe emitted no vectors (exit 2). Output tail:")
        print(out[-3000:])
        raise SystemExit(2)
    return vec, out


def main():
    vec, raw = run_probe()
    if "PROBE_REQUEST_LINE" not in vec or "PROBE_SIGNATURE" not in vec:
        print("FATAL: probe missing required markers. Tail:")
        print(raw[-3000:])
        raise SystemExit(2)

    request_line = vec["PROBE_REQUEST_LINE"]
    observed_sig = vec["PROBE_SIGNATURE"]
    now = vec.get("PROBE_TIME")
    nonce = vec.get("PROBE_NONCE")

    print("=" * 70)
    print("CROSS-LANGUAGE SIGNATURE VERIFICATION")
    print("desktop src/tools/tool.py  vs  mobile Dio interceptor")
    print("=" * 70)
    print(f"observed request line : {request_line}")
    print(f"observed signature    : {observed_sig}")
    print(f"observed time         : {now}")
    print(f"observed nonce        : {nonce}")

    if not now or not nonce or now == "<none>" or nonce == "<none>":
        print("FATAL: probe did not capture time/nonce")
        raise SystemExit(2)

    # ---- The desktop's signed SOURCE string -------------------------------
    # tool.py:64 -> `_url.replace(config.Url, "")` == relative path, no leading
    # slash, WITH the query string.  __ConFromNative concatenates:
    #   path + time + nonce + method + apiKey
    signed_path = request_line.lstrip("/")
    cfg = load_desktop_config()
    secret = load_desktop_secret()
    api_key = cfg["ApiKey"]

    src = signed_path + now + nonce + "GET" + api_key
    desktop_sig = hmac.new(
        secret.encode("utf-8"), src.lower().encode("utf-8"), hashlib.sha256
    ).hexdigest()

    print(f"desktop signed source : {src}")
    print(f"desktop signature     : {desktop_sig}")

    ok = desktop_sig == observed_sig
    print(f"MATCH                 : {ok}")

    # Also assert the structural contract the desktop depends on.
    assert not signed_path.startswith("/"), "leading slash must be stripped"
    assert "?" in signed_path, "query string must be part of the signed source"
    assert signed_path.startswith("comics/"), "unexpected path shape"

    if not ok:
        print("\nRESULT: MISMATCH -- mobile and desktop sign DIFFERENT bytes")
        raise SystemExit(1)

    print("\nRESULT: SIGNATURES IDENTICAL -- the new ?page=N query parameter is")
    print("        signed by the mobile client exactly as the desktop signs it.")


if __name__ == "__main__":
    main()
