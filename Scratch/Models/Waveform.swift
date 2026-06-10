import Foundation

enum Waveform {
    /// Reduce a recording's level history to a fixed-size thumbnail,
    /// normalized to 0...1.
    static func downsample(_ levels: [Float], to count: Int) -> [Float] {
        guard count > 0, !levels.isEmpty else { return [] }
        var out = [Float]()
        out.reserveCapacity(count)
        let chunk = max(1, levels.count / count)
        for i in stride(from: 0, to: levels.count, by: chunk) {
            let slice = levels[i..<min(i + chunk, levels.count)]
            out.append(slice.max() ?? 0)
            if out.count == count { break }
        }
        let peak = out.max() ?? 0
        guard peak > 0 else { return out }
        return out.map { $0 / peak }
    }
}
