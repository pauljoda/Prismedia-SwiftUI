import SwiftUI

enum StatisticsTimeframe: String, CaseIterable, Identifiable {
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case year = "Year"
    case all = "All"

    var id: String { rawValue }
    var days: Int? {
        switch self {
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .year: return 365
        case .all: return nil
        }
    }
}
