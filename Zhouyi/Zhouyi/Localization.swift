import SwiftUI

/// 界面语言。rawValue 即 lproj 目录名
enum AppLanguage: String, CaseIterable {
    case system, zhHans = "zh-Hans", zhHant = "zh-Hant", en, ja, ko, es, fr, de, ptBR = "pt-BR", ru, ar

    /// 自称名，不翻译
    var endonym: String {
        switch self {
        case .system: L("跟随系统")
        case .zhHans: "简体中文"
        case .zhHant: "繁體中文"
        case .en: "English"
        case .ja: "日本語"
        case .ko: "한국어"
        case .es: "Español"
        case .fr: "Français"
        case .de: "Deutsch"
        case .ptBR: "Português"
        case .ru: "Русский"
        case .ar: "العربية"
        }
    }

    /// 跟随系统：依次取首选语言中第一个支持的（与系统选 lproj 一致）；繁体地区归 zh-Hant，葡语归 pt-BR，都不匹配用英文
    static func resolve(_ preferred: [String]) -> AppLanguage {
        for p in preferred {
            if p.hasPrefix("zh") {
                return ["zh-Hant", "zh-TW", "zh-HK", "zh-MO"].contains { p.hasPrefix($0) } ? .zhHant : .zhHans
            }
            let code = String(p.prefix { $0 != "-" && $0 != "_" })
            if code == "pt" { return .ptBR }
            if let l = AppLanguage(rawValue: code), l != .system { return l }
        }
        return .en
    }
}

@Observable
final class Localizer {
    static let shared = Localizer()

    var choice: AppLanguage {
        didSet {
            UserDefaults.standard.set(choice.rawValue, forKey: "appLanguage")
            bundle = Self.bundle(for: lang)
        }
    }
    /// 当前语言的 lproj；尚无该语言时退回主包（即中文）
    private(set) var bundle: Bundle

    init() {
        choice = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "") ?? .system
        bundle = .main
        bundle = Self.bundle(for: lang)
    }

    /// 实际语言，不会是 .system
    var lang: AppLanguage { choice == .system ? .resolve(Locale.preferredLanguages) : choice }
    var isChinese: Bool { lang == .zhHans || lang == .zhHant }
    var isRTL: Bool { lang == .ar }
    /// 跟随系统且首选语言同语种时用完整地区（en-GB 日期为 “28 Sep”）
    var locale: Locale {
        if choice == .system, let p = Locale.preferredLanguages.first, p.hasPrefix(lang.rawValue.prefix(2)) { return Locale(identifier: p) }
        return Locale(identifier: lang.rawValue)
    }

    private static func bundle(for lang: AppLanguage) -> Bundle {
        Bundle.main.path(forResource: lang.rawValue, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }
}

/// 取本地化文字。读 Localizer.shared.bundle，SwiftUI 在 body 中据此追踪语言切换
func L(_ key: String, table: String? = nil, default def: String? = nil) -> String {
    Localizer.shared.bundle.localizedString(forKey: key, value: def ?? key, table: table)
}

/// 格式化：键为含 %@ / %d 的中文原文
func L(_ key: String, _ args: CVarArg...) -> String {
    String(format: L(key), locale: Localizer.shared.locale, arguments: args)
}

// MARK: - 设置

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let loc = Localizer.shared
        NavigationStack {
            List {
                Section(L("语言")) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Button { loc.choice = lang } label: {
                            HStack {
                                Text(verbatim: lang.endonym).foregroundStyle(Color.text)
                                Spacer()
                                if loc.choice == lang {
                                    Image(systemName: "checkmark").foregroundStyle(Color.accentText)
                                        .accessibilityHidden(true)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(loc.choice == lang ? .isSelected : [])
                        .listRowBackground(Color.base)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .paperBackground()
            // RTL→LTR 实时切换时 List 单元格会残留镜像，方向变了就重建
            .id(loc.isRTL)
            .navigationTitle(L("设置"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("完成")) { dismiss() }
                }
            }
        }
        // sheet 另起 UIKit 呈现，不继承 RootView 的方向，须在此重设
        .environment(\.locale, loc.locale)
        .environment(\.layoutDirection, loc.isRTL ? .rightToLeft : .leftToRight)
    }
}

/// 页眉右上角的设置按钮
struct SettingsButton: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Button { app.showSettings = true } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 20))
                .foregroundStyle(Color.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L("设置"))
    }
}
