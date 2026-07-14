import Foundation

public enum RequestActivityWantedList: Hashable, Sendable {
    case missing
    case cutoffUnmet

    var path: String {
        switch self {
        case .missing: "/api/monitors/missing"
        case .cutoffUnmet: "/api/monitors/cutoff-unmet"
        }
    }
}
