import SwiftUI

/// 声音设计：用一句自然语言描述凭空造一个音色，无需参考音频。
struct DesignView: View {
    @EnvironmentObject var player: AudioPlayback
    private let client = VoxCPMClient()

    @State private var description = "一位年轻女性，声音温柔甜美，语速适中"
    @State private var text = "你好，欢迎使用 VoxCPM2 声音设计！"
    @State private var cfg = 2.0
    @State private var steps = 10.0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var audioData: Data?

    var body: some View {
        ScreenScaffold(title: "声音设计", subtitle: "用一句话描述凭空造一个音色，无需参考音频") {
            EgoCard {
                VStack(alignment: .leading, spacing: 10) {
                    FieldLabel(text: "声音描述")
                    AppTextArea(placeholder: "性别、年龄、音色、情绪、语速…", text: $description, minHeight: 76)
                    Text("例：一位沉稳的中年男性，低沉磁性，语速偏慢")
                        .font(.app(size: 12))
                        .foregroundColor(AppColor.textTertiary)
                }
            }

            EgoCard {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(text: "朗读文本")
                    AppTextArea(placeholder: "输入要朗读的文本…", text: $text, minHeight: 110)
                }
            }

            EgoCard {
                VStack(alignment: .leading, spacing: 18) {
                    FieldLabel(text: "参数")
                    LabeledSlider(title: "引导强度 cfg", value: $cfg, range: 1...4, step: 0.5, format: "%.1f")
                    LabeledSlider(title: "推理步数", value: $steps, range: 4...30, step: 1, format: "%.0f")
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

            Text("提示：声音设计结果有随机性，可多生成 1~3 次挑选满意音色。")
                .font(.app(size: 12))
                .foregroundColor(AppColor.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    private func generate() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let data = try await client.design(text: text, description: description, cfg: cfg, steps: Int(steps))
                audioData = data
                player.play(data: data)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
