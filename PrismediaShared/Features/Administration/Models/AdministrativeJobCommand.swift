import Foundation

/// An explicit worker operation, separate from read-only activity refreshes.
enum AdministrativeJobCommand: Sendable {
    case run(type: String)
    case cancel(id: UUID)
    case stop(type: String?)
    case clearFailures(type: String?)

    var confirmationTitle: String {
        switch self {
        case .run: "Run Job?"
        case .cancel: "Stop This Job?"
        case .stop(let type): type == nil ? "Stop All Jobs?" : "Stop These Jobs?"
        case .clearFailures(let type): type == nil ? "Clear All Failures?" : "Clear These Failures?"
        }
    }

    var actionTitle: String {
        switch self {
        case .run: "Run"
        case .cancel: "Stop Job"
        case .stop: "Stop Jobs"
        case .clearFailures: "Clear Failures"
        }
    }

    var confirmationMessage: String {
        switch self {
        case .run: "The worker will queue this job."
        case .cancel, .stop: "Running and queued work will be cancelled."
        case .clearFailures: "This clears the jobs from Needs Attention. It does not retry the work or delete media."
        }
    }
}
