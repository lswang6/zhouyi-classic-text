import Foundation
import SwiftData

@Model
final class Record {
    // CloudKit 要求每个属性有默认值、无唯一约束
    var ts: Date = Date.now
    var q: String = ""
    var cat: String = "其他"
    var method: String = "coin"      // CastMethod.rawValue
    var lines: [Int] = []            // 6/7/8/9，初→上
    var fav: Bool = false
    var note: String = ""
    var verify: String = "待验"      // Record.verifyOptions

    static let categories = ["事业", "感情", "财运", "健康", "学业", "其他"]
    static let verifyOptions = ["待验", "应验", "未应验"]

    init(q: String, cat: String, method: CastMethod, lines: [Int], ts: Date = .now) {
        self.ts = ts
        self.q = q.trimmingCharacters(in: .whitespacesAndNewlines)   // 空则显示时再译占位语，随语言切换
        self.cat = cat
        self.method = method.rawValue
        self.lines = lines
        self.fav = false
        self.note = ""
        self.verify = "待验"
    }

    /// 显示用所问之事
    /// 旧版曾把占位语直接存进 q，一并视为空
    var question: String { q.isEmpty || q == "未填写所问之事" || q == "未填寫所問之事" ? L("未填写所问之事") : q }

    var analysis: Analysis { Zhouyi.analyze(lines) }

    /// “本卦 → 变卦”
    var title: String {
        let a = analysis
        return a.bian.map { L("%1$@ → %2$@", a.ben.full, $0.full) } ?? a.ben.full
    }

    /// “9月28日 14:30 · 铜钱摇卦 · 事业”
    var meta: String {
        let f = DateFormatter()
        f.locale = Localizer.shared.locale
        f.calendar = Calendar(identifier: .gregorian)   // 公历；12/24 小时制随语言
        f.setLocalizedDateFormatFromTemplate("MMMd jmm")
        return f.string(from: ts) + " · " + (CastMethod(rawValue: method)?.label ?? method) + " · " + L(cat)
    }
}
