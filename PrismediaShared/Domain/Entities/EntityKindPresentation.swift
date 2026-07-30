import Foundation

/// Platform-neutral presentation metadata generated from one backend Entity-kind definition.
public struct EntityKindPresentation: Hashable, Sendable {
    public let icon: EntityKindIcon
    public let referenceIcon: EntityKindIcon
    public let thumbnailWidth: Int
    public let thumbnailHeight: Int
    public let primaryAccent: EntityAccentHue
    public let secondaryAccent: EntityAccentHue
    public let primaryAccentIndex: Int
    public let secondaryAccentIndex: Int
    public let artworkFit: EntityArtworkFit

    public init(
        icon: EntityKindIcon,
        referenceIcon: EntityKindIcon,
        thumbnailWidth: Int,
        thumbnailHeight: Int,
        primaryAccent: EntityAccentHue,
        secondaryAccent: EntityAccentHue,
        primaryAccentIndex: Int,
        secondaryAccentIndex: Int,
        artworkFit: EntityArtworkFit
    ) {
        self.icon = icon
        self.referenceIcon = referenceIcon
        self.thumbnailWidth = thumbnailWidth
        self.thumbnailHeight = thumbnailHeight
        self.primaryAccent = primaryAccent
        self.secondaryAccent = secondaryAccent
        self.primaryAccentIndex = primaryAccentIndex
        self.secondaryAccentIndex = secondaryAccentIndex
        self.artworkFit = artworkFit
    }
}
