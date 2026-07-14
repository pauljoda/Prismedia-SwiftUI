import Foundation

/// Produces stable values for content-driven presentation choices.
///
/// Swift's `Hasher` is intentionally randomized between process launches. This
/// helper mirrors Prismedia Web's UTF-16 polynomial hash so the same title keeps
/// the same fallback artwork across launches and clients.
public enum StableStringHash {
    public static func value(for string: String) -> UInt32 {
        string.utf16.reduce(into: UInt32.zero) { hash, codeUnit in
            hash = hash &* 31 &+ UInt32(codeUnit)
        }
    }

    public static func paletteIndex(for string: String, paletteCount: Int) -> Int {
        precondition(paletteCount > 0, "A palette must contain at least one item.")
        return Int(UInt64(value(for: string)) % UInt64(paletteCount))
    }
}
