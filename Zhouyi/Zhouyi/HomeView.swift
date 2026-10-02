import SwiftUI
import SwiftData

/// 01 卜一卦
struct HomeView: View {
    @Environment(AppState.self) private var app
    @Query(sort: \Record.ts, order: .reverse) private var records: [Record]
    @State private var method: CastMethod = .time
    @AppStorage("shakeMethod") private var shakeMethod: CastMethod = .coin   // 摇卦卡内：铜钱 / 蓍草
    @State private var nums = ["", "", ""]
    @AppStorage("solarTime") private var solarTime = false
    @AppStorage("longitude") private var longitude = 116.40

    private var numberCast: TriCast? {
        // wholeNumberValue 兼认阿拉伯-印度数字（١٢）
        let n = nums.compactMap { s -> Int? in
            let d = s.compactMap(\.wholeNumberValue)
            return d.isEmpty ? nil : Int(d.map(String.init).joined())
        }
        return n.count == 3 ? Zhouyi.numberCast(n) : nil
    }

    var body: some View {
        @Bindable var app = app
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                VStack(alignment: .leading, spacing: 14) {
                    SpectrumField(label: L("所问之事"), placeholder: L("例如：这次换工作是否合适？"), text: $app.q)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("类别"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.subdued)
                        FlowLayout(spacing: 8) {
                            ForEach(Record.categories, id: \.self) { c in
                                ChipButton(label: L(c), selected: app.cat == c) { app.cat = c }
                            }
                        }
                    }
                }
                .card(shadow: true)

                methodSection

                PillButton(title: method == .coin ? L("开始摇卦") : method == .yarrow ? L("开始揲蓍") : L("起卦"),
                           disabled: method == .number && numberCast == nil, action: start)

                if let r = records.first {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L("最近一卦")).font(.system(size: 16, weight: .heavy))
                        Button { app.open(r) } label: {
                            HStack(spacing: 14) {
                                HexGlyph(bits: r.analysis.bits, lines: r.lines)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Color.text)
                                    Text(r.question)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color.subdued)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.forward")
                                    .accessibilityHidden(true)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.gray600)
                            }
                            .padding(14)
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
        .scrollDismissesKeyboard(.interactively)
        .softTopEdge()
        .paperBackground()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(Self.dateText(.now))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.subdued)
                Spacer()
                SettingsButton()
            }
            HomeBanner()
            pageTitle(L("卜一卦"))
            Text(L("静心凝神，一事一占。心中默念所问之事，再开始起卦。"))
                .font(.system(size: 15))
                .foregroundStyle(Color.subdued)
                .lineSpacing(4)
        }
    }

    /// “9月28日 星期一”，按所选语言
    static func dateText(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Localizer.shared.locale
        f.calendar = Calendar(identifier: .gregorian)
        f.setLocalizedDateFormatFromTemplate("MMMd EEEE")
        return f.string(from: d)
    }

    // MARK: - 起卦方式

    private var methodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("起卦方式")).font(.system(size: 16, weight: .heavy))
            HStack(spacing: 8) {
                methodCard(shakeMethod, L("摇卦"), shakeMethod == .yarrow ? L("四营成易，\n十有八变") : L("三钱六掷，\n逐爻成卦"))
                methodCard(.number, L("数字"), L("三个数\n定卦与动爻"))
                methodCard(.time, L("时间"), L("以此刻\n年月日时起卦"))
            }
            .fixedSize(horizontal: false, vertical: true)
            Group {
                switch method {
                case .coin, .yarrow:
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            ForEach([(CastMethod.coin, L("铜钱")), (.yarrow, L("蓍草"))], id: \.0) { m, l in
                                ChipButton(label: l, selected: method == m) { withAnimation(.spectrum) { method = m; shakeMethod = m } }
                            }
                        }
                        Group {
                            if method == .coin {
                                Text(L("三枚铜钱掷六次，自下而上成卦。背为三、字为二：三钱之和为六是老阴、七是少阳、八是少阴、九是老阳，六与九为动爻。"))
                            } else {
                                Text(L("大衍之数五十，其用四十九：分二、挂一、揲四、归奇，四营成易，三变成一爻，十有八变而成卦。"))
                                    + Text(verbatim: "\n") + Text(L("老阳 : 老阴 = 3 : 1，铜钱为 1 : 1。"))
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(Color.subdued)
                        .lineSpacing(4)
                    }
                case .number: numberPanel
                case .time: timePanel
                }
            }
            .padding(.top, 4)
        }
    }

    private func methodCard(_ m: CastMethod, _ title: String, _ sub: String) -> some View {
        let selected = method == m
        return Button { withAnimation(.spectrum) { method = m } } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(selected ? Color.accentText : Color.text)
                    .minimumScaleFactor(0.8)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.subdued)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.85)   // 长词（德语等）略缩，不截断
                    .fixedSize(horizontal: false, vertical: true)   // 折行全显，卡高随最高者
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.base, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(selected ? Color.accentVisual : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var numberPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {   // 标签折行高度不一时输入框仍对齐
                ForEach(0..<3, id: \.self) { i in
                    SpectrumField(label: [L("上卦数"), L("下卦数"), L("动爻数")][i], placeholder: L("任意"), text: $nums[i], keyboard: .numberPad)
                }
            }
            Text(L("凭直觉写下三个正整数。上、下卦取除以八的余数，动爻取除以六的余数。"))
                .font(.system(size: 12))
                .foregroundStyle(Color.subdued)
                .lineSpacing(2)
            if let c = numberCast {
                HStack(spacing: 4) { Image(systemName: "arrow.forward").accessibilityHidden(true); Text(Zhouyi.triText(c)) }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.accentText)
            }
        }
    }

    private var timePanel: some View {
        TimelineView(.everyMinute) { context in
            let solar = SettingsView.solar(context.date, on: solarTime, longitude: longitude)
            let tv = Zhouyi.timeCast(solar.date)
            let T = Zhouyi.trigrams, B = Zhouyi.branches
            let y = tv.yearBranch, h = tv.hourBranch, c = tv.cast
            VStack(alignment: .leading, spacing: 8) {
                row(L("农历"), Text(tv.lunarText + " · " + L("%@时", L(B[h - 1]))))
                row(L("年支 · 月 · 日 · 时支"), Text(verbatim: "\(L(B[y - 1]))(\(y)) · \(tv.month) · \(tv.day) · \(L(B[h - 1]))(\(h))"))
                row(L("上卦：年+月+日 = %d", tv.s1), tri(tv.s1, T[c.up - 1]))
                row(L("下卦：再加时 = %d", tv.s2), tri(tv.s2, T[c.lo - 1]))
                row(L("动爻：%d ÷ 6", tv.s2), Text(L("余 %1$d → %2$@爻", tv.s2 % 6, L(Zhouyi.positions[c.mv - 1]))))
                Text(L("年支按农历年（春节换年）· 闰月按本月数 · 23 点起为次日子时 · 按本机时区"))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.subdued)
                if let note = solar.note {
                    Text(note).font(.system(size: 11)).foregroundStyle(Color.subdued)
                }
                // 只取时辰：两小时内结果不变，属传统本意
                let from = (2 * h + 21) % 24
                Text(L("同一时辰内（%@）起卦结果相同，一事不二占。", String(format: "%02d:00–%02d:00", from, (from + 2) % 24)))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.subdued)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.base, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    /// “÷8 余 1 → 兑 ☱”：卦名与卦符以不换行空格相连，折行时不拆开
    private func tri(_ s: Int, _ t: Trigram) -> Text {
        Text(L("÷8 余 %1$d → %2$@", s % 8, t.label).trimmingCharacters(in: .whitespaces) + "\u{00A0}")
            + Text(t.sym).font(.system(size: 17))
    }

    private func row(_ k: String, _ v: Text) -> some View {
        HStack {
            // “= 37” 前后换不换行空格，折行时与前词同行，不落单
            Text(k.replacingOccurrences(of: " = ", with: "\u{00A0}=\u{00A0}"))
                .font(.system(size: 13)).foregroundStyle(Color.subdued)
            Spacer(minLength: 12)
            v.font(.system(size: 13, weight: .bold)).multilineTextAlignment(.trailing)
                .layoutPriority(1)   // 值列优先取宽，长标签折行，免值列参差折行
        }
        .frame(minHeight: 21)   // 卦符 17pt 撑高其行，各行取同高
    }

    // MARK: - 动作

    private func start() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let cast: TriCast
        switch method {
        case .coin, .yarrow:
            app.homePath.append(.cast(method))
            return
        case .number:
            guard let c = numberCast else { return }
            cast = c
        case .time:
            cast = Zhouyi.timeCast(SettingsView.solar(Date(), on: solarTime, longitude: longitude).date).cast
        }
        let r = Record(q: app.q, cat: app.cat, method: method, lines: Zhouyi.lines(from: cast))
        withAnimation(.easeOut(duration: 0.2)) { app.forming = r }   // 过场结束后入库并打开
    }
}

/// 数字、时间起卦的成卦过场：六爻自下而上逐一落定，再现卦名，稍停后入库并打开解卦
struct FormingOverlay: View {
    let record: Record
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0
    @State private var done = false

    var body: some View {
        let lines = record.lines
        VStack(spacing: 22) {
            Text(record.question)
                .font(.system(size: 14))
                .foregroundStyle(Color.subdued)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                ForEach((0..<6).reversed(), id: \.self) { i in
                    ZStack {
                        if i < shown {
                            WrittenYao(yang: lines[i] % 2 == 1, color: Zhouyi.isMoving(lines[i]) ? .accentVisual : .line, seed: i, duration: 0.3)
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.gray300, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        }
                    }
                    .frame(width: 180, height: 14)
                }
            }
            .background { InkBloom(on: done) }
            HStack(spacing: 8) {   // 印在卦名后，左侧等宽留白保持居中
                Color.clear.frame(width: 30, height: 1)
                Text(record.title)
                    .font(Localizer.shared.isChinese ? .serif(20, semibold: true) : .system(size: 20, weight: .heavy))
                    .foregroundStyle(Color.text)
                    .multilineTextAlignment(.center)
                    .opacity(done ? 1 : 0)
                    .scaleEffect(done ? 1 : 0.85)
                Color.clear.frame(width: 30, height: 1).overlay { SealStamp(on: done) }
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
        .accessibilityElement(children: .combine)
        .sensoryFeedback(trigger: shown) { _, n in
            n > 0 && Zhouyi.isMoving(lines[n - 1]) ? .impact(weight: .medium) : .impact(weight: .light)
        }
        .sensoryFeedback(.success, trigger: done)
        .task {
            let step = reduceMotion ? 60 : 280
            try? await Task.sleep(for: .milliseconds(250))
            for _ in 0..<6 {
                withAnimation(.spring(duration: 0.25)) { shown += 1 }
                try? await Task.sleep(for: .milliseconds(step))
            }
            withAnimation(.spring(duration: 0.4)) { done = true }
            try? await Task.sleep(for: .milliseconds(750))
            modelContext.insert(record)
            try? modelContext.save()
            app.open(record)
            withAnimation(.easeOut(duration: 0.25)) { app.forming = nil }
        }
    }
}

/// 首页题图池：浅色、深色各一池，缺图剔除；每次启动各池抽一张（避开上次所抽），运行中不变
private enum HeaderArt {
    static let day = pick(["home-header", "header-spring", "header-summer", "header-autumn", "header-winter"], "headerDay")
    static let night = pick(["header-night-moon", "header-night-stars", "header-night-temple"], "headerNight") ?? day

    private static func pick(_ names: [String], _ key: String) -> String? {
        let ok = names.filter { UIImage(named: $0) != nil }
        let n = ok.filter { $0 != UserDefaults.standard.string(forKey: key) }.randomElement() ?? ok.first
        if let n { UserDefaults.standard.set(n, forKey: key) }
        return n
    }
}

/// 首页题图：有图才显示。3:2 圆角，底边渐隐入纸（深色即夜墨纸）；两层云雾反向缓移，首尾相接循环
private struct HomeBanner: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var drift = false

    var body: some View {
        if let name = scheme == .dark ? HeaderArt.night : HeaderArt.day {
            Color.clear
                .aspectRatio(3 / 2, contentMode: .fit)
                .overlay { Image(decorative: name).resizable().scaledToFill() }
                .overlay {
                    GeometryReader { g in
                        let w = g.size.width
                        ZStack(alignment: .leading) {
                            mist("mist-1", w).offset(x: drift ? -w : 0)
                            mist("mist-2", w).offset(x: drift ? 0 : -w)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .mask(LinearGradient(stops: [.init(color: .black, location: 0.72), .init(color: .clear, location: 1)],
                                     startPoint: .top, endPoint: .bottom))
                .environment(\.layoutDirection, .leftToRight)   // 云雾偏移按绝对方向算
                .padding(.vertical, 6)
                .onAppear {
                    guard !reduceMotion else { return }
                    // 回到首页会再次 onAppear：先无动画归零再起，免得叠加跳动
                    var t = Transaction()
                    t.disablesAnimations = true
                    withTransaction(t) { drift = false }
                    DispatchQueue.main.async {
                        withAnimation(.linear(duration: 80).repeatForever(autoreverses: false)) { drift = true }
                    }
                }
        }
    }

    /// 同一张雾图并排两份，平移一整幅即回到原样
    private func mist(_ name: String, _ w: CGFloat) -> some View {
        HStack(spacing: 0) {
            Image(decorative: name).resizable()
            Image(decorative: name).resizable()
        }
        .frame(width: w * 2)
    }
}

/// 自动换行排布（类别标签）
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? .infinity, subviews)
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0,
                      height: rows.last.map { $0.y + $0.height } ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(bounds.width, subviews) {
            var x = bounds.minX
            for i in row.items {
                let s = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: bounds.minY + row.y), proposal: ProposedViewSize(s))
                x += s.width + spacing
            }
        }
    }

    private func arrange(_ maxWidth: CGFloat, _ subviews: Subviews) -> [(items: [Int], y: CGFloat, width: CGFloat, height: CGFloat)] {
        var rows: [(items: [Int], y: CGFloat, width: CGFloat, height: CGFloat)] = []
        var cur: [Int] = [], x: CGFloat = 0, y: CGFloat = 0, h: CGFloat = 0
        for i in subviews.indices {
            let s = subviews[i].sizeThatFits(.unspecified)
            if !cur.isEmpty, x + spacing + s.width > maxWidth {
                rows.append((cur, y, x, h))
                y += h + spacing; cur = []; x = 0; h = 0
            }
            x += (cur.isEmpty ? 0 : spacing) + s.width
            h = max(h, s.height)
            cur.append(i)
        }
        if !cur.isEmpty { rows.append((cur, y, x, h)) }
        return rows
    }
}

#Preview("浅色") {
    HomePreview()
}

#Preview("深色") {
    HomePreview().preferredColorScheme(.dark)
}

private struct HomePreview: View {
    let container: ModelContainer = {
        let c = try! ModelContainer(for: Record.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        c.mainContext.insert(Record(q: "这次换工作是否合适？", cat: "事业", method: .coin, lines: [7, 8, 9, 7, 6, 8]))
        return c
    }()

    var body: some View {
        NavigationStack { HomeView() }
            .modelContainer(container)
            .environment(AppState())
    }
}
