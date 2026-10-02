#!/usr/bin/env python3
"""Verify Zhouyi app 卦辞/爻辞 against Wikisource 周易 (ref/ws/NN.txt) and freizl/yijing (ref/freizl_*_64gua.json).
Run: venv/bin/python verify_text.py   (re-fetch refs with fetch_ws.py + gh api, see report)"""
import re, json, glob, sys, os
from opencc import OpenCC
REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../Zhouyi")
HERE = os.path.dirname(os.path.abspath(__file__))
t2s, s2t = OpenCC('t2s'), OpenCC('s2t')
# char variants treated as 异体 (applied after t2s); (a) class if ONLY these differ
VAR = {'祐':'佑','畬':'畲','寘':'置','蔾':'藜','沬':'沫','闚':'窥','窺':'窥','洌':'冽','震':'振','遯':'遁','苞':'包','彚':'彙','它':'他','敺':'驅','驅':'驅','輹':'輻','貳':'贰','兇':'凶','閽':'薰','衹':'只','无':'无','無':'无','羣':'群','於':'于','脩':'修','脢':'脢','峕':'时','悶':'闷','咸':'咸','鹹':'咸','噬':'噬','說':'说','爲':'为','為':'为','啓':'启','啟':'启','寔':'实','槩':'概','裏':'里','裡':'里','甯':'宁','寧':'宁','綫':'线','線':'线','麤':'粗','粗':'粗','喪':'丧','衞':'卫','衛':'卫','愼':'慎','慎':'慎','廻':'回','迴':'回','恆':'恒','恒':'恒','彊':'强','強':'强','强':'强','災':'灾','烖':'灾','菑':'灾','祇':'只','祗':'只','只':'只','衹':'只'}
PUNCT = re.compile(r'[\s，。、；：！？“”‘’「」『』《》（）()·,.;:!?\-—…　]')
def fold(s):
    s = t2s.convert(PUNCT.sub('', s))
    return ''.join(VAR.get(c, c) for c in s)
def strip(s): return PUNCT.sub('', s)

# ---- ours
src = open(f"{REPO}/HexagramData.swift", encoding='utf8').read()
rows = [l.split('|') for l in src.split('"""')[1].strip().split('\n')]
assert len(rows) == 64 and all(len(r) == 10 for r in rows), [len(r) for r in rows]
strings = dict(re.findall(r'"([^"]+)"\s*=\s*"([^"]*)";', open(f"{REPO}/zh-Hant.lproj/Classical.strings", encoding='utf8').read()))
def ours_s(n, k): return rows[n-1][2] if k == 'ci' else rows[n-1][3+k+1] if False else (rows[n-1][4+k])
def ours_t(n, k): return strings.get(f"hex.{n}.ci" if k == 'ci' else f"hex.{n}.yao.{k}")
YONG = {1: ('用九', '見群龍無首，吉。', '见群龙无首，吉。'), 2: ('用六', '利永貞。', '利永贞。')}  # app literals (Zhouyi.swift:152-153 / strings)

# ---- reference A: Wikisource
def clean_ws(t):
    t = re.sub(r'-\{([^}]*)\}-', r'\1', t)
    t = re.sub(r'\{\{另\|([^|}]*)\|[^}]*\}\}', r'\1', t)
    t = re.sub(r'\{\{[^}]*\}\}', '', t)
    return re.sub(r"<[^>]+>|'''", '', t)
WS = {}
for n in range(1, 65):
    t = clean_ws(open(f"{HERE}/ref/ws/{n:02d}.txt", encoding='utf8').read())
    nmraw = re.search(r"易經：[^\n]*\n\*\*<span[^>]*>'''([^']+)'''(：?)", open(f"{HERE}/ref/ws/{n:02d}.txt", encoding='utf8').read())
    blk = re.search(r"易經：[^\n]*\n((?:\*\*[^\n]*\n)+)", t).group(1)
    ci = re.sub(r"^\*+", "", blk, flags=re.M).replace('\n', '')
    # name label is bold-prefixed; if no '：' the name is part of the 卦辞 (履虎尾/否之匪人/同人于野)
    if nmraw.group(2): ci = ci.split('：', 1)[1]
    lines = re.findall(r'^\*#([^\n]+)', t.split('彖曰')[0], re.M)
    PRE = r'^(初[九六]|[九六][二三四五]|上[九六]|用[九六])[：，]'
    ys = [re.sub(PRE, '', l).strip() for l in lines]
    xia = re.search(r'下(.)上|(.)下(.)上', t.split('\n;')[1].split('\n')[1]) if False else None
    tri = re.search(r'\]\]\s*(\S+?)下(\S+?)上', t)
    WS[n] = dict(ci=ci, yao=ys[:6], extra=ys[6:], lo=tri.group(1) if tri else None, up=tri.group(2) if tri else None,
                 prefix=[re.match(PRE, l).group(1) for l in lines])
# ---- reference C: Kanripo KR1a0001 (TLS edition of 周易 正文)
KR = {}
YT = r'(?m)^(初[九六]|[九六][二三四五]|上[九六]|用[九六])[：、]'
for n in range(1, 65):
    t = '\n'.join(l for l in open(f"{HERE}/ref/kr/{n:02d}.txt", encoding='utf8').read().split('\n') if not l.startswith('#') and not l.startswith('**'))
    t = re.sub(r'<pb:[^>]*>|¶|[䷀-䷿]|（[^）]*）', '', t)
    t = re.sub(r'^[^\n]*[下][^\n]*上[^\n]*\n', '', t.lstrip('\n'), count=1) if re.match(r'^[^\n]*下[^\n]*上', t.lstrip('\n')) else t
    t = re.sub(r'^《[^》]*》', '', t.lstrip('\n'), count=1)       # drop 《name》 label
    body = t.replace('\n', '')
    ci = re.split(r'《彖》|(?m:^(?:初[九六]|[九六][二三四五]|上[九六])[：、])', t, maxsplit=1)[0].replace('\n', '')
    parts = re.split(YT, t)
    ys = [(parts[i], parts[i+1].split('《')[0].replace('\n', '').strip()) for i in range(1, len(parts)-1, 2)]
    KR[n] = dict(ci=ci, yao=[v for k, v in ys if not k.startswith('用')], extra=[v for k, v in ys if k.startswith('用')])
    assert len(KR[n]['yao']) == 6, (n, ys)
# ---- reference B: freizl/yijing zh-TW (ids are binary, order = King Wen)
FZ = json.load(open(f"{HERE}/ref/freizl_zh-TW_64gua.json", encoding='utf8'))
FZS = json.load(open(f"{HERE}/ref/freizl_zh-CN_64gua.json", encoding='utf8'))
def fzci(g): return g['gua_ci'].split('：', 1)[1] if g['gua_ci'].startswith(g['name'] + '：') else g['gua_ci']
def fzy(g): return [re.sub(r'^(初[九六]|[九六][二三四五]|上[九六]|用[九六])[：，]?', '', y) for y in g['yao_ci']]

issues = []   # (class, n, field, ours, ref, evidence)
variants = {}  # (n, field) -> note
def field_name(k): return '卦辞' if k == 'ci' else f'爻{k+1}({"初二三四五上"[k]})'
def cmp(n, k, ours, refs, label):
    """refs: dict name -> trad/simp ref string. returns list of mismatch descriptions"""
    out = []
    for rn, r in refs.items():
        if fold(ours) == fold(r):
            raw_o, raw_r = strip(ours), strip(r)
            # raw (unfolded) difference beyond punctuation => variant-only
            if t2s.convert(raw_o) != t2s.convert(raw_r):
                variants.setdefault((n, field_name(k), label), []).append((rn, raw_o, raw_r))
        else:
            out.append((rn, r))
    return out

REFS = {}
counts = dict(fields=0, all_agree=0, variant_only=0, ref_disagree_ours_matches_one=0, ours_differs_from_both=0, trad_vs_simp_mismatch=0, misplaced=0)
def eq(a, b): return fold(a) == fold(b)
for n in range(1, 65):
    for k in ['ci', 0, 1, 2, 3, 4, 5]:
        o_s, o_t = ours_s(n, k), ours_t(n, k)
        ws = WS[n]['ci'] if k == 'ci' else WS[n]['yao'][k]
        fz = fzci(FZ[n-1]) if k == 'ci' else fzy(FZ[n-1])[k]
        counts['fields'] += 1
        cmp(n, k, o_s, {'wikisource': ws, 'freizl': fz}, 'simplified'); cmp(n, k, o_t, {'wikisource': ws, 'freizl': fz}, 'traditional')
        fn = field_name(k)
        if not eq(o_s, o_t):
            counts['trad_vs_simp_mismatch'] += 1; issues.append(('internal', n, fn, o_s, o_t, 'simplified source vs Classical.strings differ'))
        for lab, o in (('S', o_s),):
            kr = KR[n]['ci'] if k == 'ci' else KR[n]['yao'][k]
            ok_ws, ok_fz, ok_kr = eq(o, ws), eq(o, fz), eq(o, kr)
            REFS[(n, fn)] = (o, o_t, ws, fz, kr)
            if ok_ws and ok_fz and ok_kr: counts['all_agree'] += 1
            elif ok_ws or ok_fz or ok_kr:
                counts['ref_disagree_ours_matches_one'] += 1
                issues.append(('refdiff', n, fn, o, '', f"matches ws={ok_ws} fz={ok_fz} kr={ok_kr} | ws={ws} | fz={fz} | kr={kr}"))
            else:
                allws = [WS[n]['ci']] + WS[n]['yao']
                mis = [i for i, w in enumerate(allws) if eq(w, o)]
                cls = 'd' if mis else 'c'
                counts['misplaced' if mis else 'ours_differs_from_both'] += 1
                issues.append((cls, n, fn, o, ws, f"freizl={fz} | kanripo={kr}" + (f" | ours matches ws item {mis}" if mis else '')))
        if not eq(o_t, ws) and not eq(o_t, fz) and eq(o_s, ws):
            issues.append(('internal', n, fn, o_s, o_t, 'trad string differs from refs though simplified matches'))
# ---- 用九/用六
for n, (nm, t, s) in YONG.items():
    wsx = [e for e in WS[n]['extra']]
    fzx = fzy(FZ[n-1])[6:]
    for lab, ours in (('S', s), ('T', t)):
        for rn, r in (('wikisource', wsx[0] if wsx else ''), ('freizl', fzx[0] if fzx else '')):
            if fold(ours) != fold(r): issues.append(('c', n, nm + f' [{lab}]', ours, r, rn))
    if fold(s) != fold(strings[f"yong{'jiu' if n==1 else 'liu'}.text"]): issues.append(('c', n, nm + ' simp/trad mismatch', s, strings[f"yong{'jiu' if n==1 else 'liu'}.text"], ''))

# ---- 爻题 order (derive from wikisource: 初?/二/三/四/五/上, yin/yang pattern) — reference sanity
order_bad = [n for n in range(1, 65) if [p[0] if p[0] in '初上' else p[1] for p in WS[n]['prefix'][:6]] != list('初二三四五上')[:6] and [p[:1] for p in WS[n]['prefix'][:6]] != ['初','九','六','上'][:0]]
# ---- names + 全名
NAT = {'乾':'天','坤':'地','震':'雷','巽':'风','坎':'水','离':'火','艮':'山','兑':'泽'}
name_issues = []
for n in range(1, 65):
    nm, full = rows[n-1][0], rows[n-1][1]
    ref_name = t2s.convert(FZ[n-1]['name'])
    ref_ws_name = None
    ref_ws_name = t2s.convert(re.search(r"易經：[^\n]*\n\*\*<span[^>]*>'''([^']+)'''", open(f"{HERE}/ref/ws/{n:02d}.txt", encoding='utf8').read()).group(1).strip().replace('-{','').replace('}-',''))
    if fold(nm) != fold(ref_name) or fold(nm) != fold(ref_ws_name): name_issues.append((n, '卦名', nm, ref_name, ref_ws_name))
    lo, up = [t2s.convert(x).replace('干','乾') for x in (WS[n]['lo'], WS[n]['up'])]
    exp = f"{nm}为{NAT[nm]}" if lo == up and n in (1,2,29,30,51,52,57,58) and False else None
    exp = (f"{NAT[lo]}为{'' }" ) if False else None
    exp = (nm + '为' + NAT[nm]) if lo == up else NAT[up] + NAT[lo] + nm
    if lo == up: exp = {'乾':'乾为天','坤':'坤为地','坎':'坎为水','离':'离为火','震':'震为雷','艮':'艮为山','巽':'巽为风','兑':'兑为泽'}[lo]
    if full != exp: name_issues.append((n, '全名', full, exp, f'{lo}下{up}上 (wikisource)'))
# trigram order in the app (dump for eyeballing): uses Zhouyi.swift kingWen -> not parsed here
open(f"{HERE}/bh_dump.txt", 'w', encoding='utf8').write('\n'.join(f"{n}|{rows[n-1][0]}|{rows[n-1][3]}" for n in range(1, 65)))

# ---- report
print(json.dumps(counts, ensure_ascii=False))
print(f"variant-only differences (异体): {len(variants)} field/label entries")
for (n, f, lab), v in sorted(variants.items()):
    print(f"  (a) hex {n} {f} [{lab}]:", '; '.join(f"{a} vs {rn}:{b}" for rn, a, b in v)[:200])
print(f"issues: {len(issues)}")
for i in sorted(issues, key=lambda x: (x[0], x[1])): print(' ', i)
print('name issues:', name_issues)
print('ws structure: all 64 have 6 lines:', all(len(WS[n]['yao']) == 6 for n in WS), '| 用九/用六 extra lines only at 1,2:', [n for n in WS if WS[n]['extra']])
# freizl vs wikisource agreement (reference quality)
dis = [(n, k) for n in range(1, 65) for k in ['ci',0,1,2,3,4,5]
       if fold(WS[n]['ci'] if k=='ci' else WS[n]['yao'][k]) != fold(fzci(FZ[n-1]) if k=='ci' else fzy(FZ[n-1])[k])]
print('wikisource vs freizl disagreements:', len(dis), dis)

# ---- leak checks: traditional chars inside simplified source / simplified chars inside Classical.strings
ALLOW_S = set('乾')  # 乾 is legit in simplified
leakS = [(n, k, c) for n in range(1, 65) for k in ['ci',0,1,2,3,4,5] for c in ours_s(n, k) if t2s.convert(c) != c and c not in ALLOW_S]
leakT = [(n, k, c) for n in range(1, 65) for k in ['ci',0,1,2,3,4,5] for c in ours_t(n, k) if s2t.convert(c) != c and c not in '于']
print('trad chars leaked into simplified source:', leakS)
print('simplified-looking chars in Classical.strings (review; s2t(c)!=c):', leakT)
print('Classical.strings keys:', len(strings), '(expect 450 = 64*7+2)')
print('用九/用六 check: app literals', YONG, '| ws', [WS[n]['extra'] for n in (1, 2)], '| kr', [KR[n]['extra'] for n in (1, 2)], '| fz', [fzy(FZ[n-1])[6:] for n in (1, 2)])
print('KR extra for 1/2 / ws prefix order ok:', all(WS[n]['prefix'][:6] and WS[n]['prefix'][0].startswith('初') and WS[n]['prefix'][5].startswith('上') for n in WS))
