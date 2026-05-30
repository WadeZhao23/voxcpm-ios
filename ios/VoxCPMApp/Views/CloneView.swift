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
        NavigationStack {
            Form {
                Section("参考音频") {
                    HStack {
                        Button(recorder.isRecording ? "停止录音" : "录音") {
                            if recorder.isRecording {
                                recorder.stop()
                                referenceURL = recorder.recordedURL
                            } else {
                                recorder.requestPermissionAndStart()
                            }
                        }
                        .foregroundColor(recorder.isRecording ? .red : .accentColor)
                        Spacer()
                        Button("选择文件") { showImporter = true }
                    }
                    if let referenceURL {
                        Text("已选择：\(referenceURL.lastPathComponent)")
                            .font(.footnote).foregroundColor(.secondary)
                    }
                }
                Section("朗读文本") {
                    TextEditor(text: $text).frame(minHeight: 100)
                }
                Section("风格控制（可选）") {
                    TextField("例如：稍快、开心的语气", text: $control)
                }
                Section("参数") {
                    Stepperized("引导强度 cfg", value: $cfg, range: 1.0...4.0, step: 0.5, format: "%.1f")
                    Stepperized("推理步数", value: $steps, range: 4...30, step: 1, format: "%.0f")
                }
                Section {
                    GenerateButton(isLoading: isLoading,
                                   disabled: referenceURL == nil || text.trimmingCharacters(in: .whitespaces).isEmpty,
                                   action: generate)
                    if let audioData {
                        Button("重新播放") { player.play(data: audioData) }
                    }
                    if let errorMessage {
                        Text(errorMessage).foregroundColor(.red).font(.footnote)
                    }
                }
            }
            .navigationTitle("声音克隆")
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { result in
                handleImport(result)
            }
        }
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
