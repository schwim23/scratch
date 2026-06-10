import SwiftUI

/// Play/scrub controls plus the word-synced transcript. Shared by the
/// review sheet and note detail.
struct PlaybackTranscriptSection: View {
    let audioURL: URL
    let transcript: String
    let wordTimings: [WordTiming]
    let duration: TimeInterval

    @State private var player = PlaybackEngine()

    private var timings: [WordTiming] {
        TranscriptSync.effectiveTimings(
            timings: wordTimings,
            transcript: transcript,
            duration: player.duration > 0 ? player.duration : duration
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                Button {
                    player.playPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(player.isLoaded ? Palette.amber : Palette.dimmed)
                }
                .disabled(!player.isLoaded)
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ),
                        in: 0...max(player.duration, 0.01)
                    )
                    .tint(Palette.amber)
                    .disabled(!player.isLoaded)

                    HStack {
                        Text(TimeFormat.clock(player.currentTime))
                        Spacer()
                        Text(TimeFormat.clock(player.duration > 0 ? player.duration : duration))
                    }
                    .font(.mono(12))
                    .foregroundStyle(Palette.dimmed)
                }
            }

            ScrollView {
                if timings.isEmpty {
                    Text(transcript.isEmpty ? "No transcript captured." : transcript)
                        .font(.system(size: 19))
                        .foregroundStyle(transcript.isEmpty ? Palette.dimmed : Palette.offWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    SyncedTranscriptView(
                        timings: timings,
                        currentTime: player.currentTime,
                        isPlaying: player.isPlaying,
                        onTapWord: { time in
                            player.seek(to: time)
                            if !player.isPlaying { player.playPause() }
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear { player.load(url: audioURL) }
        .onDisappear { player.stop() }
    }
}
