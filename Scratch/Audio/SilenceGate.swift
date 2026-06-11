import Foundation

/// Decides when a take should auto-stop because the speaker went quiet.
/// Fed from the audio tap (levels) and the recognizer (transcript activity);
/// pure so the trigger rule is unit-testable.
struct SilenceGate {
    /// Normalized mic level that counts as voice rather than room noise.
    static let voiceLevel: Float = 0.12
    /// Before any speech is heard, wait at least this long — don't cut off
    /// someone gathering their thoughts.
    static let openingGrace: TimeInterval = 10

    let window: TimeInterval
    private var lastActivity: TimeInterval = 0
    private var hasActivity = false
    private var triggered = false

    init(window: TimeInterval) {
        self.window = window
    }

    /// Returns true exactly once, when silence has lasted long enough.
    mutating func register(level: Float, transcriptChanged: Bool, at elapsed: TimeInterval) -> Bool {
        if level > Self.voiceLevel || transcriptChanged {
            lastActivity = elapsed
            hasActivity = true
            return false
        }
        guard !triggered else { return false }
        let threshold = hasActivity ? window : max(window, Self.openingGrace)
        guard elapsed - lastActivity >= threshold else { return false }
        triggered = true
        return true
    }
}
