import SwiftUI

// MARK: - 朱印

/// 朱文方印“卦成”：白字，右列卦、左列成（自右而左读），边缘微残、略斜。纯装饰，同铜钱“通寶”，各语言皆不读出
struct SealStamp: View {
    var on: Bool          // 成卦：标题出现后约 0.25s 盖下
    var size: CGFloat = 30
    @State private var down = false
    @State private var thud = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            SealShape().fill(Color.accentVisual, style: FillStyle(eoFill: true))
            Rectangle().strokeBorder(Color.onAccent, lineWidth: max(0.8, size * 0.025))   // 内框，同片头印
                .padding(size * 0.09)
            HStack(spacing: size * 0.02) {
                Text(verbatim: "成")
                Text(verbatim: "卦")
            }
            .font(.custom("ZhouyiSerif-SemiBold", fixedSize: size * 0.36))   // 印框定宽，不随动态字体
            .scaleEffect(x: 1, y: 1.25)   // 印文略长
            .foregroundStyle(Color.onAccent)
            .shadow(color: .onAccent, radius: 0, x: 0.4)   // 子集只有 SemiBold，小字号下偏细：左右各叠一层描粗
            .shadow(color: .onAccent, radius: 0, x: -0.4)
        }
        .frame(width: size, height: size)
        .environment(\.layoutDirection, .leftToRight)   // 印文读序不随界面方向翻转
        .scaleEffect(down ? 1 : 1.5)
        .rotationEffect(.degrees(down ? -3 : -10))
        .opacity(down ? 1 : 0)
        .accessibilityHidden(true)
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.9), trigger: thud)
        .task(id: on) {
            guard on else { down = false; return }
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            if reduceMotion { down = true } else { withAnimation(.spring(duration: 0.35, bounce: 0.35)) { down = true } }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 120))   // 落定时一震
            thud += 1
        }
    }
}

/// 印面：四边微微凹凸，角略圆，近边几处残缺（偶奇填充成空）
private struct SealShape: Shape {
    func path(in r: CGRect) -> Path {
        func rnd(_ k: Int) -> CGFloat {
            let x = sin(Double(k) * 12.9898 + 4.1) * 43758.5453
            return CGFloat(x - x.rounded(.down))
        }
        let s = r.width, j = s * 0.03, c = s * 0.05
        // 自左上角顺时针，每边 5 段向内抖动；角沿两边法向各内收，略圆钝
        let corners = [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)]
        let inward = [CGVector(dx: 0, dy: 1), CGVector(dx: -1, dy: 0), CGVector(dx: 0, dy: -1), CGVector(dx: 1, dy: 0)]
        func along(_ e: Int, _ f: CGFloat, _ d: CGFloat) -> CGPoint {
            let a = corners[e], b = corners[(e + 1) % 4], nv = inward[e]
            return CGPoint(x: a.x + (b.x - a.x) * f + nv.dx * d, y: a.y + (b.y - a.y) * f + nv.dy * d)
        }
        var pts: [CGPoint] = []
        for e in 0..<4 {
            let pv = inward[(e + 3) % 4]
            let a = along(e, 0, c)
            pts.append(CGPoint(x: a.x + pv.dx * c, y: a.y + pv.dy * c))
            for i in 1..<5 { pts.append(along(e, CGFloat(i) / 5, j * rnd(e * 7 + i))) }
        }
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        for k in 0..<3 {   // 残缺：近边细碎斑痕
            let w = s * (0.012 + 0.014 * rnd(60 + k))   // 整个落在印面内，否则偶奇填充会凸出
            let at = along(k % 4, 0.15 + 0.7 * rnd(40 + k), j + w + s * 0.02 * rnd(50 + k))
            p.addEllipse(in: CGRect(x: at.x - w * 1.6, y: at.y - w * 0.6, width: w * 3.2, height: w * 1.2))
        }
        return p
    }
}

// MARK: - 墨晕

/// 成卦时卦画后化开一团淡墨，约 1s，止于低透明度；减少动态时直接显示
struct InkBloom: View {
    var on: Bool
    @State private var spread = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        BlotShape()
            .fill(Color.line)
            .blur(radius: spread ? 18 : 8)
            .scaleEffect(spread ? 1 : 0.3)
            .opacity(spread ? 0.13 : 0)
            .padding(-24)   // 比卦画稍大，不占布局
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: on, initial: true) { _, v in
                guard v else { spread = false; return }
                if reduceMotion { spread = true } else { withAnimation(.easeOut(duration: 1)) { spread = true } }
            }
    }
}

/// 不规则墨团：极坐标下半径叠几道正弦
private struct BlotShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 72
        for i in 0...n {
            let a = Double(i) / Double(n) * 2 * .pi
            let k = 0.82 + 0.1 * sin(3 * a + 1.3) + 0.06 * sin(5 * a + 0.4) + 0.04 * sin(8 * a + 2.2)
            let pt = CGPoint(x: r.midX + r.width / 2 * k * cos(a), y: r.midY + r.height / 2 * k * sin(a))
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}
