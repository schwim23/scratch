import Foundation
import SwiftData

/// All properties have defaults and there are no unique constraints, so the
/// schema stays CloudKit-compatible for a future sync flip.
@Model
final class Note {
    var title: String = ""
    var createdAt: Date = Date.now
    var duration: TimeInterval = 0
    var transcript: String = ""
    var wordTimings: [WordTiming] = []
    var audioFileName: String = ""
    var waveform: [Float] = []

    init(
        title: String,
        createdAt: Date = .now,
        duration: TimeInterval,
        transcript: String,
        wordTimings: [WordTiming],
        audioFileName: String,
        waveform: [Float]
    ) {
        self.title = title
        self.createdAt = createdAt
        self.duration = duration
        self.transcript = transcript
        self.wordTimings = wordTimings
        self.audioFileName = audioFileName
        self.waveform = waveform
    }

    var audioURL: URL { AudioStore.url(for: audioFileName) }

    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return true }
        return title.localizedCaseInsensitiveContains(q)
            || transcript.localizedCaseInsensitiveContains(q)
    }
}
