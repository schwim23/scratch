import Foundation
import Observation

/// Bridges launch triggers (App Intent, widget deep link) to the library UI,
/// which flips into recording when `pendingCapture` goes true.
@Observable
final class CaptureRouter {
    static let shared = CaptureRouter()
    var pendingCapture = false
}
