import Foundation

public struct ProgressUnit: RawRepresentable, Codable, Hashable, Sendable {
    public static let page = Self(rawValue: "page")
    public static let cfi = Self(rawValue: "cfi")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
