import Foundation
import Tyme4Swift

// 六爻纳甲（京房八宫）与真太阳时。纯逻辑；枚举 rawValue 为简体术语，界面层另行本地化

/// 卦在本宫中的位次，世爻由此而定
enum GongKind: String, CaseIterable {
    case benGong = "本宫", yiShi = "一世", erShi = "二世", sanShi = "三世", siShi = "四世", wuShi = "五世",
         youHun = "游魂", guiHun = "归魂"
    /// 世爻 1...6（初=1）
    var shi: Int { [6, 1, 2, 3, 4, 5, 4, 3][GongKind.allCases.firstIndex(of: self)!] }
}

/// 六亲，以宫五行为我
enum LiuQin: String, CaseIterable {
    case xiongDi = "兄弟", ziSun = "子孙", qiCai = "妻财", guanGui = "官鬼", fuMu = "父母"
}

/// 六神，按日干自初爻起
enum LiuShen: String, CaseIterable {
    case qingLong = "青龙", zhuQue = "朱雀", gouChen = "勾陈", tengShe = "螣蛇", baiHu = "白虎", xuanWu = "玄武"
}

struct NaJiaPan {
    /// 一个纳甲爻：六亲 + 干支（如 甲子）
    struct Yao: Equatable {
        let liuqin: LiuQin, ganzhi: String
        var wuxing: String { NaJia.wuxing(ganzhi) }
    }
    struct Row {
        let liushen: LiuShen
        let liuqin: LiuQin
        let ganzhi: String
        let wuxing: String
        let fu: Yao?            // 伏神（飞神即本行）
        let bian: Yao?          // 动爻所化
    }
    let palace: Trigram         // 宫，宫五行 = palace.wx
    let kind: GongKind
    let shi: Int, ying: Int     // 1...6
    let rows: [Row]             // 初→上
    let year: String, month: String, day: String, hour: String   // 四柱干支
    let xunKong: [String]       // 日旬空两支
}

enum NaJia {
    static let stems = Array("甲乙丙丁戊己庚辛壬癸").map(String.init)
    /// 五行相生序：木火土金水
    static let elements = Array("木火土金水").map(String.init)
    /// 地支五行，下标同 Zhouyi.branches
    static let branchWx = Array("水土木木土火火土金金土水").map(String.init)

    /// 京房纳甲，下标同 Zhouyi.trigrams（乾兑离震巽坎艮坤）；前三为内卦初二三，后三为外卦四五上
    static let table: [[String]] = [
        "甲子甲寅甲辰壬午壬申壬戌", "丁巳丁卯丁丑丁亥丁酉丁未", "己卯己丑己亥己酉己未己巳", "庚子庚寅庚辰庚午庚申庚戌",
        "辛丑辛亥辛酉辛未辛巳辛卯", "戊寅戊辰戊午戊申戊戌戊子", "丙辰丙午丙申丙戌丙子丙寅", "乙未乙巳乙卯癸丑癸亥癸酉",
    ].map { s in let c = Array(s); return (0..<6).map { String(c[$0 * 2...$0 * 2 + 1]) } }

    private static func code(_ bits: [Int]) -> Int { bits.enumerated().reduce(0) { $0 | $1.element << $1.offset } }
    private static func tri(_ b: ArraySlice<Int>) -> Int { Zhouyi.trigrams.firstIndex { $0.b == Array(b) }! }

    /// 八宫表：卦码（初爻为最低位）→（宫下标, 位次）。由八纯卦逐爻变出：
    /// 一至五世依次变初至五爻，游魂再变四爻，归魂将下卦变回本宫
    static let gongTable: [Int: (palace: Int, kind: GongKind)] = {
        var t: [Int: (Int, GongKind)] = [:]
        for (p, g) in Zhouyi.trigrams.enumerated() {
            var c = code(g.b + g.b)
            t[c] = (p, .benGong)
            for i in 0..<5 { c ^= 1 << i; t[c] = (p, GongKind.allCases[i + 1]) }
            c ^= 1 << 3; t[c] = (p, .youHun)
            c ^= 0b111; t[c] = (p, .guiHun)
        }
        return t
    }()

    static func gong(_ bits: [Int]) -> (palace: Trigram, kind: GongKind) {
        let g = gongTable[code(bits)]!
        return (Zhouyi.trigrams[g.palace], g.kind)
    }

    /// 应 = 世 ± 3
    static func ying(_ shi: Int) -> Int { shi > 3 ? shi - 3 : shi + 3 }

    /// 六爻纳甲干支，初→上
    static func ganzhi(_ bits: [Int]) -> [String] {
        Array(table[tri(bits[0..<3])][0..<3] + table[tri(bits[3..<6])][3..<6])
    }

    /// 干支（或单支）的地支五行
    static func wuxing(_ gz: String) -> String { branchWx[Zhouyi.branches.firstIndex(of: String(gz.last!))!] }

    /// 六亲：我 = 宫五行，他 = 爻五行
    static func liuQin(me: String, _ other: String) -> LiuQin {
        let d = (elements.firstIndex(of: other)! - elements.firstIndex(of: me)! + 5) % 5
        return [.xiongDi, .ziSun, .qiCai, .guanGui, .fuMu][d]   // 同我 我生 我克 克我 生我
    }

    /// 六神：甲乙青龙 丙丁朱雀 戊勾陈 己螣蛇 庚辛白虎 壬癸玄武，自初爻起顺排
    static func liuShen(dayStem: String) -> [LiuShen] {
        let s = [0, 0, 1, 1, 2, 3, 4, 4, 5, 5][stems.firstIndex(of: dayStem)!]
        return (0..<6).map { LiuShen.allCases[(s + $0) % 6] }
    }

    /// 旬空：日柱所在旬多出的两支（甲子旬空戌亥）
    static func xunKong(_ dayGanzhi: String) -> [String] {
        let s = stems.firstIndex(of: String(dayGanzhi.first!))!, b = Zhouyi.branches.firstIndex(of: String(dayGanzhi.last!))!
        let k = (b - s + 10) % 12
        return [Zhouyi.branches[k], Zhouyi.branches[(k + 1) % 12]]
    }

    /// 四柱干支，经 tyme4swift（SixtyCycleHour）：立春换年，节令换月，23:00 起即换次日日柱（子时归次日）。
    /// 年、月柱以北京钟点判节气（tyme4swift 节气时刻为北京时间），日、时柱取 date 在 timeZone 下的钟点
    static func pillars(_ date: Date, timeZone: TimeZone = .current) -> (year: String, month: String, day: String, hour: String) {
        // 节气时刻按北京时间：年、月柱取北京钟点；日、时柱取当地钟点
        func at(_ tz: TimeZone) -> SixtyCycleHour {
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = tz
            let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            return try! SolarTime.fromYmdHms(c.year!, c.month!, c.day!, c.hour!, c.minute!, c.second!).getSixtyCycleHour()
        }
        let bj = at(TimeZone(identifier: "Asia/Shanghai")!), h = at(timeZone)
        return (bj.year.getName(), bj.month.getName(), h.day.getName(), h.sixtyCycle.getName())
    }

    /// 排盘。伏神：本卦缺某六亲时，取本宫纯卦同位之爻伏于本卦该爻下；变爻六亲仍以本卦宫五行为我。
    /// 启用真太阳时时，传入 trueSolarTime(...) 的结果
    static func pan(_ a: Analysis, at date: Date, timeZone: TimeZone = .current) -> NaJiaPan {
        let (palace, kind) = gong(a.bits)
        let q = { (gz: String) in liuQin(me: palace.wx, wuxing(gz)) }
        let gz = ganzhi(a.bits), qin = gz.map(q)
        let head = ganzhi(palace.b + palace.b)
        let missing = Set(LiuQin.allCases).subtracting(qin)
        let bian = a.bian.map { ganzhi($0.bits) }
        let p = pillars(date, timeZone: timeZone)
        let shen = liuShen(dayStem: String(p.day.first!))
        let rows = (0..<6).map { i in
            NaJiaPan.Row(liushen: shen[i], liuqin: qin[i], ganzhi: gz[i], wuxing: wuxing(gz[i]),
                         fu: missing.contains(q(head[i])) ? .init(liuqin: q(head[i]), ganzhi: head[i]) : nil,
                         bian: a.moving.contains(i) ? bian.map { .init(liuqin: q($0[i]), ganzhi: $0[i]) } : nil)
        }
        return NaJiaPan(palace: palace, kind: kind, shi: kind.shi, ying: ying(kind.shi), rows: rows,
                        year: p.year, month: p.month, day: p.day, hour: p.hour, xunKong: xunKong(p.day))
    }

    // MARK: 真太阳时

    /// 均时差（分钟），NOAA 公式（Meeus 简化）：真太阳时 − 平太阳时
    static func equationOfTime(_ date: Date) -> Double {
        let t = (date.timeIntervalSince1970 / 86400 + 2440587.5 - 2451545) / 36525   // 儒略世纪
        let rad = Double.pi / 180
        let l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)).truncatingRemainder(dividingBy: 360) * rad
        let m = (357.52911 + t * (35999.05029 - 0.0001537 * t)) * rad
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let eps0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let eps = (eps0 + 0.00256 * cos((125.04 - 1934.136 * t) * rad)) * rad
        let y = pow(tan(eps / 2), 2)
        let r = y * sin(2 * l0) - 2 * e * sin(m) + 4 * e * y * sin(m) * cos(2 * l0)
            - 0.5 * y * y * sin(4 * l0) - 1.25 * e * e * sin(2 * m)
        return 4 * r / rad
    }

    /// 真太阳时 = 钟表时间 +（经度 − 时区经线）× 4 分 + 均时差。东经为正。
    /// 返回值须用同一 timeZone 的日历读出时分。时区经线按 secondsFromGMT（含夏令时）折算，
    /// 这样夏令时那一小时也被扣除——真太阳时与夏令时无关
    static func trueSolarTime(_ date: Date, longitude: Double, timeZone: TimeZone) -> Date {
        let meridian = Double(timeZone.secondsFromGMT(for: date)) / 240
        return date.addingTimeInterval((longitude - meridian) * 240 + equationOfTime(date) * 60)
    }
}
