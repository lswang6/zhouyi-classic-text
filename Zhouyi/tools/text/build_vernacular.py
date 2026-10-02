"""合并白话译文 part-*.json → zh-Hans / zh-Hant Vernacular.strings。用法：python build_vernacular.py <parts_dir>"""
import glob, json, os, re, sys
from opencc import OpenCC

APP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../Zhouyi")
d = {}
for f in sorted(glob.glob(os.path.join(sys.argv[1], "part-*.json"))):
    d.update(json.load(open(f, encoding="utf8")))

keys = [f"hex.{n}.{k}" for n in range(1, 65) for k in
        ["ci", *[f"yao.{i}" for i in range(6)], "tuan", "daxiang", *[f"xiao.{i}" for i in range(6)]]]
keys += ["hex.1.yong", "hex.1.xiao.6", "hex.2.yong", "hex.2.xiao.6", "wenyan.1", "wenyan.2"]
missing, extra = set(keys) - set(d), set(d) - set(keys)
assert not missing and not extra, (sorted(missing)[:20], sorted(extra)[:20])
assert all(d[k].strip() for k in keys), [k for k in keys if not d[k].strip()]

# 文言段数须与原文一致
com = open(os.path.join(APP, "zh-Hans.lproj/Commentary.strings"), encoding="utf8").read()
for n in (1, 2):
    src = re.search(r'"wenyan\.%d" = "((?:[^"\\]|\\.)*)";' % n, com).group(1).split("\\n\\n")
    assert len(d[f"wenyan.{n}"].split("\n\n")) == len(src), f"wenyan.{n} paragraphs"

t2 = OpenCC("s2twp")
fix = [("幹卦", "乾卦"), ("幹道", "乾道"), ("幹元", "乾元")]   # 卦名保护；其余按 s2twp 词组转换，生成后人工抽查
def esc(s): return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
for lang, conv in (("zh-Hans", lambda s: s), ("zh-Hant", t2.convert)):
    out = ["/* 经传白话译文（原创）。由 Zhouyi/tools/text/build_vernacular.py 生成 */"]
    for k in keys:
        v = conv(d[k])
        for a, b in fix: v = v.replace(a, b)
        out.append(f'"{k}" = "{esc(v)}";')
    open(os.path.join(APP, f"{lang}.lproj/Vernacular.strings"), "w", encoding="utf8").write("\n".join(out) + "\n")
print(len(keys), "keys written")
