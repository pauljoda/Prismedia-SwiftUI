import Foundation

public struct EntityThumbnailTitleStyle: Hashable, Sendable {
    public let fontSize: CGFloat
    public let lineLimit: Int
    public let horizontalPadding: CGFloat
    public let verticalPadding: CGFloat

    public init(layout: EntityThumbnailLayout, width: CGFloat? = nil) {
        if let width, width <= 140 {
            fontSize = 10
            lineLimit = 1
            horizontalPadding = 6
            verticalPadding = 4
            return
        }
        if let width, width <= 220 {
            fontSize = 12
            lineLimit = 2
            horizontalPadding = 7
            verticalPadding = 6
            return
        }

        switch layout {
        case .wall, .list:
            fontSize = 13
            horizontalPadding = 10
            verticalPadding = 8
        case .grid, .rail, .feed, .mediaOnly:
            fontSize = width == nil ? 12 : 13
            horizontalPadding = width == nil ? 7 : 10
            verticalPadding = width == nil ? 6 : 8
        }
        lineLimit = 2
    }
}
