import SwiftUI

/// Transcript as tappable word chips; the word under the playhead glows
/// amber, and tapping a word seeks the audio there.
struct SyncedTranscriptView: View {
    let timings: [WordTiming]
    let currentTime: TimeInterval
    let isPlaying: Bool
    let onTapWord: (TimeInterval) -> Void

    var body: some View {
        let currentIndex = isPlaying || currentTime > 0
            ? TranscriptSync.currentIndex(in: timings, at: currentTime)
            : nil
        FlowLayout(spacing: 5, lineSpacing: 7) {
            ForEach(Array(timings.enumerated()), id: \.offset) { i, timing in
                Text(timing.word)
                    .font(.system(size: 19, weight: i == currentIndex ? .semibold : .regular))
                    .foregroundStyle(i == currentIndex ? Palette.charcoal : Palette.offWhite)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(i == currentIndex ? Palette.amber : .clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onTapWord(timing.start) }
            }
        }
    }
}
