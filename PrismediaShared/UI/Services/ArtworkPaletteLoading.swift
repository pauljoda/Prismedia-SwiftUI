import Foundation

public protocol ArtworkPaletteLoading: Sendable {
    func palette(for url: URL) async -> ArtworkPalette?
}
