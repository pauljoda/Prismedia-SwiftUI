import SwiftUI

enum StatisticsEventFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case completed = "Plays"
    case skipped = "Skips"

    var id: String { rawValue }
    var kind: PlaybackEventKind? {
        switch self {
        case .all: return nil
        case .completed: return .completed
        case .skipped: return .skipped
        }
    }
}
