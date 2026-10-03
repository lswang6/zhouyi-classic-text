import SwiftUI

// MARK: - 宣纸 · 墨 · 朱砂（浅色 / 深色）

extension Color {
    init(_ light: UInt32, _ dark: UInt32) {
        func ui(_ hex: UInt32) -> UIColor {
            UIColor(red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        }
        self.init(UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
    }

    static let layer1 = Color(0xF3EDE1, 0x1C1915)       // 页面：宣纸 / 夜墨
    static let base = Color(0xFAF6EE, 0x2B2621)         // 卡片：熟宣
    static let text = Color(0x2B2621, 0xEEE6D8)         // 正文：焦墨
    static let subdued = Color(0x6B6259, 0xB3A999)      // 次要文字：淡墨
    static let line = Color(0x2B2621, 0xE6DDCD)         // 爻画墨色
    static let accentVisual = Color(0xB5452F, 0xD9674E) // 朱砂：动爻、选中描边
    static let accentText = Color(0xA33B27, 0xE57B62)   // 朱砂强调文字
    static let accentFill = Color(0xB5452F, 0xB5452F)   // 主按钮实底
    static let onAccent = Color(0xFFFCF6, 0xFFFCF6)     // 朱底上的字
    static let blue200 = Color(0xF6E3DC, 0x3A221C)      // 高亮背景：淡朱
    static let gray75 = Color(0xEDE6D8, 0x35302A)       // 次级引文背景
    static let gray100 = Color(0xE6DFD1, 0x3A342D)      // 未选中按钮背景
    static let divider = Color(0xE0D7C7, 0x3A342D)      // 分隔线
    static let gray300 = Color(0xD3C8B5, 0x4A433A)      // 空爻位虚线
    static let gray500 = Color(0x9A8F80, 0x7A7063)
    static let gray600 = Color(0x7D7366, 0x968B7C)
    static let gray50 = Color(0xFFFCF6, 0x221E1A)
    static let notice = Color(0xC98A1A, 0xE0A43A)       // 收藏星标：藤黄
    static let negativeText = Color(0x8E2F21, 0xF0927E) // 否定、删除：赭红
}

extension Animation {
    /// 150ms cubic-bezier(0.45,0,0.4,1)
    static let spectrum = Animation.timingCurve(0.45, 0, 0.4, 1, duration: 0.15)
}

extension Font {
    /// 卦辞、爻辞用衬线（思源宋体子集，仅含卦文用字）；随动态字体按 size 所近的文本样式缩放
    static func serif(_ size: CGFloat, semibold: Bool = false) -> Font {
        .custom(semibold ? "ZhouyiSerif-SemiBold" : "ZhouyiSerif-Regular", size: size, relativeTo: textStyle(size))
    }

    /// 系统字体随动态字体缩放：按 size 所近的文本样式的比例；默认字号即 size
    /// ponytail: iOS 17–25 无 Font.scaled(by:)，退为所近样式字号（可差 1pt，如 14 → 15）
    static func scaled(_ size: CGFloat, _ weight: Weight = .regular, design: Design = .default) -> Font {
        let style = textStyle(size), font = Font.system(style, design: design, weight: weight)
        if #available(iOS 26, *) { return font.scaled(by: size / defaultSize(style)) }
        return font
    }

    /// 文本样式在默认（.large）动态字体下的字号
    static func defaultSize(_ style: TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .body, .headline: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        default: 11
        }
    }

    /// 字号 → 默认字号与之最近的系统文本样式（缩放比例随之）
    static func textStyle(_ size: CGFloat) -> TextStyle {
        switch size {
        case 30...: .largeTitle
        case 25..<30: .title
        case 21..<25: .title2
        case 18..<21: .title3
        case 17..<18: .body
        case 16..<17: .callout
        case 14..<16: .subheadline
        case 13..<14: .footnote
        case 12..<13: .caption
        default: .caption2
        }
    }
}

/// 页大标题 34pt：中文宋体，否则系统衬线粗体
/// ponytail: 卜 左侧留白大（SemiBold LSB 378/1000，易 45/1000），以卜开头的中文标题左移补齐页边；他字再补
func pageTitle(_ s: String) -> some View {
    let zh = Localizer.shared.isChinese
    return Text(s).font(zh ? .serif(34, semibold: true) : .system(.largeTitle, design: .serif, weight: .bold))
        .padding(.leading, zh && s.first == "\u{535C}" ? -CGFloat(378 - 45) * 34 / 1000 : 0)
}

extension View {
    /// 面板：圆角 16，可选暖褐淡影
    func card(radius: CGFloat = 16, padding: CGFloat = 16, shadow: Bool = false) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius).fill(Color.base)
                    .shadow(color: Color(0x5A3E24, 0x000000).opacity(shadow ? 0.14 : 0), radius: 4, y: 1)
            )
    }

    /// 顶部滚动边缘柔化（iOS 26+），免得内容在导航栏、状态栏下被硬切
    @ViewBuilder func softTopEdge() -> some View {
        if #available(iOS 26, *) { scrollEdgeEffectStyle(.soft, for: .top) } else { self }
    }

    /// 宣纸底：layer1 + 平铺纸纹（tools/make_paper.py），opacity 供半透明过场用
    func paperBackground(_ opacity: Double = 1) -> some View {
        background { Paper().opacity(opacity).ignoresSafeArea() }
    }

    /// 纸色插图在深色模式下略压暗，不刺眼
    func nightDim() -> some View { modifier(NightDim()) }
}

private struct NightDim: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.brightness(scheme == .dark ? -0.08 : 0).saturation(scheme == .dark ? 0.9 : 1)
    }
}

private struct Paper: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Color.layer1.overlay {
            Image(decorative: "paper-grain").renderingMode(.template).resizable(resizingMode: .tile)
                .foregroundStyle(Color.line)
                .opacity(scheme == .dark ? 0.22 : 0.45)   // 纹理为墨色，深色纸上更淡
        }
    }
}

// MARK: - 卦画

/// 自上（上爻）而下（初爻）绘制。lines 给出时动爻用强调色，showMarks 时右侧标 ○ / ×
struct HexGlyph: View {
    let bits: [Int]
    var lines: [Int]? = nil
    var width: CGFloat = 26
    var lineHeight: CGFloat = 3
    var gap: CGFloat = 3
    var split: CGFloat = 5
    var radius: CGFloat = 1
    var showMarks = false

    var body: some View {
        VStack(spacing: gap) {
            ForEach((0..<6).reversed(), id: \.self) { i in
                let moving = lines.map { Zhouyi.isMoving($0[i]) } ?? false
                HStack(spacing: 8) {
                    if showMarks { Color.clear.frame(width: 12, height: 1) }   // 左侧等宽留白，卦画居中、标记外挂
                    YaoBar(yang: bits[i] == 1, color: moving ? .accentVisual : .line, split: split, seed: i, halo: lineHeight >= 8)
                        .frame(width: width, height: lineHeight)
                    if showMarks {
                        Text(lines?[i] == 9 ? "○" : lines?[i] == 6 ? "×" : "")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.accentText)
                            .frame(width: 12)
                    }
                }
            }
        }
    }
}

/// 单爻：阳爻整条，阴爻两段；毛笔横画。progress 0…1 自左向右写出（阴爻先左后右）
struct YaoBar: View {
    let yang: Bool
    let color: Color
    var split: CGFloat = 5
    var radius: CGFloat = 1   // 旧参数，笔画不再用圆角
    var progress: CGFloat = 1
    var seed = 0
    var halo = true           // 晕染；3pt 小卦画不画，省开销

    var body: some View {
        let stroke = YaoStroke(yang: yang, split: split, seed: seed, progress: progress)
        let ink = LinearGradient(colors: [color, color.opacity(0.82)], startPoint: .leading, endPoint: .trailing)   // 墨渐干
        ZStack {
            if halo { stroke.fill(color.opacity(0.22)).blur(radius: 1) }
            stroke.fill(ink, style: FillStyle(eoFill: true))
        }
    }
}

/// 爻的笔画路径；animatableData 为 progress，阴爻两段按序写出
struct YaoStroke: Shape {
    var yang: Bool
    var split: CGFloat
    var seed: Int
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in r: CGRect) -> Path {
        var p = Path()
        if yang {
            brush(&p, r, seed * 2, progress)
        } else {
            let w = (r.width - split) / 2
            brush(&p, CGRect(x: r.minX, y: r.minY, width: w, height: r.height), seed * 2, min(1, progress * 2))
            brush(&p, CGRect(x: r.maxX - w, y: r.minY, width: w, height: r.height), seed * 2 + 1, max(0, progress * 2 - 1))
        }
        return p
    }

    /// 一笔横：起笔收尖、行笔微按、边缘微糙、收笔飞白。高 < 8pt 只画简化笔形
    private func brush(_ p: inout Path, _ r: CGRect, _ seed: Int, _ progress: CGFloat) {
        guard progress > 0.001, r.width > 1 else { return }
        func rnd(_ k: Int) -> CGFloat {   // 0…1，同 seed 同笔形
            let x = sin(Double(seed * 131 + k) * 12.9898) * 43758.5453
            return CGFloat(x - x.rounded(.down))
        }
        let h = r.height, rich = h >= 8, half = h / 2 * 0.9
        let tail = rich ? min(h * 0.5, r.width * 0.15) : 0   // 飞白须长
        let body = r.width - tail
        let bp = min(1, progress / 0.92), tp = max(0, (progress - 0.92) / 0.08)   // 先写笔身，再出飞白
        let vis = body * bp
        let n = rich ? 28 : 6
        let rise = h * 0.05 * (0.7 + 0.6 * rnd(2))   // 横画略向右上
        func mid(_ u: CGFloat) -> CGFloat { r.midY + rise * (0.5 - u) }

        var top: [CGPoint] = [], bot: [CGPoint] = []
        for i in 0...n {
            let x = vis * CGFloat(i) / CGFloat(n), u = x / body
            var t = 0.4 + 0.6 * sin(min(1, u / 0.1) * .pi / 2)             // 起笔收尖渐粗
            t *= 0.88 + 0.16 * exp(-pow((u - 0.12) / 0.1, 2))              // 起笔一按
                + 0.06 * exp(-pow((u - 0.78) / 0.12, 2))                   // 收笔前再按
            if u > 0.85 { t *= 1 - 0.3 * (u - 0.85) / 0.15 }               // 收笔渐散
            var tt = t, tb = t
            if rich {   // 毛边
                tt += 0.035 * sin(u * 9 + rnd(3) * 6) + 0.03 * (rnd(10 + i) - 0.5)
                tb += 0.035 * sin(u * 7 + rnd(4) * 6) + 0.03 * (rnd(50 + i) - 0.5)
            }
            top.append(CGPoint(x: r.minX + x, y: mid(u) - half * tt))
            bot.append(CGPoint(x: r.minX + x, y: mid(u) + half * tb))
        }

        p.move(to: top[0])
        top.dropFirst().forEach { p.addLine(to: $0) }
        let end = top[n].x, cy = mid(vis / body)
        if rich && bp >= 1 {   // 飞白：收笔散成几缕
            let k = 4
            for j in 0..<k {
                let f = (CGFloat(j) + 0.3 + 0.4 * rnd(25 + j)) / CGFloat(k)
                p.addLine(to: CGPoint(x: end + tail * tp * (0.15 + 0.85 * rnd(20 + j)), y: top[n].y + (bot[n].y - top[n].y) * f))
                if j < k - 1 {
                    p.addLine(to: CGPoint(x: end - h * (0.05 + 0.3 * rnd(30 + j)), y: top[n].y + (bot[n].y - top[n].y) * (CGFloat(j) + 1) / CGFloat(k)))
                }
            }
            p.addLine(to: bot[n])
        } else {
            p.addQuadCurve(to: bot[n], control: CGPoint(x: end + (bot[n].y - top[n].y) * 0.45, y: cy))
        }
        bot.reversed().dropFirst().forEach { p.addLine(to: $0) }
        p.addQuadCurve(to: top[0], control: CGPoint(x: r.minX - half * 0.2, y: mid(0) - half * 0.5))   // 起笔自左上入
        p.closeSubpath()

        guard rich else { return }
        for s in 0..<2 {   // 笔身近尾处两道细飞白（偶奇填充成空）
            let x0 = r.minX + body * (0.62 + 0.12 * rnd(40 + s)), x1 = r.minX + min(body - h * 0.2, vis - h * 0.3)
            guard x1 > x0 + h * 0.5 else { continue }
            let y = mid(((x0 + x1) / 2 - r.minX) / body) + half * 0.8 * (rnd(45 + s) - 0.5)
            let th = h * (0.05 + 0.04 * rnd(60 + s))
            p.move(to: CGPoint(x: x0, y: y))
            p.addQuadCurve(to: CGPoint(x: x1, y: y), control: CGPoint(x: (x0 + x1) / 2, y: y - th))
            p.addQuadCurve(to: CGPoint(x: x0, y: y), control: CGPoint(x: (x0 + x1) / 2, y: y + th))
            p.closeSubpath()
        }
    }
}

/// 新落之爻：出现时一笔写出（减少动态时直接显示）
struct WrittenYao: View {
    let yang: Bool
    let color: Color
    var seed = 0
    var duration = 0.35
    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        YaoBar(yang: yang, color: color, split: 18, progress: progress, seed: seed)
            .onAppear {
                if reduceMotion { progress = 1 } else { withAnimation(.easeOut(duration: duration)) { progress = 1 } }
            }
    }
}

// MARK: - 控件

/// Spectrum ActionButton S（类别、筛选、应验）
struct ChipButton: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 10)
                .frame(minHeight: 26)
                .foregroundStyle(selected ? Color.accentText : Color.text)
                .background(selected ? Color.blue200 : Color.gray100, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? Color.accentVisual : .clear, lineWidth: 1))   // 选中：淡朱底朱字朱边，同方法卡
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .animation(.spectrum, value: selected)
    }
}

/// 主按钮朱砂实底 / 次按钮墨字暖灰描边，胶囊形。XL 高 48，L 高 40
struct PillButton: View {
    let title: String
    var accent = true
    var large = true
    var disabled = false
    let action: () -> Void
    @ScaledMetric(relativeTo: .body) private var scale = 1.0

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: (large ? 18 : 16) * scale, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: large ? 48 : 40)
                .foregroundStyle(disabled ? Color.gray500 : accent ? Color.onAccent : Color.line)
                .background {
                    if disabled { Capsule().fill(Color.gray100) }   // 禁用态：浅底淡字
                    else if accent { Capsule().fill(Color.accentFill) }
                    else { Capsule().strokeBorder(Color.gray300, lineWidth: 2) }
                }
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

/// Spectrum TextField：上方标签，2px 描边，圆角 8，聚焦时强调色描边
struct SpectrumField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.subdued)
            // 系统占位语不换行（德语、阿语会截断）：自绘可换行的占位语，标题仍作无障碍标签
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder).foregroundStyle(Color.gray500).accessibilityHidden(true)
                        .onTapGesture { focused = true }   // 占位语折行处也能点进输入框
                }
                TextField(placeholder, text: $text, prompt: Text(verbatim: ""), axis: .vertical)
                    .lineLimit(1...3)
                    .keyboardType(keyboard)
                    .focused($focused)
                    .submitLabel(.done)
                    .onChange(of: text) {   // 竖向输入框回车会插入换行：去掉换行并收起键盘
                        guard text.contains("\n") else { return }
                        text.removeAll { $0 == "\n" }
                        focused = false
                    }
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(minHeight: 40)
            .background(Color.base, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(focused ? Color.accentVisual : Color.gray300, lineWidth: 2))
            .animation(.spectrum, value: focused)
        }
    }
}

enum BadgeVariant { case accent, positive, negative, neutral }

/// Spectrum Badge S。subtle 为浅底彩字，否则实底白字
struct Badge: View {
    let text: String
    var variant: BadgeVariant = .accent
    var subtle = false

    var body: some View {
        let (solid, soft, ink): (Color, Color, Color) = switch variant {
        case .accent: (.accentVisual, .blue200, .accentText)
        case .positive: (Color(0x3F7A55, 0x5A9E74), Color(0xE2ECDB, 0x1E3225), Color(0x2F5E40, 0x8CC7A0))   // 松绿
        case .negative: (Color(0x9E3B2C, 0xC9604B), Color(0xF3DED6, 0x40221B), .negativeText)   // 赭红
        case .neutral: (.gray600, .gray100, .subdued)
        }
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .frame(minHeight: 20)
            .foregroundStyle(subtle ? ink : .onAccent)
            .background(subtle ? soft : solid, in: RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Toast

@Observable
final class Toast {
    var message = ""
    private var task: Task<Void, Never>?

    func show(_ msg: String) {
        task?.cancel()
        withAnimation(.spectrum) { message = msg }
        task = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1800))
            guard !Task.isCancelled else { return }
            withAnimation(.spectrum) { message = "" }
        }
    }
}

struct ToastOverlay: View {
    let toast: Toast

    var body: some View {
        if !toast.message.isEmpty {
            Text(toast.message)
                .font(.footnote.bold())
                .foregroundStyle(Color.gray50)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.line, in: Capsule())
                .padding(.bottom, 104)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)   // 104 自屏幕底边起算，同原型
                .transition(.opacity.combined(with: .offset(y: 6)))
                .allowsHitTesting(false)
        }
    }
}
