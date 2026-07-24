import Foundation

enum EntityIdentifyAvailability: Hashable, Sendable {
    case checking
    case ready(providers: [AdministrativePlugin])
    case queued(item: AdministrativeIdentifyQueueItem, providers: [AdministrativePlugin])
    case unavailable

    var actionLabel: String {
        switch self {
        case .queued: "Pending Review"
        default: "Identify"
        }
    }

    var actionSystemImage: String {
        switch self {
        case .queued: "clock"
        default: "doc.viewfinder"
        }
    }

    var isChecking: Bool {
        self == .checking
    }

    var routesToProviders: Bool {
        self == .unavailable
    }

    var initialQueue: [AdministrativeIdentifyQueueItem] {
        guard case .queued(let item, _) = self else { return [] }
        return [item]
    }

    var initialProviders: [AdministrativePlugin] {
        switch self {
        case .ready(let providers), .queued(_, let providers):
            providers
        case .checking, .unavailable:
            []
        }
    }
}
