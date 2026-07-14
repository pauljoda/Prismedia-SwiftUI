import SwiftUI

/// One stable rendering contract for entity artwork across grids, rails, and
/// platform shells. The entity decides the frame; the host decides only size.
public struct EntityThumbnailArtworkPresentation: Hashable, Sendable {
    public let aspectRatio: Double
    public let contentMode: ContentMode

    public var isWide: Bool { aspectRatio > 1 }

    public init(kind: EntityKind) {
        aspectRatio = kind.thumbnailAspectRatio
        contentMode = kind == .studio ? .fit : .fill
    }
}
