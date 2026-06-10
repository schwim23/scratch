import SwiftUI
import UIKit

/// What gets handed to the iOS share sheet.
enum ShareKind: String, Identifiable {
    case text, audio, both
    var id: String { rawValue }

    func items(transcript: String, audioFileName: String, title: String) -> [Any] {
        switch self {
        case .text:
            return [transcript]
        case .audio:
            return [AudioStore.shareableURL(for: audioFileName, title: title)]
        case .both:
            return [transcript, AudioStore.shareableURL(for: audioFileName, title: title)]
        }
    }
}

/// UIActivityViewController wrapper — used instead of ShareLink so a single
/// share can carry mixed items (transcript text + audio file).
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// "Share → Text / Audio / Both" menu, shared by the review sheet and
/// note detail.
struct ShareMenu: View {
    let onPick: (ShareKind) -> Void

    var body: some View {
        Menu {
            Button { onPick(.text) } label: {
                Label("Share as Text", systemImage: "text.alignleft")
            }
            Button { onPick(.audio) } label: {
                Label("Share Audio", systemImage: "waveform")
            }
            Button { onPick(.both) } label: {
                Label("Share Both", systemImage: "square.and.arrow.up.on.square")
            }
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}
