import SwiftUI
import SwiftData
import AVFoundation

/// 02 摇卦：三钱法，自初爻起逐爻掷出
struct CastView: View {
    @Environment(AppState.self) private var app
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var scheme

    @State private var cast: [Int] = []
    @State private var coins = [3, 2, 3]
    @State private var rot: Double = 0
    @State private var busy = false
    @State private var shaking = false
    @State private var shakeCount = 0
    @State private var lastSum: Int?
    @State private var record: Record?
    @State private var gone = false
    @State private var rattle = 0      // 摇动中的碰撞触感
    @State private var landed = 0      // 落钱触感
    @State private var ripple = 0      // 成卦时六爻自下而上一波
    @State private var formed = false  // 成卦停顿结束，揭示卦名

    private static let curve = Animation.timingCurve(0.45, 0, 0.4, 1, duration: 0.3)

    var body: some View {
        let q = app.q.trimmingCharacters(in: .whitespacesAndNewlines)
        VStack(spacing: 0) {
            Text(q.isEmpty ? L("心中默念所问之事") : q)
                .font(.system(size: 14))
                .foregroundStyle(Color.subdued)
                .multilineTextAlignment(.center)
                .padding(.top, 6)

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {   // 列对齐：标签、爻画、爻值各成一列
                ForEach((0..<6).reversed(), id: \.self) { slot($0) }
            }
            .frame(width: 300)
            .backgroundPreferenceValue(LineBounds.self) { a in   // 墨晕只衬爻画一列，不含左右文字
                GeometryReader { g in
                    if let r = a.map({ g[$0] }).reduce(nil, { $0?.union($1) ?? $1 }) {
                        InkBloom(on: formed).frame(width: r.width, height: r.height).position(x: r.midX, y: r.midY)
                    }
                }
            }
            .padding(.top, 20)

            Spacer()

            HStack(spacing: 22) {
                ForEach(0..<3, id: \.self) { i in
                    VStack(spacing: 8) {
                        Coin(face: coins[i])
                            .rotation3DEffect(.degrees(rot), axis: (0, 1, 0))
                        Text(coins[i] == 3 ? L("背 · 3") : L("字 · 2"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.subdued)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(width: 100)   // 定宽：正反面说明长短不一（如德语）时铜钱不左右挪
                }
            }
            .keyframeAnimator(initialValue: 0.0, trigger: shakeCount) { view, t in
                let f = ShakeFrame.at(t)
                view.offset(x: f.x, y: f.y).rotationEffect(.degrees(f.angle))
            } keyframes: { _ in
                MoveKeyframe(0.0)   // 动画结束后停在 3.0，每次先归零才能重播
                LinearKeyframe(3.0, duration: 0.9)
            }

            Group {
                if let s = lastSum {
                    Text(L("三钱之和 %1$d · %2$@", s, L(Zhouyi.lineValueName[s]!)) + ((s == 6 || s == 9) ? L("（动爻）") : ""))
                } else {
                    Text(busy ? "…" : "")
                }
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.text)
            .frame(minHeight: 20)
            .padding(.top, 16)

            // 两态叠放、始终占位，取两者较高者，成卦切换时上方铜钱不跳动
            ZStack(alignment: .top) {
                VStack(spacing: 10) {
                    PillButton(title: L("掷钱"), disabled: busy) { toss() }
                    PillButton(title: L("摇一摇"), accent: false, large: false, disabled: busy) { shake() }
                    Text(L("点按掷钱，或直接摇动手机"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.subdued)
                        .frame(maxWidth: .infinity)
                }
                .placeholder(formed)

                VStack(spacing: 10) {
                    HStack(spacing: 8) {   // 印在卦名后；左侧等宽留白使卦名仍居中，印只占宽不占高
                        Color.clear.frame(width: 30, height: 1)
                        Text(record?.title ?? " ")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(Color.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Color.clear.frame(width: 30, height: 1).overlay { SealStamp(on: formed) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)   // 印比标题行高且微斜，下角距按钮仍留约 15
                    PillButton(title: L("查看解卦")) { if let record { app.open(record) } }
                    Text(L("卦已成，已保存到卜卦记录"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentText)
                        .frame(maxWidth: .infinity)
                }
                .placeholder(!formed)
            }
            .padding(.top, 18)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {   // 浅色时衬一幅淡画，深色不衬
            if scheme == .light, UIImage(named: "cast-backdrop") != nil {
                Color.clear.overlay { Image(decorative: "cast-backdrop").resizable().scaledToFill().opacity(0.6) }
                    .clipped()
                    .mask(LinearGradient(stops: [.init(color: .black, location: 0.35), .init(color: .clear, location: 0.62)], startPoint: .top, endPoint: .bottom))   // 下方铜钱、按钮、提示处淡出，文字清楚
                    .ignoresSafeArea()
            }
        }
        .paperBackground()
        .navigationTitle(L("摇卦"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(formed ? L("完成") : L("取消")) { app.homePath = [] }   // 已入库，不再是“取消”
            }
            ToolbarItem(placement: .topBarTrailing) {
                Text(verbatim: "\(cast.count) / 6")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.subdued)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in shake() }
        .onAppear { gone = false }
        .onDisappear { gone = true }
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.5), trigger: rattle)
        .sensoryFeedback(.impact(weight: .heavy), trigger: landed)
        .sensoryFeedback(.success, trigger: formed)
    }

    private func slot(_ i: Int) -> some View {
        let v = i < cast.count ? cast[i] : nil
        let moving = v.map(Zhouyi.isMoving) ?? false
        let color: Color = moving ? .accentVisual : .line
        return GridRow {
            Text([L("初爻"), L("二爻"), L("三爻"), L("四爻"), L("五爻"), L("上爻")][i])
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.subdued)
                .frame(minWidth: 40, minHeight: 18, alignment: .leading)
                .gridColumnAlignment(.leading)
            ZStack {
                if let v {
                    WrittenYao(yang: v % 2 == 1, color: color, seed: i)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(i == cast.count ? Color.accentVisual : Color.gray300,
                                      style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 14)
            .anchorPreference(key: LineBounds.self, value: .bounds) { [$0] }
            .phaseAnimator([1.0, 1.25, 1.0], trigger: ripple) { v, k in v.scaleEffect(y: k) } animation: { _ in
                .easeOut(duration: 0.14).delay(Double(i) * 0.07)   // 初爻先动，逐爻向上
            }
            Text(v.map { L(Zhouyi.lineValueName[$0]!) + ($0 == 9 ? " ○" : $0 == 6 ? " ×" : "") } ?? "")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .fixedSize()
                .frame(minWidth: 74, alignment: .leading)
                .gridColumnAlignment(.leading)
        }
    }

    private func toss() {
        guard !busy, cast.count < 6 else { return }
        let next = (0..<3).map { _ in Bool.random() ? 3 : 2 }
        let sum = next.reduce(0, +)
        busy = true
        lastSum = nil
        withAnimation(.timingCurve(0.45, 0, 0.4, 1, duration: 0.65)) { rot += 720 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(320))
            coins = next
            try? await Task.sleep(for: .milliseconds(280))
            CoinSound.play(.drop)
            landed += 1
            try? await Task.sleep(for: .milliseconds(80))
            guard !gone, cast.count < 6 else { busy = false; return }
            withAnimation(Self.curve) { cast.append(sum) }
            lastSum = sum
            guard cast.count == 6 else { busy = false; return }
            let r = Record(q: app.q, cat: app.cat, method: .coin, lines: cast)
            modelContext.insert(r)
            try? modelContext.save()
            record = r
            // 成卦：稍停，六爻一波，再揭示卦名
            try? await Task.sleep(for: .milliseconds(350))
            ripple += 1
            try? await Task.sleep(for: .milliseconds(750))
            guard !gone else { return }
            withAnimation(.spring(duration: 0.4)) { formed = true }
        }
    }

    private func shake() {
        guard !busy, !shaking, cast.count < 6 else { return }
        shaking = true
        busy = true
        shakeCount += 1
        CoinSound.play(.rattle)
        Task { @MainActor in
            for _ in 0..<6 {   // 与摇动关键帧同拍，每 150ms 碰一下
                try? await Task.sleep(for: .milliseconds(150))
                rattle += 1
            }
            shaking = false
            busy = false
            guard !gone else { return }
            toss()
        }
    }
}

private struct LineBounds: PreferenceKey {
    static let defaultValue: [Anchor<CGRect>] = []
    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) { value += nextValue() }
}

private extension View {
    /// 只占位：不绘制、不可点、不进无障碍树
    @ViewBuilder func placeholder(_ on: Bool) -> some View {
        if on { hidden() } else { self }
    }
}

/// 铜钱音效（tools/make_sounds.py 生成）：.ambient 跟随静音键，且不打断用户正在放的音乐
@MainActor private enum CoinSound {
    case rattle, drop

    private static let players: [CoinSound: AVAudioPlayer] = {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        var d: [CoinSound: AVAudioPlayer] = [:]
        for (k, n) in [(CoinSound.rattle, "coin-rattle"), (.drop, "coin-drop")] {
            if let url = Bundle.main.url(forResource: n, withExtension: "wav"), let p = try? AVAudioPlayer(contentsOf: url) {
                p.prepareToPlay()
                d[k] = p
            }
        }
        return d
    }()

    static func play(_ s: CoinSound) {
        guard let p = players[s] else { return }
        p.currentTime = 0
        p.play()
    }
}

/// 摇动关键帧：t 每增 1 为一个 300ms 周期，点位 0/15/30/…/90/100%
private struct ShakeFrame {
    var x: CGFloat = 0
    var y: CGFloat = 0
    var angle: Double = 0

    private static let stops: [(p: Double, f: ShakeFrame)] = [
        (0, .init()), (0.15, .init(x: -10, y: 4, angle: -6)), (0.3, .init(x: 9, y: -5, angle: 5)),
        (0.45, .init(x: -8, y: -3, angle: -4)), (0.6, .init(x: 10, y: 5, angle: 6)),
        (0.75, .init(x: -6, y: 2, angle: -3)), (0.9, .init(x: 4, y: -2, angle: 2)), (1, .init()),
    ]

    static func at(_ t: Double) -> ShakeFrame {
        let p = t - t.rounded(.down)
        guard let j = stops.firstIndex(where: { $0.p > p }), j > 0 else { return .init() }
        let (a, b) = (stops[j - 1], stops[j])
        let k = (p - a.p) / (b.p - a.p)
        return .init(x: a.f.x + (b.f.x - a.f.x) * k, y: a.f.y + (b.f.y - a.f.y) * k,
                     angle: a.f.angle + (b.f.angle - a.f.angle) * k)
    }
}

/// 铜钱：背（3）为深色无字，字（2）为浅色上“通”下“寶”
private struct Coin: View {
    let face: Int

    var body: some View {
        let back = face == 3
        let fg: Color = back ? .gray50 : .line
        ZStack {
            Circle().fill(back ? Color.line : Color.base)
            Circle().strokeBorder(Color.line, lineWidth: 2)
            Circle().inset(by: 6).stroke(fg.opacity(0.35), lineWidth: 1)
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.layer1)
                .overlay(Rectangle().strokeBorder(fg, lineWidth: 2))
                .frame(width: 18, height: 18)
            if !back {
                VStack {
                    Text(verbatim: "通")
                    Spacer()
                    Text(verbatim: "寶")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(fg)
                .padding(.vertical, 12)
                .accessibilityHidden(true)
            }
        }
        .frame(width: 78, height: 78)
    }
}

#Preview {
    NavigationStack { CastView() }
        .modelContainer(for: Record.self, inMemory: true)
        .environment(AppState())
}

#Preview("Dark") {
    NavigationStack { CastView() }
        .modelContainer(for: Record.self, inMemory: true)
        .environment(AppState())
        .preferredColorScheme(.dark)
}
