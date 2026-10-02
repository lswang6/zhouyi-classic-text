import SwiftUI

/// 04 易学：今日一卦、易学专栏、六十四卦
struct KnowledgeView: View {
    /// 专栏篇目，键 kb.<id>.title / .sub / .body（Knowledge 表），配图 kb-<id>
    static let ids = ["origins", "yinyang", "bagua", "sixtyfour", "yao", "change", "methods", "rules", "tenwings"]

    /// 今日一卦：按本地日历日序，每天依文王卦序走一卦
    static func todayN(_ d: Date = .now) -> Int {
        let cal = Calendar.current
        let ref = cal.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        let days = cal.dateComponents([.day], from: ref, to: cal.startOfDay(for: d)).day ?? 0
        return ((days % 64) + 64) % 64 + 1
    }

    var body: some View {
        let zh = Localizer.shared.isChinese
        let all = (1...64).map(Zhouyi.hexagram(n:))
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(L("易学")).font(zh ? .serif(34, semibold: true) : .system(size: 34, weight: .bold, design: .serif))
                    Spacer()
                    SettingsButton()
                }
                today(all[Self.todayN() - 1])

                section(L("易学专栏"))
                VStack(spacing: 0) {
                    ForEach(Self.ids, id: \.self) { id in
                        NavigationLink(value: Route.article(id)) { articleRow(id) }
                            .buttonStyle(.plain)
                        if id != Self.ids.last { Rectangle().fill(Color.divider).frame(height: 1).padding(.leading, UIImage(named: "kb-\(id)") != nil ? 98 : 14) }   // 起于标题文字
                    }
                }
                .card(padding: 0)

                section(L("六十四卦"))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(all, id: \.n) { h in
                        NavigationLink(value: Route.hexagram(h.n)) {
                            VStack(spacing: 8) {
                                HexGlyph(bits: h.bits)
                                Text(h.name)
                                    .font(zh ? .serif(15, semibold: true) : .system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.text)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 84)
                            .padding(.vertical, 6)
                            .background(Color.base, in: RoundedRectangle(cornerRadius: 10))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 88)   // 浮动标签栏下仍能滚出底部内容
        }
        .softTopEdge()
        .paperBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func section(_ s: String) -> some View {
        Text(s).font(.system(size: 16, weight: .heavy)).foregroundStyle(Color.text).padding(.bottom, -10)
    }

    private func today(_ h: Hexagram) -> some View {
        NavigationLink(value: Route.hexagram(h.n)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L("今日一卦")).font(.system(size: 12, weight: .bold)).foregroundStyle(Color.accentText)
                    Spacer()
                    Text(HomeView.dateText(.now)).font(.system(size: 12)).foregroundStyle(Color.subdued)
                }
                GuaImage(n: h.n)
                HStack(alignment: .top, spacing: 14) {
                    HexGlyph(bits: h.bits, width: 40, lineHeight: 5, gap: 4, split: 7)
                    VStack(alignment: .leading, spacing: 4) {
                        HexTitle(h: h)
                        Text(h.bh).font(.system(size: 14)).lineSpacing(3).foregroundStyle(Color.subdued)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward").accessibilityHidden(true)
                        .font(.system(size: 15)).foregroundStyle(Color.gray600)
                }
            }
            .card(shadow: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func articleRow(_ id: String) -> some View {
        HStack(spacing: 12) {
            if UIImage(named: "kb-\(id)") != nil {
                Image(decorative: "kb-\(id)").resizable().scaledToFill().nightDim()
                    .frame(width: 72, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(L("kb.\(id).title", table: "Knowledge")).font(Localizer.shared.isChinese ? .serif(16, semibold: true) : .system(size: 15, weight: .semibold, design: .serif)).foregroundStyle(Color.text)
                Text(L("kb.\(id).sub", table: "Knowledge")).font(.system(size: 13)).foregroundStyle(Color.subdued).lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward").accessibilityHidden(true)
                .font(.system(size: 15)).foregroundStyle(Color.gray600)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

/// 卦名 + 全名 + 序号与上下卦
private struct HexTitle: View {
    let h: Hexagram
    var size: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(h.full)
                .font(Localizer.shared.isChinese ? .serif(size, semibold: true) : .system(size: size, weight: .semibold, design: .serif))
                .foregroundStyle(Color.text)
            Text(L("第%1$d卦 · 上%2$@下%3$@", h.n, h.up.label, h.lo.label))
                .font(.system(size: 12)).foregroundStyle(Color.subdued)
        }
    }
}

/// 专栏文章：题图、标题、正文（空行分段，“## ”行为小标题）
struct ArticleView: View {
    let id: String

    var body: some View {
        let zh = Localizer.shared.isChinese
        let font = { (size: CGFloat, bold: Bool) -> Font in
            zh ? .serif(size, semibold: bold) : .system(size: size, weight: bold ? .semibold : .regular, design: .serif)
        }
        let blocks = L("kb.\(id).body", table: "Knowledge").components(separatedBy: "\n\n")
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if UIImage(named: "kb-\(id)") != nil {
                    Color.clear
                        .aspectRatio(3 / 2, contentMode: .fit)
                        .overlay { Image(decorative: "kb-\(id)").resizable().scaledToFill().nightDim() }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("kb.\(id).title", table: "Knowledge")).font(font(28, true)).foregroundStyle(Color.text)
                    Text(L("kb.\(id).sub", table: "Knowledge")).font(.system(size: 15)).foregroundStyle(Color.subdued)
                }
                ForEach(blocks.indices, id: \.self) { i in
                    let lines = blocks[i].components(separatedBy: "\n")
                    let head = lines.first?.hasPrefix("## ") == true ? String(lines[0].dropFirst(3)) : nil
                    let text = (head == nil ? lines : Array(lines.dropFirst())).joined(separator: "\n")
                    if let head {
                        Text(head).font(font(20, true)).foregroundStyle(Color.text).padding(.top, 8)
                    }
                    if !text.isEmpty {
                        Text(text).font(font(17, false)).lineSpacing(8).foregroundStyle(Color.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .softTopEdge()
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
    }
}

/// 卦详情：配图、卦画、卦名、白话；中文另列卦辞与六爻爻辞
struct HexagramView: View {
    let n: Int

    var body: some View {
        let h = Zhouyi.hexagram(n: n)
        let zh = Localizer.shared.isChinese
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GuaImage(n: n)
                HStack(spacing: 20) {
                    HexGlyph(bits: h.bits, width: 72, lineHeight: 8, gap: 7, split: 10, radius: 2)
                    HexTitle(h: h, size: 24)
                    Spacer(minLength: 0)
                }
                .card(shadow: true)

                block(L("白话解读")) {
                    Text(h.bh).font(.system(size: 16)).lineSpacing(4).foregroundStyle(Color.text)
                }
                if zh {
                    block(L("卦辞")) {
                        Text(h.name + "：" + h.ci).font(.serif(18)).lineSpacing(3).foregroundStyle(Color.text)
                    }
                    block(L("爻辞")) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(0..<6, id: \.self) { i in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(Zhouyi.lineName(i, yang: h.bits[i] == 1))
                                        .font(.system(size: 14, weight: .heavy)).foregroundStyle(Color.line)
                                        .frame(width: 44, alignment: .leading)
                                    Text(h.yao[i]).font(.serif(16)).lineSpacing(2).foregroundStyle(Color.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .softTopEdge()
        .paperBackground()
        .navigationTitle(h.full)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
    }

    private func block(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(Color.subdued)
            content()
        }
    }
}

#Preview { NavigationStack { KnowledgeView() }.environment(AppState()) }
