import XCTest
@testable import Scratch

final class TitleGeneratorTests: XCTestCase {
    func testEmptyTranscriptFallsBackToTakeNumber() {
        XCTAssertEqual(TitleGenerator.title(from: "", takeNumber: 3), "Take 3")
        XCTAssertEqual(TitleGenerator.title(from: "   \n ", takeNumber: 12), "Take 12")
    }

    func testUsesFirstWords() {
        XCTAssertEqual(
            TitleGenerator.title(from: "call dave about the kitchen quote tomorrow morning", takeNumber: 1),
            "Call dave about the kitchen quote"
        )
    }

    func testCapitalizesFirstLetter() {
        XCTAssertEqual(TitleGenerator.title(from: "hello world", takeNumber: 1), "Hello world")
    }

    func testStripsTrailingCommaAndPeriodButKeepsQuestionMark() {
        XCTAssertEqual(TitleGenerator.title(from: "First thought,", takeNumber: 1), "First thought")
        XCTAssertEqual(TitleGenerator.title(from: "Item one.", takeNumber: 1), "Item one")
        XCTAssertEqual(TitleGenerator.title(from: "Is this on?", takeNumber: 1), "Is this on?")
    }

    func testTruncatesVeryLongWords() {
        let transcript = String(repeating: "a", count: 80) + " tail"
        let title = TitleGenerator.title(from: transcript, takeNumber: 1)
        XCTAssertLessThanOrEqual(title.count, TitleGenerator.maxLength)
    }
}

final class TranscriptSyncTests: XCTestCase {
    func testUsableTimingsPassThrough() {
        let timings = [
            WordTiming(word: "hello", start: 0, duration: 0.4),
            WordTiming(word: "world", start: 0.5, duration: 0.4),
        ]
        let result = TranscriptSync.effectiveTimings(timings: timings, transcript: "hello world", duration: 1)
        XCTAssertEqual(result, timings)
    }

    func testAllZeroTimestampsFallBackToProportional() {
        let zeroed = [
            WordTiming(word: "one", start: 0, duration: 0),
            WordTiming(word: "two", start: 0, duration: 0),
        ]
        let result = TranscriptSync.effectiveTimings(timings: zeroed, transcript: "one two two-and-a-half four", duration: 8)
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[1].start, 2, accuracy: 0.001)
        XCTAssertEqual(result[3].start, 6, accuracy: 0.001)
    }

    func testEmptyTimingsWithEditedTranscriptSpreadEvenly() {
        let result = TranscriptSync.effectiveTimings(timings: [], transcript: "a b c d", duration: 4)
        XCTAssertEqual(result.map(\.start), [0, 1, 2, 3])
    }

    func testEmptyTranscriptYieldsNoTimings() {
        XCTAssertTrue(TranscriptSync.effectiveTimings(timings: [], transcript: " ", duration: 4).isEmpty)
    }

    func testCurrentIndexTracksPlayhead() {
        let timings = [
            WordTiming(word: "a", start: 0, duration: 1),
            WordTiming(word: "b", start: 1, duration: 1),
            WordTiming(word: "c", start: 2, duration: 1),
        ]
        XCTAssertEqual(TranscriptSync.currentIndex(in: timings, at: 0), 0)
        XCTAssertEqual(TranscriptSync.currentIndex(in: timings, at: 1.5), 1)
        XCTAssertEqual(TranscriptSync.currentIndex(in: timings, at: 99), 2)
        XCTAssertNil(TranscriptSync.currentIndex(in: timings, at: -1))
        XCTAssertNil(TranscriptSync.currentIndex(in: [], at: 1))
    }

    func testWordTimingCodableRoundTrip() throws {
        let original = [WordTiming(word: "scratch", start: 1.25, duration: 0.5)]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([WordTiming].self, from: data)
        XCTAssertEqual(decoded, original)
    }
}

final class TimeFormatTests: XCTestCase {
    func testClockFormatting() {
        XCTAssertEqual(TimeFormat.clock(0), "0:00")
        XCTAssertEqual(TimeFormat.clock(7), "0:07")
        XCTAssertEqual(TimeFormat.clock(754), "12:34")
        XCTAssertEqual(TimeFormat.clock(3675), "1:01:15")
        XCTAssertEqual(TimeFormat.clock(-5), "0:00")
    }
}

final class WaveformTests: XCTestCase {
    func testDownsampleProducesRequestedCount() {
        let levels = (0..<1000).map { Float($0 % 100) / 100 }
        let result = Waveform.downsample(levels, to: 60)
        XCTAssertEqual(result.count, 60)
    }

    func testDownsampleNormalizesToPeakOne() {
        let result = Waveform.downsample([0.1, 0.2, 0.4], to: 3)
        XCTAssertEqual(result.max() ?? 0, 1.0, accuracy: 0.0001)
    }

    func testSilenceStaysZeroWithoutDivideByZero() {
        let result = Waveform.downsample([0, 0, 0, 0], to: 2)
        XCTAssertEqual(result, result.map { _ in 0 })
    }

    func testEmptyInput() {
        XCTAssertTrue(Waveform.downsample([], to: 10).isEmpty)
    }
}
