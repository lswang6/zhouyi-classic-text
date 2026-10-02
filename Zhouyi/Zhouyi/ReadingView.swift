import SwiftUI
import SwiftData

/// 03 解卦
struct ReadingView: View {
    let record: Record
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext
    @State private var tab = "bh"
    @State private var confirmDelete = false
    @State private var shareImage: Image?
    @Namespace private var tabNS

    var body: some View {
        if record.isDeleted || record.modelContext == nil {
            EmptyView()
        } else {
            content
        }
    }

    private var content: some View {
        let a = record.analysis
        let f = Zhouyi.focus(a)
        let zh = Localizer.shared.isChinese
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("所问")).font(.scaled(12, .medium)).foregroundStyle(Color.subdued)
                    Text(record.question).font(.scaled(22, .heavy)).foregroundStyle(Color.text)
                    Text(record.meta).font(.scaled(13)).foregroundStyle(Color.subdued)
                }

                VStack(spacing: 16) {
                    guaPair(a)
                    HexRelations(h: a.ben)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .card(padding: 0, shadow: true)

                if a.bian == nil {
                    Text(L("六爻安静，无变卦"))
                        .font(.scaled(12))
                        .foregroundStyle(Color.subdued)
                        .frame(maxWidth: .infinity)
                        .padding(.top, -6)
                }

                // 非中文只有白话解卦
                if let ty = Zhouyi.tiYong(a), [CastMethod.number.rawValue, CastMethod.time.rawValue].contains(record.method) {
                    tiYongCard(ty, upper: a.moving[0] >= 3)
                }

                if zh {
                    focusCard(f)
                    tabBar
                    if ["ci", "yao", "zhuan"].contains(tab) { VernacularToggle() }
                    tabContent(a)
                } else {
                    plain(a)
                }
                Rectangle().fill(Color.divider).frame(height: 1)
                feedback
            }
            .padding(.top, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .softTopEdge()
        .paperBackground()
        .scrollDismissesKeyboard(.interactively)
        .task {
            let r = ImageRenderer(content: shareCard(a, f, zh: zh))
            r.scale = 3
            shareImage = r.uiImage.map(Image.init(uiImage:))
        }
        .navigationTitle(L("解卦"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)   // 返回键不带文字：系统界面跟系统语言，不跟应用内选择
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    record.fav.toggle()
                    try? modelContext.save()
                    app.toast.show(record.fav ? L("已收藏") : L("已取消收藏"))
                } label: {
                    Image(systemName: record.fav ? "star.fill" : "star")
                        .foregroundStyle(record.fav ? Color.accentText : Color.text)
                }
                .accessibilityLabel(L("收藏"))
                .accessibilityAddTraits(record.fav ? .isSelected : [])
                Menu {
                    ShareLink(item: shareText(a, f, zh: zh), subject: Text(record.title)) {
                        Label(L("分享文字"), systemImage: "text.alignleft")
                    }
                    if let img = shareImage {
                        ShareLink(item: img, preview: SharePreview(record.title, image: img)) {
                            Label(L("分享图片"), systemImage: "photo")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up").foregroundStyle(Color.text)
                }
                .tint(Color.text)   // 与星标同为墨色
                .accessibilityLabel(L("分享"))
            }
        }
    }

    private func shareText(_ a: Analysis, _ f: Focus, zh: Bool) -> String {
        let head = L("所问：%@", record.question) + "\n\(record.title)\n\(record.meta)\n\n"
        guard zh else { return head + pair(a).map { "\($0.0)\n\($0.1.bh)" }.joined(separator: "\n\n") }
        return head + L("断卦要点：%@", f.rule) + "\n"
            + f.items.map { "【\($0.tag)】\($0.text)" }.joined(separator: "\n")
    }

    /// 本卦 → 变卦
    private func guaPair(_ a: Analysis) -> some View {
        HStack(alignment: .top, spacing: 12) {
            column(L("本卦"), a.ben, lines: record.lines)
            if let bian = a.bian {
                Image(systemName: "arrow.forward")
                    .accessibilityHidden(true)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.gray500)
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 40)
                column(L("变卦"), bian, lines: nil)
            }
        }
    }

    /// 分享图：所问、卦象、断卦要点主条（非中文为本卦白话）、应用名。固定浅色
    private func shareCard(_ a: Analysis, _ f: Focus, zh: Bool) -> some View {
        let main = f.items.first { $0.main }
        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L("所问")).font(.scaled(12, .medium)).foregroundStyle(Color.subdued)
                Text(record.question).font(.scaled(20, .heavy)).foregroundStyle(Color.text)
            }
            guaPair(a).padding(.vertical, 16).card(padding: 0)
            if zh, let main {
                VStack(alignment: .leading, spacing: 6) {
                    Text(f.rule).font(.scaled(13)).foregroundStyle(Color.subdued)
                    Text(main.tag).font(.scaled(12, .bold)).foregroundStyle(Color.accentText)
                    Text(main.text).font(.serif(18, semibold: true)).lineSpacing(2).foregroundStyle(Color.text)
                }
            } else {
                Text(a.ben.bh).font(.scaled(15)).lineSpacing(3).foregroundStyle(Color.text)
            }
            Text(L("CFBundleDisplayName", table: "InfoPlist"))
                .font(.scaled(12, .medium)).foregroundStyle(Color.subdued)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(24)
        .frame(width: 390)
        .background(Color.layer1)
        .environment(\.colorScheme, .light)
        .environment(\.dynamicTypeSize, .large)   // ImageRenderer 不继承环境，分享图固定标准字号
    }

    /// 梅花体用：体用五行关系，始（本卦用）→ 中（互卦）→ 终（变卦用）
    private func tiYongCard(_ ty: TiYong, upper: Bool) -> some View {
        let note = switch ty.relation {
        case .biHe: L("体用同气")
        case .yongShengTi: L("外缘助我")
        case .tiShengYong: L("我耗于外")
        case .yongKeTi: L("外势制我")
        case .tiKeYong: L("我能制事")
        }
        let hu = upper ? ty.hu.up : ty.hu.lo
        return VStack(alignment: .leading, spacing: 8) {
            Text(L("体用")).font(.scaled(16, .heavy)).foregroundStyle(Color.text)
            Text(L("体卦 %1$@（%2$@）· 用卦 %3$@（%4$@）", ty.ti.label, L(ty.ti.wx), ty.yong.label, L(ty.yong.wx)))
                .font(.scaled(14)).foregroundStyle(Color.text)
            HStack(spacing: 8) {
                Badge(text: L(ty.relation.rawValue), variant: .neutral)
                Text(note).font(.scaled(14)).foregroundStyle(Color.subdued)
            }
            Text(L("始 %1$@（%2$@）→ 中 %3$@（%4$@）→ 终 %5$@（%6$@）", ty.yong.label, L(ty.yong.wx), hu.label, L(hu.wx), ty.bianYong.label, L(ty.bianYong.wx)))
                .font(.scaled(13)).foregroundStyle(Color.subdued)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
    }

    private func column(_ label: String, _ h: Hexagram, lines: [Int]?) -> some View {
        return VStack(spacing: 12) {
            Text(label).font(.scaled(12, .bold)).foregroundStyle(Color.subdued)
            HexGlyph(bits: h.bits, lines: lines, width: 88, lineHeight: 10, gap: 8, split: 12, radius: 2, showMarks: true)
            VStack(spacing: 2) {
                name(h.full).foregroundStyle(Color.text)
                Text(L("第%1$d卦 · 上%2$@下%3$@", h.n, h.up.label, h.lo.label))
                    .font(.scaled(12)).foregroundStyle(Color.subdued)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// 卦名：中文用宋体（子集含全部卦名用字）；其他语言单词不拆开，取最长单词放得下的最大字号
    @ViewBuilder
    private func name(_ s: String) -> some View {
        if Localizer.shared.isChinese {
            Text(s).font(.serif(20, semibold: true)).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            let words = s.split(whereSeparator: \.isWhitespace).map(String.init)
            ViewThatFits(in: .horizontal) {
                fitted(s, words, 20)
                fitted(s, words, 17)
                fitted(s, words, 15)
                fitted(s, words, 13)
            }
        }
    }

    /// 理想宽度 = 最长单词宽；整句理想宽为 0，只按可用宽换行
    private func fitted(_ s: String, _ words: [String], _ size: CGFloat) -> some View {
        ZStack {
            ForEach(words.indices, id: \.self) { Text(words[$0]).fixedSize().hidden() }
            Text(s).multilineTextAlignment(.center).minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity)
        }
        .font(.scaled(size, .heavy))
    }

    private func focusCard(_ f: Focus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("断卦要点")).font(.scaled(16, .heavy)).foregroundStyle(Color.text)
            Text(f.rule).font(.scaled(13)).foregroundStyle(Color.subdued)
            ForEach(f.items, id: \.self) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.tag)
                            .font(.scaled(12, .bold))
                            .foregroundStyle(item.main ? Color.accentText : Color.subdued)
                        if item.main { Badge(text: L("主")) }
                    }
                    Text(item.text)
                        .font(.serif(18, semibold: true))
                        .lineSpacing(2)
                        .foregroundStyle(Color.text)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(item.main ? Color.blue200 : Color.gray75, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .card()
    }

    // MARK: 卦辞 / 爻辞 / 白话解读

    /// 指示条不挂在任何标签内（否则该标签的点按/无障碍区域被撑高），而是跟随所选标签的 frame
    /// 大字号放不下五个标签时横向滚动
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach([("bh", L("白话解读")), ("ci", L("卦辞")), ("yao", L("爻辞")), ("zhuan", L("传")), ("najia", L("纳甲"))], id: \.0) { key, label in
                    let on = tab == key
                    Button { withAnimation(.spectrum) { tab = key } } label: {
                        Text(label)
                            .font(.scaled(15, on ? .semibold : .regular))
                            .foregroundStyle(on ? Color.text : Color.subdued)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: key, in: tabNS)
                }
            }
            .overlay {
                Capsule().fill(Color.text).frame(height: 2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .matchedGeometryEffect(id: tab, in: tabNS, isSource: false)
                    .accessibilityHidden(true)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) { Rectangle().fill(Color.divider).frame(height: 1) }
    }

    private func pair(_ a: Analysis) -> [(String, Hexagram)] {
        [(L("本卦") + " · " + a.ben.full, a.ben)] + (a.bian.map { [(L("变卦") + " · " + $0.full, $0)] } ?? [])
    }

    private func tag(_ s: String) -> some View {
        Text(s).font(.scaled(13, .bold)).foregroundStyle(Color.subdued)
    }

    /// 白话解读 + 配图 + 提示（中文为第一个标签页，其他语言直接显示）
    private func plain(_ a: Analysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(pair(a), id: \.0) { t, h in
                VStack(alignment: .leading, spacing: 6) {
                    tag(t)
                    Text(h.bh).font(.scaled(15)).lineSpacing(3).foregroundStyle(Color.text)
                }
            }
            GuaImage(n: a.ben.n)
            Text(L("本卦看当下之势，变卦看发展之向。解读仅供参考，重要决定请结合实际。"))
                .font(.scaled(12)).foregroundStyle(Color.subdued)
        }
    }

    @ViewBuilder
    private func tabContent(_ a: Analysis) -> some View {
        switch tab {
        case "yao":
            let yong = HexagramView.yong(a.ben.n)
            VStack(spacing: 4) {
                ForEach(0..<(yong == nil ? 6 : 7), id: \.self) { i in
                    // 第七行用九/用六：六爻皆动时高亮
                    let moving = i < 6 ? Zhouyi.isMoving(a.lines[i]) : a.moving.count == 6
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(i < 6 ? Zhouyi.lineName(i, yang: a.bits[i] == 1) : yong!.label)
                            .font(.scaled(14, .heavy))
                            .foregroundStyle(moving ? Color.accentText : Color.line)
                            .frame(minWidth: 44, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(i < 6 ? a.ben.yao[i] : yong!.text).font(.serif(16)).lineSpacing(2).foregroundStyle(Color.text)
                            Vernacular(i < 6 ? "hex.\(a.ben.n).yao.\(i)" : "hex.\(a.ben.n).yong")
                            let k = "hex.\(a.ben.n).xiao.\(i)", xiao = L(k, table: "Commentary")
                            if xiao != k { Text(xiao).font(.serif(14)).lineSpacing(2).foregroundStyle(Color.subdued) }
                            Vernacular(k, size: 13)
                            if moving && i < 6 { Badge(text: a.lines[i] == 9 ? L("动爻 · 老阳") : L("动爻 · 老阴"), subtle: true) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(moving ? Color.blue200 : .clear, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        case "bh":
            plain(a)
        case "najia":
            najia(a)
        case "zhuan":
            VStack(alignment: .leading, spacing: 16) {
                ForEach(pair(a), id: \.0) { t, h in
                    VStack(alignment: .leading, spacing: 6) {
                        tag(t)
                        ZhuanView(n: h.n)
                    }
                }
            }
        default:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(pair(a), id: \.0) { t, h in
                    VStack(alignment: .leading, spacing: 6) {
                        tag(t)
                        Text(h.name + "：" + h.ci).font(.serif(18)).lineSpacing(3).foregroundStyle(Color.text)
                        Vernacular("hex.\(h.n).ci")
                    }
                }
            }
        }
    }

    // MARK: 纳甲

    /// 六爻纳甲排盘，上爻在上。时刻取起卦钟点，起卦时开了真太阳时则按当时经度校正
    private func najia(_ a: Analysis) -> some View {
        let solar = SettingsView.solar(record.ts, on: record.solarLongitude != nil, longitude: record.solarLongitude ?? 0)
        let pan = NaJia.pan(a, at: solar.date, timeZone: .current)
        let hasFu = pan.rows.contains { $0.fu != nil }
        let yao = { (y: NaJiaPan.Yao) in L(y.liuqin.rawValue) + y.ganzhi + L(y.wuxing) }
        let small = { (s: String) in Text(s).font(.serif(13)).foregroundStyle(Color.subdued) }
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("%1$@宫 · %2$@", pan.palace.name, L(pan.kind.rawValue)))
                    .font(.serif(18, semibold: true)).foregroundStyle(Color.text)
                Text(L("%1$@年 %2$@月 %3$@日 %4$@时 · 旬空 %5$@", pan.year, pan.month, pan.day, pan.hour, pan.xunKong.map { L($0) }.joined()))
                    .font(.serif(14)).foregroundStyle(Color.subdued)
            }
            ViewThatFits(in: .horizontal) {   // 表放不下（大字号、有伏神列）则逐爻分行，不横滑、不缩字
                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 10) {
                    GridRow {
                        small(L("六神"))
                        if hasFu { small(L("伏神")) }
                        small(L("本卦"))
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                        Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                        if a.bian != nil { small(L("变卦")) }
                    }
                    ForEach((0..<6).reversed(), id: \.self) { i in
                        let r = pan.rows[i], v = a.lines[i]
                        GridRow(alignment: .center) {
                            Text(L(r.liushen.rawValue)).font(.serif(14)).foregroundStyle(Color.subdued)
                            if hasFu { small(r.fu.map(yao) ?? "") }
                            Text(yao(.init(liuqin: r.liuqin, ganzhi: r.ganzhi)))
                                .font(.serif(15, semibold: true))
                                .foregroundStyle(Zhouyi.isMoving(v) ? Color.accentText : Color.text)
                            HStack(spacing: 4) {
                                YaoBar(yang: a.bits[i] == 1, color: Zhouyi.isMoving(v) ? .accentVisual : .line, split: 6, seed: i, halo: false)
                                    .frame(width: 36, height: 6)
                                Text(v == 9 ? "○" : v == 6 ? "×" : "")
                                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.accentText)
                                    .frame(width: 12)
                            }
                            Text(i + 1 == pan.shi ? L("世") : i + 1 == pan.ying ? L("应") : "")
                                .font(.serif(14, semibold: true)).foregroundStyle(Color.accentText)
                            if a.bian != nil { Text(r.bian.map(yao) ?? "").font(.serif(14)).foregroundStyle(Color.text) }
                        }
                    }
                }
                .lineLimit(1)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach((0..<6).reversed(), id: \.self) { i in
                        let r = pan.rows[i], v = a.lines[i]
                        let mark = i + 1 == pan.shi ? L("世") : i + 1 == pan.ying ? L("应") : ""
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(L(r.liushen.rawValue)).font(.serif(14)).foregroundStyle(Color.subdued)
                                YaoBar(yang: a.bits[i] == 1, color: Zhouyi.isMoving(v) ? .accentVisual : .line, split: 6, seed: i, halo: false)
                                    .frame(width: 36, height: 6)
                                Text(v == 9 ? "○" : v == 6 ? "×" : "")
                                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Color.accentText)
                                if !mark.isEmpty { Text(mark).font(.serif(14, semibold: true)).foregroundStyle(Color.accentText) }
                            }
                            Text(yao(.init(liuqin: r.liuqin, ganzhi: r.ganzhi)))
                                .font(.serif(15, semibold: true))
                                .foregroundStyle(Zhouyi.isMoving(v) ? Color.accentText : Color.text)
                            if let fu = r.fu { small(L("伏神") + " " + yao(fu)) }
                            if let b = r.bian { Text(L("变卦") + " " + yao(b)).font(.serif(14)).foregroundStyle(Color.text) }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            Text(([solar.note].compactMap { $0 } + [L("只排盘，不自动断用神旺衰。")]).joined(separator: "\n"))
                .font(.scaled(12)).foregroundStyle(Color.subdued)
        }
        .card()
    }

    // MARK: 应验反馈

    private var feedback: some View {
        @Bindable var r = record
        return VStack(alignment: .leading, spacing: 12) {
            Text(L("应验反馈")).font(.scaled(16, .heavy)).foregroundStyle(Color.text)
            HStack(spacing: 8) {
                ForEach(Record.verifyOptions, id: \.self) { v in
                    ChipButton(label: L(v), selected: record.verify == v) { record.verify = v; try? modelContext.save() }
                }
            }
            SpectrumField(label: L("备注"), placeholder: L("记下后来的结果，便于日后印证"), text: $r.note)
                .onChange(of: record.note) { try? modelContext.save() }
            Button(role: .destructive) { confirmDelete = true } label: {
                Label(L("删除此记录"), systemImage: "trash")
                    .font(.scaled(14, .medium))
                    .foregroundStyle(Color.negativeText)
            }
            .buttonStyle(.plain)
            .confirmationDialog(L("删除此记录？"), isPresented: $confirmDelete, titleVisibility: .visible) {
                Button(L("删除"), role: .destructive) {
                    let r = record
                    app.pop()
                    app.toast.show(L("记录已删除"))
                    // 先返回，转场结束后再删，避免导航栈中的 Record 失效
                    Task {
                        try? await Task.sleep(for: .milliseconds(450))
                        modelContext.delete(r)
                        try? modelContext.save()
                    }
                }
                Button(L("取消"), role: .cancel) {}
            }
        }
    }
}

/// 配图位：本卦 gua-01…gua-64，图未放入时不显示。衬浅色纸框，深色模式下纸色画不悬浮在夜墨上
struct GuaImage: View {
    let n: Int

    var body: some View {
        let name = String(format: "gua-%02d", n)
        if UIImage(named: name) != nil {
            Image(name).resizable().scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(5)
                .background(Color(0xF3EDE1, 0xF3EDE1), in: RoundedRectangle(cornerRadius: 16))   // 浅色 layer1
                .nightDim()   // 画与纸框一并压暗，深色下框不刺眼
        }
    }
}

// MARK: - Preview

private struct ReadingPreview: View {
    let container: ModelContainer
    let record: Record

    init(lines: [Int]) {
        container = try! ModelContainer(for: Record.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        record = Record(q: "这次换工作是否顺利？", cat: "事业", method: .coin, lines: lines)
        container.mainContext.insert(record)
    }

    var body: some View {
        NavigationStack { ReadingView(record: record) }
            .modelContainer(container)
            .environment(AppState())
    }
}

#Preview("Light") { ReadingPreview(lines: [7, 9, 8, 7, 6, 8]) }
#Preview("Dark") { ReadingPreview(lines: [7, 8, 8, 7, 7, 8]).preferredColorScheme(.dark) }
