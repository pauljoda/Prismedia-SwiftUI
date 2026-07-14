import Foundation

public enum RequestActivityStatusFilter: String, CaseIterable, Hashable, Identifiable, Sendable {
    case all
    case downloading
    case searching
    case cleanup
    case attention

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: "All Statuses"
        case .downloading: "Downloading"
        case .searching: "Searching"
        case .cleanup: "Cleaning Up"
        case .attention: "Needs Attention"
        }
    }

    func matches(_ status: AcquisitionStatus) -> Bool {
        switch self {
        case .all: true
        case .downloading: RequestActivityStatusPolicy.tone(for: status) == .downloading
        case .searching: RequestActivityStatusPolicy.tone(for: status) == .searching
        case .cleanup: RequestActivityStatusPolicy.tone(for: status) == .cleanup
        case .attention:
            [.attention, .failed].contains(RequestActivityStatusPolicy.tone(for: status))
        }
    }
}
