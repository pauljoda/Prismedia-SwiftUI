import Foundation

public struct BookActivityKind: RawRepresentable, Codable, Hashable, Sendable {
    public static let reading = Self(rawValue: "reading")
    public static let listening = Self(rawValue: "listening")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
