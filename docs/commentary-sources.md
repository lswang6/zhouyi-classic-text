# 十翼 Commentary tables (PHASE2 item 4) - build report

Outputs
- `Zhouyi/Zhouyi/zh-Hant.lproj/Commentary.strings` (traditional, 516 keys)
- `Zhouyi/Zhouyi/zh-Hans.lproj/Commentary.strings` (simplified, 516 keys)
- Keys: `hex.N.tuan`, `hex.N.daxiang`, `hex.N.xiao.0..5` (N=1..64), `hex.1.xiao.6` (用九), `hex.2.xiao.6` (用六), `wenyan.1`, `wenyan.2` = 64*8 + 4 = 516.
- Scripts: `Zhouyi/tools/text/build_commentary.py` (`venv/bin/python build_commentary.py [--write]`, prints all disagreements), `Zhouyi/tools/text/check_commentary.py` (`python3 check_commentary.py`).

## Sources
| id | source | role |
|---|---|---|
| WS | zh.wikisource 周易/<卦> (ref/ws/NN.txt), traditional | text of record |
| FZ | freizl/yijing zh-TW + zh-CN `64gua.json` (tuan_ci, da_xiang, xiao_xiang) and `wen-yan.json` (MIT) | skeleton / 2nd witness; zh-CN cross-check for the simplified file |
| KR | Kanripo KR1a0001 (TLS 周易, ref/kr/NN.txt) | 3rd witness, substring check on the whole folded file |
| 正義 | 《周易正義》(阮刻十三經注疏) reading as I know it | tie-break |

Comparison: punctuation stripped, OpenCC t2s, variant fold (verify_text.py `fold` + 辯/辨, 晢/晰, 鹹/咸). `{{另|A|B}}` resolved by choosing the option that matches FZ (else KR, else A): only two occur in commentary: 13 九四小象 {{另|庸|墉}} -> 墉 (乘其墉) and 14 九二小象 {{另|轝|車}} -> 車 (大車以載), both = FZ, KR and the app 經文. Wiki note `{{*|一作太和}}` dropped (kept 保合大和, = 正義).

Text conventions
- Labels (彖曰/象曰/文言曰) are not included. Quotes 「」『』 in both files (same as Knowledge.strings in both scripts).
- zh-Hant: 无 -> 無, 羣 -> 群 (Classical.strings convention). Stray spaces from WS removed.
- 文言: one paragraph per WS paragraph, joined with `\n\n`; the two runs of short 「…」 lines in 乾文言 (「潛龍勿用」，下也 … / 「潛龍勿用」，陽氣潛藏 …) are each joined into one paragraph. 乾 16 paragraphs, 坤 7.
- 用九/用六 小象 keep the words 用九/用六 because they are part of the text (用九，天德不可為首也).

## Counts
- 516 fields per language. WS vs FZ (folded) agree on 485 of 516 before overrides.
- Disagreements WS vs FZ: 31 fields -> 6 resolved against WS (overrides below), 25 kept WS (FZ wrong or variant).
- Extra fields where WS and FZ agree but KR / 正義 differ: 4 overridden (23 大象, 29 彖, 40 彖, 62 彖); plus 49 彖 partly.
- Overrides total: 11 fields + 2 in-paragraph edits to 乾文言.
- zh-Hans vs freizl zh-CN: 26 fields differ, all are the same 25 kept-WS cases above + 乾文言 where FZ-CN has its own errors (或躍中淵, 乃現天則).

## Editorial decisions - WS overridden
| hex | field | WS | FZ | chosen | reason |
|---|---|---|---|---|---|
| 1 乾 | 文言 | 可與言幾也 | 可與幾也 | 可與幾也 | FZ, KR, 正義 |
| 1 乾 | 文言 | 大哉乾元，剛健中正 | 大哉乾乎 | 大哉乾乎！剛健中正 | FZ, KR, 正義 |
| 4 蒙 | 上九小象 | 利禦寇 | 利用禦寇 | 利用禦寇，上下順也。 | WS drops 用; FZ, KR, 正義 |
| 10 履 | 彖 | …不咥人，亨，利貞。 | …亨。 | drop 利貞 | FZ, KR, 正義 lack it |
| 14 大有 | 上九小象 | 自天佑也 | 自天祐也 | 自天祐也 (Hans 佑) | 异体; matches app 經文 hex.14.yao.5 (祐 / HexagramData 佑) |
| 23 剝 | 大象 | 山附地上 | 山附地上 | 山附於地 | KR + 正義; WS and FZ agree but against 通行本 |
| 29 坎 | 彖 | 坎之時用大矣哉 | 坎之時用 | 險之時用大矣哉 | KR + 正義 |
| 29 坎 | 六四小象 | 剛柔济也 | 剛柔際也 | 剛柔際也 | WS typo (simplified 济 in trad text) |
| 31 咸 | 上六小象 | 咸其輔，頰，舌 | - | 咸其輔頰舌，滕口說也。 | punctuation only |
| 40 解 | 彖 | 解之時義大矣哉 | 時義 | 解之時大矣哉 | KR + 正義 (王弼: 頤、大過、解、革 言時大) |
| 49 革 | 彖 | 已日乃孚；革而信也 … 革之時義大矣哉 | 巳日 … 信也 … 時義 | 己日乃孚，革而信之 … 革之時大矣哉 | 信之/時大: KR + 正義. 己日: matches app 卦辭 + 六二 (Classical.strings) |
| 49 革 | 六二小象 | 已日革之 | 巳日革之 | 己日革之 | 已/巳/己 scribal variants; follow app 經文 (己日) |
| 62 小過 | 彖 | 有飛鳥之象焉，有飛鳥遺之音 | (same) | …之象焉，飛鳥遺之音 | KR + 正義 lack the 2nd 有 |

Moderate confidence (worth a human glance): 23 山附於地, 29 險之時用, 40/49 時大, 49 革而信之, 62 drop 有 - WS and FZ agree on the other reading; I followed KR and my knowledge of 正義. 49 己日 is a consistency choice, not a textual one.

## Editorial decisions - WS kept, FZ rejected
| hex | field | WS (kept) | FZ | note |
|---|---|---|---|---|
| 1 | 彖 | 大明終始；御天；咸寧 | 大明始終；禦天；鹹寧 | FZ order swap + conversion artefacts; KR = WS |
| 2 | 上六小象 | 龍戰于野 | 戰龍於野 | FZ error |
| 2 | 文言 | 由辨之不早辨也 | 由辯之不早辯也 | 辨/辯 interchangeable; kept WS (正義 辯) |
| 3 | 六三小象 | 以從禽也 | 以縱禽也 | KR = WS |
| 4 | 彖 | 初筮告 | 初噬告 | FZ typo |
| 4 | 六三小象 | 勿用取女 | 娶女 | matches 經文 取女 |
| 5 | 九二小象 | 以吉終也 | 以終吉也 | 正義 以吉終 |
| 6 | 初六小象 | 雖小有言 | 雖有小言 | KR = WS |
| 6 | 九二小象 | 歸逋竄也 | 歸而逋也 | KR = WS |
| 10 | 大象 | 君子以辨上下，定民志 | 安民誌 | FZ error; 辨/辯 variant kept |
| 10 | 九四小象 | 愬愬終吉，志行也 | 訴訴…誌 | FZ conversion artefacts |
| 14 | 九四小象 | 明辨晰也 | (same) | 正義 明辯晳; variant only, kept |
| 17 | 彖 | 而天下隨時，隨時之義大矣哉 | 隨時，隨之時義 | 王弼/正義 = WS; KR has 朱熹-style 隨之 |
| 18 | 六五小象 | 幹父用譽 | 幹父之蠱 | FZ error |
| 22 | 彖 | 剛柔交錯，天文也 | 天文也 | KR = WS; 4 chars absent from 王弼本 (郭京/朱熹 supplement) - kept since WS + KR have them |
| 27 | 彖 | 頤之時大矣哉 | 時義 | 正義 時大 |
| 28 | 彖 | 大過之時大矣哉 | 時義 | 正義 時大 |
| 34 | 大象 | 非禮弗履 | 非禮勿履 | KR = WS |
| 34 | 上六小象 | 不詳也 | 不祥也 | 正義 不詳 |
| 35 | 六二小象 | 受茲介福 | 受之介福 | KR = WS |
| 35 | 九四小象 | 鼫鼠 | 碩鼠 | KR = WS |
| 41 | 初九小象 | 已事遄往 | 巳事 | matches app 經文 已事 |
| 51 | 大象 | 洊雷，震；君子以恐懼修省 | 虩雷 … 修身 | FZ errors |
| 53 | 六二小象 | 飲食衎衎，不素飽也 | …衎衎，吉，不素飽也 | KR = WS |
| 55 | 彖 | 而況于人乎 | 而況人於人乎 | FZ error |
| 63 | 大象 | 豫防 | 預防 | KR = WS |

Kanripo-only differences ignored (KR artefacts): 4 彖 童蒙來求我, 5/34/64 line splits, 8 比吉, 26 利己 (app 經文 利已), 48 彖 往來井井, 51 彖 不喪匕鬯 (程頤 addition), glyph variants 𠡠/敕, 𪸩/輝, 揜/掩.

## Simplified-char leaks in the Wikisource (traditional) text - fixed in zh-Hant
These can't be seen by the t2s-folded diff, because t2s maps the correct character onto the leaked one. They were found with an s2t scan and are now guarded in check_commentary.py:
17 初九/六二/上六小象 系 -> 係 (= app 經文 係小子 / 拘係之); 44 初六小象 系 -> 繫 (= app 繫于金柅); 40 六三 and 53 九三小象 丑 -> 醜; 53 九五, 59 九二, 61 九二小象 愿 -> 願; 62 六五小象 密云 -> 密雲. (29 六四 济 -> 際 is listed above.)
The remaining s2t hits are correct classical usage: 于, 凶, 咸, 征, 群, 后 (= sovereign: 后以財成, 后不省方, 后以施命), 辟 (= 避), 尸, 克, 欲, 舍, 咨, 斗, 机 (渙奔其机), 恒.

## Note on 22 賁 彖
This is the only place where I did not apply the "prefer 正義" rule. 剛柔交錯 is absent from the 阮刻 王弼本 and is the 郭京/朱熹 supplement. I kept it because WS (the text of record) and KR both have it and it is what most modern editions print. If strict 正義 is wanted, drop the 4 characters in hex.22.tuan.

## zh-Hans: OpenCC t2s + hand-fixes
t2s is char-for-char (asserted). Hand-fixes keyed on the traditional source char, matching what HexagramData.swift (simplified 經文) does:
| trad | OpenCC gave | kept | count |
|---|---|---|---|
| 乾 | 干 | 乾 | 18 (e.g. 終日乾乾, 乾道) - zh-Hans has zero stray 干 other than 幹->干 |
| 遯 | 遯 | 遁 | 11 (app simplified uses 遁; zh-Hant keeps 遯 like Classical.strings) |
| 祐 | 祐 | 佑 | 1 |
| 撝 | 㧑 | 撝 | 1 (15 六四小象) |
| 餗 | 𫗧 | 餗 | 1 (50 九四小象) |
Reviewed and accepted as standard simplification: 幹->干 (6: 事之干也, 干父之蛊 = app 經文), 餘->余 (積善之家必有余庆), 後->后, 於->于, 係->系 (= app), 幾->几 (= app 月几望), 穀->谷 (百谷草木), 嚮->向 (向晦), 醜->丑 (= app 匪其丑), 著: does not occur, 隻: does not occur, 纆/繻: do not occur in commentary.

## Checks
- `python3 check_commentary.py`: PASS - plutil -lint OK on both; key set == expected 516 in both; no empty values; charset limited to CJK + ，。；：？！、「」『』 + `\n` (wenyan only); no 彖曰/象曰 labels; zh-Hans and zh-Hant char-for-char equal length; 乾 count identical per key; zh-Hant has no 无/羣, no 系, and no simplified-char leaks other than the allow-listed classical chars.
- 小象 alignment heuristic (char overlap with own 爻辭 vs other 爻辭): 5 low-overlap entries (6.5, 18.2, 25.5, 26.4, 30.4) read by eye - all correct (paraphrase 小象, e.g. 六五之吉，有慶也).
- Spot-read 1, 2, 14, 31, 49, 64: every 小象 on the right 爻 (incl. 用九/用六 at .6, 大有 九二 大車以載).

## Xcode project
`xcodegen generate` -> `project.pbxproj` +8 lines, only Commentary.strings (2 PBXFileReference, 2 PBXBuildFile, 2 group children, 2 Resources entries), no other churn. As with Classical.strings, they are plain file refs (not a variant group) because there is no en/Base Commentary.strings. This is the first time two same-named plain refs (zh-Hans + zh-Hant) are in Resources; Xcode should place each in its .lproj, no existing build product in DerivedData shows how Xcode handles it, so it is unverified. Confirm in the next xcodebuild (look for "Multiple commands produce ... Commentary.strings").
