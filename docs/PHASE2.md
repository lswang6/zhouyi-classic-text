# 周易卜卦 · 二期升级方案（v1.1）

原则：无广告、免费、离线、开源（代码 MIT，仓库二期完成后公开）、不打分不预测（"象与辞"的反思工具）。
调研底稿：GitHub 19 个高分项目调研、现有 App 审计、经文多源对校（见文末"来源"）。

## 一期现状结论

- 起卦与断法逻辑**全部正确**：铜钱 6/7/8/9 = 1/8·3/8·3/8·1/8；文王卦序 64 格；朱熹《易学启蒙》七条动爻规则（含用九用六）；梅花时间起卦求余。
- 经文 448 条（64 卦辞 + 384 爻辞）与 Wikisource《周易》、freizl/yijing、Kanripo、《周易正义》对校：**仅 2 处简体错字**（繁体表已正确），另 1 处繁简用字对齐。
- 主要缺口：只有经、没有传；本卦/变卦之外无互/错/综；梅花起卦无体用；无六爻纳甲；起卦只有铜钱一种"摇"法；记录不能导出、不能同步；分享只是纯文本；无小组件；字号固定。

---

## 规格（Specs）

### S1 经文校正（P0）
- HexagramData.swift：同人九五、旅上九 `号啕→号咷`（错字）；坎上六 `置→寘`（与繁体表对齐）。
- 验收：对校脚本 `verify_text.py` 复跑，(c)(d) 类差异为 0。

### S2 朱熹断法细化（P0）
- 三爻动：本卦卦辞标"贞"、变卦卦辞标"悔"，本卦为主。
- 验收：focus3 单测断言贞/悔标签。

### S3 时间起卦口径（P0）
- 行为不变：年支按农历年（春节换年，梅花传统）；月日取农历，闰月按本月数；23:00 起入次日子时；按设备时区的钟表时间。
- 起卦卡片"计算过程"下加一行口径说明；修正代码注释。
- 若开启真太阳时（S9），时辰改用真太阳时。
- 默认「以字数加时」（《梅花易数》）：下卦与动爻之和再加所问之事字数（不计空白、标点、符号），同一时辰不同问题得卦不同；首页时间卡可切换「传统：只按时间」。
- 验收：立春与春节之间、22:59/23:00、闰月三类边界单测。

### S4 十翼入卦（P1）
- 新表 `Commentary.strings`（zh-Hans、zh-Hant）：`hex.N.tuan` 彖传、`hex.N.daxiang` 大象、`hex.N.xiao.0…5` 小象、`hex.1/2.xiao.6` 用九/用六小象、`wenyan.1/2` 文言。
- 来源：freizl/yijing（MIT）为骨架，Wikisource 公有领域原文为准，逐条对校；编辑取舍记录在案。
- UI：解卦页与卦详情页新增"传"页签（彖 · 象 · 文言），爻辞页每爻下附小象。仅中文界面显示。
- 验收：键集 = 64×8+4，非空；`乾` 不得简化成 `干`。

### S5 互卦 / 错卦 / 综卦（P1）
- 位运算：互 = 二至四爻为下、三至五爻为上；错 = 全反；综 = 倒置。
- UI：卦象卡下一行"互 · 错 · 综"，点按进入该卦详情。
- 验收：64 卦穷举 错∘错=id、综∘综=id；已知对照（屯互剥、既济互未济、屯综蒙、乾错坤）。

### S6 梅花体用（P1）
- 仅一动爻时（数字/时间起卦恒为一动）：动爻所在经卦为用，另一为体；五行关系五种：比和、用生体、体生用、用克体、体克用。
- 展示"本卦（始）→ 互卦（中）→ 变卦（终）"的用卦五行，只述关系，不给吉凶分。
- 验收：五种关系各一单测。

### S7 大衍筮法（P1）
- 新起卦方式 `yarrow`：逐爻按精确概率 6/7/8/9 = 1/16·5/16·7/16·3/16 生成。
- 摇卦页按方法分支：无铜钱，改为蓍草配图 + "三变成一爻"结果文案；说明老阳:老阴 = 3:1（铜钱为 1:1）。
- 验收：16 格映射计数 [1,5,7,3]。

### S8 六爻纳甲排盘（P1，进阶页签）
- 新文件 `NaJia.swift`（纯函数）+ `NaJiaTests.swift`。
- 内容：八宫归属与卦宫五行、世应、游魂/归魂；京房纳甲（乾内甲外壬、坤内乙外癸，震庚、巽辛、坎戊、离己、艮丙、兑丁；地支阳顺阴逆）；六亲（以宫五行为我）；六神（按日干：甲乙青龙、丙丁朱雀、戊勾陈、己螣蛇、庚辛白虎、壬癸玄武，自初爻起）；旬空（按日柱）；伏神（本宫首卦缺失之六亲）；变卦纳甲与变爻六亲。
- 历法：引入 `6tail/tyme4swift`（MIT，SPM）取日柱、月建（节令换月）、年柱（立春换年）；Apple 日历只用于梅花农历月日。
- UI：解卦页"纳甲"页签，表格：六神 · 六亲 · 纳甲 · 爻 · 世应 · 伏神 | 变爻；顶部显示 年月日时干支 与 旬空。不做旺衰/用神自动断语（只排盘不断）。
- 验收：八宫 64 卦归属、世应位置、纳甲干支与 najia / yigram-najia-rules（MIT）表穷举对拍；六神、旬空用例。

### S9 真太阳时（P2，可选）
- 设置页开关，默认关；手动选城市或输入经度（不申请定位，保持离线与隐私）。
- 真太阳时 = 钟表时间 + (经度 − 时区中央经线)×4 分钟 + 均时差（NOAA 公式）。
- 作用于时间起卦的时辰与纳甲盘的时柱；结果页注明"已按真太阳时"。
- 验收：北京/乌鲁木齐/伦敦用例，误差 < 1 分钟（与 NOAA 计算器对照）。

### S10 体验
- 解卦分享为图片（ImageRenderer，卦象卡 + 断卦要点 + App 名），保留文本分享。
- 记录导出：JSON + 纯文本，经系统分享面板；导入不做。
- 摇卦草稿：未成卦的爻存 UserDefaults，回到摇卦页可续，不动数据模型。
- 设置页"关于与致谢"：MIT 许可、Noto Serif CJK（OFL）、经文与算法来源。

### S11 iCloud 同步
- SwiftData + CloudKit（私有库），容器 `iCloud.com.lswang.zhouyi`；设置页开关（默认开，跟随系统 iCloud 状态）。
- 模型改动：`Record` 所有属性给默认值（CloudKit 要求），无唯一约束；轻量迁移，旧数据保留。
- 验收：两台模拟器/设备同一 Apple ID 互见记录；未登录 iCloud 时本地照常。
- **上架前必做**：用登录 iCloud 的真机/模拟器跑一次（生成开发环境 schema），再到 CloudKit Console → iCloud.com.lswang.zhouyi → Schema → Deploy Schema Changes to Production；否则正式版同步静默失效。归档后核对内嵌 entitlements 的 aps-environment 为 production。

### S12 小组件（Widget）
- 新 WidgetKit 扩展：今日一卦（小/中尺寸，卦画 + 卦名 + 卦辞首句），点按打开该卦详情（深链）。
- 复用 `Zhouyi.swift`、`HexagramData.swift`、`Localization.swift`；语言选择经 App Group 共享。
- 验收：小/中尺寸浅色、深色截图；跨天刷新。

### S13 Dynamic Type 与无障碍
- `Theme.swift` 字体助手改为 `Font.custom(_:size:relativeTo:)`，随系统字号缩放；固定尺寸仅保留卦画。
- 动效统一遵循"减弱动态效果"；卦画与铜钱补 VoiceOver 标签。
- 验收：最大辅助字号下主要页面无截断/重叠。

### S14 易学专栏新篇与配图
- 新篇：体用、大衍筮法、纳甲（中文先写，翻译最后统一交 codex）。
- 配图（imagegen，以现有 kb-* 水墨图为参考保持画风）：kb-tiyong、kb-dayan、kb-najia、蓍草摇卦页背景（浅/深）。

### S15 开源
- LICENSE（MIT）、OFL.txt（字体）、README（功能、截图、构建、来源与致谢）。
- 发布前确认后再把 GitHub 仓库设为 Public。

### S16 经传白话译文
- 新表 `Vernacular.strings`（zh-Hans、zh-Hant）：卦辞、384 爻辞、用九/用六、彖传、大象、小象、文言（逐段）的现代汉语译文，约 990 条。
- 译法：以王弼注、《周易正义》、程传、《本义》主流解释为准，原创译文，不照抄现代出版物；繁体由简体经 OpenCC 转换并人工校正（乾、於、繫等）。
- UI：卦辞、爻辞、传各页签顶部"白话对照"开关（默认开），译文以次要样式显示在原文下方；仅中文界面。
- 验收：键集完整、非空；文言段数与原文一致；抽查 10% 由第二位审校通读。

### 不做
旺衰/用神自动断语与吉凶评分、非中文经文译本（Wilhelm/Legge 版权与质量待核）、iPad 布局、记录导入。

---

## 计划（Waves）

| Wave | 内容 | 负责 | 文件边界 |
| --- | --- | --- | --- |
| 1 | S1 S2 S3(逻辑) S5 S6 S7(采样) 算法 + 单测 | Opus worker A | Zhouyi.swift、HexagramData.swift、ZhouyiTests.swift |
| 1 | S4 数据 | Opus worker B | */Commentary.strings、脚本在 Zhouyi/tools/text |
| 2 | S8 纳甲引擎 + S9 真太阳时函数 + tyme4swift 接入 | Opus worker D | NaJia.swift、SolarTime（并入 NaJia.swift 或 Zhouyi.swift）、NaJiaTests.swift、project.yml |
| 2 | S14 配图 | 主会话 imagegen | Assets.xcassets |
| 3 | UI-1：解卦页（传、互错综、体用、纳甲页签、分享图片）+ 卦详情 | Opus worker C1 | ReadingView.swift、KnowledgeView.swift |
| 3 | UI-2：首页/摇卦（大衍、草稿、口径说明）、记录导出、设置（真太阳时、iCloud、关于） | Opus worker C2 | HomeView、CastView、HistoryView、ZhouyiApp/Settings |
| 4 | S11 iCloud、S12 Widget、S13 Dynamic Type | Opus worker E | Record.swift、project.yml、新 Widget 目标、Theme.swift |
| 5 | 专栏中文稿 + 全部新文案翻译（10 种语言） | codex | *.lproj |
| 6 | 模拟器 QA（单机单 agent）、审阅、README/LICENSE、合并 | 主会话 | — |

规则：
- 新 UI 文案由引入者写 zh-Hans、zh-Hant、en；其余 8 种语言先填英文并标 `/* i18n-todo */`，Wave 5 由 codex 统一翻译并清除标记。
- 同一时间只有一个 agent 跑模拟器 / xcodebuild test。
- 新增文件后在 `Zhouyi/` 下 `xcodegen generate`。
- 每个 Wave 结束：主会话审阅 diff + 全量单测通过后再进下一 Wave。

## 来源与许可
- 经文/传文：freizl/yijing（MIT）；校对用 zh.wikisource《周易》（公有领域原文）、《周易正义》、Kanripo KR1a0001。
- 历法：6tail/tyme4swift（MIT，运行时依赖）。
- 纳甲对拍：bopo/najia（MIT）、AdrienSterling/yigram-najia-rules（MIT）。
- 算法思路：kentang2017/ichingshifa（MIT，大衍）、ZhouYiLab（MIT，梅花体用）、liuyao-engine（Apache-2.0，口径设计）。
- CC BY-NC-SA / AGPL / 无许可项目只借鉴思路，不拷贝代码与数据。
- 字体：Noto Serif CJK 子集（SIL OFL 1.1）。
