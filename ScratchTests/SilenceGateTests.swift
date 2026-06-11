import XCTest
@testable import Scratch

final class SilenceGateTests: XCTestCase {
    private let voice = SilenceGate.voiceLevel + 0.1
    private let quiet: Float = 0.01

    func testFiresAfterWindowOfSilenceFollowingSpeech() {
        var gate = SilenceGate(window: 4)
        XCTAssertFalse(gate.register(level: voice, transcriptChanged: false, at: 2))
        XCTAssertFalse(gate.register(level: quiet, transcriptChanged: false, at: 5))
        XCTAssertTrue(gate.register(level: quiet, transcriptChanged: false, at: 6.1))
    }

    func testTranscriptActivityCountsAsVoice() {
        var gate = SilenceGate(window: 4)
        XCTAssertFalse(gate.register(level: quiet, transcriptChanged: true, at: 3))
        // 4s window restarts from the transcript update at t=3
        XCTAssertFalse(gate.register(level: quiet, transcriptChanged: false, at: 6.5))
        XCTAssertTrue(gate.register(level: quiet, transcriptChanged: false, at: 7.1))
    }

    func testOpeningGraceBeforeAnySpeech() {
        var gate = SilenceGate(window: 4)
        // Pure silence from the start: 4s window is not enough...
        XCTAssertFalse(gate.register(level: quiet, transcriptChanged: false, at: 5))
        XCTAssertFalse(gate.register(level: quiet, transcriptChanged: false, at: 9))
        // ...but the 10s opening grace eventually is.
        XCTAssertTrue(gate.register(level: quiet, transcriptChanged: false, at: 10.5))
    }

    func testFiresExactlyOnce() {
        var gate = SilenceGate(window: 2)
        XCTAssertFalse(gate.register(level: voice, transcriptChanged: false, at: 1))
        XCTAssertTrue(gate.register(level: quiet, transcriptChanged: false, at: 4))
        XCTAssertFalse(gate.register(level: quiet, transcriptChanged: false, at: 8))
        XCTAssertFalse(gate.register(level: quiet, transcriptChanged: false, at: 20))
    }

    func testContinuousSpeechNeverFires() {
        var gate = SilenceGate(window: 2)
        for t in stride(from: 0.0, through: 60.0, by: 0.5) {
            XCTAssertFalse(gate.register(level: voice, transcriptChanged: false, at: t))
        }
    }
}
