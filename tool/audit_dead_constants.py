#!/usr/bin/env python3
"""核查 8 个"无消费方"的 API 常量，逐个与桌面端 src/server/req.py 对照。

consumer_audit.py 报告以下常量在 lib/ 中从未被引用：
  chatMessages, chatRooms, commentChildren, commentLike, commentReport,
  speedTestPing, userComments, userFavorites

必须回到桌面端源码逐个核实（pitfall #25），区分三种情况：
  A. 桌面端也没有该端点         -> 移动端不算缺口
  B. 移动端用硬编码字符串实现了  -> 不算缺口（只是常量没被用上）
  C. 桌面端有，移动端确实没有   -> 真实缺口
"""
import os
import re

DESKTOP = "/home/ubuntu/project/picacg-qt-temp/src"
MOBILE = "/home/ubuntu/project/bika-comics/lib"

NAMES = ["chatMessages", "chatRooms", "commentChildren", "commentLike",
         "commentReport", "speedTestPing", "userComments", "userFavorites"]

aconst = os.path.join(MOBILE, "shared/constants/api_constants.dart")
with open(aconst, encoding="utf-8") as f:
    atext = f.read()

vals = {}
for name in NAMES:
    m = re.search(
        r"static\s+(?:const\s+)?String\s+%s\s*(?:\([^)]*\))?\s*=>\s*'([^']*)'"
        % re.escape(name), atext)
    if not m:
        m = re.search(
            r"static\s+(?:const\s+)?String\s+%s\s*(?:\([^)]*\))?\s*=\s*'([^']*)'"
            % re.escape(name), atext)
    vals[name] = m.group(1) if m else None

print("=== MOBILE CONSTANT VALUES ===")
for k, v in vals.items():
    print("  %-18s %s" % (k, v))

# 桌面端所有端点
with open(os.path.join(DESKTOP, "server/req.py"), encoding="utf-8") as f:
    rtext = f.read()
desktop_urls = re.findall(r'config\.Url\s*\+\s*"([^"]+)"', rtext)


def norm(s):
    s = s.split("?")[0].rstrip("/")
    s = re.sub(r"\$\{[^}]*\}", "<>", s)
    s = re.sub(r"\$[A-Za-z_][A-Za-z0-9_]*", "<>", s)   # $var（非花括号）
    s = re.sub(r"\{[^}]*\}", "<>", s)
    return s


desktop_norm = {}
for u in desktop_urls:
    desktop_norm.setdefault(norm(u), u)

# 移动端 lib/ 所有 url 字面量
mobile_urls = []
for root, dirs, files in os.walk(MOBILE):
    for fn in files:
        if not fn.endswith(".dart"):
            continue
        p = os.path.join(root, fn)
        with open(p, encoding="utf-8") as f:
            t = f.read()
        for m in re.finditer(r"""['"](/[A-Za-z][A-Za-z0-9_\-/]*[^'"]*)['"]""", t):
            mobile_urls.append((m.group(1), os.path.relpath(p, MOBILE)))

print("\n=== PER-CONSTANT ANALYSIS ===")
verdict = {}
for name in NAMES:
    val = vals.get(name)
    if val is None:
        print("\n%s: CONSTANT NOT PARSED" % name)
        verdict[name] = "NOT_PARSED"
        continue
    key = norm(val)
    desktop_hit = desktop_norm.get(key)
    if desktop_hit is None:
        base = key.rsplit("/", 1)[-1]
        cands = [d for k2, d in desktop_norm.items() if base and base in k2.lower()]
        desktop_hit = ("SOFT->" + ", ".join(cands[:3])) if cands else "NONE"

    mobile_hit = sorted({p for u, p in mobile_urls
                         if norm(u) == key and "api_constants" not in p})

    print("\n%s = '%s'  (norm=%s)" % (name, val, key))
    print("  desktop endpoint : %s" % desktop_hit)
    print("  mobile hardcoded : %s" % (mobile_hit or "NONE"))
    if desktop_hit == "NONE":
        v = "A_DESKTOP_LACKS_TOO"
    elif mobile_hit:
        v = "B_IMPLEMENTED_VIA_HARDCODED"
    else:
        v = "C_REAL_GAP"
    verdict[name] = v
    print("  VERDICT          : %s" % v)

print("\n=== SUMMARY ===")
for k, v in verdict.items():
    print("  %-18s %s" % (k, v))

gaps = [k for k, v in verdict.items() if v == "C_REAL_GAP"]
print("\nREAL_GAPS: %d %s" % (len(gaps), gaps))

# 零样本守卫
if not verdict or all(v == "NOT_PARSED" for v in verdict.values()):
    raise SystemExit("ABORT: zero samples parsed")
