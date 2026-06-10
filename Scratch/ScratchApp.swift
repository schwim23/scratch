import SwiftData
import SwiftUI

@main
struct ScratchApp: App {
    /// Unit tests host in this app but build their own in-memory containers;
    /// two live containers for the same schema trap in SwiftData, so skip
    /// the app's UI and store entirely under XCTest.
    private var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    var body: some Scene {
        WindowGroup {
            if isRunningTests {
                Color.clear
            } else {
                RootView()
                    .tint(Palette.amber)
                    .preferredColorScheme(.dark)
                    .modelContainer(for: Note.self)
            }
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.environment["SCRATCH_SCREEN"] == "recording" {
            SeededRecordingScreen()
        } else {
            libraryRoot
        }
        #else
        libraryRoot
        #endif
    }

    private var libraryRoot: some View {
        LibraryView()
        #if DEBUG
            .task { DebugSeed.seedIfNeeded(context: modelContext) }
        #endif
    }
}

#if DEBUG
/// Launch-environment hooks so screens can be screenshot-verified in the
/// simulator without mic/speech permissions.
enum DebugSeed {
    static func seedIfNeeded(context: ModelContext) {
        guard ProcessInfo.processInfo.environment["SCRATCH_SEED"] == "1" else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<Note>())) ?? 0
        guard existing == 0 else { return }

        let samples: [(String, String, TimeInterval, Double)] = [
            ("Idea for the pitch deck opener", "Idea for the pitch deck opener. Start with the publisher revenue chart, then cut straight to the agent demo. Don't explain the protocol first, show it working.", 47, -0.5),
            ("Call Dave about the kitchen quote", "Call Dave about the kitchen quote, he said the cabinet number was negotiable if we commit before July.", 12, -26),
            ("Song sketch, slow build in E minor", "Song sketch, slow build in E minor, drums don't come in until the second verse. Keep the verse almost spoken.", 95, -50),
        ]
        for (title, transcript, duration, hoursAgo) in samples {
            let words = transcript.components(separatedBy: " ")
            let slot = duration / Double(words.count)
            let note = Note(
                title: title,
                createdAt: Date.now.addingTimeInterval(hoursAgo * 3600),
                duration: duration,
                transcript: transcript,
                wordTimings: words.enumerated().map {
                    WordTiming(word: $1, start: Double($0) * slot, duration: slot)
                },
                audioFileName: "missing-debug-audio.m4a",
                waveform: (0..<60).map { i in
                    Float(0.25 + 0.7 * abs(sin(Double(i) * 0.43 + duration)))
                }
            )
            context.insert(note)
        }
    }
}

private struct SeededRecordingScreen: View {
    @State private var recorder = RecorderEngine()

    var body: some View {
        ZStack {
            Palette.charcoal.ignoresSafeArea()
            RecordingView(recorder: recorder, onStop: {}, onCancel: {})
        }
        .task {
            recorder.seedForPreview(
                transcript: "Idea for the pitch deck opener. Start with the publisher revenue chart, then cut straight to the agent demo.",
                elapsed: 23,
                levels: (0..<RecorderEngine.liveLevelCount).map { i in
                    Float(0.15 + 0.8 * abs(sin(Double(i) * 0.37)))
                }
            )
        }
    }
}
#endif
