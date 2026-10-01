#!/usr/bin/env python3
"""校验某语言的 lproj：python3 tools/check_lang.py <lang> [--ui-only|--content-only]
与 zh-Hans 清单比对键、格式符、空值；Hexagrams/Classical 键数。"""
import re, subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent / "Zhouyi"
SPEC = re.compile(r"%(?:\d+\$)?[@dDfsu]")

def load(p):
    if not p.exists():
        return None
    r = subprocess.run(["plutil", "-lint", str(p)], capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"SYNTAX {p}: {r.stdout}{r.stderr}")
    out = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(p)], capture_output=True, text=True)
    import json
    return json.loads(out.stdout)

def types(s):
    return sorted(re.sub(r"\d+\$", "", m) for m in SPEC.findall(s))

lang, mode = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else "")
errs = []
d = ROOT / f"{lang}.lproj"
if mode != "--content-only":
    man = load(ROOT / "zh-Hans.lproj/Localizable.strings")
    ui = load(d / "Localizable.strings") or {}
    for k in man:
        if k not in ui: errs.append(f"missing UI key: {k!r}")
        elif not ui[k].strip(): errs.append(f"empty: {k!r}")
        elif types(ui[k]) != types(k): errs.append(f"specifier mismatch: {k!r} -> {ui[k]!r}")
    errs += [f"extra UI key: {k!r}" for k in ui if k not in man]
    ip = load(d / "InfoPlist.strings") or {}
    if not ip.get("CFBundleDisplayName", "").strip(): errs.append("InfoPlist.strings: CFBundleDisplayName missing")
if mode != "--ui-only" and lang != "zh-Hans":   # zh-Hans 卦文在 HexagramData.swift
    hx = load(d / "Hexagrams.strings") or {}
    want = {f"hex.{n}.{f}" for n in range(1, 65) for f in ("name", "full", "bh")} | {f"tri.{i}.{f}" for i in range(1, 9) for f in ("k", "nat")}
    errs += [f"Hexagrams missing: {k}" for k in sorted(want - hx.keys())]
    errs += [f"Hexagrams extra: {k}" for k in sorted(hx.keys() - want)]
    errs += [f"Hexagrams empty: {k}" for k, v in hx.items() if not v.strip()]
    cl = load(d / "Classical.strings")
    if lang == "zh-Hant":
        want = {f"hex.{n}.ci" for n in range(1, 65)} | {f"hex.{n}.yao.{i}" for n in range(1, 65) for i in range(6)} | {"yongjiu.text", "yongliu.text"}
        cl = cl or {}
        errs += [f"Classical missing: {k}" for k in sorted(want - cl.keys())]
        errs += [f"Classical extra: {k}" for k in sorted(cl.keys() - want)]
    elif cl is not None:
        errs.append("Classical.strings must exist only for zh-Hant")
    if lang != "zh-Hant":
        cjk = re.compile(r"[一-鿿]")
        if lang not in ("ja",):
            errs += [f"CJK left in {k}: {v!r}" for k, v in hx.items() if cjk.search(v)]
print("\n".join(errs) or f"OK {lang}")
sys.exit(1 if errs else 0)
