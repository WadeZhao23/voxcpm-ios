import SwiftUI

/// 多语言朗读：输入文本直接合成，无需语言标签。
struct TTSView: View {
    @EnvironmentObject var player: AudioPlayback
    private let client = VoxCPMClient()

    @State private var text = "VoxCPM2 可以直接朗读多种语言的文本，无需指定语言标签。"
    @State private var cfg = 2.0
    @State private var steps = 10.0
    @State private var normalize = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var audioData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("文本") {
                    TextEditor(text: $text).frame(minHeight: 120)
                }
                Section("参数") {
                    Stepperized("引导强度 cfg", value: $cfg, range: 1.0...4.0, step: 0.5, format: "%.1f")
                    Stepperized("推理步数", value: $steps, range: 4...30, step: 1, format: "%.0f")
                    Toggle("文本归一化（数字 / 日期等）", isOn: $normalize)
                }
                Section {
                    GenerateButton(isLoading: isLoading,
                                   disabled: text.trimmingCharacters(in: .whitespaces).isEmpty,
                                   action: generate)
                    if let audioData {
                        Button("重新播放") { player.play(data: audioData) }
                    }
                    if let errorMessage {
                        Text(errorMessage).foregroundColor(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle("多语言朗读")
        }
    }

    private func generate() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let data = try await client.tts(text: text, cfg: cfg, steps: Int(steps), normalize: normalize)
                audioData = data
                player.play(data: data)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
