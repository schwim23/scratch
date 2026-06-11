import AppIntents

struct ScratchShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "New take in \(.applicationName)",
                "Start a \(.applicationName)",
                "Record a \(.applicationName) note",
            ],
            shortTitle: "New Take",
            systemImageName: "mic.fill"
        )
    }
}
