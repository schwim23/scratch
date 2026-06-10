import SwiftUI

/// Scratch palette. Rec-red is reserved exclusively for the live-recording
/// state — never decorative.
enum Palette {
    static let charcoal = Color(red: 0x0E / 255, green: 0x0E / 255, blue: 0x10 / 255)
    static let surface = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x1E / 255)
    static let groove = Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x32 / 255)
    static let offWhite = Color(red: 0xF2 / 255, green: 0xEF / 255, blue: 0xEA / 255)
    static let dimmed = Color(red: 0x8E / 255, green: 0x8E / 255, blue: 0x96 / 255)
    static let amber = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x2E / 255)
    static let recRed = Color(red: 0xFF / 255, green: 0x3B / 255, blue: 0x30 / 255)
}

extension Font {
    /// SF Mono for timestamps, durations, and take counters.
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
