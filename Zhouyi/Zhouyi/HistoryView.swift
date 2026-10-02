import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 04 卜卦记录
struct HistoryView: View {
    @Environment(AppState.self) private var app
    @Query(sort: \Record.ts, order: .reverse) private var records: [Record]
    @State private var hq = ""
    @State private var hf = "all"

    /// 出现过的本卦，按记录顺序（新→旧）按卦序去重（各语言卦名可能同形，如 Lǚ）
    private var hexes: [Hexagram] {
        var seen = Set<Int>()
        return records.map(\.analysis.ben).filter { seen.insert($0.n).inserted }
    }

    /// 所选卦（卦序）已不存在（删除后）则退回“全部”
    private var filter: String {
        hf == "all" || hf == "fav" || hexes.contains { String($0.n) == hf } ? hf : "all"
    }

    /// 汉字圈用短名加“卦”，其他语言短名是拼音，用译名
    private func chip(_ h: Hexagram) -> String {
        let l = Localizer.shared
        return l.isChinese || l.lang == .ja || l.lang == .ko ? L("%@卦", h.name) : h.full
    }

    private var list: [Record] {
        let f = filter, qq = hq.trimmingCharacters(in: .whitespacesAndNewlines)
        return records.filter { r in
            if f == "fav" && !r.fav { return false }
            if f != "all" && f != "fav" && String(r.analysis.ben.n) != f { return false }
            return qq.isEmpty || [r.question, r.title, r.note, r.analysis.ben.name].joined(separator: "\n").localizedStandardContains(qq)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    pageTitle(L("卜卦记录"))
                    Spacer()
                    Text(L("共 %d 卦", records.count)).font(.scaled(13)).foregroundStyle(Color.subdued)
                    exportMenu
                        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                    SettingsButton()
                        .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 5 }
                }
                .foregroundStyle(Color.text)

                SearchField(text: $hq)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([("all", L("全部")), ("fav", L("收藏"))] + hexes.map { (String($0.n), chip($0)) }, id: \.0) { k, l in
                            ChipButton(label: l, selected: filter == k) { hf = k }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)

                LazyVStack(spacing: 8) {
                    ForEach(list) { r in
                        Button { app.historyPath.append(.reading(r)) } label: { row(r) }
                            .buttonStyle(.plain)
                    }
                    if records.isEmpty {
                        VStack(spacing: 16) {
                            if UIImage(named: "history-empty") != nil {
                                Image(decorative: "history-empty").resizable().scaledToFit()
                                    .frame(maxWidth: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            Text(L("还没有卜卦记录")).font(.scaled(16, .heavy)).foregroundStyle(Color.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else if list.isEmpty {
                        VStack(spacing: 6) {
                            Text(L("没有找到相关记录")).font(.scaled(16, .heavy)).foregroundStyle(Color.text)
                            Text(L("换个关键词或筛选条件试试")).font(.scaled(13)).foregroundStyle(Color.subdued)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
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
        .onChange(of: records.count) { if filter != hf { hf = "all" } }
    }

    /// 导出全部记录：JSON 与纯文本，经系统分享面板。先取值快照，导出闭包在后台线程不碰 @Model
    private var exportMenu: some View {
        // ponytail: 每次重绘都取快照（逐条排卦），记录上千条若觉卡顿再改为点按时生成
        let rows = records.map(RecordsExport.Row.init)
        return Menu {
            ShareLink(item: RecordsExport(rows: rows, json: true), preview: SharePreview(L("导出为 JSON"))) {
                Label(L("导出为 JSON"), systemImage: "curlybraces")
            }
            ShareLink(item: RecordsExport(rows: rows, json: false), preview: SharePreview(L("导出为文本"))) {
                Label(L("导出为文本"), systemImage: "doc.plaintext")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.scaled(20))
                .foregroundStyle(records.isEmpty ? Color.gray500 : Color.text)
        }
        .disabled(records.isEmpty)
        .accessibilityLabel(L("导出记录"))
    }

    private func row(_ r: Record) -> some View {
        HStack(alignment: .top, spacing: 14) {
            HexGlyph(bits: r.analysis.bits, lines: r.lines)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(r.title)
                        .font(.scaled(15, .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if r.fav {
                        Image(systemName: "star.fill").font(.scaled(14)).foregroundStyle(Color.notice)
                            .accessibilityLabel(L("收藏"))
                    }
                }
                Text(r.question).font(.scaled(14)).lineSpacing(2)
                HStack(spacing: 8) {
                    Text(r.meta).font(.scaled(12)).foregroundStyle(Color.subdued)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Badge(text: L(r.verify), variant: verifyVariant(r.verify), subtle: true)
                }
                .padding(.top, 2)
                if !r.note.isEmpty {
                    Text(L("备注：%@", r.note)).font(.scaled(12)).lineSpacing(2).foregroundStyle(Color.subdued)
                }
            }
            .foregroundStyle(Color.text)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.base, in: RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// 记录导出文件。存储字段（类别、应验）原样为中文键；卦名取简体全名，文本版按当前语言
private struct RecordsExport: Transferable {
    struct Row: Encodable {
        let ts: Date, q: String, cat: String, method: String, lines: [Int], fav: Bool, note: String, verify: String
        let ben: String, bian: String?
        let text: String

        enum CodingKeys: String, CodingKey { case ts, q, cat, method, lines, fav, note, verify, ben, bian }

        @MainActor init(_ r: Record) {
            let a = r.analysis
            ts = r.ts; q = r.q; cat = r.cat; method = r.method; lines = r.lines; fav = r.fav; note = r.note; verify = r.verify
            ben = Zhouyi.texts[a.ben.n - 1][1]
            bian = a.bian.map { Zhouyi.texts[$0.n - 1][1] }
            let f = DateFormatter()
            f.locale = Localizer.shared.locale
            f.calendar = Calendar(identifier: .gregorian)
            f.dateStyle = .medium
            f.timeStyle = .short
            text = [f.string(from: r.ts) + " · " + (CastMethod(rawValue: r.method)?.label ?? r.method) + " · " + L(r.cat) + (r.fav ? " ★" : ""),
                    r.question,
                    r.title + " · " + r.lines.map(String.init).joined(separator: " ") + " · " + L(r.verify)]
                .joined(separator: "\n") + (r.note.isEmpty ? "" : "\n" + L("备注：%@", r.note))
        }
    }

    let rows: [Row]
    let json: Bool

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { try $0.file() }.exportingCondition { $0.json }
        FileRepresentation(exportedContentType: .plainText) { try $0.file() }.exportingCondition { !$0.json }
    }

    private func file() throws -> SentTransferredFile {
        let data: Data
        if json {
            let e = JSONEncoder()
            e.dateEncodingStrategy = .iso8601
            e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            data = try e.encode(rows)
        } else {
            data = Data(rows.map(\.text).joined(separator: "\n\n").utf8)
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("zhouyi-records." + (json ? "json" : "txt"))
        try data.write(to: url, options: .atomic)
        return SentTransferredFile(url)
    }
}

/// Spectrum SearchField：胶囊形，2px 描边，聚焦时强调色
private struct SearchField: View {
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.scaled(15)).foregroundStyle(Color.subdued)
                .accessibilityHidden(true)
            TextField(L("搜索所问之事或卦名"), text: $text)
                .font(.scaled(15))
                .submitLabel(.search)
                .focused($focused)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.subdued)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("清除"))
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 36)
        .background(Color.base, in: Capsule())
        .overlay(Capsule().strokeBorder(focused ? Color.accentVisual : Color.gray300, lineWidth: 2))
        .animation(.spectrum, value: focused)
    }
}

private struct HistoryPreview: View {
    let container: ModelContainer = {
        let c = try! ModelContainer(for: Record.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let samples: [(String, String, [Int], Bool, String, String)] = [
            ("这次跳槽是否顺利？", "事业", [7, 8, 9, 7, 8, 7], true, "应验", "三个月后拿到 offer"),
            ("与对方的关系能否更进一步", "感情", [8, 8, 7, 7, 6, 8], false, "待验", ""),
            ("本季度投资收益", "财运", [7, 7, 7, 7, 7, 7], false, "未应验", ""),
        ]
        for (i, s) in samples.enumerated() {
            let r = Record(q: s.0, cat: s.1, method: .coin, lines: s.2, ts: .now.addingTimeInterval(Double(-i) * 86400))
            r.fav = s.3; r.verify = s.4; r.note = s.5
            c.mainContext.insert(r)
        }
        return c
    }()

    var body: some View {
        NavigationStack { HistoryView() }
            .modelContainer(container)
            .environment(AppState())
    }
}

#Preview("浅色") { HistoryPreview() }
#Preview("深色") { HistoryPreview().preferredColorScheme(.dark) }
