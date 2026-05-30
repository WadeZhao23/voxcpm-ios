import AVFoundation
import Foundation

/// 录制参考音频（16kHz 单声道 WAV，正好是 VoxCPM 推荐的参考音频规格）。
@MainActor
final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedURL: URL?

    private var recorder: AVAudioRecorder?

    func requestPermissionAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard granted else {
                    print("[AudioRecorder] microphone permission denied")
                    return
                }
                self?.start()
            }
        }
    }

    private func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("voxcpm_ref_\(UUID().uuidString).wav")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
            ]
            let r = try AVAudioRecorder(url: url, settings: settings)
            r.record()
            recorder = r
            recordedURL = url
            isRecording = true
        } catch {
            print("[AudioRecorder] start error: \(error)")
        }
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        isRecording = false
    }
}
