# legge.json -> legge_clean.json (OCR clean-up)

## Result
`legge_clean.json`: same 966 keys, 513 values changed. `check_clean.py` exits 0 (0 hard failures, 2 quote warnings, 2 suspicious tokens, listed below).
Full change log, one entry per edit with before/after: `changes.json` (`changes`: [category, key, before, after]; `rejected_votes`: majority votes refused by the guards).

Re-run: `python3 align.py && python3 clean_legge.py && python3 check_clean.py`. The order matters: clean_legge.py and check_clean.py read regions.json.

| file | role |
|---|---|
| `align.py` | finds each legge.json paragraph in dli.txt and mlbd.txt (4-gram votes; position from unique 5-gram anchors in wg916; book order kept), aligns word-by-word with difflib, writes every differing span to `regions.json` (a=wg916/legge.json, b=dli, c=mlbd) |
| `clean_legge.py` | stage 1 vote, stage 2 OCR fixes made by hand, stage 3 names, stage 4 punctuation/hyphenation/quote closing |
| `words.py` | English lookup (/usr/share/dict/web2 + suffix and British-spelling rules + a short list of irregular forms that were checked by eye) |
| `show.py` | `python3 show.py "phrase"` prints the phrase from all three raw OCRs. Used for every judgement call below |
| `check_clean.py` | self-check |

## Changes by category (counts from changes.json)
| category | n | what |
|---|---|---|
| name | 216 | romanisation normalised to Legge's forms (130 distinct garbled->canonical pairs) |
| punct | 472 paragraphs | OCR spacing: `‘ He`->`‘He`, `perish ! ’`->`perish!’`, `distributed ;`->`distributed;`, ` — `->`—`, `( =`->`(=`, `—-`->`—`, line-split hyphen `self- produced`->`self-produced` |
| quote-close | 92 | a lost `:’` before the dash in Legge's ‘quotation:’—comment formula (wg916 dropped it; dli/mlbd usually show it). Uses the existing `;`/`:` if one was there, otherwise `:`. A `;—` inside a quotation is treated as Legge's internal separator (‘...deep;—it is not...doing:’—), so the quote closes at the next dash |
| vote | 34 | dli and mlbd agree with each other against wg916 (mostly the lost `:’` before dashes, `advantageous/`->`advantageous,’`, `this,`->`this;` in 25/54.daxiang, `heaven,`->`heaven.` at the end of 22.tuan) |
| vote-punct | 30 | same letters in all three OCRs, and dli and mlbd agree on punctuation once quote junk (`* ^ ' "`) and `;` vs `:` are ignored |
| ocr-fix | 32 | individual fixes, each checked in the three OCRs (see `FIXES` in clean_legge.py): `hundred 11`/`It`->`li` (51.ci, 51.tuan), `against/`, `nourishing/`, `1 Remove`->`‘Remove`, `Such 1 exceeding`->`Such ‘exceeding`, `* The`->`‘The`, `motherhe`->`mother:’—he`, `city-wallbut`->`city-wall;’ but`, `c ivided`, `H eaven`, `show's`->`shows`, `white mi 3 grass`->`white mâo grass`, stray `'` (27.yao.4, 58.xiao.3), missing full stop after the name in 14/59.daxiang |
| hyphenation | 11 | words split at a line end rejoined when the joined form is a word: repre-sentative, advan-tageous, sym-pathy, con-fidence, moun-tains, com-ponent, cook-ing, cross-ing, seek-ing, per-chance; `correctly-arranged`->`correctly arranged`. Real compounds (self-produced, long-continued, bye-passage, city-wall) keep the hyphen |

Guards on voting. A vote is refused when any of these hold: the span differs in length by more than 2 tokens; similarity is below 0.5 (that means a misalignment into Legge's notes); it would add digits or a running head (APPENDIX/SECT/HEX/TEXT); it would put in a non-word that both OCRs share (`fayour`, `decile`, `tq`); it would swap one real word for another (`docile`->`decile`, `In`->`after`); it would delete a quote, parenthesis or `!`/`?`; or the paragraph's quote balance gets worse. The 22 refused votes are in `changes.json`. The useful ones among them were applied by hand as ocr-fix.

## Names (stage 3)
Hexagram names, now used in every ci/tuan/daxiang/xiao/wenyan reference:
Khien, Khwăn, Kun, Măng, Hsü, Sung, Sze, Pî, Hsiâo Khû, Lî, Thâi, Phî, Thung Zăn, Tâ Yû, Khien, Yü, Sui, Kû, Lin, Kwân, Shih Ho, Pî, Po, Fû, Wû Wang,
Tâ Khû, Î, Tâ Kwo, Khân, Lî, Hsien, Hăng, Thun, Tâ Kwang, **Tsin**, Ming Î, Kiâ Zăn, Khwei, Kien, Kieh, Sun, Yî, Kwâi, Kâu, **Tshui**, Shăng, Khwăn, **Tsing**,
Ko, Ting, Kăn, Kăn, Kien, Kwei Mei, Făng, Lü, Sun, Tui, Hwân, Kieh, Kung Fû, Hsiâo Kwo, **Kî Tsî**, **Wei Tsî**.

Where this departs from your list:
- **63 and 64 are Kî Tsî and Wei Tsî, not Kî Kî / Wei Kî.** All three OCRs print Legge's special letter ȝ there: wg `Ki 3 t`/`Wei 31`, dli `Wei 3!`, mlbd `Ai 3%`. That is the same letter as in 35 `3in`, 45 `3hui` and 48 `3ing`, which your list already writes Ts-. ȝ (U+021C) is outside Latin Extended-A, so it is written `Ts` everywhere, the usual e-text rendering.
- 49.tuan `line of Hsii` is 夏 **Hsiâ** (dli `HsiA`, mlbd `Hsia`), not Hsü. `Wu` there is king **Wû**, and `Shang` (the dynasty) has no breve. **Shăng** is used only for hexagram 46.
- Other names: king Wăn (36.tuan), duke of Kâu (wenyan.1), Kâo Zung (63.yao.2), the count of Kî (36), (king) Tî-yî (11.yao.4, 54.yao.4, 54.xiao.4), Thang (49.tuan), mount Khî (46.yao.3, 46.xiao.3), the Yî (the book) and the Yâo (wenyan), li (the measure, 51), mâo grass (28.yao.0). Trigram names are in the same forms (Khien, Khwăn, Kăn, Khân, Sun, Lî, Tui).
- Kâo Zung follows your list. The OCR shows the same ȝ (`Kao 3 ung`), so strictly ȝ->Ts would give "Kâo Tsung". Change it in `NAMES` if you want ȝ handled the same way everywhere.
- Legge writes 震 (51) and 艮 (52) both as Kăn (italic vs roman K in print), and 乾/謙 (1/15) both as Khien. Italic K (= Ch) cannot be shown in plain text and is written K.
- Kî-dze and Kwei-fang do not occur in these 966 values. Legge's 36.yao.4 says "the count of Kî", and 64.yao.3 says "the Demon region".

## Kept as printed (all three OCRs agree; not modernised)
- Unbalanced parentheses in Legge's print: 4.yao.1 `admitting (even the goodness of women`, 50.tuan `We have the symbol of) flexible obedience`, 12.daxiang `restrains (the manifestation) of) his virtue`, 13.daxiang `in accordance with this), distinguishes`. check_clean.py whitelists these 4.
- Quotes that are never closed in the print: 25.tuan (`there will be ‘great progress proceeding from correctness; such is the appointment of Heaven.`) and 53.tuan (one-paragraph quote with no closing mark). These are the 2 quote warnings.
- 46.xiao.3 `to prevent his offerings`: wg916 and mlbd both read "prevent", dli is garbled. 46.yao.3 has "present", so this is probably a printer's error, but two OCRs agree, so it stays. **Please review.**
- Digits that are Legge's own: 4.xiao.3 `(shown in lines 2 and 6)`, 40.xiao.2 `(See Appendix III, i, 48.)`. `(= descends or ascends)`, `(= golden)` and `(= the undivided lines)` are Legge's notation.
- British/Victorian spellings (connexion, realise, fulness, purslain, waggon) are unchanged.

## Self-check (check_clean.py) — PASS
- 966 keys, same set as legge.json, none empty.
- Characters allowed: ASCII, Latin-1, Latin Extended-A, — ‘ ’ “ ”. Banned: `# $ % * + < > @ \ ^ _ { | } ~ / & [ ] ' "`. 0 hits.
- Digits: only the 2 whitelisted Legge cross-references.
- Parentheses balanced per paragraph except the 4 whitelisted as-printed cases. No double spaces and no padded paragraphs.
- All 384 yao contain their line-position phrase within the first 45 characters: "In the first (or lowest) line", "The second line, divided", "The topmost line", and also Legge's "From the first line…" (39.yao.0) and "(To the subject of) the fourth line…" (40.yao.3). The data uses ordinal + divided/undivided, not NINE/SIX.
- Every daxiang has `<Name>. ` followed by a capital letter (except 1 and 25, which have no name). The name in each ci is followed by a space, `,` or `)`.
- All 64 ci open with the hexagram's Legge name, except 52, whose Thwan opens "When one's resting is like that of the back…".
- Remaining suspicious tokens (not English, not in the name list): **2**: `yî’s` (in "Tî-yî’s", correct) and `III` (Legge's cross-reference "Appendix III", correct). The dictionary check cannot catch real-word OCR errors such as prevent/present.

## Spot check by reading: hexagrams 1, 2, 11, 29, 49, 63, 64 (every key)
All ci/yao/yong/tuan/daxiang/xiao read clean: names correct, every xiao closes its ‘quotation:’—, no stray glyphs.

Before/after examples:
1. hex.1.xiao.1
   - before: `‘The dragon appears in the field —the diffusion of virtuous influence has been wide.`
   - after: `‘The dragon appears in the field:’—the diffusion of virtuous influence has been wide.`
2. hex.46.xiao.3
   - before: `‘ The king employs him to prevent his offerings on mount Kh \—such a service …`
   - after: `‘The king employs him to prevent his offerings on mount Khî:’—such a service …`
3. hex.63.yao.2 / hex.64.ci
   - before: `(suggests the case of) Kao 3 ung who attacked …` / `Wei 3* intimates progress …`
   - after: `(suggests the case of) Kâo Zung who attacked …` / `Wei Tsî intimates progress …`
4. hex.51.ci
   - before: `A'an gives the intimation … all within a hundred 11, he will be …`
   - after: `Kăn gives the intimation … all within a hundred li, he will be …`

## Limits
- Voting needs dli and mlbd to agree on the letters. Where all three differ (mostly names), stage 3's hand-built table decides. Names are only normalised where a pattern in `NAMES` matches. Any garble not in the table would show up as a suspicious token, and none are left.
- quote-close is a structural rule (an open ‘ followed by a dash with no ’ before the next ‘). The 92 edits are in the log. I read a random sample of 8 by eye and all fit the ‘quotation:’—comment formula. 20.tuan and 8.tuan were also compared with the OCRs, which led to the `;—` rule. The other 82 were not checked one by one against dli/mlbd.
- Two paragraphs could not be aligned in dli/mlbd: 64.yao.5 and 35.tuan paragraph 0 (very short, "Sin denotes advancing."). Both were read by eye: 35.tuan is now "Tsin denotes advancing.", and 64.yao.5 is clean.
