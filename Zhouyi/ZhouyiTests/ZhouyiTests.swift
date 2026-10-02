import Foundation
import Testing
@testable import Zhouyi

// 期望值均按 README 规则与卦文手算。涉及文字的测试先固定为简体中文，英文模拟器上也能通过
// 只执行一次（全局 let 惰性初始化线程安全），并清掉 didSet 写入的设置，免得模拟器上的 App 被固定为简体
private let pinned: Void = {
    Localizer.shared.choice = .zhHans
    UserDefaults.standard.removeObject(forKey: "appLanguage")
}()
private func pinChinese() { _ = pinned }

@Test func textsData() {
    #expect(Zhouyi.texts.count == 64)
    for row in Zhouyi.texts {
        #expect(row.count == 10)
        #expect(row.allSatisfy { !$0.isEmpty })
    }
    #expect(Zhouyi.texts[0][0] == "乾")
    #expect(Zhouyi.texts[63][0] == "未济")
}

@Test func analyzeBasics() {
    pinChinese()
    let q = Zhouyi.analyze([7, 7, 7, 7, 7, 7])
    #expect(q.ben.n == 1 && q.ben.name == "乾")
    #expect(q.bian == nil)
    #expect(q.moving.isEmpty)
    #expect(Zhouyi.analyze([8, 8, 8, 8, 8, 8]).ben.n == 2)

    var seen = Set<Int>()
    for lo in Zhouyi.trigrams { for up in Zhouyi.trigrams { seen.insert(Zhouyi.hexagram(bits: lo.b + up.b).n) } }
    #expect(seen == Set(1...64))
}

@Test func hexagramByNumber() {
    for n in 1...64 { #expect(Zhouyi.hexagram(n: n).n == n) }
    #expect(KnowledgeView.todayN(Calendar.current.date(from: DateComponents(year: 2000, month: 1, day: 1))!) == 1)
}

@Test func analyzeSpecific() {
    pinChinese()
    let a = Zhouyi.analyze([7, 8, 9, 7, 8, 7])
    #expect(a.bits == [1, 0, 1, 1, 0, 1])
    #expect(a.ben.lo.k == "离" && a.ben.up.k == "离" && a.ben.n == 30)
    #expect(a.moving == [2])
    #expect(a.bian?.bits == [1, 0, 0, 1, 0, 1])
    #expect(a.bian?.lo.k == "震" && a.bian?.up.k == "离" && a.bian?.n == 21 && a.bian?.name == "噬嗑")
}

private func focus(_ lines: [Int]) -> Focus { Zhouyi.focus(Zhouyi.analyze(lines)) }

@Test func focus0() {
    pinChinese()
    let f = focus([7, 8, 7, 7, 8, 7])
    #expect(f.rule == "六爻安静，以本卦卦辞为断。")
    #expect(f.items == [FocusItem(tag: "离卦 卦辞", text: "利贞，亨。畜牝牛，吉。", main: true)])
}

@Test func focus1() {
    pinChinese()
    let f = focus([7, 8, 9, 7, 8, 7])
    #expect(f.rule == "一爻动，以本卦动爻爻辞为断。")
    #expect(f.items == [FocusItem(tag: "九三 · 离卦", text: "日昃之离，不鼓缶而歌，则大耋之嗟，凶。", main: true)])
}

@Test func focus2() {
    pinChinese()
    let f = focus([9, 7, 7, 7, 9, 7])
    #expect(f.rule == "二爻动，以本卦两动爻爻辞为断，以上爻为主。")
    #expect(f.items == [
        FocusItem(tag: "九五 · 乾卦", text: "飞龙在天，利见大人。", main: true),
        FocusItem(tag: "初九 · 乾卦", text: "潜龙勿用。", main: false),
    ])
}

@Test func focus3() {
    pinChinese()
    // 乾下三爻动 → 天地否
    let f = focus([9, 9, 9, 7, 7, 7])
    #expect(f.rule == "三爻动，以本卦与变卦卦辞为断，本卦为贞（主），变卦为悔。")
    #expect(f.items == [
        FocusItem(tag: "贞 · 乾卦 卦辞", text: "元亨利贞。", main: true),
        FocusItem(tag: "悔 · 否卦 卦辞", text: "否之匪人，不利君子贞，大往小来。", main: false),
    ])
}

@Test func focus4() {
    pinChinese()
    // 乾下四爻动 → 风地观，静爻五、上
    let f = focus([9, 9, 9, 9, 7, 7])
    #expect(f.rule == "四爻动，以变卦两静爻爻辞为断，以下爻为主。")
    #expect(f.items == [
        FocusItem(tag: "九五 · 观卦", text: "观我生，君子无咎。", main: true),
        FocusItem(tag: "上九 · 观卦", text: "观其生，君子无咎。", main: false),
    ])
}

@Test func focus5() {
    pinChinese()
    // 乾下五爻动 → 山地剥，静爻上
    let f = focus([9, 9, 9, 9, 9, 7])
    #expect(f.rule == "五爻动，以变卦静爻爻辞为断。")
    #expect(f.items == [FocusItem(tag: "上九 · 剥卦", text: "硕果不食，君子得舆，小人剥庐。", main: true)])
}

@Test func focus6() {
    pinChinese()
    let q = focus([9, 9, 9, 9, 9, 9])
    #expect(q.rule == "六爻皆动，乾卦以用九为断。")
    #expect(q.items == [FocusItem(tag: "用九 · 乾卦", text: "见群龙无首，吉。", main: true)])

    let k = focus([6, 6, 6, 6, 6, 6])
    #expect(k.rule == "六爻皆动，坤卦以用六为断。")
    #expect(k.items == [FocusItem(tag: "用六 · 坤卦", text: "利永贞。", main: true)])

    // 既济全动 → 未济
    let o = focus([9, 6, 9, 6, 9, 6])
    #expect(o.rule == "六爻皆动，以变卦卦辞为断。")
    #expect(o.items == [FocusItem(tag: "未济卦 卦辞", text: "亨，小狐汔济，濡其尾，无攸利。", main: true)])
}

@Test func derivedHexagrams() {
    for n in 1...64 {
        let h = Zhouyi.hexagram(n: n)
        #expect(h.cuo.cuo.n == n && h.zong.zong.n == n)
    }
    let hu = { Zhouyi.hexagram(n: $0).hu.n }
    #expect(hu(1) == 1 && hu(2) == 2 && hu(3) == 23 && hu(4) == 24 && hu(63) == 64 && hu(64) == 63)
    let zong = { Zhouyi.hexagram(n: $0).zong.n }
    #expect(zong(3) == 4 && zong(4) == 3 && zong(11) == 12 && zong(12) == 11)
    let cuo = { Zhouyi.hexagram(n: $0).cuo.n }
    #expect(cuo(1) == 2 && cuo(2) == 1 && cuo(29) == 30 && cuo(30) == 29)
}

@Test func tiYong() {
    let rel = { Zhouyi.tiYong(Zhouyi.analyze($0))?.relation }
    #expect(rel([9, 7, 7, 7, 7, 7]) == .biHe)          // 乾金 / 乾金
    #expect(rel([9, 8, 8, 7, 8, 7]) == .yongShengTi)   // 用震木 生 体离火
    #expect(rel([7, 8, 8, 9, 8, 7]) == .tiShengYong)   // 体震木 生 用离火
    #expect(rel([7, 8, 8, 8, 8, 6]) == .tiKeYong)      // 体震木 克 用坤土
    #expect(rel([9, 8, 8, 8, 8, 8]) == .yongKeTi)      // 用震木 克 体坤土
    #expect(rel([7, 7, 7, 7, 7, 7]) == nil && rel([9, 9, 7, 7, 7, 7]) == nil)

    // 噬嗑初爻动：用震 体离，互卦蹇，变卦晋之用为坤
    let t = Zhouyi.tiYong(Zhouyi.analyze([9, 8, 8, 7, 8, 7]))!
    #expect(t.yong.k == "震" && t.ti.k == "离" && t.hu.n == 39 && t.bianYong.k == "坤")
}

private struct FixedRNG: RandomNumberGenerator {
    var k: UInt64
    mutating func next() -> UInt64 { k }
}

@Test func yarrowWeights() {
    var counts: [Int: Int] = [:]
    for k in 0..<16 {
        var g = FixedRNG(k: UInt64(k))
        counts[Zhouyi.yarrowLine(using: &g), default: 0] += 1
    }
    #expect(counts == [6: 1, 7: 5, 8: 7, 9: 3])
    #expect((0..<100).allSatisfy { _ in (6...9).contains(Zhouyi.yarrowLine()) })
}

@Test func lineNames() {
    pinChinese()
    #expect(Zhouyi.lineName(0, yang: true) == "初九")
    #expect(Zhouyi.lineName(5, yang: false) == "上六")
    #expect(Zhouyi.lineName(1, yang: true) == "九二")
    #expect(Zhouyi.lineName(3, yang: false) == "六四")
}

@Test func numberCast() {
    pinChinese()
    #expect(Zhouyi.numberCast([8, 16, 6]) == TriCast(up: 8, lo: 8, mv: 6))
    #expect(Zhouyi.numberCast([1, 2, 3]) == TriCast(up: 1, lo: 2, mv: 3))
    #expect(Zhouyi.numberCast([9, 10, 13]) == TriCast(up: 1, lo: 2, mv: 1))
    #expect(Zhouyi.numberCast([0, 1, 1]) == nil)
    #expect(Zhouyi.numberCast([-1, 1, 1]) == nil)

    let c = TriCast(up: 3, lo: 6, mv: 3)
    #expect(Zhouyi.lines(from: c) == [8, 7, 6, 7, 8, 7])
    #expect(Zhouyi.triText(c) == "上离 下坎 · 动三爻")
}

private let shanghai: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return cal
}()

private func cast(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ mi: Int = 0) -> TimeCast {
    let date = shanghai.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: mi))!
    return Zhouyi.timeCast(date, calendar: shanghai)
}

@Test func timeCastAfternoon() {
    pinChinese()
    // 丙午年八月十八 未时：7+8+18=33，+8=41 → 上乾 下乾 动五
    let t = cast(2026, 9, 28, 14, 30)
    #expect(t.yearBranch == 7 && t.month == 8 && t.day == 18 && !t.isLeapMonth && t.hourBranch == 8)
    #expect(t.s1 == 33 && t.s2 == 41)
    #expect(t.cast == TriCast(up: 1, lo: 1, mv: 5))
    #expect(t.lunarText == "八月十八")
}

@Test func timeCastIgnoresDeviceCalendarSystem() {
    pinChinese()
    let date = shanghai.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 14, minute: 30))!
    for id in [Calendar.Identifier.japanese, .buddhist, .hebrew, .islamicUmmAlQura] {
        var c = Calendar(identifier: id)
        c.timeZone = shanghai.timeZone
        let t = Zhouyi.timeCast(date, calendar: c)
        #expect(t.yearBranch == 7 && t.lunarText == "八月十八" && t.cast == TriCast(up: 1, lo: 1, mv: 5))
    }
}

@Test func timeCastZiHour() {
    pinChinese()
    let late = cast(2026, 9, 28, 23, 30)
    #expect(late.month == 8 && late.day == 19 && late.hourBranch == 1)
    #expect(late.lunarText == "八月十九")

    let early = cast(2026, 9, 28, 0, 30)
    #expect(early.day == 18 && early.hourBranch == 1)

    let before = cast(2026, 9, 28, 22, 59)
    #expect(before.day == 18 && before.hourBranch == 12)
    let at = cast(2026, 9, 28, 23, 0)
    #expect(at.day == 19 && at.hourBranch == 1)
}

@Test func timeCastLeapAndNewYear() {
    pinChinese()
    let leap = cast(2025, 7, 25, 10)
    #expect(leap.isLeapMonth && leap.month == 6 && leap.day == 1 && leap.yearBranch == 6)
    #expect(leap.lunarText == "闰六月初一")

    // 立春（2/4）后、春节（2/17）前：年支仍随农历乙巳年。巳6+腊月12+十八=36，午7 → 43
    let lichun = cast(2026, 2, 5, 12)
    #expect(lichun.yearBranch == 6 && lichun.month == 12 && lichun.day == 18 && lichun.hourBranch == 7)
    #expect(lichun.cast == TriCast(up: 4, lo: 3, mv: 1))

    let eve = cast(2026, 2, 16, 12)
    #expect(eve.yearBranch == 6 && eve.month == 12 && eve.day == 29)

    let ny = cast(2026, 2, 17, 12)
    #expect(ny.yearBranch == 7 && ny.month == 1 && ny.day == 1)
    #expect(ny.lunarText == "正月初一")
}

@Test func lunarNames() {
    pinChinese()
    #expect(Zhouyi.lunarDayName(1) == "初一")
    #expect(Zhouyi.lunarDayName(10) == "初十")
    #expect(Zhouyi.lunarDayName(11) == "十一")
    #expect(Zhouyi.lunarDayName(20) == "二十")
    #expect(Zhouyi.lunarDayName(21) == "廿一")
    #expect(Zhouyi.lunarDayName(30) == "三十")
    #expect(Zhouyi.lunarMonthName(11, leap: false) == "冬月")
    #expect(Zhouyi.lunarMonthName(12, leap: false) == "腊月")
}

@Test func recordInit() {
    pinChinese()
    let r = Record(q: "  ", cat: "事业", method: .coin, lines: [7, 8, 9, 7, 8, 7])
    #expect(r.q == "")
    #expect(r.question == "未填写所问之事")
    #expect(r.verify == "待验")
    #expect(r.title == "离为火 → 火雷噬嗑")
}

@Test func chineseDates() {
    pinChinese()
    let d = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 14, minute: 30))!
    let r = Record(q: "x", cat: "事业", method: .coin, lines: [7, 7, 7, 7, 7, 7], ts: d)
    #expect(r.meta.hasPrefix("9月28日 14:30"), "\(r.meta)")
    #expect(HomeView.dateText(d) == "9月28日 星期一")
}

// MARK: - 多语言

@Test func resolveSystemLanguage() {
    let cases: [([String], AppLanguage)] = [
        (["zh-Hans-CN"], .zhHans), (["zh-Hant-TW"], .zhHant), (["zh-HK"], .zhHant), (["zh-TW"], .zhHant),
        (["zh-MO"], .zhHant), (["zh-CN"], .zhHans), (["zh"], .zhHans), (["zh-Hans-HK"], .zhHans),
        (["pt-PT"], .ptBR), (["pt-BR"], .ptBR), (["en-GB", "zh-Hans"], .en), (["ja-JP"], .ja), (["ko-KR"], .ko),
        (["es-419"], .es), (["fr-CA"], .fr), (["de-CH"], .de), (["ru-RU"], .ru), (["ar-SA"], .ar),
        (["it-IT", "zh-Hans"], .zhHans), (["it-IT"], .en), (["system"], .en), ([], .en),
    ]
    for (list, want) in cases { #expect(AppLanguage.resolve(list) == want, "\(list)") }
}

private func strings(_ lang: String, _ table: String) -> [String: String]? {
    Bundle.main.path(forResource: table, ofType: "strings", inDirectory: nil, forLocalization: lang)
        .flatMap { NSDictionary(contentsOfFile: $0) as? [String: String] }
}

/// 格式符类型多重集（位置序号可不同）
private func specifiers(_ s: String) -> [String] {
    let re = try! NSRegularExpression(pattern: #"%(\d+\$)?([@dDfsu])"#)
    return re.matches(in: s, range: NSRange(s.startIndex..., in: s)).map { (s as NSString).substring(with: $0.range(at: 2)) }.sorted()
}

private let manifest = strings("zh-Hans", "Localizable") ?? [:]

@Test func translationCoverage() throws {
    #expect(manifest.count > 100)
    #expect(manifest.allSatisfy { $0.key == $0.value })
    let kbKeys = Set(KnowledgeView.ids.flatMap { id in ["title", "sub", "body"].map { "kb.\(id).\($0)" } })
    #expect(Set((strings("zh-Hans", "Knowledge") ?? [:]).keys) == kbKeys, "zh-Hans Knowledge keys")
    let hexKeys = Set((1...64).flatMap { n in ["name", "full", "bh"].map { "hex.\(n).\($0)" } }
        + (1...8).flatMap { n in ["k", "nat"].map { "tri.\(n).\($0)" } })
    let classicalKeys = Set((1...64).flatMap { n in ["hex.\(n).ci"] + (0..<6).map { "hex.\(n).yao.\($0)" } }
        + ["yongjiu.text", "yongliu.text"])
    // 多参数键须带位置序号，译文才能调换参数顺序（阿拉伯语等）
    for k in manifest.keys where specifiers(k).count >= 2 {
        #expect(k.range(of: #"%[@dDfsu]"#, options: .regularExpression) == nil, "non-positional: \(k)")
    }
    let langs = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
        .filter { $0.hasSuffix(".lproj") }.map { String($0.dropLast(6)) }
        .filter { $0 != "zh-Hans" && $0 != "Base" }
    #expect(Set(langs).isSuperset(of: AppLanguage.allCases.filter { $0 != .system && $0 != .zhHans }.map(\.rawValue)))
    for lang in langs {
        let loc = strings(lang, "Localizable") ?? [:]
        #expect(Set(loc.keys) == Set(manifest.keys), "\(lang) Localizable keys")
        // 易学专栏：键同 zh-Hans，值非空
        let kb = strings(lang, "Knowledge")
        #expect(kb != nil, "\(lang) Knowledge")
        if let kb {
            #expect(Set(kb.keys) == kbKeys, "\(lang) Knowledge keys")
            for (k, v) in kb { #expect(!v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(lang) empty: \(k)") }
        }
        let hex = try #require(strings(lang, "Hexagrams"), "\(lang) Hexagrams")
        #expect(Set(hex.keys) == hexKeys, "\(lang) Hexagrams keys")
        let classical = strings(lang, "Classical")
        #expect((classical != nil) == (lang == "zh-Hant"), "\(lang) Classical")
        if let classical { #expect(Set(classical.keys) == classicalKeys, "\(lang) Classical keys") }
        for (k, v) in loc.merging(hex) { a, _ in a }.merging(classical ?? [:]) { a, _ in a } {
            #expect(!v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(lang) empty: \(k)")
            if loc[k] != nil { #expect(specifiers(v) == specifiers(k), "\(lang) format: \(k)") }
        }
    }
}

/// S16 白话译文：仅简繁中文；64×15 + 用九/用六各 2 + 文言 2 = 966 键，非空；文言段数同 Commentary
@Test func vernacularCoverage() throws {
    let keys = Set((1...64).flatMap { n in
        ["ci", "tuan", "daxiang"].map { "hex.\(n).\($0)" } + (0..<6).flatMap { ["hex.\(n).yao.\($0)", "hex.\(n).xiao.\($0)"] }
    } + ["hex.1.yong", "hex.2.yong", "hex.1.xiao.6", "hex.2.xiao.6", "wenyan.1", "wenyan.2"])
    #expect(keys.count == 966)
    for lang in ["zh-Hans", "zh-Hant"] {
        let v = try #require(strings(lang, "Vernacular"), "\(lang) Vernacular")
        #expect(Set(v.keys) == keys, "\(lang) Vernacular keys")
        for (k, s) in v { #expect(!s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(lang) empty: \(k)") }
        let c = try #require(strings(lang, "Commentary"), "\(lang) Commentary")
        for k in ["wenyan.1", "wenyan.2"] {
            #expect(v[k]?.components(separatedBy: "\n\n").count == c[k]?.components(separatedBy: "\n\n").count, "\(lang) \(k) paragraphs")
        }
    }
    let langs = try FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
        .filter { $0.hasSuffix(".lproj") }.map { String($0.dropLast(6)) }
    for lang in langs where !lang.hasPrefix("zh-") { #expect(strings(lang, "Vernacular") == nil, "\(lang) Vernacular") }
}

private let sources: [(name: String, text: String)] = {
    let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Zhouyi")
    let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    return files.filter { $0.hasSuffix(".swift") }.sorted()
        .map { ($0, (try? String(contentsOf: dir.appendingPathComponent($0), encoding: .utf8)) ?? "") }
}()

/// 源码中 L("…") 的字面键都在 zh-Hans 清单里（带 table: 的走 Hexagrams/Classical 表，跳过）
/// 运行时拼出的动态键也都在清单里
@Test func dynamicKeysInManifest() {
    let keys = Record.categories + Record.verifyOptions + Zhouyi.branches + Zhouyi.positions
        + Array(Zhouyi.lineValueName.values) + Zhouyi.lunarMonths + ["闰", "用九", "用六"]
        + ["比和", "用生体", "体生用", "用克体", "体克用"] + ["木", "火", "土", "金", "水"]   // TiYong.Relation、Trigram.wx
        + LiuQin.allCases.map(\.rawValue) + LiuShen.allCases.map(\.rawValue) + GongKind.allCases.map(\.rawValue)   // 纳甲页
    for k in keys { #expect(manifest[k] != nil, "\(k)") }
}

@Test func literalKeysInManifest() {
    #expect(sources.count >= 9)
    let re = try! NSRegularExpression(pattern: #"\bL\("((?:[^"\\]|\\.)*)"(\s*,\s*table:)?"#)
    var n = 0
    for (name, text) in sources {
        for m in re.matches(in: text, range: NSRange(text.startIndex..., in: text)) where m.range(at: 2).location == NSNotFound {
            let key = (text as NSString).substring(with: m.range(at: 1)).replacingOccurrences(of: "\\n", with: "\n")
            n += 1
            #expect(manifest[key] != nil, "\(name): \(key)")
        }
    }
    #expect(n > 100)
}

/// 界面文件里不应再有未经 L() 的中文字面量。卦文、卦理数据表与存储键所在文件不查
@Test func noBareChineseLiterals() {
    let skipFiles: Set = ["HexagramData.swift", "Zhouyi.swift", "NaJia.swift", "Record.swift"]
    let allowed = [
        "\"简体中文\"", "\"繁體中文\"", "\"日本語\"",     // 语言自称名
        "Text(verbatim: \"通\")", "Text(verbatim: \"寶\")",                  // 铜钱钱文
        "Text(verbatim: \"成\")", "Text(verbatim: \"卦\")",                  // 成卦朱印印文
        "v == \"应验\"", "v == \"未应验\"",               // verifyVariant 按存储键判断
    ]
    let re = try! NSRegularExpression(pattern: #"(L\(|table: |default: )?"[^"\n]*\p{Han}[^"\n]*""#)
    for (name, text) in sources where !skipFiles.contains(name) {
        for line in text.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            // 预览区在文件末尾，之后不查
            if t.hasPrefix("#Preview") || t.hasPrefix("// MARK: - Preview") || t.range(of: #"^private struct \w*Preview"#, options: .regularExpression) != nil { break }
            let code = line.components(separatedBy: "//").first!
            for m in re.matches(in: code, range: NSRange(code.startIndex..., in: code)) where m.range(at: 1).location == NSNotFound {
                let lit = (code as NSString).substring(with: m.range)
                #expect(allowed.contains { code.contains($0) && $0.contains(lit) }, "\(name): \(t)")
            }
        }
    }
}
