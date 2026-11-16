#!/usr/bin/env python3
"""CI triage: fetch runs + real log ZIP for oneMuggle/bika-comics, print the
discriminating lines. Token is read from the Hermes profile config at runtime
and never printed."""
import json
import re
import sys
import urllib.request
import zipfile
import io
import os

OWNER = "oneMuggle"
REPO = "bika-comics"
CONFIG = os.path.expanduser("~/.hermes/profiles/router/config.yaml")


def find_token():
    txt = open(CONFIG).read()
    m = re.search(r"GITHUB_PERSONAL_ACCESS_TOKEN:\s*(\S+)", txt)
    if m:
        return m.group(1).strip().strip("'\"")
    return None


TOKEN = find_token()


def api(path, accept="application/vnd.github+json"):
    req = urllib.request.Request(
        f"https://api.github.com{path}",
        headers={
            "Accept": accept,
            "User-Agent": "hermes-cron",
            **({"Authorization": f"Bearer {TOKEN}"} if TOKEN else {}),
        },
    )
    with urllib.request.urlopen(req, timeout=40) as r:
        return r.read()


def main():
    if not TOKEN:
        print("NO TOKEN FOUND in", CONFIG)
        sys.exit(2)

    print("=== RUNS ===")
    data = json.loads(api(f"/repos/{OWNER}/{REPO}/actions/runs?per_page=8"))
    runs = data.get("workflow_runs", [])
    if not runs:
        print("!! NO RUNS - aborting (would be vacuous)")
        sys.exit(2)
    for r in runs:
        concl = r.get("conclusion") or r.get("status") or "?"
        name = (r.get("name") or "?")[:34]
        num = r.get("run_number")
        num = str(num) if num is not None else "?"
        print(f"{concl:10s} {r.get('created_at','?')} "
              f"{name:34s} #{num:4} "
              f"id={r.get('id')} sha={str(r.get('head_sha'))[:8]}")

    # find the most recent run with a failure
    target = None
    for r in runs:
        if r.get("conclusion") not in ("success", None, "skipped"):
            target = r
            break
    if target is None:
        target = runs[0]

    print(f"\n=== TARGET RUN: id={target['id']} name={target.get('name')} "
          f"conclusion={target.get('conclusion')} ===")

    # jobs
    jd = json.loads(api(f"/repos/{OWNER}/{REPO}/actions/runs/{target['id']}/jobs?per_page=50"))
    jobs = jd.get("jobs", [])
    if not jobs:
        print("!! NO JOBS")
    for j in jobs:
        print(f"\nJOB {j.get('name')} -> {j.get('conclusion')}")
        for s in j.get("steps", []):
            print(f"   {s.get('number','?'):>2} {s.get('name','?')[:44]:44s} "
                  f"{str(s.get('conclusion','?'))}")

    # real logs ZIP
    print("\n=== LOG GREP ===")
    try:
        blob = api(f"/repos/{OWNER}/{REPO}/actions/runs/{target['id']}/logs",
                   accept="application/vnd.github.v3+zip")
    except Exception as e:
        print("log fetch failed:", e)
        return
    try:
        zf = zipfile.ZipFile(io.BytesIO(blob))
    except Exception as e:
        print("not a zip:", e, "len=", len(blob))
        return
    names = zf.namelist()
    print(f"log files: {len(names)}")
    pats = re.compile(
        r"(Execution failed for task|error:|Error:|FAILURE:|^\s*> Task .*FAILED|"
        r"Process: .*\.dart|Could not resolve|was not found|"
        r"Failed to install the following|"
        r"Changed \d+ dependencies|No space left|"
        r"##\[error\]|Unhandled exception|"
        r"✗|failed)", re.M)
    hits = []
    for n in names:
        try:
            body = zf.read(n).decode("utf-8", "replace")
        except Exception:
            continue
        for line in body.splitlines():
            if pats.search(line):
                hits.append((n, line.strip()[:300]))
    if not hits:
        print("!! NO MATCHING LOG LINES - aborting (would be vacuous)")
        sys.exit(2)
    print(f"matched lines: {len(hits)}")
    seen = set()
    for n, line in hits:
        k = line[:160]
        if k in seen:
            continue
        seen.add(k)
        print(f"[{n[-48:]}] {line}")
        if len(seen) > 120:
            print("... truncated")
            break


if __name__ == "__main__":
    main()
