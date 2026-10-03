import SwiftUI
import SwiftData
import CoreText
import AVFoundation

@main
struct ZhouyiApp: App {
    init() {
        for name in ["ZhouyiSerif-Regular", "ZhouyiSerif-SemiBold"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }

    /// iCloud 私有库同步；未登录 iCloud 时 SwiftData 照常本地存取。
    /// groupContainer 须 .none：默认 .automatic 有 App Group 权限时会把库移进组容器，旧记录就找不到了
    private let container: ModelContainer = {
        let cloud = ModelConfiguration(groupContainer: .none, cloudKitDatabase: .private("iCloud.com.lswang.zhouyi"))
        if let c = try? ModelContainer(for: Record.self, configurations: cloud) { return c }
        // 权限或容器出错时退回纯本地，同一库文件
        return try! ModelContainer(for: Record.self, configurations: ModelConfiguration(groupContainer: .none, cloudKitDatabase: .none))
    }()
}

enum Route: Hashable {
    case cast(CastMethod)   // .coin / .yarrow
    case reading(Record)
    case article(String)
    case hexagram(Int)
}

enum AppTab: Hashable { case home, history, learn }

/// 跨页面共享的界面状态
@Observable
final class AppState {
    var tab: AppTab = .learn   // 以经典研读为首页（App Review 4.3）
    var homePath: [Route] = []
    var historyPath: [Route] = []
    var learnPath: [Route] = []
    var q = ""
    var cat = Record.categories[0]
    var showSettings = false
    var forming: Record?   // 数字、时间起卦的成卦过场，未入库
    let toast = Toast()

    /// 打开解卦页；从摇卦进入时替换摇卦页（返回直接回首页）
    func open(_ record: Record) {
        switch tab {
        case .home: homePath = [.reading(record)]
        case .history: historyPath = [.reading(record)]
        case .learn: learnPath = [.reading(record)]
        }
    }

    /// 从当前页返回（删除记录等）
    func pop() {
        switch tab {
        case .home: homePath = []
        case .history: historyPath = []
        case .learn: learnPath = []
        }
    }
}

struct RootView: View {
    @State private var app = AppState()
    @State private var splash = true   // 每次冷启动一次

    var body: some View {
        let loc = Localizer.shared
        TabView(selection: $app.tab) {
            NavigationStack(path: $app.learnPath) {
                KnowledgeView()
                    .navigationDestination(for: Route.self, destination: destination)
            }
            .tabItem { Label(L("易学"), systemImage: "book") }
            .tag(AppTab.learn)

            NavigationStack(path: $app.homePath) {
                HomeView()
                    .navigationDestination(for: Route.self, destination: destination)
            }
            .tabItem { Label(L("起卦"), systemImage: "circle.grid.3x3") }
            .tag(AppTab.home)

            NavigationStack(path: $app.historyPath) {
                HistoryView()
                    .navigationDestination(for: Route.self, destination: destination)
            }
            .tabItem { Label(L("笔记"), systemImage: "note.text") }
            .tag(AppTab.history)
        }
        .tint(.accentText)
        .overlay { if let r = app.forming { FormingOverlay(record: r).transition(.opacity) } }
        .overlay { ToastOverlay(toast: app.toast) }
        .overlay { if splash { SplashOverlay { splash = false } } }
        .sheet(isPresented: $app.showSettings) { SettingsView() }
        .onOpenURL { url in   // 小组件：zhouyi://hexagram/<n>
            guard url.scheme == "zhouyi", url.host == "hexagram", let n = Int(url.lastPathComponent), (1...64).contains(n) else { return }
            app.showSettings = false
            app.tab = .learn
            app.learnPath = [.hexagram(n)]
        }
        .environment(app)
        .environment(\.locale, loc.locale)
        .environment(\.layoutDirection, loc.isRTL ? .rightToLeft : .leftToRight)
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .cast(let m): CastView(method: m).toolbar(.hidden, for: .tabBar)
        case .reading(let r): ReadingView(record: r).toolbar(.hidden, for: .tabBar)
        case .article(let id): ArticleView(id: id).toolbar(.hidden, for: .tabBar)
        case .hexagram(let n): HexagramView(n: n).toolbar(.hidden, for: .tabBar)
        }
    }
}

// MARK: - 片头

/// 按深浅色播放 splash-light / splash-dark.mp4，铺满、静音、不动音频会话；播完 0.3s 淡出，点按跳过。
/// 减少动态、缺片或片子坏了都直接跳过
struct SplashOverlay: View {
    let finish: () -> Void
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var player: AVPlayer?
    @State private var fading = false

    var body: some View {
        ZStack {
            Color.layer1   // 首帧解码前与启动屏同色
            if let player { PlayerLayer(player: player) }
        }
        .ignoresSafeArea()
        .opacity(fading ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture { end() }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion,
                  let url = Bundle.main.url(forResource: scheme == .dark ? "splash-dark" : "splash-light", withExtension: "mp4")
            else { return finish() }
            let p = AVPlayer(url: url)
            p.isMuted = true
            p.preventsDisplaySleepDuringVideoPlayback = false
            p.play()
            player = p
            Task { if (try? await AVURLAsset(url: url).load(.isPlayable)) != true { end() } }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.didPlayToEndTimeNotification).receive(on: DispatchQueue.main)) {
            if $0.object as? AVPlayerItem === player?.currentItem { end() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification).receive(on: DispatchQueue.main)) {
            if $0.object as? AVPlayerItem === player?.currentItem { end() }
        }
    }

    private func end() {
        guard !fading else { return }
        withAnimation(.easeOut(duration: 0.3)) { fading = true } completion: {
            player?.pause()
            finish()
        }
    }
}

/// AVPlayerLayer 铺满（VideoPlayer 会带控件）
private struct PlayerLayer: UIViewRepresentable {
    let player: AVPlayer

    final class View: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
    }

    func makeUIView(context: Context) -> View {
        let v = View()
        let l = v.layer as! AVPlayerLayer
        l.player = player
        l.videoGravity = .resizeAspectFill
        return v
    }

    func updateUIView(_ v: View, context: Context) {}
}

// MARK: - 摇一摇

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake { NotificationCenter.default.post(name: .deviceDidShake, object: nil) }
        super.motionEnded(motion, with: event)
    }
}
