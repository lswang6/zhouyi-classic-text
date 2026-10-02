import Foundation

// 八卦，爻序自下而上（1=阳）。数组顺序即先天数：1乾 2兑 3离 4震 5巽 6坎 7艮 8坤
struct Trigram {
    let k: String, b: [Int], sym: String, nat: String, wx: String
    private var i: Int { Zhouyi.trigrams.firstIndex { $0.b == b }! + 1 }
    /// 显示用卦名、卦象（天泽火雷…）
    var name: String { L("tri.\(i).k", table: "Hexagrams", default: k) }
    var nature: String { L("tri.\(i).nat", table: "Hexagrams", default: nat) }
    /// 中文用卦名，其他语言用卦象，与解卦页一致
    var label: String { Localizer.shared.isChinese ? name : nature }
}

struct Hexagram {
    let n: Int              // 文王卦序 1...64
    let name: String        // 乾
    let full: String        // 乾为天
    let ci: String          // 卦辞
    let bh: String          // 白话要旨
    let yao: [String]       // 初→上 六爻爻辞
    let up: Trigram, lo: Trigram
    let bits: [Int]         // 初→上，1=阳

    /// 互卦：二三四爻为下卦，三四五爻为上卦
    var hu: Hexagram { Zhouyi.hexagram(bits: Array(bits[1...3] + bits[2...4])) }
    /// 错卦：六爻皆变
    var cuo: Hexagram { Zhouyi.hexagram(bits: bits.map { 1 - $0 }) }
    /// 综卦：六爻倒置
    var zong: Hexagram { Zhouyi.hexagram(bits: bits.reversed()) }
}

struct Analysis {
    let lines: [Int]        // 6/7/8/9，初→上
    let bits: [Int]
    let moving: [Int]       // 动爻下标，升序
    let ben: Hexagram
    let bian: Hexagram?
}

/// 梅花体用：动爻所在经卦为用，另一经卦为体。始/中/终 = 本卦用 / 互卦 / 变卦用
struct TiYong {
    enum Relation: String { case biHe = "比和", yongShengTi = "用生体", tiShengYong = "体生用", yongKeTi = "用克体", tiKeYong = "体克用" }
    let ti: Trigram, yong: Trigram, relation: Relation
    let hu: Hexagram, bianYong: Trigram
}

struct FocusItem: Hashable {
    let tag: String, text: String, main: Bool
}

struct Focus {
    let rule: String, items: [FocusItem]
}

/// 上卦、下卦为先天数 1...8，动爻 1...6
struct TriCast: Equatable {
    let up: Int, lo: Int, mv: Int
}

struct TimeCast {
    let yearBranch: Int     // 年支数，子=1
    let month: Int          // 农历月（闰月按本月数）
    let isLeapMonth: Bool
    let day: Int            // 农历日
    let hourBranch: Int     // 时支数，子=1
    let extra: Int          // 所问之事字数（以字数加时），传统纯时间为 0
    let s1: Int, s2: Int
    let cast: TriCast
    /// 中文：八月十八；其他语言：农历8月18日
    var lunarText: String {
        guard Localizer.shared.isChinese else { return isLeapMonth ? L("农历闰%1$d月%2$d日", month, day) : L("农历%1$d月%2$d日", month, day) }
        return Zhouyi.lunarMonthName(month, leap: isLeapMonth) + Zhouyi.lunarDayName(day)
    }
}

enum CastMethod: String, CaseIterable {
    case coin, number, time, yarrow
    var label: String {
        switch self {
        case .coin: L("铜钱摇卦")
        case .yarrow: L("大衍筮法")
        case .number: L("数字起卦")
        case .time: L("时间起卦")
        }
    }
}

enum Zhouyi {
    static let trigrams: [Trigram] = [
        Trigram(k: "乾", b: [1, 1, 1], sym: "☰", nat: "天", wx: "金"),
        Trigram(k: "兑", b: [1, 1, 0], sym: "☱", nat: "泽", wx: "金"),
        Trigram(k: "离", b: [1, 0, 1], sym: "☲", nat: "火", wx: "火"),
        Trigram(k: "震", b: [1, 0, 0], sym: "☳", nat: "雷", wx: "木"),
        Trigram(k: "巽", b: [0, 1, 1], sym: "☴", nat: "风", wx: "木"),
        Trigram(k: "坎", b: [0, 1, 0], sym: "☵", nat: "水", wx: "水"),
        Trigram(k: "艮", b: [0, 0, 1], sym: "☶", nat: "山", wx: "土"),
        Trigram(k: "坤", b: [0, 0, 0], sym: "☷", nat: "地", wx: "土"),
    ]
    // 文王卦序表：kingWen[上卦][下卦]，下标同 trigrams
    static let kingWen: [[Int]] = [
        [1, 10, 13, 25, 44, 6, 33, 12],
        [43, 58, 49, 17, 28, 47, 31, 45],
        [14, 38, 30, 21, 50, 64, 56, 35],
        [34, 54, 55, 51, 32, 40, 62, 16],
        [9, 61, 37, 42, 57, 59, 53, 20],
        [5, 60, 63, 3, 48, 29, 39, 8],
        [26, 41, 22, 27, 18, 4, 52, 23],
        [11, 19, 36, 24, 46, 7, 15, 2],
    ]
    /// 卦文，下标 = 卦序 - 1。每行：卦名|全名|卦辞|白话|初…上
    static let texts: [[String]] = hexagramSource
        .split(separator: "\n").map { $0.components(separatedBy: "|") }

    static let branches = Array("子丑寅卯辰巳午未申酉戌亥").map(String.init)
    static let positions = ["初", "二", "三", "四", "五", "上"]
    static let lineValueName = [6: "老阴", 7: "少阳", 8: "少阴", 9: "老阳"]

    static func isMoving(_ v: Int) -> Bool { v == 6 || v == 9 }

    static func hexagram(bits: [Int]) -> Hexagram {
        let ti = { (b: ArraySlice<Int>) in trigrams.firstIndex { $0.b == Array(b) }! }
        let lo = ti(bits[0..<3]), up = ti(bits[3..<6])
        let n = kingWen[up][lo], t = texts[n - 1]
        let h = { (x: String, zh: String) in L("hex.\(n).\(x)", table: "Hexagrams", default: zh) }
        let c = { (x: String, zh: String) in L("hex.\(n).\(x)", table: "Classical", default: zh) }
        return Hexagram(n: n, name: h("name", t[0]), full: h("full", t[1]), ci: c("ci", t[2]), bh: h("bh", t[3]),
                        yao: (0..<6).map { c("yao.\($0)", t[4 + $0]) }, up: trigrams[up], lo: trigrams[lo], bits: bits)
    }

    /// 文王卦序 n → 卦
    static func hexagram(n: Int) -> Hexagram {
        let up = kingWen.firstIndex { $0.contains(n) }!, lo = kingWen[up].firstIndex(of: n)!
        return hexagram(bits: trigrams[lo].b + trigrams[up].b)
    }

    static func analyze(_ lines: [Int]) -> Analysis {
        let bits = lines.map { $0 % 2 }
        let moving = (0..<6).filter { isMoving(lines[$0]) }
        let bian = moving.isEmpty ? nil
            : hexagram(bits: bits.enumerated().map { moving.contains($0.offset) ? 1 - $0.element : $0.element })
        return Analysis(lines: lines, bits: bits, moving: moving, ben: hexagram(bits: bits), bian: bian)
    }

    /// 爻名：初九、九二……上六
    static func lineName(_ i: Int, yang: Bool) -> String {
        let n = yang ? "九" : "六"
        return i == 0 ? "初" + n : i == 5 ? "上" + n : n + positions[i]
    }

    /// 朱熹《易学启蒙》动爻断法
    static func focus(_ a: Analysis) -> Focus {
        let ben = a.ben, mov = a.moving
        func Y(_ h: Hexagram, _ i: Int, _ main: Bool = false) -> FocusItem {
            FocusItem(tag: L("%1$@ · %2$@卦", lineName(i, yang: h.bits[i] == 1), h.name), text: h.yao[i], main: main)
        }
        func C(_ h: Hexagram, _ main: Bool = false) -> FocusItem {
            FocusItem(tag: L("%@卦 卦辞", h.name), text: h.ci, main: main)
        }
        let still = (0..<6).filter { !mov.contains($0) }
        switch mov.count {
        case 0: return Focus(rule: L("六爻安静，以本卦卦辞为断。"), items: [C(ben, true)])
        case 1: return Focus(rule: L("一爻动，以本卦动爻爻辞为断。"), items: [Y(ben, mov[0], true)])
        case 2: return Focus(rule: L("二爻动，以本卦两动爻爻辞为断，以上爻为主。"), items: [Y(ben, mov[1], true), Y(ben, mov[0])])
        case 3: return Focus(rule: L("三爻动，以本卦与变卦卦辞为断，本卦为贞（主），变卦为悔。"), items: [
            FocusItem(tag: L("贞 · %@卦 卦辞", ben.name), text: ben.ci, main: true),
            FocusItem(tag: L("悔 · %@卦 卦辞", a.bian!.name), text: a.bian!.ci, main: false)])
        case 4: return Focus(rule: L("四爻动，以变卦两静爻爻辞为断，以下爻为主。"), items: [Y(a.bian!, still[0], true), Y(a.bian!, still[1])])
        case 5: return Focus(rule: L("五爻动，以变卦静爻爻辞为断。"), items: [Y(a.bian!, still[0], true)])
        default:
            if ben.n == 1 { return Focus(rule: L("六爻皆动，乾卦以用九为断。"), items: [FocusItem(tag: L("%1$@ · %2$@卦", L("用九"), ben.name), text: L("yongjiu.text", table: "Classical", default: "见群龙无首，吉。"), main: true)]) }
            if ben.n == 2 { return Focus(rule: L("六爻皆动，坤卦以用六为断。"), items: [FocusItem(tag: L("%1$@ · %2$@卦", L("用六"), ben.name), text: L("yongliu.text", table: "Classical", default: "利永贞。"), main: true)]) }
            return Focus(rule: L("六爻皆动，以变卦卦辞为断。"), items: [C(a.bian!, true)])
        }
    }

    /// 梅花体用，仅一爻动时成立。五行按相生序排列，克即隔一位
    static func tiYong(_ a: Analysis) -> TiYong? {
        guard a.moving.count == 1, let bian = a.bian else { return nil }
        let upper = a.moving[0] >= 3
        let ti = upper ? a.ben.lo : a.ben.up, yong = upper ? a.ben.up : a.ben.lo
        let wx = ["木", "火", "土", "金", "水"]
        let d = (wx.firstIndex(of: yong.wx)! - wx.firstIndex(of: ti.wx)! + 5) % 5
        let rel: TiYong.Relation = [.biHe, .tiShengYong, .tiKeYong, .yongKeTi, .yongShengTi][d]
        return TiYong(ti: ti, yong: yong, relation: rel, hu: a.ben.hu, bianYong: upper ? bian.up : bian.lo)
    }

    /// 大衍筮法一爻：老阴 1/16、少阳 5/16、少阴 7/16、老阳 3/16
    static func yarrowLine(using rng: inout some RandomNumberGenerator) -> Int {
        switch rng.next() & 15 {   // 16 整除 2^64，取低 4 位即均匀
        case 0: 6
        case 1...5: 7
        case 6...12: 8
        default: 9
        }
    }

    static func yarrowLine() -> Int {
        var g = SystemRandomNumberGenerator()
        return yarrowLine(using: &g)
    }

    /// 由先天数上卦、下卦与动爻（1...6）生成六爻值
    static func lines(from c: TriCast) -> [Int] {
        let bits = trigrams[c.lo - 1].b + trigrams[c.up - 1].b
        return bits.enumerated().map { i, b in i == c.mv - 1 ? (b == 1 ? 9 : 6) : (b == 1 ? 7 : 8) }
    }

    /// 数字起卦：上卦 n1%8，下卦 n2%8（余 0 取 8），动爻 n3%6（余 0 取 6）
    static func numberCast(_ n: [Int]) -> TriCast? {
        guard n.count == 3, n.allSatisfy({ $0 > 0 }) else { return nil }
        return TriCast(up: n[0] % 8 == 0 ? 8 : n[0] % 8, lo: n[1] % 8 == 0 ? 8 : n[1] % 8, mv: n[2] % 6 == 0 ? 6 : n[2] % 6)
    }

    /// 时间起卦（梅花易数）：年支 + 农历月 + 农历日 → 上卦；再加时支 → 下卦；总和 % 6 → 动爻。
    /// 日期、时辰取设备当地时钟；以当地公历日正午按北京时间查农历（闰月按本月数）。
    /// 年支随农历年，春节换年而非立春（梅花旧例）；23 点起为子时，日期计入次日。
    /// extra：《梅花易数》「以字数加时」，所问之事字数并入下卦与动爻之和（见 charCount）；0 即纯时间。
    static func timeCast(_ date: Date, calendar local: Calendar = .current, extra: Int = 0) -> TimeCast {
        var g = Calendar(identifier: .gregorian)   // 设备日历可能是和历/佛历等，年月日须按公历取
        g.timeZone = local.timeZone
        let hour = g.component(.hour, from: date)
        let civil = hour >= 23 ? g.date(byAdding: .day, value: 1, to: date)! : date
        let ymd = g.dateComponents([.year, .month, .day], from: civil)

        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        var greg = Calendar(identifier: .gregorian)
        greg.timeZone = chinese.timeZone
        let noon = greg.date(from: DateComponents(year: ymd.year, month: ymd.month, day: ymd.day, hour: 12))!
        let lunar = chinese.dateComponents([.year, .month, .day, .isLeapMonth], from: noon)

        let y = (lunar.year! - 1) % 12 + 1          // 六十甲子序 1=甲子 → 子=1
        let m = lunar.month!, d = lunar.day!
        let h = (hour + 1) / 2 % 12 + 1
        let s1 = y + m + d, s2 = s1 + h + extra
        return TimeCast(yearBranch: y, month: m, isLeapMonth: lunar.isLeapMonth ?? false, day: d, hourBranch: h, extra: extra,
                        s1: s1, s2: s2, cast: TriCast(up: s1 % 8 == 0 ? 8 : s1 % 8, lo: s2 % 8 == 0 ? 8 : s2 % 8, mv: s2 % 6 == 0 ? 6 : s2 % 6))
    }

    /// 所问之事的字数：按 Swift Character（字形簇）计，空白、换行、标点、符号（¥ + 及多数 emoji）不计。
    /// 「这次换工作是否合适？」→ 9；「  a b，c 」→ 3
    static func charCount(_ s: String) -> Int {
        let skip = CharacterSet.punctuationCharacters.union(.symbols).union(.whitespacesAndNewlines)
        return s.filter { !$0.unicodeScalars.allSatisfy(skip.contains) }.count
    }

    static let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]

    /// 今日一卦：2000-01-01 起按本地日历日序，每天依文王卦序走一卦（App 与小组件共用）
    static func todayN(_ d: Date = .now) -> Int {
        let cal = Calendar.current
        let ref = cal.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let days = cal.dateComponents([.day], from: ref, to: cal.startOfDay(for: d)).day ?? 0
        return ((days % 64) + 64) % 64 + 1
    }

    static func lunarMonthName(_ m: Int, leap: Bool) -> String {
        (leap ? L("闰") : "") + L(lunarMonths[m - 1])
    }

    static func lunarDayName(_ d: Int) -> String {
        let digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch d {
        case 1...10: return "初" + digits[d]
        case 20: return "二十"
        case 30: return "三十"
        default: return ["十", "廿"][d / 10 - 1] + digits[d % 10]
        }
    }

    /// 例如 “上离 下坎 · 动三爻”
    static func triText(_ c: TriCast) -> String {
        L("上%1$@ 下%2$@ · 动%3$@爻", trigrams[c.up - 1].label, trigrams[c.lo - 1].label, L(positions[c.mv - 1]))
    }
}
