import AppIntents

/// "New Take" — opens the app straight into recording. Bind it to the iPhone
/// Action button, trigger it from Siri/Shortcuts, or the Control Center
/// widget. Compiled into both the app and the widget extension; with
/// `openAppWhenRun` the perform always executes in the app process.
struct StartRecordingIntent: AppIntent {
    static let title: LocalizedStringResource = "New Take"
    static let description = IntentDescription("Start recording a new voice note.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        CaptureRouter.shared.pendingCapture = true
        return .result()
    }
}
