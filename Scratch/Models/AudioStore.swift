import Foundation

/// Where note audio lives on disk. Notes store only the file name so the
/// container can move between launches/devices.
enum AudioStore {
    static var directory: URL {
        let dir = URL.applicationSupportDirectory.appending(path: "Recordings", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    static func delete(_ fileName: String) {
        guard !fileName.isEmpty else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    /// Copy to a temp file named after the note title so shared audio
    /// arrives as "Idea for the pitch.m4a", not a UUID.
    static func shareableURL(for fileName: String, title: String) -> URL {
        let safe = title
            .components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>"))
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (safe.isEmpty ? "Scratch note" : safe) + ".m4a"
        let dest = FileManager.default.temporaryDirectory.appending(path: name)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: url(for: fileName), to: dest)
            return dest
        } catch {
            return url(for: fileName)
        }
    }
}
