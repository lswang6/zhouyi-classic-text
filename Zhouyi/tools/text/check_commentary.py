#!/usr/bin/env python3
"""Self-check for Commentary.strings (zh-Hans + zh-Hant). Run: python3 check_commentary.py  (exit 0 = pass)"""
import os, re, subprocess, sys
R = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../Zhouyi")
FILES = {l: f"{R}/{l}.lproj/Commentary.strings" for l in ('zh-Hans', 'zh-Hant')}
EXPECTED = {f"hex.{n}.{k}" for n in range(1, 65) for k in ['tuan', 'daxiang'] + [f'xiao.{i}' for i in range(6)]}
EXPECTED |= {'hex.1.xiao.6', 'hex.2.xiao.6', 'wenyan.1', 'wenyan.2'}
assert len(EXPECTED) == 64 * 8 + 4
ENTRY = re.compile(r'^"([^"]+)" = "((?:[^"\\]|\\.)*)";$')
ALLOWED = re.compile(r'[㐀-鿿\U00020000-\U0003134f，。；：？！、「」『』\n]')

def load(path):
    subprocess.run(['plutil', '-lint', path], check=True, capture_output=True)
    lines = open(path, encoding='utf8').read().split('\n')
    assert lines[0].startswith('/*') and lines[-1] == '', path
    d = {}
    for l in lines[1:-1]:
        m = ENTRY.match(l); assert m, l
        assert m.group(1) not in d, m.group(1)
        d[m.group(1)] = m.group(2).replace('\\n', '\n').replace('\\"', '"').replace('\\\\', '\\')
    return d

T = {l: load(p) for l, p in FILES.items()}
for l, d in T.items():
    assert set(d) == EXPECTED, (l, set(d) ^ EXPECTED)
    for k, v in d.items():
        assert v.strip() and v == v.strip(), (l, k)
        bad = [c for c in v if not ALLOWED.match(c)]
        assert not bad, (l, k, bad)                        # no ASCII, wiki markup, brackets, labels' 《》
        assert not re.match(r'(彖|象|文言)曰', v), (l, k)  # labels stripped
    assert '\n\n' in d['wenyan.1'] and '\n\n' in d['wenyan.2']
H, S = T['zh-Hant'], T['zh-Hans']
assert all(len(H[k]) == len(S[k]) for k in EXPECTED)          # t2s is char-for-char
assert '干' not in ''.join(S.values()) .replace('干父', '').replace('干母', '').replace('之干也', '').replace('以干事', ''), 'stray 干'
assert all(S[k].count('乾') == H[k].count('乾') for k in EXPECTED), '乾 lost in zh-Hans'
assert not set('无羣') & set(''.join(H.values())), 'zh-Hant must use 無/群 (Classical.strings convention)'

# simplified-char leaks in zh-Hant: s2t must only touch these legit classical chars
from opencc import OpenCC
s2t = OpenCC('s2t'); OK = set('于凶咸征群后辟尸系克欲舍咨斗机恒')   # 于野, 后=君, 辟=避, 拘系 no longer, 日中見斗, 渙奔其机 …
leak = {(k, a) for k, v in H.items() for a, b in zip(v, s2t.convert(v)) if a != b and a not in OK}
assert not leak, leak
assert '系' not in ''.join(H.values()), 'zh-Hant 系 should be 係/繫'

# 小象 alignment: each 小象 should share the most characters with its own 爻辭 (Classical.strings)
cl = dict(re.findall(r'"([^"]+)" = "([^"]*)";', open(f"{R}/zh-Hant.lproj/Classical.strings", encoding='utf8').read()))
def sim(a, b): return len(set(a) & set(b) - set('，。；：？！、「」也之其以而無咎吉凶'))
weak = []
for n in range(1, 65):
    for i in range(6):
        scores = [sim(H[f'hex.{n}.xiao.{i}'], cl[f'hex.{n}.yao.{j}']) for j in range(6)]
        if scores[i] < max(scores): weak.append((n, i, scores))
assert len(weak) <= 6, weak     # a few 小象 paraphrase instead of quoting; listed for eyeballing
print(f"PASS: 2 files, {len(EXPECTED)} keys each, plutil OK, charset OK, 乾 preserved; weak-alignment (eyeball): {weak}")
