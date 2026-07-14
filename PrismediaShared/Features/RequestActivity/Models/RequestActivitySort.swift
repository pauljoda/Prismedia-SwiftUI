import Foundation

public enum RequestActivitySort: String, CaseIterable, Hashable, Identifiable, Sendable {
    case updatedNewest
    case title
    case progress

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .updatedNewest: "Recently Updated"
        case .title: "Title"
        case .progress: "Progress"
        }
    }
}
