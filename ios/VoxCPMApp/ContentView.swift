import SwiftUI

struct ContentView: View {
    @StateObject private var player = AudioPlayback()
    @State private var selectedTab = 0

    private let items: [FloatingTabBar.Item] = [
        .init(tag: 0, title: "朗读", icon: "text.bubble.fill"),
        .init(tag: 1, title: "克隆", icon: "waveform"),
        .init(tag: 2, title: "设计", icon: "paintbrush.fill"),
        .init(tag: 3, title: "设置", icon: "gearshape.fill"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColor.pageBackground.ignoresSafeArea()

            // keep-alive：四个页面同时挂载，靠 opacity 切换，保留各自滚动/输入状态
            ZStack {
                screen(0) { TTSView() }
                screen(1) { CloneView() }
                screen(2) { DesignView() }
                screen(3) { SettingsView() }
            }

            FloatingTabBar(selection: $selectedTab, items: items)
                .padding(.horizontal, 21)
        }
        .environmentObject(player)
    }

    @ViewBuilder
    private func screen<V: View>(_ tag: Int, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .opacity(selectedTab == tag ? 1 : 0)
            .allowsHitTesting(selectedTab == tag)
    }
}
