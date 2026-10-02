# 周易 / 六爻 / 梅花 / 干支 开源项目调研（2026-10-02，gh + WebFetch，只读）

校验标记：[V]=已读 README/源码确认；[U]=仅来自 GitHub 元数据或搜索摘要，未深读。Stars/license/pushed 来自 `gh api`（2026-10-02）。

## 0. 先给结论

- 高星“周易”类 repo 极少；GitHub 上能用的多是 AI-skill / MCP 包装。最有价值的是：历法库 6tail/tyme4swift（MIT，Swift）、六爻排盘对照集（najia / liuyao-engine / yigram-najia-rules，MIT/Apache）、ichingshifa（MIT，含大衍筮法）、ZhouYiLab（MIT，梅花文档较完整）。
- 文本：没有一个“高星 + 宽松协议 + 十翼齐全”的现成数据集。公有领域原文来源是 Wikisource / ctext（原典本身 PD），GitHub 数据集多半协议不清或带 NC。建议自己用 PD 原典校对而不是拷贝某 repo 数据。
- 与我们 app 的直接关系：我们是三枚铜钱（6/7/8/9 = 1/8,3/8,3/8,1/8）+ 数字/时间起卦 + 朱熹《易学启蒙》断法，不做六爻纳甲。所以“准确性”主要在 (1) 历法/干支/节气/子时边界 (2) 起卦概率（可加大衍筮法）(3) 梅花起卦取数口径 (4) 互/错/综卦 和 卦宫 等结构表的交叉校验。

## 1. Repo 总表

| # | repo | ★ | license | 语言 | 最近 push | 做什么 | 能借什么 | 可复用代码/数据？ |
|---|---|---|---|---|---|---|---|---|
| 1 | 6tail/tyme4swift [V] | 30 | MIT | Swift | 2026-06 | Lunar 升级版：公历/农历/干支/节气/寿星天文历，SixtyCycleHour 注释“立春换年，节令换月，23点换日” | 直接 SPM 引入；干支四柱、节令月建、旬、节气精确到时刻 | 可以（MIT） |
| 2 | 6tail/lunar-swift [V] | 154 | MIT | Swift | 2025-11 | 同作者旧版，星数高，已被 Tyme 取代 | 备选；同源算法 | 可以 |
| 3 | 6tail/lunar-javascript [U] | 1689 | MIT | JS | 2025-11 | 同作者 JS 版，事实标准，被多个六爻库当交叉验证 | 当“预言机”写测试用例 | 可以（仅测试用） |
| 4 | kentang2017/ichingshifa [V] | 289 | MIT | Python | 2026-10 | 大衍筮法模拟、六十四卦、纳甲、京房、六神、伏神、日期占卦；Streamlit/Kivy 应用 | 三变筮法流程、卦爻辞数据 pkl、伏神/飞伏、旬空 | 代码可（MIT，署名）；data.pkl 来源需追溯（爬取，见 kentang2017/iching_databases，无 license） |
| 5 | bopo/najia [V] | 45 | MIT | Python | 2023-08 | 纳甲六爻排盘；被多项目当差分预言机 | 八宫/纳甲/六亲/世应查表 | 可以 |
| 6 | yaomancy/liuyao-engine [V] | 8 | Apache-2.0 | Python | 2026-06 | 确定性六爻引擎，sxtwl+lunar-python 双库交叉；DESIGN.md 讲清子时、节气、跨时区、真太阳时取舍；带 ctext 公有领域《卜筮正宗》《增删卜易》全文 | 设计原则“凡进核心必可交叉验证”；边界测试清单；真太阳时做成可选层 | 可以（Apache-2.0，署名+NOTICE）；古籍原文 PD |
| 7 | AdrienSterling/yigram-najia-rules [V] | 1 | MIT | JSON/MD | 2026-06 | 纳甲/六亲/八宫/世应/用神机器可读规则表 + 铜钱概率说明 | tables.json 作 64 卦宫位/世应/纳甲表的测试预言 | 可以 |
| 8 | banderzhm/ZhouYiLab [V部分] | 132 | MIT | C++23 | 2026-09 | 六爻/梅花/八字/奇门等；docs/meihua 有《梅花易数排盘后如何分析》，引《梅花易数》原文，写明五种起卦口径、体用、应期、真太阳时选项 | 梅花起卦口径规范、体用分判、闰月处理、规则版本回显 | 文档思路可借；README 含商务微信，注意质量参差，代码 C++ 不好移植 |
| 9 | ChesterRa/mingpan [U] | 116 | Apache-2.0 | TS | 2026-09 | MCP 排盘：六爻/梅花/八字等，多时区换算北京时间 | 跨时区起卦处理思路 | 可以（Apache） |
| 10 | muyen/meihua-yishu [V部分] | 205 | CC BY-NC-SA 4.0 | Python/skill | 2026-08 | 梅花易数 AI skill；强调“象不是评分”，实验报告称按五行算吉凶≈抛硬币 | UX 文案立场：不给分数/百分比，展示 体/用/互/变 关系 | 仅思路（NC，不可拷贝） |
| 11 | muyen/decoding-iching [V] | 30 | CC BY-NC-SA 4.0 | Python/SQLite | 2026-07 | 384 爻标签 + iching.db（64卦/384爻/十翼/周易集解/周易本义/东坡易传）+ Wilhelm 对照 | 用来人工核对我们的卦爻辞和十翼（只读校验） | 仅校验，不可打包进 app（NC+SA） |
| 12 | john-walks-slow/open-iching [V] | 13 | 无 license | HTML/JSON | 2023-05 | 易经+易传结构化 JSON 目标项目，施工中 | 数据结构设计参考（array/name/symbol 词典） | 否（无 license） |
| 13 | zhuzai-2007/yi [V] | 0 | 无 license | TS/PWA | 2026-10 | 周易经传阅读 + 三钱起卦 + 记录 + BYOK AI 解读；卦爻辞/小象/彖/大象/文言/序卦/杂卦关联完整，静态离线 PWA | UX：经/传/六爻三层标签、原典关联、卦例导入导出 | 否（无 license）；可参考信息架构 |
| 14 | adamblvck/iching-wilhelm-dataset [V] | 40 | MIT | JSON/CSV | 2025-10 | Wilhelm-Baynes 英译 JSON（该译本 2020 起 PD） | 英文界面语言的卦辞/爻辞英文来源 | 大概率可（MIT + PD 原译）；需自查是否含现代编辑内容 [U] |
| 15 | opencosmos-ai/iching [V部分] | 0 | CC0-1.0 | TS | 2026-09 | 64 卦/8 卦查表 + sources/zhouyi 原典 + Legge | CC0 的 周易核心文本（卦辞+386 爻辞含用九用六）可作校对基准 | 可以（CC0）；数据质量需自查 |
| 16 | Horace-Maxwell/Horosa-Web-App-*（macOS/Win）、Brhiza/mingyu、hhszzzz/taibu [V部分] | 384/379、464、602 | AGPL-3.0、AGPL-3.0、other | JS/TS | 2026-10 | 大而全“玄学工作站/AI 算命” | 仅功能灵感：每日运势、起卦后“导出文本”、历史库、择日 | 不可复制代码（AGPL/other） |
| 17 | RealKai42/liu-yao-divining [U] | 349 | MIT | Python | 2025-03 | 六爻游戏+GPT 解读 | 摇卦交互动画灵感 | 可以 |
| 18 | Hsiao-Feng/MeiHuaYiShu-Analysis [V] | 20 | MIT | HTML | 2025-08 | 体用五行生克关系小工具，引《梅花易数》“用生体、比和则吉，体生用、克体则不吉” | 体用生克文案/对照表 | 可以 |
| 19 | zjinhu/LunarCalendar-SwiftUI、bestheme/lunar-swift [U] | 32、29 | MIT | Swift | 2021/2025 | 轻量农历 | 无需，tyme4swift 更全 | - |

未找到：有星数的“周易全文+十翼+多语翻译、宽松协议”单一数据集；搜索 `iching json`/`易经 json` 等关键词 gh 仅返回零星低星仓库。

## 2. 可借鉴点（按优先级）

### A. 准确性

A1. 历法四柱/月建/节令/子时：用 tyme4swift 对拍或直接引入。[M]
- 来源：6tail/tyme4swift（MIT）。已确认 SixtyCycleHour 的规则：立春换年、节令换月（月柱由交节精确时刻决定）、23:00 换日；SolarTerm 来自寿星天文历 ShouXingUtil。
- 我们现状：时间起卦用 Apple `.chinese` 日历。注意 Apple 日历给的是农历年月日（含闰月标记），不给 月建/节令；也不处理 23:00 晚子时换日。若 app 只需“农历年支数+月+日+时支”，Apple 历法够用，但“年柱按立春、月柱按节令”的显示或六爻风格功能必须用节令库。
- 建议：先不引依赖，写 20~50 组边界用例（跨子时 23:00、立春前后 1 分钟、闰月、1900 年前后、春节当天）拿 tyme4swift（作为测试专用 SPM test dependency）和 Apple `.chinese` 互相比对，差异进 bug 列表。[S]

A2. 起卦概率：铜钱已是正确的 6/7/8/9=1/8,3/8,3/8,1/8（yigram-najia-rules 的 casting-probability.md 同样强调这点）。增加“大衍筮法（蓍草）”选项：老阴6=1/16、少阳7=5/16、少阴8=7/16、老阳9=3/16（标准值，ichingshifa 的 bookgua 实现了三变流程：分二、挂一、揲四、归奇）。[S 直接按概率表采样；M 做可视化三变动画]
- 注意 [U]：ichingshifa 的分二用均匀随机整数，其输出分布是否精确等于上述概率我没有验证；我们应直接用精确概率采样，或用枚举验证后再做动画。
- 朱熹《易学启蒙》动爻断法对老阴/老阳比例有影响，需要在文案里说明两种方法的变爻概率不同：铜钱动爻概率 1/4，蓍草 = 1/16+3/16 = 1/4（总动爻概率恰好相同，但老阳:老阴 = 3:1，铜钱是 1:1）。[已演算，可核对]

A3. 梅花起卦口径核对：以 ZhouYiLab 的 docs/meihua 为清单（MIT）。[S 校对，M 增加方式]
- 时间起卦：年取地支数（子1…亥12），月、日取农历数，三者相加除8取上卦，加时支数除8取下卦、除6取动爻；余0按8/6论。闰月按该月月序，不加第13月。（我们的实现应对照一遍：年用“地支数”而非公元年；用农历年地支即春节分界，与四柱的立春分界不同，需在文档中说明。）
- 两数起卦、三数起卦、字占笔画、闻声起卦五种；我们已有数字起卦，可补“三数”。
- 体用分判：动爻所在经卦为用，另一为体；初二三动→下卦为用，四五上动→上卦为用。
- 来源文献是《梅花易数》卷一~三（Wikisource 有，PD）。

A4. 结构表交叉验证：把 yigram-najia-rules/tables.json（MIT）和 najia 的八宫归属、世应、游魂归魂，对我们 64 卦数据做自动断言（如互卦、错卦、综卦由位运算生成，不手填）。[S]
- 来源：AdrienSterling/yigram-najia-rules、bopo/najia。

A5. 真太阳时做成可选层，默认用钟表时间（liuyao-engine DESIGN.md 的取舍，理由是可验证性；ZhouYiLab 梅花文档也让调用方显式声明）。我们可加“按所在地经度校正”的高级开关，默认关；需要定位权限，建议只手输城市/经度，保持离线、隐私。[M]
- 跨时区：先把本地时刻换算成北京时间再判节令（liuyao-engine/mingpan 的做法）。海外用户（我们有 12 种界面语言）会遇到。

A6. 差分测试文化：liuyao-engine 的 tests/test_differential.py 思路——用第二个独立实现对拍，CI 不一致即 bug。我们可以把 64 卦卦序/二进制/互变综错生成函数做穷举对拍（4096 个 (本卦,动爻集) 组合）。[S]

### B. 功能完善

B1. 互卦、错卦、综卦 展示（若尚未有）。梅花易数 本/互/变 三卦 + 体用生克；ZhouYiLab 文档与 ichingshifa 都有。[S]
B2. 梅花体用生克解读：体用五行关系五种（比和、用生体、体生用、用克体、体克用）+ 应期原则（用为即应、互为中应、变为终应——ZhouYiLab 文档引卷三）。不要给分数。[M]
B3. 序卦/杂卦/十翼关联（zhuzai-2007/yi 的结构：每卦关联彖、大象、小象、文言、序卦、杂卦）。[M，依赖 C 部分文本]
B4. 六爻纳甲排盘（装卦：纳甲、六亲、六神、世应、旬空、伏神）：najia/liuyao-engine/yigram 的表可交叉验证，但这是另一体系，会增大范围，且依赖日干支和旬空，必须先做 A1。建议作为 phase 3 或“进阶盘”，若做，用 MIT/Apache 表对拍后自己实现。[L]
B5. 用九/用六（乾坤全变）规则：386 爻辞=384+用九+用六；opencosmos 数据（CC0）和 zhuzai-2007/yi 都显式覆盖。我们应确认乾、坤六爻全动时有处理。[S]
B6. 多爻变断法 按朱熹《易学启蒙》七条：我们已实现，无需借鉴。可参考 ichingshifa 的 decode_two_gua（本卦+之卦合盘）展示布局。[S]

### C. 数据/文本

C1. 原典权威来源（均是公有领域原文，不是某 repo 的整理版）：Wikisource《周易》《易傳》（zh.wikisource.org，PD，网页协议 CC BY-SA 仅针对编辑部分，需谨慎 [U]），ctext.org 周易（原文 PD，站点条款限制批量抓取，需自行确认 [U]）。建议：用 Wikisource 文本逐条对拍我们现有 384 爻辞 + 64 卦辞 + 彖/象，输出差异清单，人工裁决。[M]
C2. 校对基准：muyen/decoding-iching 的 iching.db 与十翼 JSON（NC，仅本地对拍，不进 app）；opencosmos-ai/iching sources/zhouyi（CC0，可作第二基准，质量未验证）。[S]
C3. 英文译本：Wilhelm-Baynes（2020 进入 PD，adamblvck MIT 数据集）与 Legge（1882，PD）。可为英文/其他界面语言提供“经典英译”原文。需注意白话/现代译文不能拷贝，我们自己的白话保留。[S~M]
C4. 先天八卦数、五行、自然象、方位、人伦、人体、五色、动物等表（ZhouYiLab docs/meihua）——文本源自《梅花易数》，是 PD 知识，可自己整理成表（不要逐字拷贝其行文）。[S]
C5. 古籍原文包：liuyao-engine/data 带《卜筮正宗》《增删卜易》ctext 全文（PD），可作“易学专栏”引用来源（我们已有专栏 articles，可给每条加出处链接）。[S]

### D. UX

D1. “不是预测、是反思工具”的定位与文案：muyen/meihua-yishu 和 decoding-iching 的实验结论（吉凶无法从结构推出，≈50% 基线）支持我们“不打分、不给百分比、只展示象与关系”。App Store 审核/用户信任角度也更稳。[S，文案]
D2. 三层阅读结构“经 / 传 / 六爻 + 原典关联”标签（zhuzai-2007/yi，无 license，仅借布局想法）。[M]
D3. 起卦草稿保存：六次独立投掷每投存草稿，刷新/被杀后台可恢复（zhuzai-2007/yi）。我们的摇卦页若中途退出是否保留？[S]
D4. 卦例 JSON 导入导出、本地隐私说明（同上）；我们已有历史记录，可加导出。[S~M]
D5. 规则版本回显：结果页或设置里显示“起卦口径/历法口径/断法版本”（ZhouYiLab 文档的做法），减少口径争议。[S]
D6. 多时区/海外语言用户的时间说明（“按设备当前时区时间起卦”）。[S]

## 3. 许可与合规速查（App Store 商用）

- 可用代码/数据（保留版权声明与 LICENSE）：tyme4swift/lunar-swift/lunar-javascript（MIT）、ichingshifa（MIT）、najia（MIT）、yigram-najia-rules（MIT）、liuyao-engine（Apache-2.0，需 NOTICE）、ZhouYiLab（MIT）、mingpan（Apache-2.0）、opencosmos-ai/iching（CC0）、adamblvck Wilhelm 数据集（MIT，译本 PD）。
- 只借想法：muyen 两个 repo（CC BY-NC-SA）、Horosa/mingyu（AGPL-3.0）、taibu（other）、无 license 的 open-iching / zhuzai-2007/yi / sunls2/zhouyi / kentang2017/iching_databases（默认保留所有权利）。
- 在 App 内加“开源许可/致谢”页面（MIT/Apache 需要）。

## 4. 建议的 phase-2 执行顺序

1. A1+A6：做历法/起卦/结构表的对拍测试（不引入运行时依赖，S）。
2. C1：用 Wikisource PD 原文对拍现有卦爻辞/彖象，修错（M）。
3. A2：加大衍筮法起卦选项（S~M）。
4. A3+B2：梅花口径核对 + 体用生克/应期（M）。
5. B1/B3/B5：互错综、十翼关联、用九用六（S~M）。
6. A5：可选真太阳时/节令月建展示，决定是否引入 tyme4swift 运行时（M）。
7. 六爻纳甲盘（L）视需求放 phase 3。

## 5. 未验证项汇总

- Apple `.chinese` Calendar 对 1900 年前后、闰月、子时的行为（待用例验证）。
- ichingshifa 大衍实现的实际输出分布。
- Wikisource/ctext 具体条款是否允许打包进商业 app（PD 原文本身无问题，站点编辑/格式的版权需另核）。
- adamblvck、opencosmos 数据内容质量与是否含现代编辑。
- ZhouYiLab 只读了梅花分析文档，未读 C++ 源码；mingpan、taibu、liu-yao-divining 仅看 README/元数据。
- tyme4swift 的旬空（空亡）API 是否存在未确认（SixtyCycle.swift 内未找到 grep 命中，可能在 Ten.swift 一类中）。
