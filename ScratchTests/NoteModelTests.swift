import SwiftData
import XCTest
@testable import Scratch

final class NoteModelTests: XCTestCase {
    /// Note: a plain ModelContext, not container.mainContext — accessing
    /// mainContext inside a test host traps in SwiftData on iOS 26.2.
    @MainActor
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Note.self, configurations: config)
        return ModelContext(container)
    }

    @MainActor
    func testInsertAndFetchRoundTrip() throws {
        let context = try makeContext()
        let note = Note(
            title: "Test take",
            duration: 12.5,
            transcript: "hello from the test",
            wordTimings: [WordTiming(word: "hello", start: 0, duration: 0.3)],
            audioFileName: "abc.m4a",
            waveform: [0.1, 0.9, 0.4]
        )
        context.insert(note)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Note>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].title, "Test take")
        XCTAssertEqual(fetched[0].wordTimings.first?.word, "hello")
        XCTAssertEqual(fetched[0].waveform, [0.1, 0.9, 0.4])
    }

    func testSearchMatchesTitleAndTranscriptCaseInsensitive() {
        let note = Note(
            title: "Kitchen quote",
            duration: 1,
            transcript: "Call Dave about the cabinets",
            wordTimings: [],
            audioFileName: "x.m4a",
            waveform: []
        )
        XCTAssertTrue(note.matches("kitchen"))
        XCTAssertTrue(note.matches("DAVE"))
        XCTAssertTrue(note.matches("  cabinets "))
        XCTAssertTrue(note.matches(""))
        XCTAssertFalse(note.matches("garage"))
    }

    func testShareKindItems() {
        let textOnly = ShareKind.text.items(transcript: "hi", audioFileName: "x.m4a", title: "T")
        XCTAssertEqual(textOnly.count, 1)
        XCTAssertEqual(textOnly[0] as? String, "hi")

        let both = ShareKind.both.items(transcript: "hi", audioFileName: "x.m4a", title: "T")
        XCTAssertEqual(both.count, 2)
        XCTAssertTrue(both[1] is URL)
    }
}
