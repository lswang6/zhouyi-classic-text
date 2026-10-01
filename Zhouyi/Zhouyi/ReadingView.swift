import SwiftUI
import SwiftData

/// 03 解卦
struct ReadingView: View {
    let record: Record
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext
    @State private var tab = "bh"
    @State private var confirmDelete = false
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
                    Text(L("所问")).font(.system(size: 12, weight: .medium)).foregroundStyle(Color.subdued)
                    Text(record.question).font(.system(size: 22, weight: .heavy)).foregroundStyle(Color.text)
                    Text(record.meta).font(.system(size: 13)).foregroundStyle(Color.subdued)
                }

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
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .card(padding: 0, shadow: true)

                if a.bian == nil {
                    Text(L("六爻安静，无变卦"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subdued)
                        .frame(maxWidth: .infinity)
                        .padding(.top, -6)
                }

                // 非中文只有白话解卦
                if zh {
                    focusCard(f)
                    tabBar
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
                ShareLink(item: shareText(a, f, zh: zh), subject: Text(record.title)) {
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

    private func column(_ label: String, _ h: Hexagram, lines: [Int]?) -> some View {
        return VStack(spacing: 12) {
            Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(Color.subdued)
            HexGlyph(bits: h.bits, lines: lines, width: 88, lineHeight: 10, gap: 8, split: 12, radius: 2, showMarks: true)
            VStack(spacing: 2) {
                name(h.full).foregroundStyle(Color.text)
                Text(L("第%1$d卦 · 上%2$@下%3$@", h.n, h.up.label, h.lo.label))
                    .font(.system(size: 12)).foregroundStyle(Color.subdued)
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
        .font(.system(size: size, weight: .heavy))
    }

    private func focusCard(_ f: Focus) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("断卦要点")).font(.system(size: 16, weight: .heavy)).foregroundStyle(Color.text)
            Text(f.rule).font(.system(size: 13)).foregroundStyle(Color.subdued)
            ForEach(f.items, id: \.self) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.tag)
                            .font(.system(size: 12, weight: .bold))
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
    private var tabBar: some View {
        HStack(spacing: 24) {
            ForEach([("bh", L("白话解读")), ("ci", L("卦辞")), ("yao", L("爻辞"))], id: \.0) { key, label in
                let on = tab == key
                Button { withAnimation(.spectrum) { tab = key } } label: {
                    Text(label)
                        .font(.system(size: 15, weight: on ? .semibold : .regular))
                        .foregroundStyle(on ? Color.text : Color.subdued)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: key, in: tabNS)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 44)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.divider).frame(height: 1) }
        .overlay {
            Capsule().fill(Color.text).frame(height: 2)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .matchedGeometryEffect(id: tab, in: tabNS, isSource: false)
                .accessibilityHidden(true)
        }
    }

    private func pair(_ a: Analysis) -> [(String, Hexagram)] {
        [(L("本卦") + " · " + a.ben.full, a.ben)] + (a.bian.map { [(L("变卦") + " · " + $0.full, $0)] } ?? [])
    }

    private func tag(_ s: String) -> some View {
        Text(s).font(.system(size: 13, weight: .bold)).foregroundStyle(Color.subdued)
    }

    /// 白话解读 + 配图 + 提示（中文为第一个标签页，其他语言直接显示）
    private func plain(_ a: Analysis) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(pair(a), id: \.0) { t, h in
                VStack(alignment: .leading, spacing: 6) {
                    tag(t)
                    Text(h.bh).font(.system(size: 15)).lineSpacing(3).foregroundStyle(Color.text)
                }
            }
            GuaImage(n: a.ben.n)
            Text(L("本卦看当下之势，变卦看发展之向。解读仅供参考，重要决定请结合实际。"))
                .font(.system(size: 12)).foregroundStyle(Color.subdued)
        }
    }

    @ViewBuilder
    private func tabContent(_ a: Analysis) -> some View {
        switch tab {
        case "yao":
            VStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { i in
                    let moving = Zhouyi.isMoving(a.lines[i])
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(Zhouyi.lineName(i, yang: a.bits[i] == 1))
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(moving ? Color.accentText : Color.line)
                            .frame(width: 44, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(a.ben.yao[i]).font(.serif(16)).lineSpacing(2).foregroundStyle(Color.text)
                            if moving { Badge(text: a.lines[i] == 9 ? L("动爻 · 老阳") : L("动爻 · 老阴"), subtle: true) }
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
        default:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(pair(a), id: \.0) { t, h in
                    VStack(alignment: .leading, spacing: 6) {
                        tag(t)
                        Text(h.name + "：" + h.ci).font(.serif(18)).lineSpacing(3).foregroundStyle(Color.text)
                    }
                }
            }
        }
    }

    // MARK: 应验反馈

    private var feedback: some View {
        @Bindable var r = record
        return VStack(alignment: .leading, spacing: 12) {
            Text(L("应验反馈")).font(.system(size: 16, weight: .heavy)).foregroundStyle(Color.text)
            HStack(spacing: 8) {
                ForEach(Record.verifyOptions, id: \.self) { v in
                    ChipButton(label: L(v), selected: record.verify == v) { record.verify = v; try? modelContext.save() }
                }
            }
            SpectrumField(label: L("备注"), placeholder: L("记下后来的结果，便于日后印证"), text: $r.note)
                .onChange(of: record.note) { try? modelContext.save() }
            Button { confirmDelete = true } label: {
                Label(L("删除此记录"), systemImage: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.text)
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
            Image(name).resizable().scaledToFit().nightDim()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(5)
                .background(Color(0xF3EDE1, 0xF3EDE1), in: RoundedRectangle(cornerRadius: 16))   // 浅色 layer1
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
