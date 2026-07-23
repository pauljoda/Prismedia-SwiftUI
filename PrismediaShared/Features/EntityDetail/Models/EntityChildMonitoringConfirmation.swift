import Foundation

enum EntityChildMonitoringConfirmation: Equatable, Identifiable, Sendable {
    case item(UUID)
    case all

    var id: String {
        switch self {
        case .item(let id):
            return "item-\(id.uuidString)"
        case .all:
            return "all"
        }
    }
}
