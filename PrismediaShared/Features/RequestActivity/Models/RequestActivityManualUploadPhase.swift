import Foundation

enum RequestActivityManualUploadPhase: Equatable, Sendable {
    case idle
    case preparing
    case uploading(Double)
    case finishing

    var isBusy: Bool {
        self != .idle
    }
}
