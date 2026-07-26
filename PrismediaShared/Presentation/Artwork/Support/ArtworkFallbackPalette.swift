import SwiftUI

public enum ArtworkFallbackPalette {
    public static func colors(for seed: String) -> [Color] {
        let index = StableStringHash.paletteIndex(
            for: seed,
            paletteCount: PrismediaColor.materialSpectrum.count
        )
        return PrismediaColor.materialSpectrumPair(at: index)
    }
}
