import SwiftUI

enum StatisticsEventFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case accessed = "Opened"
    case completed = "Completed"
    case skipped = "Skips"

    var id: String { rawValue }
    var kind: ConsumptionEventKind? {
        switch self {
        case .all: return nil
        case .accessed: return .accessed
        case .completed: return .completed
        case .skipped: return .skipped
        }
    }
}
