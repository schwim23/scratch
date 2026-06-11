import AppIntents
import SwiftUI
import WidgetKit

@main
struct ScratchWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickCaptureWidget()
        QuickCaptureControl()
    }
}

// MARK: - Lock Screen / Home Screen widget

struct QuickCaptureEntry: TimelineEntry {
    let date: Date
}

struct QuickCaptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickCaptureEntry {
        QuickCaptureEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickCaptureEntry) -> Void) {
        completion(QuickCaptureEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCaptureEntry>) -> Void) {
        completion(Timeline(entries: [QuickCaptureEntry(date: .now)], policy: .never))
    }
}

struct QuickCaptureWidgetView: View {
    @Environment(\.widgetFamily) private var family

    private static let amber = Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x2E / 255)
    private static let charcoal = Color(red: 0x0E / 255, green: 0x0E / 255, blue: 0x10 / 255)

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                ZStack {
                    Circle().fill(.fill.tertiary)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22, weight: .semibold))
                }
            default:
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Self.amber)
                            .frame(width: 52, height: 52)
                        Image(systemName: "mic.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Self.charcoal)
                    }
                    Text("New Take")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .widgetURL(URL(string: "scratch://record"))
        .containerBackground(for: .widget) { Self.charcoal }
    }
}

struct QuickCaptureWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ScratchQuickCapture", provider: QuickCaptureProvider()) { _ in
            QuickCaptureWidgetView()
        }
        .configurationDisplayName("New Take")
        .description("Jump straight into recording a voice note.")
        .supportedFamilies([.accessoryCircular, .systemSmall])
    }
}

// MARK: - Control Center / Lock Screen control (iOS 18+)

struct QuickCaptureControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "ScratchQuickCaptureControl") {
            ControlWidgetButton(action: StartRecordingIntent()) {
                Label("New Take", systemImage: "mic.fill")
            }
        }
        .displayName("New Take")
        .description("Start recording a voice note in Scratch.")
    }
}
