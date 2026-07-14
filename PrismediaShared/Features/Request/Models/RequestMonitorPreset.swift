import Foundation

public enum RequestMonitorPreset: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case missing
    case future
    case manual = "none"
    case custom

    public var id: String { rawValue }
    public var wireValue: String? { self == .custom ? nil : rawValue }

    public var label: String {
        switch self {
        case .all: "All current and future"
        case .missing: "Missing now"
        case .future: "Future only"
        case .manual: "Manual selection"
        case .custom: "Custom"
        }
    }

    public var detail: String {
        switch self {
        case .all: "Request every current item and automatically monitor new ones."
        case .missing: "Request every missing current item without adding future ones."
        case .future: "Request nothing now and automatically monitor newly discovered items."
        case .manual: "Request only the items you select and add nothing automatically."
        case .custom: "Uses the items selected below."
        }
    }
}
