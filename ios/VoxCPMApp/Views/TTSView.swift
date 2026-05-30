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
        ScreenScaffold(title: "多语言朗读", subtitle: "输入文本直接合成，支持 30 语种，无需语言标签") {
            EgoCard {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(text: "文本")
                    AppTextArea(placeholder: "输入要朗读的文本…", text: $text, minHeight: 130)
                }
            }

            EgoCard {
                VStack(alignment: .leading, spacing: 18) {
                    FieldLabel(text: "参数")
                    LabeledSlider(title: "引导强度 cfg", value: $cfg, range: 1...4, step: 0.5, format: "%.1f")
                    LabeledSlider(title: "推理步数", value: $steps, range: 4...30, step: 1, format: "%.0f")
                    Toggle(isOn: $normalize) {
                        Text("文本归一化（数字 / 日期）")
                            .font(.app(size: 14))
                            .foregroundColor(AppColor.textPrimary)
                    }
                    .tint(AppColor.brand)
                }
            }

            PrimaryButton(title: isLoading ? "合成中…" : "生成语音",
                          isLoading: isLoading,
                          enabled: !text.trimmingCharacters(in: .whitespaces).isEmpty) {
                generate()
            }
            .padding(.top, 4)

            if let audioData {
                PlaybackBar(player: player, data: audioData)
            }
            if let errorMessage {
                ErrorNote(text: errorMessage)
            }
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
