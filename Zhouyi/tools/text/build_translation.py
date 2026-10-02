#!/usr/bin/env python3
"""Build <lang>.lproj/Translation.strings (经文译文, non-Chinese UI) from scratch JSON.
Run: python3 build_translation.py <scratch dir>
  en: <scratch>/legge/legge_clean.json (else legge.json) — James Legge 1882, 966 keys incl. 十翼
  ja ko es pt-BR fr de ru ar: <scratch>/xl/<lang>.json — 514 keys (卦辞、爻辞、大象、用九/用六)
Missing files are skipped; a present file whose key set is wrong is reported, not written, and the run exits 1."""
import json, os, subprocess, sys
REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../Zhouyi")

CORE = [f"hex.{n}.{k}" for n in range(1, 65) for k in ["ci", "daxiang"] + [f"yao.{i}" for i in range(6)]] + ["hex.1.yong", "hex.2.yong"]
FULL = CORE + [f"hex.{n}.{k}" for n in range(1, 65) for k in ["tuan"] + [f"xiao.{i}" for i in range(6)]] \
    + ["hex.1.xiao.6", "hex.2.xiao.6", "wenyan.1", "wenyan.2"]
assert len(set(CORE)) == 514 and len(set(FULL)) == 966
LEGGE = "James Legge, The Yî King (SBE XVI, 1882), public domain"
EDITORS = "Translated by the Zhouyi app editors from the classical text"

def esc(s): return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

def main(scratch):
    legge = next((p for p in (f"{scratch}/legge/legge_clean.json", f"{scratch}/legge/legge.json") if os.path.exists(p)), None)
    jobs = [("en", legge, FULL, LEGGE)] + [(l, f"{scratch}/xl/{l}.json", CORE, EDITORS) for l in "ja ko es pt-BR fr de ru ar".split()]
    bad = []
    for lang, src, keys, credit in jobs:
        if not src or not os.path.exists(src): print(f"skip {lang}: no source"); continue
        d = json.load(open(src, encoding="utf8"))
        missing, extra = set(keys) - set(d), set(d) - set(keys)
        empty = [k for k in keys if k in d and not str(d[k]).strip()]
        if missing or extra or empty:
            bad.append(lang)
            print(f"FAIL {lang} ({src}): {len(d)} keys, want {len(keys)}; missing {len(missing)}, extra {len(extra)}, empty {len(empty)}"
                  f" e.g. {sorted(missing | extra)[:3] + empty[:3]}", file=sys.stderr)
            continue
        out = f"{REPO}/{lang}.lproj/Translation.strings"
        with open(out, "w", encoding="utf8") as f:
            f.write(f"/* 周易 · {lang} · 经文译文. {credit}. Source: {os.path.basename(src)} */\n")
            for k in keys: f.write(f'"{k}" = "{esc(d[k].strip())}";\n')
        r = subprocess.run(["plutil", "-lint", out], capture_output=True, text=True)
        if r.returncode: sys.exit(f"plutil failed: {r.stdout}{r.stderr}")
        print(f"wrote {lang}: {len(keys)} keys")
    if bad: sys.exit(f"incomplete: {' '.join(bad)}")

if __name__ == "__main__":
    if len(sys.argv) != 2: sys.exit(__doc__)
    main(sys.argv[1])
