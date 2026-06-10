import Foundation

/// Pure logic behind word-synced playback: which timings to use and which
/// word is current at a given playback time.
enum TranscriptSync {
    /// Recognizer timings when they're usable; otherwise spread the
    /// transcript's words evenly across the duration. On-device recognition
    /// sometimes reports all-zero timestamps, and edited transcripts drop
    /// their timings entirely.
    static func effectiveTimings(
        timings: [WordTiming],
        transcript: String,
        duration: TimeInterval
    ) -> [WordTiming] {
        let usable = timings.count > 1 && timings.contains { $0.start > 0 }
        if usable || timings.count == 1 { return timings }

        let words = transcript
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        guard !words.isEmpty, duration > 0 else { return [] }
        let slot = duration / Double(words.count)
        return words.enumerated().map { i, w in
            WordTiming(word: w, start: Double(i) * slot, duration: slot)
        }
    }

    /// Index of the word being spoken at `time`, or nil before the first word.
    static func currentIndex(in timings: [WordTiming], at time: TimeInterval) -> Int? {
        guard !timings.isEmpty, time >= 0 else { return nil }
        var current: Int?
        for (i, t) in timings.enumerated() where t.start <= time {
            current = i
        }
        return current
    }
}
