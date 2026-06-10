import Foundation

enum TitleGenerator {
    static let maxLength = 48
    static let maxWords = 6

    /// First few words of the transcript become the title; an empty
    /// transcript falls back to studio-style take numbering.
    static func title(from transcript: String, takeNumber: Int) -> String {
        let words = transcript
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        guard !words.isEmpty else { return "Take \(takeNumber)" }

        var title = words.prefix(maxWords).joined(separator: " ")
        if title.count > maxLength {
            title = String(title.prefix(maxLength)).trimmingCharacters(in: .whitespaces)
        }
        // Trim trailing punctuation left mid-sentence, but keep ? and !
        while let last = title.last, [",", ".", ";", ":"].contains(String(last)) {
            title.removeLast()
        }
        return title.prefix(1).uppercased() + title.dropFirst()
    }
}
