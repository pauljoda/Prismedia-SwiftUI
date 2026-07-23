import Foundation

enum AcquisitionBlocklistClearRange: String, CaseIterable, Identifiable {
    case lastHour
    case lastDay
    case lastWeek
    case lastFourWeeks
    case allTime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lastHour: "Last hour"
        case .lastDay: "Last 24 hours"
        case .lastWeek: "Last 7 days"
        case .lastFourWeeks: "Last 4 weeks"
        case .allTime: "All time"
        }
    }

    func createdAfter(relativeTo now: Date = Date()) -> Date? {
        let interval: TimeInterval? = switch self {
        case .lastHour: 60 * 60
        case .lastDay: 24 * 60 * 60
        case .lastWeek: 7 * 24 * 60 * 60
        case .lastFourWeeks: 28 * 24 * 60 * 60
        case .allTime: nil
        }
        return interval.map { now.addingTimeInterval(-$0) }
    }
}
