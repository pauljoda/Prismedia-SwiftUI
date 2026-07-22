import Foundation

enum RequestActivityAcquisitionAction: Equatable, Hashable, Sendable {
    case research
    case cancel
    case retryImport(allowFormatChange: Bool)
    case startOver

    var title: String {
        switch self {
        case .research: "Search Again"
        case .cancel: "Cancel Acquisition"
        case .retryImport(let allowFormatChange):
            allowFormatChange ? "Import Anyway" : "Retry Import"
        case .startOver: "Start Over"
        }
    }

    var progressTitle: String {
        switch self {
        case .research: "Searching…"
        case .cancel: "Cancelling…"
        case .retryImport: "Importing…"
        case .startOver: "Starting Over…"
        }
    }

    var systemImage: String {
        switch self {
        case .research: "arrow.clockwise"
        case .cancel: "xmark"
        case .retryImport: "arrow.down.doc"
        case .startOver: "arrow.counterclockwise"
        }
    }
}
