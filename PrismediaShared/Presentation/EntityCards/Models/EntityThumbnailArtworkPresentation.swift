import SwiftUI

/// One stable rendering contract for entity artwork across grids, rails, and
/// platform shells. The entity decides the frame; the host decides only size.
public struct EntityThumbnailArtworkPresentation: Hashable, Sendable {
    public let aspectRatio: Double
    public let contentMode: ContentMode
    public let surface: EntityArtworkSurface

    public var isWide: Bool { aspectRatio > 1 }
    public var usesBrandPlate: Bool { surface == .brandPlate }

    public func width(forHeight height: CGFloat) -> CGFloat {
        height * aspectRatio
    }

    public init(kind: EntityKind) {
        aspectRatio = kind.thumbnailAspectRatio
        contentMode = kind.definition?.presentation.artworkFit == .contain ? .fit : .fill
        surface = kind.definition?.presentation.artworkSurface ?? .plain
    }
}
