import SwiftUI

struct ContentView: View {
    // 全局共享一个播放器
    @StateObject private var player = AudioPlayback()

    var body: some View {
        TabView {
            TTSView()
                .tabItem { Label("朗读", systemImage: "text.bubble") }
            CloneView()
                .tabItem { Label("克隆", systemImage: "waveform") }
            DesignView()
                .tabItem { Label("设计", systemImage: "paintbrush") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gear") }
        }
        .environmentObject(player)
    }
}
