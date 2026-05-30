import AVFoundation
import Foundation

/// 播放后端返回的 WAV 数据。
@MainActor
final class AudioPlayback: ObservableObject {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?

    func play(data: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(data: data)
            player = p
            p.play()
            isPlaying = true
        } catch {
            print("[AudioPlayback] play error: \(error)")
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        isPlaying = false
    }
}
