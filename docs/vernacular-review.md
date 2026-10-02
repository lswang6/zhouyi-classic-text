# REVIEW: 白话译文 Vernacular.strings (zh-Hans)

Method: seed(7) stratified sample (102 keys: one per hexagram cycling ci/yao/tuan/daxiang/xiao, +34 random, +yong/xiao.6) + wenyan.2 (all 7 paragraphs) + wenyan.1 (paragraphs idx 10, 2, 6, 15). In addition a full read-through of all 64 ci, 384 yao, 384 xiao, 64 daxiang, 64 tuan against originals. Automated scan on all 966 keys.

## Sample verdicts (all OK unless listed)
OK: hex.1.ci, hex.2.yao.2, hex.3.tuan, hex.4.daxiang, hex.5.xiao.1, hex.6.ci, hex.7.yao.3, hex.8.tuan, hex.9.daxiang, hex.10.xiao.5, hex.11.ci, hex.12.yao.0, hex.13.tuan, hex.14.daxiang, hex.15.xiao.0, hex.16.ci, hex.17.yao.4, hex.18.tuan, hex.19.daxiang, hex.20.xiao.0, hex.21.ci, hex.22.yao.2, hex.23.tuan, hex.24.daxiang, hex.25.xiao.4, hex.26.ci, hex.27.yao.0, hex.28.tuan, hex.29.daxiang, hex.30.xiao.4, hex.31.ci, hex.32.yao.1, hex.33.tuan, hex.34.daxiang, hex.35.xiao.0, hex.36.ci, hex.37.yao.0, hex.38.tuan, hex.39.daxiang, hex.40.xiao.3, hex.41.ci, hex.42.yao.3, hex.43.tuan, hex.44.daxiang, hex.45.xiao.0, hex.46.ci, hex.47.yao.1, hex.48.tuan, hex.49.daxiang, hex.50.xiao.0, hex.51.ci, hex.52.yao.4, hex.53.tuan, hex.54.daxiang, hex.55.xiao.3, hex.56.ci, hex.57.yao.0, hex.58.tuan, hex.59.daxiang, hex.60.xiao.4, hex.61.ci, hex.62.yao.0, hex.63.tuan, hex.64.daxiang, hex.17.yao.3, hex.47.yao.0, hex.46.xiao.4, hex.43.xiao.0, hex.5.tuan, hex.43.yao.1, hex.43.xiao.3, hex.30.ci, hex.4.xiao.0, hex.17.yao.1, hex.4.yao.4, hex.41.xiao.2, hex.63.xiao.3, hex.10.xiao.1, hex.22.yao.1, hex.31.xiao.1, hex.11.daxiang, hex.40.tuan, hex.9.xiao.0, hex.42.xiao.2, hex.23.daxiang, hex.41.xiao.5, hex.60.xiao.0, hex.50.xiao.4, hex.14.yao.2, hex.8.daxiang, hex.43.daxiang, hex.47.xiao.2, hex.14.xiao.2, hex.28.yao.2, hex.8.yao.0, hex.41.yao.0, hex.53.yao.0, hex.5.daxiang, hex.1.yong, hex.2.yong, hex.1.xiao.6, hex.2.xiao.6
OK: wenyan.2 (7/7 paragraphs), wenyan.1 paragraphs 2, 6, 10, 15; paragraph counts match original (wenyan.1 16/16, wenyan.2 7/7).

Issue in sample: none (A/B/C/D = 0). 

## Automated scan (966 keys)
- (B) line alignment: char-overlap check of every yao/xiao against all six original lines (+xiao vs. yao); every flagged outlier was manually checked, all correctly aligned (false positives from short/abstract lines). Count B = 0.
- (E) leading labels 「九二：」/译：: 0. Markdown: 0. ASCII punctuation: 0. Leading/trailing whitespace, embedded newlines (outside wenyan): 0. Empty values: 0. Shorter than 0.9x original: 0.
- Quote check: 「…」 fragments absent from the original = 78 xiao keys (hexagrams [31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47]) plus a few yao/tuan. These quote the *translated* phrase rather than the original (e.g. 31.xiao.0 「感应在脚拇趾」), while hex 1-30 xiao quote the original (「潜龙勿用」). Inconsistent but not wrong; optional normalisation only.
- Length: only hex.8.xiao.4 (61 chars) and hex.10.xiao.2 (67 chars) exceed 60 for xiao; acceptable (originals are 3 clauses).

## Fix list (all low severity; no real mistranslation found)
1. key hex.2.yao.5 (A-minor, consistency)
   current: 龙在原野上交战，流出的血青黄混杂（喻阴盛与阳相争，两败俱伤）。
   suggested: 龙在原野上交战，流出的血玄黄相杂（玄为青黑色，天色；黄为地色，喻阴阳两败俱伤）。
   reason: 玄 = 青黑/黑色 (wenyan.2 itself renders 天玄 as 青黑色); 「青黄」 mistranslates 玄黄, and 王弼/孔疏 read 玄黄 as 天地杂色.
2. key hex.1.yao.5 (D, optional)
   current: 龙飞得过高，到了极点，必将有悔恨。
   suggested: 龙飞得过高，到了极点，会有悔恨。
   reason: 「必将」 is stronger than 有悔; very mild, the 文言/小象 reading (盈不可久) supports it, so keep if preferred.
No other fixes. Items I checked and judged legitimate alternative readings, NOT to be changed: 34.xiao.5 不详=考虑不周详 (程传); 64.yao.2 note about 「利」前当有「不」; 49.ci 己日 with 已日 note; 6.yao.2 and 14.yao.2 parentheticals; 41.xiao.2 一人行 gloss; 49.tuan 水火相息=相灭.
