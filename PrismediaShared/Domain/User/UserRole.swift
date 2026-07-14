import Foundation

public struct UserRole: RawRepresentable, Codable, Hashable, Sendable {
    public static let admin = UserRole(rawValue: "admin")
    public static let member = UserRole(rawValue: "member")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
