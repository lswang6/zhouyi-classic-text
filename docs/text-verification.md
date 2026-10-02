# 周易 text verification (卦辞 / 爻辞 / 用九 / 用六 / names)

Script: `Zhouyi/tools/text/verify_text.py` (run `venv/bin/python verify_text.py`; refs cached in `ref/`; `fetch_ws.py` re-downloads Wikisource).

## Sources
| id | source | use | license |
|---|---|---|---|
| WS | zh.wikisource.org 周易/<卦名> (MediaWiki API, 64 pages; trad.) 通行本 经 + 彖/象/文言 | primary ref | text public domain; wiki content CC BY-SA 4.0 |
| FZ | github.com/freizl/yijing `zh-TW|zh-CN/64gua.json` (+ xi-ci, wen-yan, xu-gua, za-gua, shuo-gua) | second ref | MIT |
| KR | github.com/kanripo/KR1a0001 周易(正文), TLS edition, 64 files + 彖/象/文言 | third ref | no LICENSE file in repo (GitHub reports none); Kanripo/TLS texts - check terms before shipping |
| 周易正義 | zh.wikisource.org 周易正義/05革, 04損, 06旅, 02同人 (spot-check, 十三经注疏) | tie-break | CC BY-SA 4.0 |
ctext.org: not used (Cloudflare challenge + ToS forbids scraping).
Noise in refs (found, so don't trust any single one): FZ has 卦辞 of 咸 prefixed "鹹，", 大有 爻2 = "同人於宗，吝" (misaligned), 凶->兇, 號咷->號啕, 巳日, 娶女, 碩鼠, dropped/added words in ~48 places; WS has typos (大耋之差, 矢得勿恤, 君子德車, 来荼荼, 裂其夤, 輿->轝/車) in ~48 places; KR has 童蒙來求我, 意无喪, 利己, some line-break punctuation.

## Counts
- Fields compared: 448 (64 卦辞 + 384 爻辞), plus 用九/用六, 64 卦名, 64 全名.
- Simplified source (HexagramData) equals all three refs (after punctuation strip + OpenCC t2s + variant fold): 393.
- Ours matches >=1 ref, others differ (ref noise / variant chars / KR parse artifacts of a leading 《卦名》 label): 53 - all adjudicated, none are errors in our text.
- Ours differs from all refs: 2 (hex 49, 己日 vs 巳日 - variant reading, see below).
- Wrong line order / misplaced text (d): 0. 64 hexagrams x 6 lines present in order; Classical.strings has all 450 keys (64x7 + 2).
- Simplified vs Classical.strings internal mismatch (beyond 简繁/异体): 2 (both real, below).
- 用九 "見群龍無首，吉。" / 用六 "利永貞。": match WS, KR, FZ (WS writes 羣/无 variants only).
- 卦名 n=1..64 vs WS & FZ: all match (29 坎 = 習坎 in refs; our 卦辞 correctly starts with 习坎). 全名 (up-nature + low-nature + 卦名, 8 pure hexagrams "X为Y") derived from WS "下卦下上卦上": all 64 correct.
- 白话: all 64 read as the right hexagram (checked by eye, dump in bh_dump.txt); no wrong-hexagram content.

## Fixes needed
| n | field | ours | correct | evidence |
|---|---|---|---|---|
| 13 同人 | 九五 (HexagramData.swift, simplified col 9) | 先号啕而后笑 | 先号咷而后笑 | 通行本 "號咷"; 周易正義/02同人 "同人先號咷，而後笑"; KR "號咷"; our Classical.strings already 號咷. (WS/FZ show 號啕 = conversion artefact) |
| 56 旅 | 上九 (simplified col 9) | 旅人先笑后号啕 | 旅人先笑后号咷 | 周易正義/06旅 "後號咷"; KR, WS "號咷"; Classical.strings already 號咷 |

Only these 2 are real errors, both in the simplified source (Classical.strings is fine). 啕 vs 咷 are different characters (not 异体), 咷 is the same in simplified.

## Variant-only / optional (no change required)
- 49 革 卦辞 + 六二: ours 己日; 周易正義 has 己日 in the 卦辞 line and 巳日 in 六二 and in 疏; KR/FZ 巳日; WS 已日. Scribal variants of one graph; ours = 阮刻 卦辞 reading. Keep (optionally make 六二 巳日 for consistency with 正義).
- 41 損 初九 已事 (ours, KR) vs 巳事 (正義) vs 祀事 (WS): variant, keep.
- 55 豐 九三 沫 (ours) vs 沬 (WS/KR); 12 否 九五 苞桑 vs 包桑; 24 復 初九 祗 vs 祇; 33 遁 vs 遯; 61 有他 vs 有它; 25 畲/畬, 14 佑/祐, 29 置/寘, 系/係, 47 蒺藜/蒺蔾, 20/55 窥/闚, 26 利已/利己: all 异体, none needs change.
- Simplified source keeps 4 rare traditional-only glyphs (15 六四 撝, 29 上六 纆, 50 九四 餗, 63 九三 繻): fine unless a font lacks them.
- Traditional strings use modern 無 (not 通行本 无); fine.

## Phase 2 (彖传 / 大象 / 小象 / 文言)
- Best: Wikisource 周易/<卦名> pages (already downloaded in `ref/ws/NN.txt`; contain 彖曰, 象曰 大象 + 小象 x6/7, 文言曰 for 乾坤, ordered; license CC BY-SA 4.0, attribution + share-alike) - needs cleaning of `-{x}-`, `{{另|a|b}}` markup (done in verify_text.py `clean_ws`).
- Also MIT: freizl/yijing zh-CN/zh-TW `64gua.json` has tuan_ci, da_xiang, xiao_xiang[7] and `wen-yan.json`, `xi-ci.json`, `xu-gua.json`, `za-gua.json`, `shuo-gua.json` in clean JSON, clear license, but has conversion errors (鹹, 兇, 號啕, etc.) so verify against WS/KR before import.
- KR1a0001 (TLS) has same content, license unclear.
