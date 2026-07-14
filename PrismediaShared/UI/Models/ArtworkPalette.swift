public struct ArtworkPalette: Equatable, Sendable {
    public let background: ArtworkColor
    public let primary: ArtworkColor
    public let secondary: ArtworkColor

    public init(
        background: ArtworkColor,
        primary: ArtworkColor,
        secondary: ArtworkColor
    ) {
        self.background = background
        self.primary = primary
        self.secondary = secondary
    }
}
