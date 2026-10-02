#!/usr/bin/env python3
"""Build Commentary.strings (彖/大象/小象/文言) for zh-Hant + zh-Hans.
Text of record: Wikisource 周易 (ref/ws/NN.txt). Cross-checked vs freizl/yijing zh-TW/zh-CN (ref/freizl_*) and
Kanripo KR1a0001 (ref/kr/NN.txt, substring check only). Run: venv/bin/python build_commentary.py [--write]
Prints every disagreement; manual decisions live in OVERRIDE (trad) and HANS_FIX (OpenCC t2s fixes)."""
import re, json, os, sys, itertools
from opencc import OpenCC
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../Zhouyi")
t2s = OpenCC('t2s')

# ---- normalization (copied from verify_text.py)
VAR = {'祐':'佑','畬':'畲','寘':'置','蔾':'藜','沬':'沫','闚':'窥','窺':'窥','洌':'冽','震':'振','遯':'遁','苞':'包','彚':'彙','它':'他','敺':'驅','輹':'輻','貳':'贰','兇':'凶','閽':'薰','衹':'只','無':'无','羣':'群','於':'于','脩':'修','峕':'时','說':'说','爲':'为','為':'为','啓':'启','啟':'启','裏':'里','裡':'里','甯':'宁','寧':'宁','麤':'粗','衞':'卫','衛':'卫','愼':'慎','廻':'回','迴':'回','恆':'恒','彊':'强','強':'强','災':'灾','烖':'灾','菑':'灾','祇':'只','祗':'只','鹹':'咸','辯':'辨','辨':'辨','晢':'晰','晣':'晰','晰':'晰','于':'于'}
PUNCT = re.compile(r'[\s，。、；：！？“”‘’「」『』《》（）()·,.;:!?\-—…　]')
def fold(s): return ''.join(VAR.get(c, c) for c in t2s.convert(PUNCT.sub('', s)))
def clean_ws(t):
    t = re.sub(r'-\{([^}]*)\}-', r'\1', t)
    t = re.sub(r'\{\{\*\|[^}]*\}\}', '', t)   # editorial note {{*|一作太和}}
    return re.sub(r"<[^>]+>|'''", '', t)
LING = re.compile(r'\{\{另\|([^|}]*)\|([^}]*)\}\}')
def candidates(raw):
    """{{另|A|B}} -> every A/B combination (first = A everywhere, Wikisource display form)."""
    opts = LING.findall(raw)
    for combo in itertools.product(*[(a, b) for a, b in opts]):
        it = iter(combo); yield clean_ws(LING.sub(lambda m: next(it), raw))

# ---- Wikisource
def ws_sections(n):
    t = open(f"{HERE}/ref/ws/{n:02d}.txt", encoding='utf8').read()
    sec = lambda name: t.split(f"*'''{name}：'''")[1].split("\n*'''")[0].strip().split('\n')
    tuan = ''.join(re.sub(r'^\*+', '', l) for l in sec('彖曰'))
    xl = sec('象曰'); assert xl[0].startswith('**') and all(l.startswith('*#') for l in xl[1:]), n
    out = {'tuan': tuan, 'daxiang': xl[0][2:]}
    for i, l in enumerate(xl[1:]): out[f'xiao.{i}'] = l[2:]
    if n <= 2:   # 文言: one paragraph per line; consecutive 「…」 one-liners (乾 第二、三節) joined
        paras = []
        for l in sec('文言曰'):
            if l.startswith('*:'): paras.append(None); continue
            body = re.sub(r'^\*[*#]', '', l)
            if body.startswith('「') and paras and paras[-1] and paras[-1].startswith('「'): paras[-1] += body
            else: paras.append(body)
        out['wenyan'] = '\n\n'.join(p for p in paras if p)
    return out
WS = {n: ws_sections(n) for n in range(1, 65)}

# ---- freizl (King Wen order)
def fz(lang):
    g = json.load(open(f"{HERE}/ref/freizl_{lang}_64gua.json", encoding='utf8'))
    wy = {c['subtitle']: c['content'] for c in json.load(open(f"{HERE}/ref/freizl_{lang}_wen-yan.json", encoding='utf8'))['content']}
    out = {}
    for n, x in enumerate(g, 1):
        d = {'tuan': x['tuan_ci'], 'daxiang': x['da_xiang']}
        for i, s in enumerate(x['xiao_xiang']): d[f'xiao.{i}'] = s
        out[n] = d
    for n, paras in zip((1, 2), wy.values()): out[n]['wenyan'] = '\n\n'.join(paras)   # order: 乾, 坤
    for n in (1, 2): out[n]['wenyan'] = re.sub(r'^《文言》曰：', '', out[n]['wenyan'])
    return out
FZT, FZS = fz('zh-TW'), fz('zh-CN')

# ---- Kanripo: whole-file folded text, used as a containment witness
def kr(n):
    t = '\n'.join(l for l in open(f"{HERE}/ref/kr/{n:02d}.txt", encoding='utf8').read().split('\n') if not l.startswith('#'))
    return fold(re.sub(r'<pb:[^>]*>|¶|[䷀-䷿]', '', t))
KR = {n: kr(n) for n in range(1, 65)}

def keys(n):
    ks = ['tuan', 'daxiang'] + [f'xiao.{i}' for i in range(7 if n <= 2 else 6)]
    return ks + (['wenyan'] if n <= 2 else [])

# ---- manual decisions: (n, field) -> (final traditional text, reason). Filled after reading the diff output.
Z = '《周易正義》(阮刻十三經注疏) / 通行本'
OVERRIDE = {  # (n, field) -> (final traditional text, reason). WS = Wikisource, FZ = freizl zh-TW, KR = Kanripo KR1a0001
    (1, 'wenyan'): None,  # paragraph-level edits applied below (WENYAN_EDIT)
    (4, 'xiao.5'): ('利用禦寇，上下順也。', f'WS drops 用; FZ, KR and {Z} have 利用禦寇'),
    (10, 'tuan'): ('履，柔履剛也。說而應乎乾，是以履虎尾，不咥人，亨。剛中正，履帝位而不疚，光明也。', f'WS adds 利貞 after 亨; FZ, KR, {Z} lack it'),
    (23, 'daxiang'): ('山附於地，剝；上以厚下，安宅。', f'WS and FZ 山附地上; KR and {Z} 山附於地'),
    (29, 'tuan'): ('習坎，重險也。水流而不盈，行險而不失其信。維心亨，乃以剛中也。行有尚，往有功也。天險不可升也，地險山川丘陵也，王公設險以守其國，險之時用大矣哉！', f'WS and FZ 坎之時用; KR and {Z} 險之時用'),
    (29, 'xiao.3'): ('樽酒簋貳，剛柔際也。', 'WS 剛柔济 (simplified-char typo); FZ, KR, 通行本 際'),
    (40, 'tuan'): ('解，險以動，動而免乎險，解。解利西南，往得眾也。其來復吉，乃得中也。有攸往夙吉，往有功也。天地解，而雷雨作，雷雨作，而百果草木皆甲坼，解之時大矣哉！', f'WS and FZ 時義; KR and {Z} 解之時大矣哉 (王弼: 頤、大過、解、革 言「時大」)'),
    (49, 'tuan'): ('革，水火相息，二女同居，其志不相得，曰革。己日乃孚，革而信之。文明以說，大亨以正，革而當，其悔乃亡。天地革而四時成，湯武革命，順乎天而應乎人，革之時大矣哉！', f'WS/FZ 革而信也、時義; KR and {Z} 革而信之、時大. 已/巳 -> 己日 to match the app 卦辭 and 六二 (Classical.strings)'),
    (49, 'xiao.1'): ('己日革之，行有嘉也。', 'WS 已日, FZ/KR 巳日: scribal variants; 己日 matches the app 經文 (Classical.strings hex.49.yao.1)'),
    (14, 'xiao.5'): ('大有上吉，自天祐也。', 'WS 佑 vs KR 祐: 异体; 祐 matches the app 經文 hex.14.yao.5 (zh-Hans -> 佑 like HexagramData)'),
    (31, 'xiao.5'): ('咸其輔頰舌，滕口說也。', 'punctuation only: WS 咸其輔，頰，舌 -> 咸其輔頰舌 as in the app 經文 and 通行本'),
    (62, 'tuan'): ('小過，小者過而亨也。過以利貞，與時行也。柔得中，是以小事吉也。剛失位而不中，是以不可大事也。有飛鳥之象焉，飛鳥遺之音，不宜上宜下，大吉；上逆而下順也。', f'WS adds 有 before 飛鳥遺之音; KR and {Z} lack it'),
}
WENYAN_EDIT = [  # (n, old, new, reason) on the Wikisource 文言
    (1, '可與言幾也', '可與幾也', f'WS adds 言; FZ, KR, {Z} 可與幾也'),
    (1, '大哉乾元，剛健中正', '大哉乾乎！剛健中正', f'WS 大哉乾元; FZ, KR, {Z} 大哉乾乎'),
]
del OVERRIDE[(1, 'wenyan')]

# Wikisource leaks of simplified chars that t2s-folding cannot see (t2s maps the correct char onto them)
LEAK = {(17, 'xiao.1'): ('系', '係'), (17, 'xiao.2'): ('系', '係'), (17, 'xiao.5'): ('系', '係'), (44, 'xiao.0'): ('系', '繫'),
        (40, 'xiao.2'): ('丑', '醜'), (53, 'xiao.2'): ('丑', '醜'), (53, 'xiao.4'): ('愿', '願'), (59, 'xiao.1'): ('愿', '願'),
        (61, 'xiao.1'): ('愿', '願'), (62, 'xiao.4'): ('云', '雲')}
def norm_hant(s):   # app zh-Hant convention (Classical.strings): 無, 群
    return re.sub(r'[ \u3000\t]', '', s).replace('无', '無').replace('羣', '群')   # WS has stray spaces

final, log = {}, []
for n in range(1, 65):
    for k in keys(n):
        raw = WS[n][k]; cands = list(candidates(raw)); ref = fold(FZT[n][k])
        pick = next((c for c in cands if fold(c) == ref), None) or next((c for c in cands if fold(c) in KR[n]), cands[0])
        if len(cands) > 1: log.append(('另', n, k, f"{LING.findall(raw)} -> {pick}"))
        for wn, a, b, _ in WENYAN_EDIT:
            if (n, k) == (wn, 'wenyan'): assert a in pick, a; pick = pick.replace(a, b)
        if (n, k) in OVERRIDE: text = OVERRIDE[(n, k)][0]
        else:
            text = pick
            if fold(pick) != ref:
                log.append(('DIFF', n, k, f"ws={pick}\n      fz={FZT[n][k]}\n      kr: ws_in={fold(pick) in KR[n]} fz_in={ref in KR[n]}"))
        if (n, k) in LEAK: a, b = LEAK[(n, k)]; assert a in text, (n, k); text = text.replace(a, b)
        final[(n, k)] = norm_hant(text)

# ---- zh-Hans: OpenCC t2s, then hand-fixes
# OpenCC t2s pitfalls, by traditional source char -> simplified form the app's 经文 (HexagramData.swift) uses
HANS_FIX = {'乾': '乾', '撝': '撝', '餗': '餗', '纆': '纆', '繻': '繻', '遯': '遁', '祐': '佑', '畬': '畲'}
hans, tsmap, fixed = {}, {}, {}
for key, t in final.items():
    s = t2s.convert(t); assert len(s) == len(t), key
    out = []
    for a, b in zip(t, s):
        c = HANS_FIX.get(a, b)
        if c != b: fixed[(a, b, c)] = fixed.get((a, b, c), 0) + 1
        if a != c: tsmap.setdefault((a, c), []).append(key)
        out.append(c)
    hans[key] = ''.join(out)
for key, s in hans.items():
    if fold(s) != fold(FZS[key[0]][key[1]]) and (key[0], key[1]) not in OVERRIDE:
        log.append(('HANS', key[0], key[1], f"ours={s}\n      fzCN={FZS[key[0]][key[1]]}"))

def skey(n, k): return f"wenyan.{n}" if k == 'wenyan' else f"hex.{n}.{k}"
def esc(s): return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
def write(path, header, table):
    with open(path, 'w', encoding='utf8') as f:
        f.write(f"/* {header} */\n")
        for (n, k), v in table.items(): f.write(f'"{skey(n, k)}" = "{esc(v)}";\n')

if __name__ == '__main__':
    for c, n, k, msg in log: print(c, n, k, msg)
    print('t2s char map (trad->simp, count):')
    print(' '.join(f"{a}{b}:{len(v)}" for (a, b), v in sorted(tsmap.items(), key=lambda x: -len(x[1]))))
    print('HANS_FIX applied (trad, opencc, kept):', fixed)
    print('fields:', len(final), '| DIFF:', sum(1 for x in log if x[0] == 'DIFF'), '| HANS:', sum(1 for x in log if x[0] == 'HANS'), '| overrides:', len(OVERRIDE))
    if '--write' in sys.argv:
        os.makedirs(f"{REPO}/zh-Hans.lproj", exist_ok=True)
        write(f"{REPO}/zh-Hant.lproj/Commentary.strings", "周易 · 繁體中文（台灣）· 十翼：彖傳、大象、小象（hex.N.xiao.0–5 初至上，乾坤 .6 為用九／用六）、文言（據通行本，Wikisource 校 freizl/yijing）", final)
        write(f"{REPO}/zh-Hans.lproj/Commentary.strings", "周易 · 简体中文 · 十翼：彖传、大象、小象（hex.N.xiao.0–5 初至上，乾坤 .6 为用九／用六）、文言（据通行本，Wikisource 校 freizl/yijing）", hans)
        print('written')
