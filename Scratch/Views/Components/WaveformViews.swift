import SwiftUI

/// Live input meter on the recording screen. Red while recording — the one
/// place rec-red is allowed — dimmed while paused.
struct LiveWaveformView: View {
    let levels: [Float]
    let isPaused: Bool

    var body: some View {
        Canvas { context, size in
            let count = RecorderEngine.liveLevelCount
            let slot = size.width / CGFloat(count)
            let barWidth = slot * 0.55
            let midY = size.height / 2
            let start = count - levels.count
            for (i, level) in levels.enumerated() {
                let x = CGFloat(start + i) * slot + (slot - barWidth) / 2
                let h = max(3, CGFloat(level) * size.height)
                let rect = CGRect(x: x, y: midY - h / 2, width: barWidth, height: h)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                context.fill(path, with: .color(isPaused ? Palette.dimmed : Palette.recRed))
            }
        }
        .animation(.linear(duration: 0.05), value: levels)
    }
}

/// Static thumbnail rendered from a note's stored waveform samples.
struct WaveformThumbnailView: View {
    let samples: [Float]
    var tint: Color = Palette.dimmed

    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else {
                let line = CGRect(x: 0, y: size.height / 2 - 1, width: size.width, height: 2)
                context.fill(Path(roundedRect: line, cornerRadius: 1), with: .color(tint.opacity(0.4)))
                return
            }
            let slot = size.width / CGFloat(samples.count)
            let barWidth = max(1, slot * 0.6)
            let midY = size.height / 2
            for (i, sample) in samples.enumerated() {
                let x = CGFloat(i) * slot
                let h = max(2, CGFloat(sample) * size.height)
                let rect = CGRect(x: x, y: midY - h / 2, width: barWidth, height: h)
                context.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(tint))
            }
        }
    }
}
