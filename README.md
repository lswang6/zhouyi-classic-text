# 周易卜卦 · Zhouyi I Ching Oracle

一款免费、无广告、离线、开源的 iOS 周易应用。重"象与辞"的阅读与反思，不打分、不预测吉凶。

A free, ad-free, offline, open-source I Ching app for iOS — a tool for reading and reflection, not fortune scoring.

## 功能

- **起卦**：铜钱摇卦（可摇手机）、大衍筮法（蓍草，精确概率 1/16·5/16·7/16·3/16）、数字起卦、时间起卦（梅花易数，农历；默认「以字数加时」，所问不同则卦不同，可切换传统纯时间）。
- **解卦**：本卦 / 变卦，朱熹《易学启蒙》动爻断法（含贞悔、用九用六）；卦辞、爻辞、白话；互卦 · 错卦 · 综卦。
- **十翼**：彖传、大象、小象（随爻）、文言（乾坤）。
- **梅花体用**：体用五行生克，本 → 互 → 变 的始中终。
- **六爻纳甲**：八宫、世应、纳甲、六亲、六神、旬空、伏神、变爻；四柱以 [tyme4swift](https://github.com/6tail/tyme4swift) 按节气计算。只排盘，不自动断语。
- **真太阳时**（可选，手选城市或经度，不申请定位）。
- **记录**：搜索、收藏、应验反馈、备注、导出 JSON / 文本；iCloud 同步。
- **易学专栏** 12 篇、今日一卦、桌面小组件。
- 12 种界面语言；支持动态字体。

## 构建

```sh
brew install xcodegen
cd Zhouyi
xcodegen generate
xcodebuild test -project Zhouyi.xcodeproj -scheme Zhouyi -destination 'platform=iOS Simulator,name=iPhone 17'
```

要求 Xcode 16+（Swift Testing）、iOS 17+。

## 准确性

- 经传白话译文 966 条（原创），原文下方对照显示。
- 卦辞 64 条、爻辞 384 条与 Wikisource《周易》、freizl/yijing、Kanripo、《周易正义》多源对校。
- 十翼以 Wikisource 公有领域原文为准、freizl/yijing 为第二见证，分歧按《周易正义》裁决，取舍逐条留档。
- 纳甲八宫、世应、纳甲、六亲、伏神对 [bopo/najia](https://github.com/bopo/najia) 做 64 卦穷举对拍。
- 单元测试覆盖卦序、断法七例、互错综、体用、大衍概率、时间起卦边界（春节/立春、子时、闰月）、四柱与真太阳时。

## 来源与致谢

- 经文与传文：《周易》通行本（公有领域）；[freizl/yijing](https://github.com/freizl/yijing)（MIT）。
- 历法：[6tail/tyme4swift](https://github.com/6tail/tyme4swift)（MIT）。
- 纳甲对校：[bopo/najia](https://github.com/bopo/najia)（MIT）。
- 算法思路参考：kentang2017/ichingshifa（MIT）、ZhouYiLab（MIT）、liuyao-engine（Apache-2.0）。
- 字体：Noto Serif CJK 子集，SIL OFL 1.1（见 `OFL-NotoSerifCJK.txt`）。
- 水墨配图由 AI 生成。

## 许可

代码以 MIT 许可发布（见 `LICENSE`）。经典原文属公有领域。
