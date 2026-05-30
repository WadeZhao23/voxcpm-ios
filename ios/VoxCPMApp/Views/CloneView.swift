import SwiftUI
import UniformTypeIdentifiers

/// 声音克隆：录制或选择一段参考音频，克隆其音色来朗读新文本。
struct CloneView: View {
    @EnvironmentObject var player: AudioPlayback
    @StateObject private var recorder = AudioRecorder()
    private let client = VoxCPMClient()

    @State private var text = "这是用 VoxCPM2 克隆出来的声音。"
    @State private var control = ""
    @State private var referenceURL: URL?
    @State private var showImporter = false
    @State private var cfg = 2.0
    @State private var steps = 10.0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var audioData: Data?

    var body: some View {
        ScreenScaffold(title: "声音克隆", subtitle: "录制或上传一段参考音频，克隆其音色") {
            EgoCard {
                VStack(alignment: .leading, spacing: 14) {
                    FieldLabel(text: "参考音频")
                    HStack(spacing: 10) {
                        recordButton
                        importButton
                    }
                    if let referenceURL {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(AppColor.green)
                            Text(referenceURL.lastPathComponent)
                                .font(.app(size: 12))
                                .foregroundColor(AppColor.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            }

            EgoCard {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(text: "朗读文本")
                    AppTextArea(placeholder: "输入要朗读的文本…", text: $text, minHeight: 100)
                }
            }

            EgoCard {
                VStack(alignment: .leading, spacing: 10) {
                    FieldLabel(text: "风格控制（可选）")
                    AppTextField(placeholder: "例如：稍快、开心的语气", text: $control)
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
                          enabled: referenceURL != nil && !text.trimmingCharacters(in: .whitespaces).isEmpty) {
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
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { result in
            handleImport(result)
        }
    }

    private var recordButton: some View {
        Button {
            if recorder.isRecording {
                recorder.stop()
                referenceURL = recorder.recordedURL
            } else {
                recorder.requestPermissionAndStart()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(recorder.isRecording ? "停止录音" : "录音")
                    .font(.app(size: 15, weight: .semibold))
            }
            .foregroundColor(recorder.isRecording ? .white : AppColor.brand)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                Capsule(style: .continuous)
                    .fill(recorder.isRecording ? AppColor.red : AppColor.brandSoft)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var importButton: some View {
        Button { showImporter = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("选择文件")
                    .font(.app(size: 15, weight: .semibold))
            }
            .foregroundColor(AppColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                Capsule(style: .continuous)
                    .fill(AppColor.fill)
            )
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            // 选中的文件在沙箱外，需先获取访问权限再复制到临时目录
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            do {
                try FileManager.default.copyItem(at: url, to: dest)
                referenceURL = dest
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func generate() {
        guard let ref = referenceURL else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let data = try await client.clone(text: text, control: control, audioURL: ref, cfg: cfg, steps: Int(steps))
                audioData = data
                player.play(data: data)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
