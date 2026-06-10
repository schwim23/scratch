import Foundation

/// One transcribed word and where it sits in the recording.
struct WordTiming: Codable, Hashable {
    var word: String
    var start: TimeInterval
    var duration: TimeInterval
}
