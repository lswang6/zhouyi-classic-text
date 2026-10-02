import SwiftUI

// MARK: - 设置

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("solarTime") private var solarTime = false
    @AppStorage("longitude") private var longitude = 116.40

    /// 常用城市经度（东经为正）
    private var cities: [(String, Double)] {
        [(L("北京"), 116.40), (L("上海"), 121.47), (L("广州"), 113.26), (L("深圳"), 114.06), (L("成都"), 104.07),
         (L("重庆"), 106.55), (L("西安"), 108.94), (L("武汉"), 114.31), (L("南京"), 118.80), (L("杭州"), 120.16),
         (L("天津"), 117.20), (L("沈阳"), 123.43), (L("哈尔滨"), 126.63), (L("昆明"), 102.83), (L("乌鲁木齐"), 87.62),
         (L("拉萨"), 91.13), (L("香港"), 114.17), (L("台北"), 121.56), (L("新加坡"), 103.82), (L("东京"), 139.69),
         (L("纽约"), -74.01), (L("洛杉矶"), -118.24), (L("伦敦"), -0.13), (L("悉尼"), 151.21)]
    }

    /// 真太阳时：开启时返回校正后的时刻与说明行，否则原样、无说明。时间起卦与纳甲时柱共用
    static func solar(_ date: Date, on: Bool, longitude: Double) -> (date: Date, note: String?) {
        guard on else { return (date, nil) }
        let t = NaJia.trueSolarTime(date, longitude: longitude, timeZone: .current)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return (t, L("已按真太阳时（经度 %1$@°）· 时钟 %2$@ → 真太阳 %3$@", String(format: "%.2f", longitude), f.string(from: date), f.string(from: t)))
    }

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
                Section {
                    Toggle(L("真太阳时"), isOn: $solarTime).tint(Color.accentText)
                    if solarTime {
                        Picker(L("城市"), selection: $longitude) {
                            ForEach(cities, id: \.1) { Text($0.0).tag($0.1) }
                            if !cities.contains(where: { $0.1 == longitude }) {
                                Text(L("自定义经度")).tag(longitude)
                            }
                        }
                        HStack {
                            Text(L("自定义经度"))
                            TextField("", value: $longitude, format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing)
                        }
                        .onChange(of: longitude) { longitude = min(180, max(-180, longitude)) }
                    }
                } footer: {
                    Text(L("按经度与均时差校正时间起卦的时辰与纳甲时柱。东经为正、西经为负；不使用定位。"))
                }
                .listRowBackground(Color.base)
                Section(L("关于与致谢")) {
                    let info = Bundle.main.infoDictionary
                    credit(L("版本"), "\(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))")
                    VStack(alignment: .leading, spacing: 2) {
                        credit(L("开源许可"), "MIT")
                        Link("github.com/lswang6/zhouyi-Ching-Oracle", destination: URL(string: "https://github.com/lswang6/zhouyi-Ching-Oracle")!)
                            .font(.scaled(13))
                    }
                    .listRowBackground(Color.base)
                    credit(L("字体"), "Noto Serif CJK（SIL OFL 1.1）")
                    credit(L("经文与传文"), L("《周易》通行本（Wikisource 公有领域原文；freizl/yijing, MIT）"))
                    credit(L("历法"), "6tail/tyme4swift (MIT)")
                    credit(L("纳甲对校"), "bopo/najia (MIT)")
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

    /// 致谢一行：上为名目，下为出处
    private func credit(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.scaled(12, .medium)).foregroundStyle(Color.subdued)
            Text(verbatim: value).font(.scaled(15)).foregroundStyle(Color.text)
        }
        .listRowBackground(Color.base)
    }
}

/// 页眉右上角的设置按钮
struct SettingsButton: View {
    @Environment(AppState.self) private var app

    var body: some View {
        Button { app.showSettings = true } label: {
            Image(systemName: "gearshape")
                .font(.scaled(20))
                .foregroundStyle(Color.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L("设置"))
    }
}
