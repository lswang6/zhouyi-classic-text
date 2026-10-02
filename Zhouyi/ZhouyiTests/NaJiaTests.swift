import Foundation
import Testing
@testable import Zhouyi

// 纳甲对拍表：由 bopo/najia 2.0.1（PyPI，MIT）逐卦生成，下标 = 文王卦序 - 1。
// 每行：宫 世 应 | 初→上纳甲 | 初→上六亲首字 | 伏神（爻位 六亲首字 干支，逗号分隔）
// najia 只取本宫首卦中该六亲的第一个爻位；64 卦里所缺六亲在首卦中都只出现一次，故与"取所有爻位"等价
private let reference = [
    "乾63 甲子甲寅甲辰壬午壬申壬戌 子妻父官兄父 ",
    "坤63 乙未乙巳乙卯癸丑癸亥癸酉 兄父官兄妻子 ",
    "坎25 庚子庚寅庚辰戊申戊戌戊子 兄子官父官兄 3妻戊午",
    "离41 戊寅戊辰戊午丙戌丙子丙寅 父子兄子官父 4妻己酉",
    "坤41 甲子甲寅甲辰戊申戊戌戊子 妻官兄子兄妻 2父乙巳",
    "离41 戊寅戊辰戊午壬午壬申壬戌 父子兄兄妻子 3官己亥",
    "坎36 戊寅戊辰戊午癸丑癸亥癸酉 子官妻官兄父 ",
    "坤36 乙未乙巳乙卯戊申戊戌戊子 兄父官子兄妻 ",
    "巽14 甲子甲寅甲辰辛未辛巳辛卯 父兄妻妻子兄 3官辛酉",
    "艮52 丁巳丁卯丁丑壬午壬申壬戌 父官兄父子兄 5妻丙子",
    "坤36 甲子甲寅甲辰癸丑癸亥癸酉 妻官兄兄妻子 2父乙巳",
    "乾36 乙未乙巳乙卯壬午壬申壬戌 父官妻官兄父 1子甲子",
    "离36 己卯己丑己亥壬午壬申壬戌 父子官兄妻子 ",
    "乾36 甲子甲寅甲辰己酉己未己巳 子妻父兄父官 ",
    "兑52 丙辰丙午丙申癸丑癸亥癸酉 父官兄父子兄 2妻丁卯",
    "震14 乙未乙巳乙卯庚午庚申庚戌 妻子兄子官妻 1父庚子",
    "震36 庚子庚寅庚辰丁亥丁酉丁未 父兄妻父官妻 4子庚午",
    "巽36 辛丑辛亥辛酉丙戌丙子丙寅 妻父官妻父兄 5子辛巳",
    "坤25 丁巳丁卯丁丑癸丑癸亥癸酉 父官兄兄妻子 ",
    "乾41 乙未乙巳乙卯辛未辛巳辛卯 父官妻父官妻 1子甲子,5兄壬申",
    "巽52 庚子庚寅庚辰己酉己未己巳 父兄妻官妻子 ",
    "艮14 己卯己丑己亥丙戌丙子丙寅 官兄妻兄妻官 2父丙午,3子丙申",
    "乾52 乙未乙巳乙卯丙戌丙子丙寅 父官妻父子妻 5兄壬申",
    "坤14 庚子庚寅庚辰癸丑癸亥癸酉 妻官兄兄妻子 2父乙巳",
    "巽41 庚子庚寅庚辰壬午壬申壬戌 父兄妻子官妻 ",
    "艮25 甲子甲寅甲辰丙戌丙子丙寅 妻官兄兄妻官 2父丙午,3子丙申",
    "巽41 庚子庚寅庚辰丙戌丙子丙寅 父兄妻妻父兄 3官辛酉,5子辛巳",
    "震41 辛丑辛亥辛酉丁亥丁酉丁未 妻父官父官妻 2兄庚寅,4子庚午",
    "坎63 戊寅戊辰戊午戊申戊戌戊子 子官妻父官兄 ",
    "离63 己卯己丑己亥己酉己未己巳 父子官妻子兄 ",
    "兑36 丙辰丙午丙申丁亥丁酉丁未 父官兄子兄父 2妻丁卯",
    "震36 辛丑辛亥辛酉庚午庚申庚戌 妻父官子官妻 2兄庚寅",
    "乾25 丙辰丙午丙申壬午壬申壬戌 父官兄官兄父 1子甲子,2妻甲寅",
    "坤41 甲子甲寅甲辰庚午庚申庚戌 妻官兄父子兄 ",
    "乾41 乙未乙巳乙卯己酉己未己巳 父官妻兄父官 1子甲子",
    "坎41 己卯己丑己亥癸丑癸亥癸酉 子官兄官兄父 3妻戊午",
    "巽25 己卯己丑己亥辛未辛巳辛卯 兄妻父妻子兄 3官辛酉",
    "艮41 丁巳丁卯丁丑己酉己未己巳 父官兄子兄父 5妻丙子",
    "兑41 丙辰丙午丙申戊申戊戌戊子 父官兄兄父子 2妻丁卯",
    "震25 戊寅戊辰戊午庚午庚申庚戌 兄妻子子官妻 1父庚子",
    "艮36 丁巳丁卯丁丑丙戌丙子丙寅 父官兄兄妻官 3子丙申",
    "巽36 庚子庚寅庚辰辛未辛巳辛卯 父兄妻妻子兄 3官辛酉",
    "坤52 甲子甲寅甲辰丁亥丁酉丁未 妻官兄妻子兄 2父乙巳",
    "乾14 辛丑辛亥辛酉壬午壬申壬戌 父子兄官兄父 2妻甲寅",
    "兑25 乙未乙巳乙卯丁亥丁酉丁未 父官妻子兄父 ",
    "震41 辛丑辛亥辛酉癸丑癸亥癸酉 妻父官妻父官 2兄庚寅,4子庚午",
    "兑14 戊寅戊辰戊午丁亥丁酉丁未 妻父官子兄父 ",
    "震52 辛丑辛亥辛酉戊申戊戌戊子 妻父官官妻父 2兄庚寅,4子庚午",
    "坎41 己卯己丑己亥丁亥丁酉丁未 子官兄兄父官 3妻戊午",
    "离25 辛丑辛亥辛酉己酉己未己巳 子官妻妻子兄 1父己卯",
    "震63 庚子庚寅庚辰庚午庚申庚戌 父兄妻子官妻 ",
    "艮63 丙辰丙午丙申丙戌丙子丙寅 兄父子兄妻官 ",
    "艮36 丙辰丙午丙申辛未辛巳辛卯 兄父子兄父官 5妻丙子",
    "兑36 丁巳丁卯丁丑庚午庚申庚戌 官妻父官兄父 4子丁亥",
    "坎52 己卯己丑己亥庚午庚申庚戌 子官兄妻父官 ",
    "离14 丙辰丙午丙申己酉己未己巳 子兄妻妻子兄 1父己卯,3官己亥",
    "巽63 辛丑辛亥辛酉辛未辛巳辛卯 妻父官妻子兄 ",
    "兑63 丁巳丁卯丁丑丁亥丁酉丁未 官妻父子兄父 ",
    "离52 戊寅戊辰戊午辛未辛巳辛卯 父子兄子兄父 3官己亥,4妻己酉",
    "坎14 丁巳丁卯丁丑戊申戊戌戊子 妻子官父官兄 ",
    "艮41 丁巳丁卯丁丑辛未辛巳辛卯 父官兄兄父官 3子丙申,5妻丙子",
    "兑41 丙辰丙午丙申庚午庚申庚戌 父官兄官兄父 2妻丁卯,4子丁亥",
    "坎36 己卯己丑己亥戊申戊戌戊子 子官兄父官兄 3妻戊午",
    "离36 戊寅戊辰戊午己酉己未己巳 父子兄妻子兄 3官己亥"
]

private func at(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int, _ tz: String = "Asia/Shanghai") -> Date {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: tz)!
    return cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
}

/// 按 tz 读出时:分（分钟数）
private func clock(_ date: Date, _ tz: String) -> Double {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: tz)!
    let c = cal.dateComponents([.hour, .minute, .second], from: date)
    return Double(c.hour! * 60 + c.minute!) + Double(c.second!) / 60
}

@Test func baGongStructure() {
    var byPalace: [String: [Int]] = [:], seen = Set<Int>()
    for n in 1...64 {
        let g = NaJia.gong(Zhouyi.hexagram(n: n).bits)
        byPalace[g.palace.k, default: []].append(n)
        seen.insert(n)
    }
    #expect(NaJia.gongTable.count == 64)
    #expect(seen == Set(1...64))
    #expect(byPalace.count == 8 && byPalace.values.allSatisfy { $0.count == 8 })
    // 按宫内位次排列：本宫 一世…五世 游魂 归魂
    let order = { (k: String) in
        byPalace[k]!.sorted { GongKind.allCases.firstIndex(of: NaJia.gong(Zhouyi.hexagram(n: $0).bits).kind)!
            < GongKind.allCases.firstIndex(of: NaJia.gong(Zhouyi.hexagram(n: $1).bits).kind)! } }
    #expect(order("乾") == [1, 44, 33, 12, 20, 23, 35, 14])     // 乾 姤 遁 否 观 剥 晋 大有
    #expect(order("坤") == [2, 24, 19, 11, 34, 43, 5, 8])       // 坤 复 临 泰 大壮 夬 需 比
    #expect(GongKind.allCases.map(\.shi) == [6, 1, 2, 3, 4, 5, 4, 3])
    let kind = { (k: GongKind) in Set((1...64).filter { NaJia.gong(Zhouyi.hexagram(n: $0).bits).kind == k }) }
    #expect(kind(.youHun) == [35, 5, 28, 27, 36, 6, 61, 62])
    #expect(kind(.guiHun) == [14, 8, 17, 18, 7, 13, 53, 54])
    #expect((1...6).map(NaJia.ying) == [4, 5, 6, 1, 2, 3])
}

@Test func najiaMatchesReference() {
    #expect(reference.count == 64)
    for n in 1...64 {
        let bits = Zhouyi.hexagram(n: n).bits
        let p = NaJia.pan(Zhouyi.analyze(bits.map { $0 == 1 ? 7 : 8 }), at: at(2026, 10, 2, 12, 0))
        let fu = p.rows.enumerated().compactMap { i, r in r.fu.map { "\(i + 1)\($0.liuqin.rawValue.prefix(1))\($0.ganzhi)" } }
        let mine = "\(p.palace.k)\(p.shi)\(p.ying) " + p.rows.map(\.ganzhi).joined() + " "
            + p.rows.map { String($0.liuqin.rawValue.prefix(1)) }.joined() + " " + fu.joined(separator: ",")
        #expect(mine == reference[n - 1], "卦 \(n)")
        #expect(p.rows.allSatisfy { $0.bian == nil })
    }
}

@Test func najiaBasics() {
    #expect(NaJia.ganzhi([1, 1, 1, 1, 1, 1]) == ["甲子", "甲寅", "甲辰", "壬午", "壬申", "壬戌"])
    #expect(NaJia.ganzhi([0, 0, 0, 0, 0, 0]) == ["乙未", "乙巳", "乙卯", "癸丑", "癸亥", "癸酉"])
    #expect(NaJia.wuxing("甲子") == "水" && NaJia.wuxing("己未") == "土" && NaJia.wuxing("酉") == "金")
    #expect(NaJia.liuQin(me: "金", "金") == .xiongDi)
    #expect(NaJia.liuQin(me: "金", "水") == .ziSun)
    #expect(NaJia.liuQin(me: "金", "木") == .qiCai)
    #expect(NaJia.liuQin(me: "金", "火") == .guanGui)
    #expect(NaJia.liuQin(me: "金", "土") == .fuMu)
}

@Test func liuShenByDayStem() {
    let first = NaJia.stems.map { NaJia.liuShen(dayStem: $0)[0].rawValue }
    #expect(first == ["青龙", "青龙", "朱雀", "朱雀", "勾陈", "螣蛇", "白虎", "白虎", "玄武", "玄武"])
    #expect(NaJia.liuShen(dayStem: "己").map(\.rawValue) == ["螣蛇", "白虎", "玄武", "青龙", "朱雀", "勾陈"])
    #expect(NaJia.liuShen(dayStem: "甲") == LiuShen.allCases)
}

@Test func xunKong() {
    #expect(NaJia.xunKong("甲子") == ["戌", "亥"])
    #expect(NaJia.xunKong("癸酉") == ["戌", "亥"])
    #expect(NaJia.xunKong("甲戌") == ["申", "酉"])
    #expect(NaJia.xunKong("甲申") == ["午", "未"])
    #expect(NaJia.xunKong("甲午") == ["辰", "巳"])
    #expect(NaJia.xunKong("甲辰") == ["寅", "卯"])
    #expect(NaJia.xunKong("甲寅") == ["子", "丑"])
    #expect(NaJia.xunKong("己酉") == ["寅", "卯"])
}

// 期望值与 lunar_python 1.4（6tail 同作者的 Python 版，另一实现）对照；立春 2026-02-04 04:02 北京时间
@Test func pillars() {
    let b = NaJia.pillars(at(2026, 2, 4, 4, 1), timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    #expect([b.year, b.month, b.day, b.hour] == ["乙巳", "己丑", "己酉", "丙寅"])
    let a = NaJia.pillars(at(2026, 2, 4, 4, 3), timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    #expect([a.year, a.month, a.day, a.hour] == ["丙午", "庚寅", "己酉", "丙寅"])
    let d = NaJia.pillars(at(2026, 10, 2, 12, 0), timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    #expect([d.year, d.month, d.day, d.hour] == ["丙午", "丁酉", "己酉", "庚午"])
    // 23:00 起换次日日柱（tyme4swift 口径；lunar_python 默认八字仍记当日 己酉）
    let n = NaJia.pillars(at(2026, 10, 2, 23, 30), timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    #expect([n.day, n.hour] == ["庚戌", "丙子"])
    let e = NaJia.pillars(at(2026, 10, 2, 22, 59), timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    #expect([e.day, e.hour] == ["己酉", "乙亥"])
}

@Test func panDetails() {
    // 乾为天初爻动 → 天风姤；己酉日：六神起螣蛇，旬空寅卯
    let p = NaJia.pan(Zhouyi.analyze([9, 7, 7, 7, 7, 7]), at: at(2026, 10, 2, 12, 0),
                      timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    #expect(p.palace.k == "乾" && p.kind == .benGong && p.shi == 6 && p.ying == 3)
    #expect(p.rows[0].liushen == .tengShe && p.rows[5].liushen == .gouChen)
    #expect(p.xunKong == ["寅", "卯"] && p.day == "己酉")
    #expect(p.rows[0].bian == .init(liuqin: .fuMu, ganzhi: "辛丑"))
    #expect(p.rows[1...].allSatisfy { $0.bian == nil })
    #expect(p.rows.allSatisfy { $0.fu == nil })
    // 天风姤：缺妻财，伏乾宫二爻甲寅木于亥水之下；四爻动化 巽 未土父母（宫五行仍为金）
    var lines = Zhouyi.hexagram(n: 44).bits.map { $0 == 1 ? 7 : 8 }
    lines[3] = 9
    let g = NaJia.pan(Zhouyi.analyze(lines), at: at(2026, 10, 2, 12, 0), timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    #expect(g.kind == .yiShi && g.shi == 1 && g.ying == 4)
    #expect(g.rows[1].fu == .init(liuqin: .qiCai, ganzhi: "甲寅") && g.rows[1].ganzhi == "辛亥")
    #expect(g.rows[3].bian == .init(liuqin: .fuMu, ganzhi: "辛未"))
}

// 期望值由 Python 按 NOAA 均时差公式独立算出（scratchpad ref.py）
@Test func trueSolarTime() {
    let sh = TimeZone(identifier: "Asia/Shanghai")!
    // 北京 116.4°E：经度 −14.4 分，均时差 −14.2 分 → 11:31.4
    #expect(abs(clock(NaJia.trueSolarTime(at(2026, 2, 11, 12, 0), longitude: 116.4, timeZone: sh), "Asia/Shanghai") - 691.4) < 1)
    // 乌鲁木齐 87.6°E：经度 −129.6 分，均时差 −14.2 分 → 09:36.2
    #expect(abs(clock(NaJia.trueSolarTime(at(2026, 2, 11, 12, 0), longitude: 87.6, timeZone: sh), "Asia/Shanghai") - 576.2) < 1)
    // 伦敦 0.13°W，冬令时：均时差 +16.5 分 → 12:16.0
    let lon = TimeZone(identifier: "Europe/London")!
    #expect(abs(clock(NaJia.trueSolarTime(at(2026, 11, 3, 12, 0, "Europe/London"), longitude: -0.13, timeZone: lon), "Europe/London") - 736.0) < 1)
    // 伦敦夏令时 12:00 BST：真太阳时与夏令时无关 → 10:55.6
    #expect(abs(clock(NaJia.trueSolarTime(at(2026, 7, 1, 12, 0, "Europe/London"), longitude: -0.13, timeZone: lon), "Europe/London") - 655.6) < 1)
    #expect(abs(NaJia.equationOfTime(at(2026, 2, 11, 12, 0)) + 14.2) < 0.2)
}
