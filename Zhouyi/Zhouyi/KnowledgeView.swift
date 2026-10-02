import SwiftUI

/// 04 易学：今日一卦、易学专栏、六十四卦
struct KnowledgeView: View {
    /// 专栏篇目，键 kb.<id>.title / .sub / .body（Knowledge 表），配图 kb-<id>
    static let ids = ["origins", "yinyang", "bagua", "sixtyfour", "yao", "change", "methods", "dayan", "rules", "tiyong", "najia", "tenwings"]

    static func todayN(_ d: Date = .now) -> Int { Zhouyi.todayN(d) }

    var body: some View {
        let zh = Localizer.shared.isChinese
        let all = (1...64).map(Zhouyi.hexagram(n:))
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(L("易学")).font(zh ? .serif(34, semibold: true) : .scaled(34, .bold, design: .serif))
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
                                    .font(zh ? .serif(15, semibold: true) : .scaled(12, .semibold))
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
        Text(s).font(.scaled(16, .heavy)).foregroundStyle(Color.text).padding(.bottom, -10)
    }

    private func today(_ h: Hexagram) -> some View {
        NavigationLink(value: Route.hexagram(h.n)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L("今日一卦")).font(.scaled(12, .bold)).foregroundStyle(Color.accentText)
                    Spacer()
                    Text(HomeView.dateText(.now)).font(.scaled(12)).foregroundStyle(Color.subdued)
                }
                GuaImage(n: h.n)
                HStack(alignment: .top, spacing: 14) {
                    HexGlyph(bits: h.bits, width: 40, lineHeight: 5, gap: 4, split: 7)
                    VStack(alignment: .leading, spacing: 4) {
                        HexTitle(h: h)
                        Text(h.bh).font(.scaled(14)).lineSpacing(3).foregroundStyle(Color.subdued)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward").accessibilityHidden(true)
                        .font(.scaled(15)).foregroundStyle(Color.gray600)
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
                Text(L("kb.\(id).title", table: "Knowledge")).font(Localizer.shared.isChinese ? .serif(16, semibold: true) : .scaled(15, .semibold, design: .serif)).foregroundStyle(Color.text)
                Text(L("kb.\(id).sub", table: "Knowledge")).font(.scaled(13)).foregroundStyle(Color.subdued).lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.forward").accessibilityHidden(true)
                .font(.scaled(15)).foregroundStyle(Color.gray600)
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
                .font(Localizer.shared.isChinese ? .serif(size, semibold: true) : .scaled(size, .semibold, design: .serif))
                .foregroundStyle(Color.text)
            Text(L("第%1$d卦 · 上%2$@下%3$@", h.n, h.up.label, h.lo.label))
                .font(.scaled(12)).foregroundStyle(Color.subdued)
        }
    }
}

/// 专栏文章：题图、标题、正文（空行分段，“## ”行为小标题）
struct ArticleView: View {
    let id: String

    var body: some View {
        let zh = Localizer.shared.isChinese
        let font = { (size: CGFloat, bold: Bool) -> Font in
            zh ? .serif(size, semibold: bold) : .scaled(size, bold ? .semibold : .regular, design: .serif)
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
                    Text(L("kb.\(id).sub", table: "Knowledge")).font(.scaled(15)).foregroundStyle(Color.subdued)
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
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        HexGlyph(bits: h.bits, width: 72, lineHeight: 8, gap: 7, split: 10, radius: 2)
                        HexTitle(h: h, size: 24)
                        Spacer(minLength: 0)
                    }
                    HexRelations(h: h)
                }
                .card(shadow: true)

                block(L("白话解读")) {
                    Text(h.bh).font(.scaled(16)).lineSpacing(4).foregroundStyle(Color.text)
                }
                if zh || Translation.available {
                    VernacularToggle()
                    block(L("卦辞")) {
                        Scripture("hex.\(n).ci", zh ? h.name + "：" + h.ci : h.ci, size: 18)
                        Vernacular("hex.\(n).ci")
                    }
                    if !zh { TranslationImage(n: n) }
                    block(L("爻辞")) {
                        VStack(alignment: .leading, spacing: 12) {
                            let yong = Self.yong(n)
                            ForEach(0..<(yong == nil ? 6 : 7), id: \.self) { i in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(i < 6 ? Zhouyi.lineName(i, yang: h.bits[i] == 1) : yong!.label)
                                        .font(.scaled(14, .heavy)).foregroundStyle(Color.line)
                                        .frame(minWidth: 44, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Scripture(i < 6 ? "hex.\(n).yao.\(i)" : "hex.\(n).yong", i < 6 ? h.yao[i] : yong!.text)
                                        Vernacular(i < 6 ? "hex.\(n).yao.\(i)" : "hex.\(n).yong")
                                        let k = "hex.\(n).xiao.\(i)", xiao = L(k, table: "Commentary")
                                        if xiao != k || Translation.lookup(k) != nil { Scripture(k, xiao, size: 14, color: .subdued) }
                                        Vernacular(k, size: 13)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    if zh || Translation.lookup("hex.\(n).tuan") != nil { block(L("传")) { ZhuanView(n: n) } }
                    TranslationCredit()
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

    /// 乾用九、坤用六：第七行，小象键 hex.n.xiao.6
    static func yong(_ n: Int) -> (label: String, text: String)? {
        switch n {
        case 1: (L("用九"), Zhouyi.classical("yongjiu.text", default: "见群龙无首，吉。"))
        case 2: (L("用六"), Zhouyi.classical("yongliu.text", default: "利永贞。"))
        default: nil
        }
    }

    private func block(_ title: String, @ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.scaled(13, .bold)).foregroundStyle(Color.subdued)
            content()
        }
    }
}

/// 互 · 错 · 综：各一小卦画 + 卦名，点按进入该卦详情
struct HexRelations: View {
    let h: Hexagram

    var body: some View {
        HStack(spacing: 8) {
            ForEach([(L("互卦"), h.hu), (L("错卦"), h.cuo), (L("综卦"), h.zong)], id: \.0) { label, x in
                NavigationLink(value: Route.hexagram(x.n)) {
                    HStack(spacing: 8) {
                        HexGlyph(bits: x.bits, width: 18, lineHeight: 2, gap: 2, split: 4)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(label).font(.scaled(11, .bold)).foregroundStyle(Color.subdued)
                            Text(x.name)
                                .font(Localizer.shared.isChinese ? .serif(15, semibold: true) : .scaled(12, .semibold))
                                .foregroundStyle(Color.text)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray75, in: RoundedRectangle(cornerRadius: 10))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 传：彖、大象、文言（仅乾坤）。表中缺的段不显示；非中文读 Translation 表（仅英文有传）
struct ZhuanView: View {
    let n: Int
    @AppStorage("vernacular") private var vernacular = true

    var body: some View {
        let zh = Localizer.shared.isChinese
        let parts = [(L("彖曰"), "hex.\(n).tuan"), (L("象曰"), "hex.\(n).daxiang"), (L("文言"), "wenyan.\(n)")]
            .map { ($0.0, L($0.1, table: zh ? "Commentary" : "Translation"), $0.1) }
            .filter { $0.1 != $0.2 }   // 缺键时 L 返回键名
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parts, id: \.0) { label, text, key in
                VStack(alignment: .leading, spacing: 4) {
                    Text(label).font(.scaled(12, .bold)).foregroundStyle(Color.accentText)
                    // 白话逐段对照（文言按 \n\n 分段）；段数对不上则整段原文后接整段白话
                    let paras = text.components(separatedBy: "\n\n")
                    let vs = vernacular ? Vernacular.lookup(key)?.components(separatedBy: "\n\n") : nil
                    if !zh {
                        Scripture(key, "")
                    } else if let vs, vs.count == paras.count {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(paras.indices, id: \.self) { i in
                                VStack(alignment: .leading, spacing: 4) {
                                    original(paras[i])
                                    Vernacular(text: vs[i])
                                }
                            }
                        }
                    } else {
                        original(text)
                        Vernacular(key)
                    }
                }
            }
        }
    }

    private func original(_ s: String) -> some View {
        Text(s).font(.serif(16)).lineSpacing(3).foregroundStyle(Color.text)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// 白话对照（S16）：Vernacular 表仅简繁中文；开关关闭或缺键时不显示
struct Vernacular: View {
    let text: String?
    var size: CGFloat = 14
    @AppStorage("vernacular") private var on = true

    init(_ key: String, size: CGFloat = 14) { text = Self.lookup(key); self.size = size }
    init(text: String) { self.text = text }

    var body: some View {
        if on, let text {
            Text(text).font(.scaled(size)).lineSpacing(2).foregroundStyle(Color.subdued)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 缺键时 L 返回键名
    static func lookup(_ key: String) -> String? {
        let t = L(key, table: "Vernacular")
        return t == key ? nil : t
    }
}

/// 白话对照开关，卦辞/爻辞/传页签顶部各一；日韩为「原文」对照开关，其他语言不显示
struct VernacularToggle: View {
    @AppStorage("vernacular") private var on = true
    @AppStorage("original") private var original = true

    var body: some View {
        if Localizer.shared.isChinese {
            ChipButton(label: L("白话对照"), selected: on) { on.toggle() }
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else if Translation.hasOriginal {
            ChipButton(label: L("原文"), selected: original) { original.toggle() }
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

/// 经文译文（非中文界面）：Translation 表。en 为理雅各全本（含彖、大小象、文言），其余为卦辞、爻辞、大象、用九用六
enum Translation {
    /// 缺表或缺键时 L 返回键名
    static func lookup(_ key: String) -> String? {
        let t = L(key, table: "Translation")
        return t == key ? nil : t
    }
    static var available: Bool { !Localizer.shared.isChinese && lookup("hex.1.ci") != nil }
    /// 日韩可对照汉文原文（繁体）
    static var hasOriginal: Bool { [.ja, .ko].contains(Localizer.shared.lang) }
}

/// 经文：中文界面为原文；有译文时为译文（\n 分段），日韩开「原文」时原文在上
struct Scripture: View {
    let key: String, original: String
    var size: CGFloat = 16
    var color = Color.text
    @AppStorage("original") private var on = true

    init(_ key: String, _ original: String, size: CGFloat = 16, color: Color = .text) {
        self.key = key; self.original = original; self.size = size; self.color = color
    }

    var body: some View {
        let t = Localizer.shared.isChinese ? nil : Translation.lookup(key)
        if t == nil || (on && Translation.hasOriginal) {
            Text(original).font(.serif(size)).lineSpacing(size >= 18 ? 3 : 2).foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let t {
            ForEach(Array(t.components(separatedBy: "\n").enumerated()), id: \.offset) { _, p in
                Text(p).font(.scaled(size, design: .serif)).lineSpacing(3).foregroundStyle(color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// 非中文卦辞页签下的大象（象曰）
struct TranslationImage: View {
    let n: Int

    var body: some View {
        let k = "hex.\(n).daxiang"
        if Translation.lookup(k) != nil {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("象曰")).font(.scaled(12, .bold)).foregroundStyle(Color.accentText)
                Scripture(k, Zhouyi.classical(k, default: "", table: "Commentary"))
            }
        }
    }
}

/// 译文出处，非中文卦辞/爻辞/传底部
struct TranslationCredit: View {
    var body: some View {
        if Translation.available {
            Text(Localizer.shared.lang == .en ? L("译文：理雅各（1882）") : L("译文：周易编辑部"))
                .font(.scaled(12)).foregroundStyle(Color.subdued)
        }
    }
}

#Preview { NavigationStack { KnowledgeView() }.environment(AppState()) }
