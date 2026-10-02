import SwiftUI
import WidgetKit

// 今日一卦：与应用共用 Zhouyi.swift、HexagramData.swift、Language.swift、Theme.swift（见 project.yml）

@main
struct ZhouyiWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayHexagram", provider: Provider()) { entry in
            TodayView(entry: entry).containerBackground(Color.layer1, for: .widget)
        }
        .configurationDisplayName(L("今日一卦"))
        .description(L("每日一卦，点按查看卦辞。"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct Entry: TimelineEntry {
    let date: Date
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now)) }

    /// 现在一条，下个本地零点换卦
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = Date.now, cal = Calendar.current
        let midnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now)!)
        completion(Timeline(entries: [Entry(date: now), Entry(date: midnight)], policy: .atEnd))
    }
}

/// 同 KnowledgeView.todayN：2000-01-01 起按日数循文王卦序
/// ponytail: 两处各一份，待移入 Zhouyi.swift 共用
func todayN(_ d: Date) -> Int {
    let cal = Calendar.current
    let ref = cal.date(from: DateComponents(year: 2000, month: 1, day: 1))!
    let days = cal.dateComponents([.day], from: ref, to: cal.startOfDay(for: d)).day ?? 0
    return ((days % 64) + 64) % 64 + 1
}

struct TodayView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let loc = Localizer.shared
        let zh = loc.isChinese
        let h = Zhouyi.hexagram(n: todayN(entry.date))
        // 中文取卦辞首句，其他语言取白话要旨
        let line = zh ? String(h.ci.prefix { $0 != "。" }) : h.bh
        let small = family == .systemSmall
        HStack(alignment: .center, spacing: 14) {
            if !small { glyph(h) }
            VStack(alignment: .leading, spacing: 4) {
                Text(L("今日一卦")).font(.caption2.weight(.medium)).foregroundStyle(Color.subdued)
                if small {
                    HStack(alignment: .center, spacing: 10) {
                        glyph(h)
                        Text(h.name).font(zh ? .serif(28, semibold: true) : .system(.title3, design: .serif, weight: .semibold))
                            .minimumScaleFactor(0.6).lineLimit(2)
                    }
                    .padding(.vertical, 2)
                } else {
                    Text(h.full).font(zh ? .serif(20, semibold: true) : .system(.title3, design: .serif, weight: .semibold))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                Text(line).font(zh ? .serif(small ? 13 : 15) : .system(small ? .caption : .footnote, design: .serif))
                    .foregroundStyle(Color.text.opacity(0.85))
                    .lineLimit(small ? 2 : 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color.text)
        .widgetURL(URL(string: "zhouyi://hexagram/\(h.n)"))
        .environment(\.locale, loc.locale)
        .environment(\.layoutDirection, loc.isRTL ? .rightToLeft : .leftToRight)
    }

    private func glyph(_ h: Hexagram) -> some View {
        let small = family == .systemSmall
        return HexGlyph(bits: h.bits, width: small ? 30 : 52, lineHeight: small ? 4 : 6, gap: small ? 3 : 5, split: small ? 5 : 8)
            .accessibilityLabel(h.full)
    }
}
