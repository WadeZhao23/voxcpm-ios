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
        NavigationStack {
            Form {
                Section("声音描述") {
                    TextEditor(text: $description).frame(minHeight: 70)
                    Text("用自然语言描述：性别、年龄、音色、情绪、语速等")
                        .font(.footnote).foregroundColor(.secondary)
                }
                Section("朗读文本") {
                    TextEditor(text: $text).frame(minHeight: 100)
                }
                Section("参数") {
                    Stepperized("引导强度 cfg", value: $cfg, range: 1.0...4.0, step: 0.5, format: "%.1f")
                    Stepperized("推理步数", value: $steps, range: 4...30, step: 1, format: "%.0f")
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
                Section {
                    Text("提示：声音设计结果有随机性，可多生成 1~3 次挑选满意音色。")
                        .font(.footnote).foregroundColor(.secondary)
                }
            }
            .navigationTitle("声音设计")
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
