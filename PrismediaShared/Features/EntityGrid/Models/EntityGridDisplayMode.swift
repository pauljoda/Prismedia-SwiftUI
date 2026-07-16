import Foundation

public enum EntityGridDisplayMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case grid
    case list
    case feed
    case wall

    public var id: Self { self }

    public var label: String {
        switch self {
        case .grid: "Grid"
        case .list: "List"
        case .feed: "Feed"
        case .wall: "Media Wall"
        }
    }

    public var systemImage: String {
        switch self {
        case .grid: "square.grid.2x2"
        case .list: "list.bullet"
        case .feed: "rectangle.grid.1x2"
        case .wall: "rectangle.grid.3x2"
        }
    }

    public var thumbnailLayout: EntityThumbnailLayout {
        switch self {
        case .grid: .grid
        case .list: .list
        case .feed: .feed
        case .wall: .mediaOnly
        }
    }

    public func thumbnailLayout(for kind: EntityKind) -> EntityThumbnailLayout {
        if self == .list, kind == .video { return .rail }
        return thumbnailLayout
    }
}
