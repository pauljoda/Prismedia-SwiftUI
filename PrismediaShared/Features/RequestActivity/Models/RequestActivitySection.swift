import Foundation

public enum RequestActivitySection: String, CaseIterable, Hashable, Identifiable, Sendable {
    case downloads
    case missing
    case cutoffUnmet
    case history

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .downloads: "Downloads"
        case .missing: "Missing"
        case .cutoffUnmet: "Cutoff Unmet"
        case .history: "History"
        }
    }

    public var systemImage: String {
        switch self {
        case .downloads: "arrow.down.circle"
        case .missing: "shippingbox"
        case .cutoffUnmet: "exclamationmark.triangle"
        case .history: "clock.arrow.circlepath"
        }
    }
}
