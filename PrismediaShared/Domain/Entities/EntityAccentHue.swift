import Foundation

/// Named hue in Prismedia's shared Entity spectrum.
public struct EntityAccentHue: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
