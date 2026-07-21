import Foundation

public protocol ArtworkPaletteLoading: Sendable {
    func palette(for url: URL) async -> ArtworkPalette?
    func clearCache() async
}

extension ArtworkPaletteLoading {
    public func clearCache() async {}
}
