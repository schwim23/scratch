import AVFoundation
import Foundation
import Observation

/// Thin observable wrapper around AVAudioPlayer with a UI-rate clock for
/// transcript sync and scrubbing.
@Observable
final class PlaybackEngine {
    private(set) var isPlaying = false
    var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isLoaded = false

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private let delegateProxy = AudioPlayerDelegateProxy()

    func load(url: URL) {
        stopTimer()
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = delegateProxy
        player?.prepareToPlay()
        duration = player?.duration ?? 0
        isLoaded = player != nil
        currentTime = 0
        isPlaying = false
        delegateProxy.onFinish = { [weak self] in
            guard let self else { return }
            self.isPlaying = false
            self.currentTime = 0
            self.stopTimer()
        }
    }

    func playPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            stopTimer()
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        let clamped = min(max(0, time), duration)
        player.currentTime = clamped
        currentTime = clamped
    }

    func stop() {
        player?.stop()
        isPlaying = false
        stopTimer()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let player = self.player, self.isPlaying else { return }
            self.currentTime = player.currentTime
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

/// AVAudioPlayerDelegate requires NSObject; kept separate so PlaybackEngine
/// can stay a plain @Observable class.
private final class AudioPlayerDelegateProxy: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.onFinish?()
        }
    }
}
